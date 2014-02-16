local Dialog = require 'dialog'
local utils = require 'utils'

local Info = {}
Info.__index = Info
-- Nodes with 'isInteractive' are nodes which the player can interact with, but not pick up in any way
Info.isInteractive = true

function Info.new(node, collider)
    local info = {}
    setmetatable(info, Info)
    
    info.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
    info.bb.node = info
    info.info = utils.split(node.properties.info, '|')

    info.x = node.x
    info.y = node.y
    info.height = node.height
    info.width = node.width
    info.position = { x = node.x, y = node.y }
    info.note = false
    
    if node.properties.sprite ~= nil then
        info.sprite = love.graphics.newImage('images/info/'.. node.properties.sprite ..'.png')
    end

    if info.note = true then
        info.collider = collider
        info.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
        material.bb.node = material
        collider:setSolid(info.bb)
        
        info.exists = true
    end    
    collider:setPassive(info.bb)
    
    info.current = nil

    return info
end

function Info:update(dt, player)
end

function Info:draw()
    if self.sprite ~= nil then
        love.graphics.draw(self.sprite, self.position.x, self.position.y)
    end
end

function Info:keypressed( button, player )
    if self.prompt then
        return self.prompt:keypressed( button )
    end
    if button == 'INTERACT' and self.dialog == nil and not player.freeze then
        player.freeze = true
        local message = {'Would you like to..'}
        local callback = function(result)
            if result == 'Take' then
                local itemNode = utils.require( 'items/materials/' .. self.name )
                itemNode.type = 'note'
                local item = Item.new(itemNode, self.quantity)
                if player.inventory:addItem(item) then
                    self.exists = false
                    self.containerLevel:removeNode(self)
                    self.collider:remove(self.bb)
                    -- Key has been handled, halt further processing
                    return true
                end
            end

            if result == 'Read' then
                Dialog.new(self.info, function()
                    player.freeze = false
                    Dialog.currentDialog = nil
                end)
            end
            self.prompt = nil
            player.freeze = false
        end
        self.prompt = prompt.new(message, callback, {'Read', 'Take', 'Cancel'})
        -- Key has been handled, halt further processing
        return true
    end
end

return Info
