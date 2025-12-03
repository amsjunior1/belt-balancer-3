require("helper.math")
require("util")
require("helper.conversion")

balancer_functions = {}

-- ============================================================================
-- TABELA DE VELOCIDADE BASE (Por Peça de Balancer)
-- Amarelo: 0.25 items/tick (15/s)
-- Vermelho: 0.50 items/tick (30/s)
-- Azul: 0.75 items/tick (45/s)
-- Turbo: 1.00 items/tick (60/s)
-- ============================================================================
local global_speed_limits = {
    ["balancer-part"] = 0.25,
    ["balancer-part-fast"] = 0.5,
    ["balancer-part-express"] = 0.75,
    ["balancer-part-turbo"] = 1.0,
    ["belt-balancer"] = 0.25,
    ["belt-balancer-fast"] = 0.5,
    ["belt-balancer-express"] = 0.75,
    ["belt-balancer-turbo"] = 1.0,
}

function balancer_functions.new()
    local balancer = {}
    balancer.unit_number = get_next_balancer_unit_number()
    balancer.parts = {}
    balancer.nth_tick = 0
    balancer.buffer = {}
    balancer.input_lanes = {}
    balancer.output_lanes = {}
    
    balancer.global_accumulator = 0
    balancer.global_speed = 0.25 
    
    storage.balancer[balancer.unit_number] = balancer
    return balancer
end

function balancer_functions.merge(balancer_index, balancer_index2)
    local balancer = storage.balancer[balancer_index]
    local balancer2 = storage.balancer[balancer_index2]
    
    if not balancer or not balancer2 then return end

    for k, part_index in pairs(balancer2.parts) do
        balancer.parts[k] = part_index
        local part = storage.parts[part_index]
        if part then
            part.balancer = balancer_index
            for _, belt_index in pairs(part.input_belts) do
                local belt = storage.belts[belt_index]
                if belt then
                    belt.output_balancer[balancer_index2] = nil
                    belt.output_balancer[balancer_index] = balancer_index
                end
            end
            for _, belt_index in pairs(part.output_belts) do
                local belt = storage.belts[belt_index]
                if belt then
                    belt.input_balancer[balancer_index2] = nil
                    belt.input_balancer[balancer_index] = balancer_index
                end
            end
        end
    end

    balancer_functions.reload_lanes(balancer_index)

    for _, item in pairs(balancer2.buffer) do
        table.insert(balancer.buffer, item)
    end
    
    if balancer2.global_accumulator then
        balancer.global_accumulator = (balancer.global_accumulator or 0) + balancer2.global_accumulator
    end

    storage.balancer[balancer_index2] = nil
end

-- ============================================================================
-- RELOAD LANES: Agora calcula velocidade baseada no NÚMERO DE PEÇAS
-- ============================================================================
function balancer_functions.reload_lanes(balancer_index)
    local balancer = storage.balancer[balancer_index]
    if not balancer then return end

    balancer.input_lanes = {}
    balancer.output_lanes = {}

    local main_entity_name = nil
    local part_count = 0 -- Contador de peças

    for _, part_index in pairs(balancer.parts) do
        local part = storage.parts[part_index]
        if part then
            part_count = part_count + 1 -- Conta +1 peça
            
            if part.entity and part.entity.valid then
                main_entity_name = part.entity.name
            end

            for _, belt_index in pairs(part.input_belts) do
                local belt = storage.belts[belt_index]
                if belt then
                    for _, lane in pairs(belt.lanes) do
                        if storage.lanes[lane] then
                            balancer.input_lanes[lane] = storage.lanes[lane]
                        end
                    end
                end
            end
            for _, belt_index in pairs(part.output_belts) do
                local belt = storage.belts[belt_index]
                if belt then
                    for _, lane in pairs(belt.lanes) do
                        if storage.lanes[lane] then
                            balancer.output_lanes[lane] = storage.lanes[lane]
                        end
                    end
                end
            end
        end
    end

    -- CORREÇÃO AQUI:
    -- Velocidade Total = (Velocidade da Tier) * (Número de Peças)
    -- Exemplo Foto: 0.5 (Red) * 2 (Peças) = 1.0 (60 itens/s)
    local base_speed = 0.25
    if main_entity_name then
        base_speed = global_speed_limits[main_entity_name] or 0.25
    end
    
    -- Se part_count for 0 (erro), assume 1 para não travar
    if part_count < 1 then part_count = 1 end
    
    balancer.global_speed = base_speed * part_count
    
    balancer_functions.recalculate_nth_tick(balancer_index)
