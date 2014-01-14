local Wall = {}
local Timer = require 'vendor/timer'
Wall.__index = Wall
function Wall.new(node, collider)
    local wall = {}
    setmetatable(wall, Wall)
    wall.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
    wall.bb.node = wall
    wall.node = node
    collider:setPassive(wall.bb)
    wall.isSolid = false
    wall.breathable = false

    return wall
end



function Wall:collide(node)
    if node.hurt then
        Timer.add(5, function()
        node:hurt(10)
        end)
    end
end


return Wall