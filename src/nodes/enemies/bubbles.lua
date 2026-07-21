-- Decorative floating bubbles for underwater levels. Peaceful (no damage,
-- can't be jump-killed) -- just bobs in place.
local tween = require 'vendor/tween'

return {
  name = 'bubbles',
  spawn_sound = 'hippy_enter',
  height = 24,
  width = 24,
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
  movetime = 2,
  bounceheight = 40,
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
    enemy.start_y = enemy.position.y
    enemy.startmove = function()
      enemy.moving = true
      tween.start( enemy.props.movetime, enemy.position, { y = enemy.start_y - enemy.props.bounceheight }, enemy.props.easeup, enemy.reversemove )
    end
    enemy.reversemove = function()
      tween.start( enemy.props.movetime, enemy.position, { y = enemy.start_y }, enemy.props.easedown, enemy.startmove )
    end
    enemy.startmove()
  end,

  floor_pushback = function() end,
}
