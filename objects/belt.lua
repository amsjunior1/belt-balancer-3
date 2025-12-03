belt_functions = {}

-- Função auxiliar para comparar posições (usada na construção)
local function pos_equals(p1, p2)
    return math.abs(p1.x - p2.x) < 0.1 and math.abs(p1.y - p2.y) < 0.1
end

---get belt, if not yet in storage table, create it...
function belt_functions.get_or_create(belt_entity)
    local storage_belt = storage.belts[belt_entity.unit_number]
    if storage_belt then
        return storage_belt
    end

    ---@type Belt
    local belt = {}

    belt.entity = belt_entity
    belt.type = belt_entity.type
    belt.position = belt_entity.position
    belt.direction = belt_entity.direction
    belt.surface = belt_entity.surface
    belt.output_balancer = {}
    belt.input_balancer = {}

    local belt_count
    if belt_entity.type == "underground-belt" then
        belt_count = 2
    else
        belt_count = belt_entity.get_max_transport_line_index()
    end

    belt.lanes = {}
    for i = 1, belt_count do
        local index = get_next_lane_unit_number()
        local transport_line = belt_entity.get_transport_line(i)
        storage.lanes[index] = transport_line
        belt.lanes[i] = index
    end

    storage.belts[belt_entity.unit_number] = belt

    return belt
end

---get_input_output_pos
function belt_functions.get_input_output_pos(belt, direction, position)
    position = position or belt.position
    direction = direction or belt.direction
    local into_pos, from_pos

    if direction == defines.direction.north then
        into_pos = { x = position.x, y = position.y - 1 }
        from_pos = { x = position.x, y = position.y + 1 }
    elseif direction == defines.direction.south then
        into_pos = { x = position.x, y = position.y + 1 }
        from_pos = { x = position.x, y = position.y - 1 }
    elseif direction == defines.direction.west then
        into_pos = { x = position.x - 1, y = position.y }
        from_pos = { x = position.x + 1, y = position.y }
    elseif direction == defines.direction.east then
        into_pos = { x = position.x + 1, y = position.y }
        from_pos = { x = position.x - 1, y = position.y }
    end

    return into_pos, from_pos
end

---get_input_output_pos_splitter
function belt_functions.get_input_output_pos_splitter(splitter, direction, position)
    local splitter_pos = position or splitter.position
    direction = direction or splitter.direction
    
    local into_pos = {}
    local from_pos = {}
    local output_left_lanes = { 5, 6 }
    local output_right_lanes = { 7, 8 }
    local input_left_lanes = { 1, 2 }
    local input_right_lanes = { 3, 4 }

    if direction == defines.direction.north then
        table.insert(into_pos, { position = { x = splitter_pos.x - 0.5, y = splitter_pos.y - 1 }, lanes = output_left_lanes })
        table.insert(into_pos, { position = { x = splitter_pos.x + 0.5, y = splitter_pos.y - 1 }, lanes = output_right_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x - 0.5, y = splitter_pos.y + 1 }, lanes = input_left_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x + 0.5, y = splitter_pos.y + 1 }, lanes = input_right_lanes })
    elseif direction == defines.direction.south then
        table.insert(into_pos, { position = { x = splitter_pos.x - 0.5, y = splitter_pos.y + 1 }, lanes = output_right_lanes })
        table.insert(into_pos, { position = { x = splitter_pos.x + 0.5, y = splitter_pos.y + 1 }, lanes = output_left_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x - 0.5, y = splitter_pos.y - 1 }, lanes = input_right_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x + 0.5, y = splitter_pos.y - 1 }, lanes = input_left_lanes })
    elseif direction == defines.direction.west then
        table.insert(into_pos, { position = { x = splitter_pos.x - 1, y = splitter_pos.y - 0.5 }, lanes = output_right_lanes })
        table.insert(into_pos, { position = { x = splitter_pos.x - 1, y = splitter_pos.y + 0.5 }, lanes = output_left_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x + 1, y = splitter_pos.y - 0.5 }, lanes = input_right_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x + 1, y = splitter_pos.y + 0.5 }, lanes = input_left_lanes })
    elseif direction == defines.direction.east then
        table.insert(into_pos, { position = { x = splitter_pos.x + 1, y = splitter_pos.y - 0.5 }, lanes = output_left_lanes })
        table.insert(into_pos, { position = { x = splitter_pos.x + 1, y = splitter_pos.y + 0.5 }, lanes = output_right_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x - 1, y = splitter_pos.y - 0.5 }, lanes = input_left_lanes })
        table.insert(from_pos, { position = { x = splitter_pos.x - 1, y = splitter_pos.y + 0.5 }, lanes = input_right_lanes })
    end

    return into_pos, from_pos
