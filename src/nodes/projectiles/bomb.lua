local game = require 'game'
local Timer = require('vendor/timer')
local sound = require('vendor/TEsound')
return{
  name = 'bomb',
  type = 'projectile',
  friction = 1,
  width = 72,
  height = 72,
  frameWidth = 72,
  frameHeight = 72,
  solid = true,
  lift = game.gravity,
  playerCanPickUp = false,
  enemyCanPickUp = false,
  canPlayerStore = true,
  velocity = { x = 2, y = 0 }, --initial velocity
  throwVelocityX = 1, 
  throwVelocityY = 0,
  stayOnScreen = false,
  thrown = false,
  damage = 15,
  horizontalLimit = 120,
  animations = {
    default = {'once', {'1,1'},1},
    thrown = {'once', {'2,1'}, 1},
    finish = {'once', {'1,1'}, 0.15},
  },
  update = function( dt, enemy, player )
    collide = function(node, dt, mtv_x, mtv_y,projectile)
      if node.hurt then
        Timer.add(3, function () 
          if player.position.x < 48 then
            node:hurt(projectile.damage)
            projectile:die()
          end
        end)
      end
    end
  end,  
}
