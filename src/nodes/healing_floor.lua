-- An invisible zone (e.g. an air pocket / land patch above an underwater
-- room) that refills the player's oxygen while they're touching it. Plays
-- 'healing_quiet' once per contact rather than every frame.
local Wall = {}
Wall.__index = Wall

local sound = require 'vendor/TEsound'

function Wall.new(node, collider)
  local wall = {}
  setmetatable(wall, Wall)
  wall.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
  wall.bb.node = wall
  wall.node = node
  collider:setPassive(wall.bb)
  wall.isSolid = false
  wall.healing = false

  return wall
end

function Wall:collide(node)
  if not node.isPlayer then return end

  if not self.healing then
    self.healing = true
    sound.playSfx( "healing_quiet" )
  end

  node:refillOxygen()
end

function Wall:collide_end(node)
  if node and node.isPlayer then
    self.healing = false
  end
end

return Wall