end

function balancer_functions.find_from_part(part)
    if part.balancer ~= nil then return part.balancer end
    local entity = part.entity
    local nearby_balancer_indices = part_functions.find_nearby_balancer(entity)
    local nearby_balancer_amount = table_size(nearby_balancer_indices)

    if nearby_balancer_amount == 0 then
        local balancer = balancer_functions.new()
        balancer.parts[entity.unit_number] = entity.unit_number
        balancer_functions.reload_lanes(balancer.unit_number)
        return balancer.unit_number
    elseif nearby_balancer_amount == 1 then
        local balancer
        for _, index in pairs(nearby_balancer_indices) do
            balancer = storage.balancer[index]
            if balancer then
                balancer.parts[entity.unit_number] = entity.unit_number
            end
        end
        if balancer then 
            balancer_functions.reload_lanes(balancer.unit_number)
        end
        return balancer and balancer.unit_number
    elseif nearby_balancer_amount >= 2 then
        local base_balancer_index
        for _, nearby_balancer_index in pairs(nearby_balancer_indices) do
            if not base_balancer_index then
                base_balancer_index = nearby_balancer_index
                local balancer = storage.balancer[nearby_balancer_index]
                if balancer then
                    balancer.parts[entity.unit_number] = entity.unit_number
                end
            else
                balancer_functions.merge(base_balancer_index, nearby_balancer_index)
            end
        end
        balancer_functions.reload_lanes(base_balancer_index)
        return base_balancer_index
    end
end

function balancer_functions.recalculate_nth_tick(balancer_index)
    local balancer = storage.balancer[balancer_index]
    if not balancer then return end

    if table_size(balancer.input_lanes) == 0 or table_size(balancer.output_lanes) == 0 or table_size(balancer.parts) == 0 then
        unregister_on_tick(balancer_index)
        balancer.nth_tick = 0
        return
    end
    
    local target_tick = 1 
    if balancer.nth_tick ~= target_tick then
        balancer.nth_tick = target_tick
        unregister_on_tick(balancer_index)
        register_on_tick(target_tick, balancer_index)
    end
end

function balancer_functions.run(balancer_index)
    local balancer = storage.balancer[balancer_index]
    if not balancer then 
        unregister_on_tick(balancer_index)
        return 
    end

    local output_lane_count = table_size(balancer.output_lanes)
    if output_lane_count == 0 then return end
    
    if not balancer.global_accumulator then balancer.global_accumulator = 0 end
    if not balancer.global_speed then balancer.global_speed = 0.25 end

    -- 1. ACUMULADOR (Agora com velocidade multiplicada por peças)
    balancer.global_accumulator = balancer.global_accumulator + balancer.global_speed

    -- Cap ajustado para permitir bufferização maior em balancers gigantes (4x4, 8x8)
    -- Multiplicamos o Cap um pouco baseado na velocidade para não gargalar balancers grandes
    local cap = math.max(2.0, balancer.global_speed * 2)
    if balancer.global_accumulator > cap then balancer.global_accumulator = cap end

    -- 2. INPUT
    local buffer_limit = output_lane_count * 6 
    local items_in_buffer = #balancer.buffer
    
    if items_in_buffer < buffer_limit then
        for _, lane in pairs(balancer.input_lanes) do
            if items_in_buffer >= buffer_limit then break end
            
            if lane and lane.valid and #lane > 0 then
                local item = lane[1]
                local simple_stack = stablize_item_stack(item)
                
                if simple_stack then
                    local removed = lane.remove_item(simple_stack)
                    if removed > 0 then
                        table.insert(balancer.buffer, simple_stack)
                        items_in_buffer = items_in_buffer + 1
                    end
                end
            end
        end
    end

    if #balancer.buffer == 0 then return end

    -- 3. OUTPUT
    local starting_index = balancer.next_output
    local lane_index, lane
    
    if starting_index and balancer.output_lanes[starting_index] then 
        lane_index = starting_index
        lane = balancer.output_lanes[starting_index]
    else
        lane_index, lane = next(balancer.output_lanes)
    end
    if not lane_index then lane_index, lane = next(balancer.output_lanes) end

    local attempts = 0
    local max_attempts = output_lane_count * 2 

    while balancer.global_accumulator >= 1.0 and #balancer.buffer > 0 and attempts < max_attempts do
        if not lane_index then 
            lane_index, lane = next(balancer.output_lanes)
            if not lane_index then break end
        end

        local inserted = false
        
        if lane and lane.valid and lane.can_insert_at_back() then
            local input = balancer.buffer[1]
            if input and lane.insert_at_back(input) then
                table.remove(balancer.buffer, 1)
                balancer.global_accumulator = balancer.global_accumulator - 1.0
                inserted = true
            end
        end

        lane_index, lane = next(balancer.output_lanes, lane_index)
        
        if inserted then
            balancer.next_output = lane_index
            attempts = 0
        else
            attempts = attempts + 1
        end
        
        if lane_index == starting_index and attempts >= output_lane_count then break end
    end
