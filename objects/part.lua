part_functions = {}

local function pos_equals(p1, p2)
    return math.abs(p1.x - p2.x) < 0.1 and math.abs(p1.y - p2.y) < 0.1
end

---built
function part_functions.built(entity)
    local part = part_functions.get_or_create(entity)
end

---get_or_create
function part_functions.get_or_create(entity)
    local storage_part = storage.parts[entity.unit_number]
    if storage_part then
        return storage_part
    end

    ---@type Part
    local part = {}
    part.entity = entity

    -- get balancer for this part
    part.balancer = balancer_functions.find_from_part(part)
    local balancer = storage.balancer[part.balancer]

    -- find belts
    part.input_belts = {}
    part.output_belts = {}
    part.input_lanes = {}
    part.output_lanes = {}

    local input_belts, output_belts = part_functions.find_input_output_belts(entity)
    
    -- Mapeia inputs
    for _, input_belt in pairs(input_belts) do
        local belt_unit_number = input_belt.belt.unit_number
        local belt = belt_functions.get_or_create(input_belt.belt)
        belt.output_balancer[balancer.unit_number] = balancer.unit_number
        part.input_belts[belt_unit_number] = belt_unit_number
    end

    -- Mapeia outputs
    for _, output_belt in pairs(output_belts) do
        local belt_unit_number = output_belt.belt.unit_number
        local belt = belt_functions.get_or_create(output_belt.belt)
        belt.input_balancer[balancer.unit_number] = balancer.unit_number
        part.output_belts[belt_unit_number] = belt_unit_number
    end

    -- set parts in storage table
    storage.parts[entity.unit_number] = part

    -- [CORREÇÃO] Em vez de lógica manual complexa, usa reload para garantir consistência
    balancer_functions.reload_lanes(balancer.unit_number)

    return part
end

function part_functions.find_nearby_balancer(entity)
    local found_parts = entity.surface.find_entities_filtered {
        position = entity.position,
        name = entity.name, -- Garante que só junta com mesmo tier (amarelo com amarelo, etc)
        radius = 1,
    }
    
    if #found_parts == 0 or (#found_parts == 1 and found_parts[1].unit_number == entity.unit_number) then
         local candidates = entity.surface.find_entities_filtered {
            position = entity.position,
            radius = 1
        }
        for _, cand in pairs(candidates) do
            if string.find(cand.name, "balancer") and cand.unit_number ~= entity.unit_number then
                table.insert(found_parts, cand)
            end
        end
    end

    local found_balancer = {}
    for _, found_part in ipairs(found_parts) do
        if found_part.unit_number ~= entity.unit_number then
            local part = storage.parts[found_part.unit_number]
            if part then
                local balancer_id = part.balancer
                if balancer_id then
                    found_balancer[balancer_id] = balancer_id
                end
            end
        end
    end

    return found_balancer
end

function part_functions.find_input_output_belts(balancer_part)
    local splitter_pos = balancer_part.position
    local input_belts = {}
    local output_belts = {}

    local found_belts = balancer_part.surface.find_entities_filtered {
        position = splitter_pos,
        type = "transport-belt",
        radius = 1.1 
    }
    for _, belt in pairs(found_belts) do
        local into_pos, from_pos = belt_functions.get_input_output_pos(belt)
        if pos_equals(into_pos, splitter_pos) then
            input_belts[belt.unit_number] = { belt = belt, belt_type = "belt" }
        elseif pos_equals(from_pos, splitter_pos) then
            output_belts[belt.unit_number] = { belt = belt, belt_type = "belt" }
        end
    end

    local found_underground_belts = balancer_part.surface.find_entities_filtered {
        position = splitter_pos,
        type = "underground-belt",
        radius = 1.1
    }
    for _, underground_belt in pairs(found_underground_belts) do
        local into_pos, from_pos = belt_functions.get_input_output_pos(underground_belt)
        if underground_belt.belt_to_ground_type == "output" and pos_equals(into_pos, splitter_pos) then
            input_belts[underground_belt.unit_number] = { belt = underground_belt, belt_type = "underground" }
        elseif underground_belt.belt_to_ground_type == "input" and pos_equals(from_pos, splitter_pos) then
            output_belts[underground_belt.unit_number] = { belt = underground_belt, belt_type = "underground" }
        end
    end

    local found_splitter_belts = balancer_part.surface.find_entities_filtered {
        position = splitter_pos,
        type = "splitter",
        radius = 1.6 
    }
    for _, splitter_belt in pairs(found_splitter_belts) do
        local into_pos, from_pos = belt_functions.get_input_output_pos_splitter(splitter_belt)
        for _, into in pairs(into_pos) do
            if pos_equals(into.position, splitter_pos) then
                input_belts[splitter_belt.unit_number] = { belt = splitter_belt, belt_type = "splitter", lanes = into.lanes }
            end
        end
        for _, from in pairs(from_pos) do
            if pos_equals(from.position, splitter_pos) then
                output_belts[splitter_belt.unit_number] = { belt = splitter_belt, belt_type = "splitter", lanes = from.lanes }
            end
        end
    end

    return input_belts, output_belts
end

---remove
function part_functions.remove(entity, buffer)
    local part = storage.parts[entity.unit_number]
    if not part then return end
    
    local balancer = storage.balancer[part.balancer]

    -- 1. Remove a parte da lista do balancer
    if balancer then
	    balancer.parts[entity.unit_number] = nil
    end

    -- 2. Limpa referências nas correias de INPUT
    for _, belt_index in pairs(part.input_belts) do
        local belt = storage.belts[belt_index]
        if belt and belt.valid then
            belt.output_balancer[part.balancer] = nil
            -- check if belt is still attached to a part
            belt_functions.check_track(belt_index)
        end
    end

    -- 3. Limpa referências nas correias de OUTPUT
    for _, belt_index in pairs(part.output_belts) do
        local belt = storage.belts[belt_index]
        if belt and belt.valid then
            belt.input_balancer[part.balancer] = nil
            -- check if belt is still attached to a part
            belt_functions.check_track(belt_index)
        end
    end
    
    -- 4. Remove a parte do storage
    storage.parts[entity.unit_number] = nil

    -- 5. AGORA A MÁGICA: Força o balancer a reconstruir as lanes
    -- Ele só vai pegar lanes das partes que sobraram.
    if balancer then
        balancer_functions.reload_lanes(balancer.unit_number)

        ---@type Item_drop_param
        local drop_to = {
            buffer = buffer,
            position = entity.position,
            surface = entity.surface,
            force = entity.force
        }

        local check_track_result = balancer_functions.check_track(balancer.unit_number, drop_to)
        if check_track_result then
            balancer_functions.check_connected(balancer.unit_number, drop_to)
        end
    end
end

return part_functions