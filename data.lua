require("prototypes.entity")
require("prototypes.item")
-- require("prototypes.recipe") -- MANTENHA COMENTADO
require("prototypes.technology")

local util = require("util")

local tiers = {
    -- NÍVEL 1: AMARELO (15 itens/s)
    {
        suffix = "", 
        icon_file = "__belt-balancer-3__/graphics/icons/belt-balancer-icon.png",
        entity_file = "__belt-balancer-3__/graphics/entities/belt-balancer.png",
        ingredient_belt = "transport-belt",
        amount_belt = 1,
        amount_circuit = 5,
        circuit_type = "electronic-circuit",
        amount_gear = 5,
        order_suffix = "a",
        throughput = "15" -- Valor para mostrar no texto
    },
    -- NÍVEL 2: VERMELHO (30 itens/s)
    {
        suffix = "-fast", 
        icon_file = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-fast.png",
        entity_file = "__belt-balancer-3__/graphics/entities/belt-balancer-fast.png",
        ingredient_belt = "fast-transport-belt",
        amount_belt = 1,
        amount_circuit = 10,
        circuit_type = "electronic-circuit",
        amount_gear = 10,
        order_suffix = "b",
        throughput = "30"
    },
    -- NÍVEL 3: AZUL (45 itens/s)
    {
        suffix = "-express", 
        icon_file = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-express.png",
        entity_file = "__belt-balancer-3__/graphics/entities/belt-balancer-express.png",
        ingredient_belt = "express-transport-belt",
        amount_belt = 1,
        amount_circuit = 10,
        circuit_type = "advanced-circuit",
        amount_gear = 15,
        order_suffix = "c",
        throughput = "45"
    }
}

if mods["space-age"] then
    table.insert(tiers, {
        suffix = "-turbo", 
        icon_file = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-turbo.png", 
        entity_file = "__belt-balancer-3__/graphics/entities/belt-balancer-turbo.png",
        ingredient_belt = "turbo-transport-belt",
        amount_belt = 1,
        amount_circuit = 10,
        circuit_type = "processing-unit",
        amount_gear = 20,
        order_suffix = "d",
        throughput = "60"
    })
end

local base_entity = data.raw["container"]["balancer-part"] or data.raw["loader"]["balancer-part"] or data.raw["simple-entity-with-force"]["balancer-part"] 

if not base_entity then
    log("AVISO: Entidade base 'balancer-part' não encontrada.")
else
    for _, tier in pairs(tiers) do
        local new_name = "belt-balancer" .. tier.suffix
        
        -- 1. CRIAR O ITEM
        local base_item = data.raw.item["balancer-part"]
        if base_item then
            local new_item = table.deepcopy(base_item)
            new_item.name = new_name
            new_item.place_result = new_name 
            new_item.order = "z[balancer]-" .. tier.order_suffix
            
            new_item.icons = {{ icon = tier.icon_file, icon_size = 200 }} 
            
            -- AQUI ESTÁ A MÁGICA DA DESCRIÇÃO
            -- Cria um texto composto: "Descrição Padrão" + Pula Linha + "Velocidade: X"
            new_item.localised_description = {
                "", 
                {"item-description.belt-balancer-desc"}, 
                "\n", 
                {"item-description.belt-balancer-stat", tier.throughput}
            }
            
            data:extend{new_item}
        end

        -- 2. CRIAR A ENTIDADE
        local new_entity = table.deepcopy(base_entity)
        new_entity.name = new_name
        new_entity.minable.result = new_name
        
        new_entity.icons = {{ icon = tier.icon_file, icon_size = 200 }}
        new_entity.icon = nil 
        
        -- Limpeza Visual Nuclear
        new_entity.picture = nil
        new_entity.pictures = nil
        new_entity.animation = nil
        new_entity.animations = nil
        new_entity.structure = nil
        if new_entity.type ~= "loader" and new_entity.type ~= "loader-1x1" then
            new_entity.belt_animation_set = nil 
        end
        new_entity.working_visualisations = nil

        local anim_definition = {
            filename = tier.entity_file,
            priority = "high",
            width = 200,
            height = 200,
            frame_count = 16,
            line_length = 8,
            scale = 0.25,
            animation_speed = 0.15,
            hr_version = nil,
            shift = util.by_pixel(0, -1)
        }

        if new_entity.type == "loader" or new_entity.type == "loader-1x1" then
            new_entity.structure = {
                direction_in = { sheet = anim_definition },
                direction_out = { sheet = anim_definition }
            }
            local source_belt = data.raw["transport-belt"][tier.ingredient_belt]
            if source_belt and source_belt.belt_animation_set then
                new_entity.belt_animation_set = source_belt.belt_animation_set
            end
            if source_belt then new_entity.speed = source_belt.speed end
        else
            new_entity.animation = anim_definition
            new_entity.animations = { anim_definition }
        end
        
        data:extend{new_entity}

        -- 3. CRIAR A RECEITA
        local new_recipe = {
            type = "recipe",
            name = new_name,
            enabled = false, 
            energy_required = 0.5,
            ingredients = {
                {type="item", name="iron-gear-wheel", amount=tier.amount_gear},
                {type="item", name=tier.circuit_type, amount=tier.amount_circuit},
                {type="item", name=tier.ingredient_belt, amount=tier.amount_belt}
            },
            results = {
                {type="item", name=new_name, amount=1}
            }
        }
        data:extend{new_recipe}
    end
end