end

function balancer_functions.check_track(balancer_index, drop_to)
    local balancer = storage.balancer[balancer_index]
    if not balancer then return false end

    if table_size(balancer.parts) == 0 then
        if table_size(balancer.output_lanes) > 0 or table_size(balancer.input_lanes) > 0 then
            return true 
        end
        balancer_functions.empty_buffer(balancer, drop_to)
        storage.balancer[balancer_index] = nil
        return false
    end
    return true
end

function balancer_functions.empty_buffer(balancer, drop_to)
    if drop_to.buffer and drop_to.buffer.valid then
        for _, item in pairs(balancer.buffer) do
            drop_to.buffer.insert(item)
        end
    end
end

function balancer_functions.get_linked(balancer)
    local matrix = {}
    for _, part_index in pairs(balancer.parts) do
        local part = storage.parts[part_index]
        if part and part.entity and part.entity.valid then
            local pos = part.entity.position
            if not matrix[pos.x] then matrix[pos.x] = {} end
            matrix[pos.x][pos.y] = part.entity
        end
    end
    local curr_num = 0
    local result = {}
    repeat
        curr_num = curr_num + 1
        balancer_functions.expand_first(matrix, curr_num, result)
    until (table_size(matrix) == 0)
    return result
end

function balancer_functions.expand_first(matrix, num, result)
    for x_key, _ in pairs(matrix) do
        for y_key, _ in pairs(matrix[x_key]) do
            if matrix[x_key][y_key] then
                result[num] = {}
                balancer_functions.expand_matrix(matrix, { x = x_key, y = y_key }, num, result)
                return
            end
        end
    end
end

function balancer_functions.expand_matrix(matrix, pos, num, result)
    if matrix[pos.x] and matrix[pos.x][pos.y] then
        local part_entity = matrix[pos.x][pos.y]
        result[num][part_entity.unit_number] = part_entity
        matrix[pos.x][pos.y] = nil
        if table_size(matrix[pos.x]) == 0 then matrix[pos.x] = nil end
        balancer_functions.expand_matrix(matrix, { x = pos.x - 1, y = pos.y }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x + 1, y = pos.y }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x, y = pos.y - 1 }, num, result)
        balancer_functions.expand_matrix(matrix, { x = pos.x, y = pos.y + 1 }, num, result)
    end
end

function balancer_functions.new_from_part_list(part_list)
    local balancer = balancer_functions.new()
    for _, part_entity in pairs(part_list) do
        local part = storage.parts[part_entity.unit_number]
        if part then
            balancer.parts[part_entity.unit_number] = part_entity.unit_number
            part.balancer = balancer.unit_number
            balancer_functions.reload_lanes(balancer.unit_number)
        end
    end
    return balancer
end

function balancer_functions.check_connected(balancer_index, drop_to)
    local balancer = storage.balancer[balancer_index]
    if not balancer then return end
    
    local linked = balancer_functions.get_linked(balancer)
    if table_size(linked) > 1 then
        unregister_on_tick(balancer_index)
        for _, parts in pairs(linked) do
            balancer_functions.new_from_part_list(parts)
        end
        balancer_functions.empty_buffer(balancer, drop_to)
        storage.balancer[balancer_index] = nil
    end
end

return balancer_functions