end

---finds the parts, that the belt has as input/output
function belt_functions.get_input_output_parts(belt, direction, surface, position)
    surface = surface or belt.surface
    position = position or belt.position

    local into_pos, from_pos = belt_functions.get_input_output_pos(belt, direction, position)

    local into_part, from_part

    -- Busca geométrica melhorada com pos_equals
    local into_entities = surface.find_entities_filtered{position = into_pos, name = "balancer-part", radius = 0.5}
    if #into_entities > 0 then
        into_part = part_functions.get_or_create(into_entities[1])
    else
        local candidates = surface.find_entities_filtered{position = into_pos, radius = 1}
        for _, cand in pairs(candidates) do
            if string.find(cand.name, "balancer") and pos_equals(cand.position, into_pos) then
                into_part = part_functions.get_or_create(cand)
                break
            end
        end
    end

    local from_entities = surface.find_entities_filtered{position = from_pos, name = "balancer-part", radius = 0.5}
    if #from_entities > 0 then
        from_part = part_functions.get_or_create(from_entities[1])
    else
        local candidates = surface.find_entities_filtered{position = from_pos, radius = 1}
        for _, cand in pairs(candidates) do
            if string.find(cand.name, "balancer") and pos_equals(cand.position, from_pos) then
                from_part = part_functions.get_or_create(cand)
                break
            end
        end
    end

    return into_part, from_part
end

---finds the parts, that the splitter has as input/output
function belt_functions.get_input_output_parts_splitter(splitter, direction, surface, position)
    surface = surface or splitter.surface

    local into_positions, from_positions = belt_functions.get_input_output_pos_splitter(splitter, direction, position)

    local into_parts = {}
    local from_parts = {}

    for _, into_position in pairs(into_positions) do
        local found = false
        local into_entities = surface.find_entities_filtered{position = into_position.position, name = "balancer-part", radius = 0.5}
        if #into_entities > 0 then
            local into_part = into_position
            into_part.part = part_functions.get_or_create(into_entities[1])
            table.insert(into_parts, into_part)
            found = true
        end
        if not found then
             local candidates = surface.find_entities_filtered{position = into_position.position, radius = 1}
             for _, cand in pairs(candidates) do
                if string.find(cand.name, "balancer") and pos_equals(cand.position, into_position.position) then
                    local into_part = into_position
                    into_part.part = part_functions.get_or_create(cand)
                    table.insert(into_parts, into_part)
                    break
                end
             end
        end
    end

    for _, from_position in pairs(from_positions) do
        local found = false
        local from_entities = surface.find_entities_filtered{position = from_position.position, name = "balancer-part", radius = 0.5}
        if #from_entities > 0 then
            local from_part = from_position
            from_part.part = part_functions.get_or_create(from_entities[1])
            table.insert(from_parts, from_part)
            found = true
        end
        if not found then
             local candidates = surface.find_entities_filtered{position = from_position.position, radius = 1}
             for _, cand in pairs(candidates) do
                if string.find(cand.name, "balancer") and pos_equals(cand.position, from_position.position) then
                    local from_part = from_position
                    from_part.part = part_functions.get_or_create(cand)
                    table.insert(from_parts, from_part)
                    break
                end
             end
        end
    end

    return into_parts, from_parts
end

