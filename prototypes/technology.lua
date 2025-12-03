require("helper.technology_calc")

data:extend {
    -- TECNOLOGIA 1: AMARELO (Normal)
    {
        type = "technology",
        name = "belt-balancer-1",
        icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon.png",
        icon_size = 200,
        effects = {
            { type = "unlock-recipe", recipe = "belt-balancer" }
        },
        prerequisites = { "logistics" },
        unit = {
            count = 20, -- Defina a quantidade aqui (ex: 50 vezes)
            ingredients = data.raw.technology["logistics"].unit.ingredients,
            time = 15
        },
    },

    -- TECNOLOGIA 2: VERMELHO (Fast)
    {
        type = "technology",
        name = "belt-balancer-2",
        icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-fast.png",
        icon_size = 200,
        effects = {
            { type = "unlock-recipe", recipe = "belt-balancer-fast" }
        },
        prerequisites = { "logistics-2", "belt-balancer-1" },
        unit = {
            count = 200,            
            ingredients = data.raw.technology["logistics-2"].unit.ingredients,
            time = 30 -- Tempo em segundos por ciclo
        },
    },

    -- TECNOLOGIA 3: AZUL (Express)
    {
        type = "technology",
        name = "belt-balancer-3",
        icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-express.png",
        icon_size = 200,
        effects = {
            { type = "unlock-recipe", recipe = "belt-balancer-express" }
        },
        prerequisites = { "logistics-3", "belt-balancer-2" },
        unit = {
            count = 300,
            ingredients = data.raw.technology["logistics-3"].unit.ingredients,
            time = 15
        },
    }
}

-- TECNOLOGIA 4: TURBO (SPACE AGE)
if mods["space-age"] then
    data:extend {
        {
            type = "technology",
            name = "belt-balancer-4",
            icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon-turbo.png",
            icon_size = 200,
            effects = {
                { type = "unlock-recipe", recipe = "belt-balancer-turbo" }
            },
            prerequisites = { "turbo-transport-belt", "belt-balancer-3" },
            unit = {
                count = 500,
                ingredients = data.raw.technology["turbo-transport-belt"] and data.raw.technology["turbo-transport-belt"].unit.ingredients or {{"automation-science-pack", 1}},
                time = 60
            },
        }
    }
end