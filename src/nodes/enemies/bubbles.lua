local tween = require 'vendor/tween'
local sound = require 'vendor/TEsound'
return {
  name = 'bubbles',
  spawn_sound = 'hippy_enter',
  height = 24,
  width = 24,
  position_offset = { x = 13, y = 50 },
  bb_width = 12,
  bb_height = 20,
  bb_offset = {x=0, y=2},
  damage = 0,
  peaceful = true,
  hp = 1,
  jumpkill = false,
  antigravity = true,
  easeup = 'outQuad',
  easedown = 'inQuad',
  movetime = 10,
  bounceheight = 400,
  speed = .1,
  dropSpeed = .1,
  dyingdelay = .1, 
  animations = {
  dying = {
      right = {'once', {'4,2'}, 1},
      left = {'once', {'4,2'}, 1}
    },
    default = {
      right = {'loop', {'1-4,1'}, 0.5},
      left = {'loop', {'1-4,1'}, 0.5}
    },
  
  },


  enter = function(enemy)
    --enemy.delay = math.random(200)/100
    enemy.delay = .1
    enemy.startmove = function()
      enemy.moving = true
      tween.start( enemy.props.movetime, enemy.position, { y = enemy.node.y - enemy.props.bounceheight }, enemy.props.easeup, enemy.reversemove )
    end
    enemy.reversemove = function()
      tween.start( enemy.props.movetime, enemy.position, { y = enemy.node.y + enemy.position_offset.y }, enemy.props.easedown, function() enemy.moving = false end )
    end
  end,

  update = function(dt, enemy, player)
    if enemy.delay >= 0 then
      enemy.delay = enemy.delay - dt
    else
      if not enemy.moving then
        enemy.startmove()
      end
    end

function enemy:collide_end( node )
    if node and node.isPlayer then
        node.health = node.max_health
        sound.playSfx( "healing" )
    end

end

  end
}