---built_belt
function belt_functions.built_belt(belt)
    local into_part, from_part = belt_functions.get_input_output_parts(belt)

    if belt.type == "underground-belt" then
        if belt.belt_to_ground_type == "input" then
            into_part = nil
        elseif belt.belt_to_ground_type == "output" then
            from_part = nil
        end
    end
    if script.active_mods["loaders-modernized"] then
        if string.find(belt.name, ".*mdrn%-loader") then
            if belt.loader_type == "input" then
                into_part = nil
            elseif belt.loader_type == "output" then
                from_part = nil
            end
        end
    end

    if into_part then
        local stack_belt = belt_functions.get_or_create(belt)
        stack_belt.output_balancer[into_part.balancer] = into_part.balancer
        into_part.input_belts[belt.unit_number] = belt.unit_number

        local balancer = storage.balancer[into_part.balancer]
        for _, lane in pairs(stack_belt.lanes) do
            balancer.input_lanes[lane] = storage.lanes[lane]
            into_part.input_lanes[lane] = storage.lanes[lane]
        end
        balancer_functions.recalculate_nth_tick(balancer.unit_number)
    end

    if from_part then
        local stack_belt = belt_functions.get_or_create(belt)
        stack_belt.input_balancer[from_part.balancer] = from_part.balancer
        from_part.output_belts[belt.unit_number] = belt.unit_number

        local balancer = storage.balancer[from_part.balancer]
        for _, lane in pairs(stack_belt.lanes) do
            balancer.output_lanes[lane] = storage.lanes[lane]
            from_part.output_lanes[lane] = storage.lanes[lane]
        end
        balancer_functions.recalculate_nth_tick(balancer.unit_number)
    end
end

---built_splitter
function belt_functions.built_splitter(splitter_entity)
    local into_parts, from_parts = belt_functions.get_input_output_parts_splitter(splitter_entity)

    for _, into_part in pairs(into_parts) do
        local stack_belt = belt_functions.get_or_create(splitter_entity)
        stack_belt.output_balancer[into_part.part.balancer] = into_part.part.balancer
        into_part.part.input_belts[splitter_entity.unit_number] = splitter_entity.unit_number

        local balancer = storage.balancer[into_part.part.balancer]
        for _, lane_index in pairs(into_part.lanes) do
            local lane = stack_belt.lanes[lane_index]
            balancer.input_lanes[lane] = storage.lanes[lane]
            into_part.part.input_lanes[lane] = storage.lanes[lane]
        end
        balancer_functions.recalculate_nth_tick(balancer.unit_number)
    end

    for _, from_part in pairs(from_parts) do
        local stack_belt = belt_functions.get_or_create(splitter_entity)
        stack_belt.input_balancer[from_part.part.balancer] = from_part.part.balancer
        from_part.part.output_belts[splitter_entity.unit_number] = splitter_entity.unit_number

        local balancer = storage.balancer[from_part.part.balancer]
        for _, lane_index in pairs(from_part.lanes) do
            local lane = stack_belt.lanes[lane_index]
            balancer.output_lanes[lane] = storage.lanes[lane]
            from_part.part.output_lanes[lane] = storage.lanes[lane]
        end
        balancer_functions.recalculate_nth_tick(balancer.unit_number)
    end
end

