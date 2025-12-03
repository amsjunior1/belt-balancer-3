-- helper/conversion.lua

---@param stack LuaItemStack
---@return SimpleItemStack
function stablize_item_stack(stack)
    if not stack or not stack.valid_for_read then return nil end

    local type = stack.prototype.type

    local quality_name = "normal"
    if stack.quality then
        quality_name = stack.quality.name
    end

    return {
        name = stack.name,
        count = stack.count, -- Em esteiras geralmente é 1
        quality = quality_name, -- Salvando como string
        health = stack.health,
        durability = (type == "tool" or type == "repair-tool" or type == "armor") and stack.durability,
        ammo = type == "ammo" and stack.ammo,
        tags = type == "item-with-tags" and stack.tags,
        custom_description = type == "item-with-tags" and stack.custom_description,
        spoil_percent = stack.spoil_percent
    }
end