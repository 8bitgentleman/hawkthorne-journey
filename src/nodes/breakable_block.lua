local Timer = require 'vendor/timer'
local Level = require 'level'
local anim8 = require 'vendor/anim8'
local sound = require 'vendor/TEsound'
local Dialog = require 'dialog'

local Wall = {}
Wall.__index = Wall
Wall.isWall = true

local crack = love.graphics.newImage('images/blocks/crack.png')

function Wall.new(node, collider)
    local wall = {}
    setmetatable(wall, Wall)
    wall.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
    wall.bb.node = wall
    wall.node = node
    wall.collider = collider
    collider:setPassive(wall.bb)
    wall.isSolid = true
    wall.dyingdelay = node.properties.dyingdelay or 0
    wall.dead = false
    wall.sound = node.properties.sound
    wall.brokenBy = node.properties.brokenBy
    wall.message = node.properties.message or 'This is to hard for that weapon to break!'

    if node.properties.dying_animation then
        wall.dying_image = love.graphics.newImage('images/blocks/'..node.properties.dying_animation)
        local d = anim8.newGrid(node.width, node.height, wall.dying_image:getWidth(), wall.dying_image:getHeight())
        local frames = math.floor(wall.dying_image:getWidth()/node.width)
        wall.dying_animation = anim8.newAnimation('once', d('1-'..frames..',1'), 0.1)
        wall.dyingdelay = frames * 0.1
    end
    
    wall.crack = node.properties.crack ~= 'false' and true or false
    
    if node.height > 24 then wall.crack = false end
    
    assert(node.properties.sprite, "breakable_block must be provided a sprite image")
    wall.sprite = love.graphics.newImage('images/blocks/'..node.properties.sprite)
    
    local sprite = wall.crack and crack or wall.sprite
    
    local g = anim8.newGrid(node.width, node.height, sprite:getWidth(), sprite:getHeight())
    
    local frames = math.floor(sprite:getWidth()/node.width)
    
    wall.hp = node.properties.hp or frames
    
    wall.destroyAnimation = anim8.newAnimation('once', g('1-'..frames..',1'), 0.9 / (frames / wall.hp))
    
    return wall
end

function Wall:collide( node, dt, mtv_x, mtv_y, bb)
    bb = bb or node.bb
    if not (node.floor_pushback or node.wall_pushback) then return end

    node.bottom_bb = node.bottom_bb or node.bb
    node.top_bb = node.top_bb or node.bb
    
    if not node.top_bb or not node.bottom_bb then return end
    local _, wy1, _, wy2 = self.bb:bbox()
    local _, _, _, py2 = node.bottom_bb:bbox()
    local _, py1, _, _ = node.top_bb:bbox()


    if mtv_x ~= 0 and node.wall_pushback and node.position.y + node.height > wy1 + 2 then
        -- horizontal block
        node:wall_pushback(self, node.position.x+mtv_x)
    end

    if mtv_y > 0 and node.ceiling_pushback and node.velocity.y < 0 then
        -- bouncing off bottom
        node:ceiling_pushback(self, node.position.y + mtv_y)
    end
    
    if mtv_y < 0 and (not node.isPlayer or bb == node.bottom_bb) and node.velocity.y >= 0 then
        -- standing on top
        node:floor_pushback(self, self.node.y - node.height)
    end

end

function Wall:collide_end( node ,dt )
end

function Wall:update(dt, player)
    if not self.dead then return end
    self.dying_animation:update(dt)
end

function Wall:hurt( damage, special_damage )
    self.hp = self.hp - self:calculateDamage(damage, special_damage)

    self.destroyAnimation:update(damage)
    self:draw()
    if self.hp <= 0 then
        self.dead = true
        if self.sound then sound.playSfx(self.sound) end
        Timer.add(self.dyingdelay, function() self:die() end)
    end
end

-- Compares brokenBy to a weapons special damage and sums up total damage
function Wall:calculateDamage(damage, special_damage, player)
    if not self:specialDamageCheck(special_damage) then 
            sound.playSfx( "dbl_beep" )
        	--player.freeze = true
            Dialog.new(''..self.message..'', function()
                --player.freeze = false
            end)
        return 0 

    end
    --[[if self:specialDamageCheck(special_damage) == true then
        damage = damage + special_damage[value]
    else 
        damage = 0
    end

end--]]

    return damage
end

function Wall:specialDamageCheck( special_damage )
    if not self.brokenBy or self.brokenBy == {} then 
        return true 
    end

    if special_damage and special_damage[self.brokenBy] ~= nil then
        return true
    end

    return false
end

function Wall:die()

    self.collider:remove(self.bb)
    if self.containerLevel then
      self.containerLevel:removeNode(self)
    end
end

function Wall:draw()
    if self.crack then
        love.graphics.draw(self.sprite, self.node.x, self.node.y)
        self.destroyAnimation:draw(crack, self.node.x, self.node.y)
    elseif not self.dead then
        self.destroyAnimation:draw(self.sprite, self.node.x, self.node.y)
    else
        self.dying_animation:draw(self.dying_image, self.node.x, self.node.y)
    end
end

---
-- Returns an user-friendly identifier
-- @return string describing where this wall is located in a user-friendly (and hopefully unique) way
function Wall:getSourceId()
  local levelName = (self.containerLevel ~= nil and self.containerLevel.name ~= nil and self.containerLevel.name ~= "") and self.containerLevel.name or "(UNKNOWN)"
  local wallPos = (self.node ~= nil) and string.format("[%s,%s]", tostring(self.node.x), tostring(self.node.y)) or "(UNKNOWN)"

  return string.format("level %s, breakable block at %s", levelName, wallPos)
end

return Wall
