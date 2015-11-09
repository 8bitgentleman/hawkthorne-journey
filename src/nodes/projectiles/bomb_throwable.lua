local game = require 'game'
local Timer = require 'vendor/timer'
local Projectile = require 'nodes/projectile'

return{
  name = 'bomb_throwable',
  type = 'projectile',
  lift = 0.05 * game.step,
  width = 11,
  height = 19,
  frameWidth = 11,
  frameHeight = 19,
  solid = true,
  bomb = true,
  --handle_x = 10,
  --handle_y = -6,
  lift = 0,
  velocity = { x=300, y=-30},
  throwVelocityX = 400, 
  throwVelocityY = -550,
  damage = 20,
  stayOnScreen = true,
  horizontalLimit = 400,
  special_damage = {fire = 5},
  playerCanPickUp = false,
  enemyCanPickUp = false,
  canPlayerStore = true,
  offset= { x=0, y=-1},
  --explosive = true,
  explodeTime = 1,
  --explode_sound = 'explosion_quiet',
  animations = {
    default = {'once', {'1,1'}, 1},
    thrown = {'once', {'2,1'}, 1},
    finish = {'loop', {'3-6,1'}, .1},
  },
  update = function(node, projectile)

  
  end,

  floor_collide = function(projectile)
    projectile:finish()
    if not projectile.exploding and projectile.velocity.x == 0 then
      local position = { x = projectile.position.x, y = projectile.position.y }
      projectile.exploding = true
      local level = projectile.containerLevel
      
      Timer.add(projectile.explodeTime, function() 
        local node = {
          type = 'projectile',
          name = 'bomb_explosion',
          x = position.x+(projectile.width/2)-(75),
          y = position.y+projectile.height-75,
          width = 150,
          height = 75,
          properties = {
          }
        }
        print(projectile.position.x)
        local explosion = Projectile.new( node, projectile.collider )
        level:addNode(explosion)
        Timer.add(.8, function() 
          explosion:die()
        end)
        projectile:die()
        end)
    end
    if math.ceil(math.abs(projectile.velocity.x / projectile.friction)) == 1 then
      projectile.collider:remove(projectile.bb)
    end
  end,

}
