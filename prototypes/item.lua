local function create_balancer_item(name, icon_suffix, order_suffix)
    return {
        type = "item",
        name = name,
        -- Monta o caminho do ícone (ex: belt-balancer-icon-fast.png)
        icon = "__belt-balancer-3__/graphics/icons/belt-balancer-icon" .. icon_suffix .. ".png",
        icon_size = 200, -- Mantido tamanho original
        subgroup = "belt",
        -- Define a ordem no menu (para que fiquem agrupados)
        order = "c[splitter]-x[" .. order_suffix .. "]",
        place_result = name, -- Garante que o item construa a entidade de mesmo nome
        stack_size = 50,
    }
end

data:extend({
    -- 🟢 1. Balancer Amarelo (Base)
    create_balancer_item("balancer-part", "", "balancer-1"),

    -- 🔴 2. Balancer Vermelho (Fast)
    create_balancer_item("balancer-part-fast", "-fast", "balancer-2"),

    -- 🔵 3. Balancer Azul (Express)
    create_balancer_item("balancer-part-express", "-express", "balancer-3"),

    -- 🟢 4. Balancer Verde/Turbo (Turbo)
    create_balancer_item("balancer-part-turbo", "-turbo", "balancer-4"),
})