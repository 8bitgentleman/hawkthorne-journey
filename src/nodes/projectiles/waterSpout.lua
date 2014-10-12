local game = require 'game'
return{
  name = 'waterSpout',
  type = 'projectile',
  friction = 1,
  width = 24,
  height = 72,
  frameWidth = 24,
  frameHeight = 72,
  solid = true,
  lift = game.gravity,
  playerCanPickUp = false,
  enemyCanPickUp = false,
  canPlayerStore = false,
  velocity = { x = 0, y = 0 }, --initial velocity
  throwVelocityX = 100,
  throwVelocityY = 0,
  offset = { x = 0, y = -10 },
  handle_y = 50,
  stayOnScreen = false,
  thrown = false,
  damage = 5,
  special_damage = {water= 6},
  max_damage = 15,
  horizontalLimit = 6000,
  explosive = true,
  explodeTime = 1,
  explode_sound = 'explosion_quiet',
  animations = {
    default = {'loop', {'1-4,1'}, 0.3},
    thrown = {'loop', {'1-4,1'}, 0.3},
    explode = {'once', {'5-14,1'}, .08},
    finish = {'once', {'15,1'}, 1},
  },
  collide = function(node, dt, mtv_x, mtv_y,projectile)
    if node.isPlayer then return end
    if node.hurt then
      node:hurt(projectile.damage, projectile.special_damage, 0)
      projectile:die()
    end
  end,
}
