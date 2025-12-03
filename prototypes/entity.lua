-- Definição dos parâmetros da animação baseada no seu sprite 200x200 (16 frames)
local animation_params = {
    priority = "high",
    width = 200,    
    height = 200,   
    frame_count = 16, 
    line_length = 8,  
    
    -- [CORREÇÃO VISUAL]
    -- Aumentei de 0.25 para 0.28 para a caixa ficar maior e cobrir o "buraco"
    scale = 0.28,     
    
    animation_speed = 0.15,
    
    -- [CORREÇÃO VISUAL]
    -- Ajuste fino na posição para centralizar a nova escala
    shift = util.by_pixel(0, 2)
}

-- Configurações base
local base_config = {
    type = "simple-entity-with-force",
    flags = { "placeable-neutral", "player-creation" },
    max_health = 170,
    corpse = "splitter-remnants",
    
    -- [CORREÇÃO VISUAL]
    -- Reduzi levemente a caixa de colisão (de 0.35 para 0.29).
    -- Isso deixa a esteira chegar um pouquinho mais perto visualmente.
    collision_box = { { -0.29, -0.29 }, { 0.29, 0.29 } },
    
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    collision_mask = { layers = { floor=true, meltable=true, object=true, transport_belt=true, water_tile=true } },
    fast_replaceable_group = "balancer-part", 
}

local function get_icon_suffix(name)
    if name == "balancer-part-fast" then return "-fast"
    elseif name == "balancer-part-express" then return "-express"
    elseif name == "balancer-part-turbo" then return "-turbo"
    else return "" -- Para "balancer-part" base
    end
end

local function create_balancer(name, sprite_name, next_upgrade)
    local entity = table.deepcopy(base_config)
    entity.name = name
    entity.minable = { mining_time = 0.1, result = name }
    
    local suffix = get_icon_suffix(name)
    entity.icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon" .. suffix .. ".png"
    entity.icon_size = 200
    entity.next_upgrade = next_upgrade
    
    local animation = table.deepcopy(animation_params)
    animation.filename = "__belt-balancer-3__/graphics/entities/" .. sprite_name
    entity.animations = { animation }
    
    return entity
end

data:extend({
    -- 🟢 1. Balancer Amarelo (BASE)
    create_balancer("balancer-part", "belt-balancer.png", "balancer-part-fast"),

    -- 🔴 2. Balancer Vermelho (FAST)
    create_balancer("balancer-part-fast", "belt-balancer-fast.png", "balancer-part-express"),

    -- 🔵 3. Balancer Azul (EXPRESS)
    create_balancer("balancer-part-express", "belt-balancer-express.png", "balancer-part-turbo"),

    -- 🟢 4. Balancer Verde/Turbo (TURBO)
    create_balancer("balancer-part-turbo", "belt-balancer-turbo.png", nil),
})