-- Same hazard as killing_floor, kept as a distinct node type for underwater
-- levels (e.g. spikes/rocks at the bottom of forest-underwater) so map authors
-- can tell the two apart. node:hurt already gates repeat damage via the
-- target's own invulnerability window, so no extra timer bookkeeping is needed.
local Wall = {}
Wall.__index = Wall

function Wall.new(node, collider)
  local wall = {}
  setmetatable(wall, Wall)
  wall.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
  wall.bb.node = wall
  wall.node = node
  collider:setPassive(wall.bb)
  wall.isSolid = false

  return wall
end



function Wall:collide(node)
  if node.hurt then
    node:hurt(10)
  end
end

return Wall
