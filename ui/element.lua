-- Element

Element = {}
Element.__index = Element



-- ========== Methods ==========

Element.new = function(x, y, draw)
    local element = {
        -- Position
        x = x or 0,
        y = y or 0,

        -- Relationships
        children = {},
        parent = nil,
        z = 0,  -- Relative to parent

        -- Methods
        draw = draw,
    }
    setmetatable(element, Element)
    return element
end


--[[
Delete element and move all children to parent element.
]]
function Element:delete()
    if self.parent then self.parent:remove_child(self) end
    for child, _ in pairs(self.children) do
        self:remove_child(child)
        if self.parent then self.parent:add_child(child) end
    end
end


function Element:add_child(element)
    self.children[element] = true
    element.parent = self
    return element
end


function Element:remove_child(element)
    self.children[element] = nil
    element.parent = nil
    return element
end


function Element:get_global_x()
    local x = 0
    local current = self
    while current do
        x = x + current.x
        current = current.parent
    end
    return x
end


function Element:get_global_y()
    local y = 0
    local current = self
    while current do
        y = y + current.y
        current = current.parent
    end
    return y
end


function Element:get_global_z()
    local z = 0
    local current = self
    while current do
        z = z + current.z
        current = current.parent
    end
    return z
end