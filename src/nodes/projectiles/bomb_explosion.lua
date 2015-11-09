local game = require 'game'
local Timer = require 'vendor/timer'

return{
  name = 'bomb_explosion',
  type = 'projectile',
  lift = 0.05 * game.step,
  width = 150,
  height = 75,
  frameWidth = 150,
  frameHeight = 75,
  solid = true,
  bomb = true,
  --handle_x = 10,
  --handle_y = -6,
  lift = 0,
  velocity = { x=0, y=0},
  throwVelocityX = 0, 
  throwVelocityY = 0,
  damage = 20,
  stayOnScreen = false,
  horizontalLimit = 400,
  special_damage = {fire = 5},
  playerCanPickUp = false,
  enemyCanPickUp = false,
  canPlayerStore = false,
  offset= { x=0, y=0},
  --explosive = true,
  explodeTime = .8,
  --explode_sound = 'explosion_quiet',
  animations = {
    default = {'once', {'1-8,1'}, .1},
    thrown = {'once', {'1-7,1'}, .1},
    finish = {'loop', {'1-7,1'}, .1},
  },
  
  collide = function(node, dt, mtv_x, mtv_y,projectile)
    if node.isPlayer then return end
    if node.hurt then
      node:hurt(projectile.damage, projectile.special_damage, 0)
      projectile.collider:remove(projectile.bb)
      print('explode hurt')
      
      Timer.add(projectile.explodeTime, function() 
        print('explode die')
        projectile:die()
        end)
    end
  end,

  floor_collide = function(projectile)
    local waiting = false

    if not waiting then
      projectile:finish()
      waiting = true
      Timer.add(projectile.explodeTime, function() 
        projectile:die()

        end)
    end
    if math.ceil(math.abs(projectile.velocity.x / projectile.friction)) == 1 then
      projectile.collider:remove(projectile.bb)
    end
  end,

}
