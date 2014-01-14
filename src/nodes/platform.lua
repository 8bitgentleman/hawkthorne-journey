local Timer = require 'vendor/timer'
local controls = require 'controls'
local Gamestate = require 'vendor/gamestate'
local Tween = require 'vendor/tween'
local anim8 = require 'vendor/anim8'
local sound = require 'vendor/TEsound'
local utils = require 'utils'

local Platform = {}
Platform.__index = Platform
Platform.isPlatform = true

function Platform.new(node, collider)
    local platform = {}
    setmetatable(platform, Platform)

    --If the node is a polyline, we need to draw a polygon rather than rectangle
    if node.polyline or node.polygon then
        local polygon = node.polyline or node.polygon
        local vertices = {}

        for i, point in ipairs(polygon) do
            table.insert(vertices, node.x + point.x)
            table.insert(vertices, node.y + point.y)
        end
           
        platform.bb = collider:addPolygon(unpack(vertices))
        platform.bb.polyline = polygon
    else
        platform.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
        platform.bb.polyline = nil
    end
    
    platform.node = node
    
    platform.drop = node.properties.drop ~= 'false'

    platform.down_dt = 0

    platform.bb.node = platform
    collider:setPassive(platform.bb)

    platform.hideable = node.properties.hideable == 'true'

    -- generic support for hidden platforms
    if platform.hideable then
        platform.hidden = true
        platform.sprite = love.graphics.newImage('images/' .. node.properties.sprite .. '.png')
        platform.sprite_width = tonumber( node.properties.sprite_width )
        platform.sprite_height = tonumber( node.properties.sprite_height )
        platform.grid = anim8.newGrid( platform.sprite_width, platform.sprite_height, platform.sprite:getWidth(), platform.sprite:getHeight())
        platform.animode = node.properties.animode and node.properties.animode or 'once'
        platform.anispeed = node.properties.anispeed and tonumber( node.properties.anispeed ) or 1
        platform.aniframes = node.properties.aniframes and node.properties.aniframes or '1,1'
        platform.animation = anim8.newAnimation(platform.animode, platform.grid(platform.aniframes), platform.anispeed)
        platform.position_hidden = {
            x = node.x + ( node.properties.offset_hidden_x and tonumber( node.properties.offset_hidden_x ) or 0 ),
            y = node.y + ( node.properties.offset_hidden_y and tonumber( node.properties.offset_hidden_y ) or 0 )
        }
        platform.position_shown = {
            x = node.x + ( node.properties.offset_shown_x and tonumber( node.properties.offset_shown_x ) or 0 ),
            y = node.y + ( node.properties.offset_shown_y and tonumber( node.properties.offset_shown_y ) or 0 )
        }
        platform.position = utils.deepcopy(platform.position_hidden)
        platform.movetime = node.properties.movetime and tonumber(node.properties.movetime) or 1
    end

    return platform
end

function Platform:update( dt )
    if self.animation then
        self.animation:update(dt)
    end
    if controls.isDown( 'DOWN' ) then
        self.down_dt = 0
    else
        self.down_dt = self.down_dt + dt
    end
end

function Platform:collide( node, dt, mtv_x, mtv_y, bb )
    bb = bb or node.bb
    
    if not node.floor_pushback then return end
    
    if node.isPlayer then
        self.player_touched = true
        
        if self.dropping then
            return
        end
        
        --ignore head vs. platform collisions
        if bb == node.top_bb then
            return
        end
    end
    if node.bb then
        node.top_bb = node.bb
        node.bottom_bb = node.bb
    end
    
    if not node.top_bb or not node.bottom_bb then return end

    local _, wy1, _, wy2  = self.bb:bbox()
    local px1, py1, _, _ = node.top_bb:bbox()
    local _, _, px2, py2 = node.bottom_bb:bbox()
    local distance = math.abs(node.velocity.y * dt) + 2.10
    
    if self.bb.polyline and node.velocity.y >= 0 then
        -- If the player is close enough to the tip bring the player to the tip
        if math.abs(wy1 - py2) < 2 then
            node:floor_pushback(self, wy1 - node.height)
            
        -- Prevent the player from being treadmilled through an object
        elseif self.bb:contains(px2,py2) or self.bb:contains(px1,py2) then
        
            -- Use the MTV to keep players feet on the ground
            node:floor_pushback(self, (py2 - node.height) + mtv_y)

        end

    elseif node.velocity.y >= 0 and math.abs(wy1 - py2) <= distance then
        node:floor_pushback(self, wy1 - node.height)
    elseif node.velocity.y > 0 and mtv_y < 0 and mtv_y > -5 then
        node:floor_pushback(self, wy1 - node.height)
    end
end

function Platform:collide_end(node)
    if node.isPlayer then
        self.player_touched = false
        self.dropping = false
    end
end

function Platform:keypressed( button, player )
    if player.controlState:is('ignoreMovement') then return end
    if self.drop and button == 'DOWN' and self.down_dt > 0 and self.down_dt < 0.15 then
         self.dropping = true
         Timer.add( 0.25, function() self.dropping = false end )
         -- Key has been handled, halt further processing
        return true
    end
end

-- everything below this is required for hidden platforms
function Platform:show()
    if self.hideable and self.hidden then
        self.hidden = false
        sound.playSfx( 'reveal' )
        Tween.start( self.movetime, self.position, self.position_shown )
    end
end

function Platform:hide()
    if self.hideable and not self.hidden then
        self.hidden = true
        sound.playSfx( 'unreveal' )
        Tween.start( self.movetime, self.position, self.position_hidden )
    end
end

function Platform:draw()

    if not self.hideable then return end
    
    self.animation:draw(self.sprite, self.position.x, self.position.y)
end

return Platform