-- ============================================================================
-- REMOVE BELT (Versão Blindada via Storage)
-- ============================================================================
function belt_functions.remove_belt(entity, direction, unit_number, surface, position)
    unit_number = unit_number or entity.unit_number
    -- Recupera o objeto da esteira da memória (Storage)
    local belt = storage.belts[unit_number]
    if not belt then
        return
    end

    -- 1. Desconecta de Balancers que recebem desta esteira (Belt é INPUT deles)
    -- Em vez de procurar no mapa, olhamos a lista de output_balancer que a esteira guardou
    for balancer_id, _ in pairs(belt.output_balancer) do
        local balancer = storage.balancer[balancer_id]
        if balancer then
            -- Remove as lanes dessa esteira da lista de input do balancer
            for _, lane in pairs(belt.lanes) do
                balancer.input_lanes[lane] = nil
            end
            -- Procura qual 'parte' do balancer estava ligada e remove a referência
            for _, part_id in pairs(balancer.parts) do
                local part = storage.parts[part_id]
                if part and part.input_belts[unit_number] then
                    part.input_belts[unit_number] = nil
                    for _, lane in pairs(belt.lanes) do
                        part.input_lanes[lane] = nil
                    end
                end
            end
            balancer_functions.recalculate_nth_tick(balancer_id)
        end
    end

    -- 2. Desconecta de Balancers que alimentam esta esteira (Belt é OUTPUT deles)
    for balancer_id, _ in pairs(belt.input_balancer) do
        local balancer = storage.balancer[balancer_id]
        if balancer then
            for _, lane in pairs(belt.lanes) do
                -- Se o balancer ia jogar nessa lane na próxima vez, pula
                if balancer.next_output == lane then 
                    balancer.next_output = next(balancer.output_lanes, balancer.next_output)
                end
                balancer.output_lanes[lane] = nil
            end
            
            for _, part_id in pairs(balancer.parts) do
                local part = storage.parts[part_id]
                if part and part.output_belts[unit_number] then
                    part.output_belts[unit_number] = nil
                    for _, lane in pairs(belt.lanes) do
                        part.output_lanes[lane] = nil
                    end
                end
            end
            balancer_functions.recalculate_nth_tick(balancer_id)
        end
    end

    -- Limpa a esteira da memória
    for _, lane in pairs(belt.lanes) do
        storage.lanes[lane] = nil
    end

    if unit_number == storage.next_belt_check then
        storage.next_belt_check, _ = next(storage.belts, storage.next_belt_check)
    end
    
    storage.belts[unit_number] = nil
end

-- ============================================================================
-- REMOVE SPLITTER (Versão Blindada com pos_equals e Storage)
-- ============================================================================
function belt_functions.remove_splitter(entity, direction, unit_number, surface, position)
    unit_number = unit_number or entity.unit_number
    local belt = storage.belts[unit_number]
    if not belt then return end

    -- Limpa memória das lanes
    for _, lane in pairs(belt.lanes) do
        storage.lanes[lane] = nil
    end
    if unit_number == storage.next_belt_check then
        storage.next_belt_check, _ = next(storage.belts, storage.next_belt_check)
    end
    storage.belts[unit_number] = nil

    -- Usa busca geométrica com pos_equals para splitters (mais complexo de mapear direto no storage)
    local into_parts, from_parts = belt_functions.get_input_output_parts_splitter(entity, direction, surface, position)
    
    for _, part in pairs(into_parts) do
        if part.part then
            part.part.input_belts[unit_number] = nil
            local balancer = storage.balancer[part.part.balancer]
            if balancer then
                for _, lane in pairs(belt.lanes) do
                    balancer.input_lanes[lane] = nil
                    part.part.input_lanes[lane] = nil
                end
                balancer_functions.recalculate_nth_tick(part.part.balancer)
            end
        end
    end

    for _, part in pairs(from_parts) do
        if part.part then
            part.part.output_belts[unit_number] = nil
            local balancer = storage.balancer[part.part.balancer]
            if balancer then
                for _, lane in pairs(belt.lanes) do
                    if balancer.next_output == lane then 
                        balancer.next_output = next(balancer.output_lanes, balancer.next_output)
                    end
                    balancer.output_lanes[lane] = nil
                    part.part.output_lanes[lane] = nil
                end
                balancer_functions.recalculate_nth_tick(part.part.balancer)
            end
        end
    end
end

function belt_functions.check_track(belt_index)
    local belt = storage.belts[belt_index]
    if not belt then return end -- Segurança
    
    if table_size(belt.input_balancer) == 0 and table_size(belt.output_balancer) == 0 then
        for _, lane in pairs(belt.lanes) do
            storage.lanes[lane] = nil
        end

        if belt.unit_number == storage.next_belt_check then
            storage.next_belt_check, _ = next(storage.belts, storage.next_belt_check)
        end
        
        storage.belts[belt_index] = nil
    end
end

return belt_functions