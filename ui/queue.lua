-- Queue

Queue = {}
Queue.__index = Queue



-- ========== Methods ==========

Queue.new = function()
    local queue = {
        t = {}
    }
    setmetatable(queue, Queue)
    return queue
end


--[[
Order and draw everything in queue, then clear it.
]]
function Queue:draw()
    table.sort(self.t, function(a, b)
        local az = a:get_global_z()
        local bz = b:get_global_z()
        if az == bz then
            if b.parent == a then
                return true
            end
        end
        return az < bz
    end)
    for _, element in ipairs(self.t) do
        element.draw(element, element:get_global_x(), element:get_global_y())
    end
    self.t = {}
end


function Queue:add(element)
    table.insert(self.t, element)
end


function Queue:add_recursive(element)
    table.insert(self.t, element)
    for child, _ in pairs(element.children) do
        self:add_recursive(child)
    end
end