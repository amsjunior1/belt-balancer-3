---get_next_balancer_unit_number
---get the next balancer unit_number to use. Also set the unit_number tracker one up.
---@return uint the unit_number to use
function get_next_balancer_unit_number()
    local cur_value = storage.next_balancer_unit_number
    storage.next_balancer_unit_number = storage.next_balancer_unit_number + 1
    return cur_value
end

---get_next_lane_unit_number
---get the next lane unit_number to use. Also set the unit_number tracker one up.
---@return uint the unit_number to use
function get_next_lane_unit_number()
    local cur_value = storage.next_lane_unit_number
    storage.next_lane_unit_number = storage.next_lane_unit_number + 1
    return cur_value
end
