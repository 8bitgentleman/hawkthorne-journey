local splat = require 'nodes/splat'
local game = require 'game'

return{
  name = 'paintball_ammo',
  type = 'projectile',
  friction = 1,
  width = 6,
  height = 6,
  frameWidth = 6,
  frameHeight = 6,
  solid = true,
  lift = game.gravity,
  playerCanPickUp = false,
  enemyCanPickUp = false,
  canPlayerStore = true,
  usedAsAmmo = true,
  --throw_sound = 'arrow',
  velocity = { x = -200, y = 0 }, --initial velocity
  throwVelocityX = 200, 
  throwVelocityY = 0,
  thrown = false,
  damage = 10,
  special_damage = {paint = 1000},
  horizontalLimit = 800,
  animations = {
    default = {'once', {'1,1'},1},
    thrown = {'once', {'1,1'}, 1},
    finish = {'once', {'1,1'}, 1},
  },

  splat = function(projectile, node)
    local s = splat.new(projectile.position.x, projectile.position.y, projectile.width, projectile.height)
    s:add(projectile.position.x, projectile.position.y, projectile.width, projectile.height, projectile.generic)
    return s
  end,

  collide = function(node, dt, mtv_x, mtv_y,projectile)
    if node.isPlayer then print('hit') end
    if projectile.host == node then return end    
    
    if node.isPlayer or (node.isEnemy and projectile.host ~= node) then
      if projectile.containerLevel then
        table.insert(projectile.containerLevel.nodes, 5, projectile.props.splat(projectile))
      end 
    end

    if node.hurt then
      node:hurt(projectile.damage, projectile.special_damage, 0)
      projectile:die()
    end
  end,
}
