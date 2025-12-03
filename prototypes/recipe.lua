data:extend({
    -- 🟢 1. Balancer Amarelo (Base)
    {
        type = "recipe",
        name = "balancer-part",
        enabled = true, -- Pode ser desbloqueada na tecnologia base (Logistics)
        energy_required = 3,
        ingredients = {
            { type="item", name="iron-gear-wheel", amount=10 },
            { type="item", name="electronic-circuit", amount=5 },
            { type="item", name="transport-belt", amount=1 }
        },
        result = "balancer-part",
        order = "c[balancer-1]"
    },

    -- 🔴 2. Balancer Vermelho (Fast)
    {
        type = "recipe",
        name = "balancer-part-fast",
        enabled = false, -- Exige tecnologia para desbloquear
        energy_required = 4,
        ingredients = {
            { type="item", name="balancer-part", amount=1 },
            { type="item", name="fast-splitter", amount=1 },
            { type="item", name="advanced-circuit", amount=5 }
        },
        result = "balancer-part-fast",
        order = "c[balancer-2]"
    },

    -- 🔵 3. Balancer Azul (Express)
    {
        type = "recipe",
        name = "balancer-part-express",
        enabled = false, -- Exige tecnologia para desbloquear
        energy_required = 6,
        ingredients = {
            { type="item", name="balancer-part-fast", amount=1 },
            { type="item", name="express-splitter", amount=1 },
            { type="item", name="processing-unit", amount=5 }
        },
        result = "balancer-part-express",
        order = "c[balancer-3]"
    }
})

-- Suporte ao Tier Turbo (Verde) do Factorio 2.0 (Space Age)
if data.raw.item["turbo-transport-belt"] then
    data:extend({
        {
            type = "recipe",
            name = "balancer-part-turbo",
            enabled = false, -- Exige tecnologia para desbloquear
            energy_required = 8,
            ingredients = {
                { type="item", name="balancer-part-express", amount=1 },
                { type="item", name="turbo-splitter", amount=1 },
                { type="item", name="low-density-structure", amount=5 } -- Item de alto nível
            },
            result = "balancer-part-turbo",
            order = "c[balancer-4]"
        }
    })
end