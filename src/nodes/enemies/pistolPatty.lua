local Timer = require 'vendor/timer'
local sound = require 'vendor/TEsound'

return {
  name = 'pistolPatty',
  attack_sound = 'acorn_growl',
  die_sound = 'acorn_crush',
  --position_offset = { x = 0, y = 4 },
  height = 80,
  width = 48,
  damage = 25,
  bb_width = 31,
  bb_height = 80,
  bb_offset = { x = 1, y = 0},
  jumpkill = false,
  hp = 40,
  tokens = 0,
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },
  animations = {
    dying = {
      right = {'once', {'3,1'}, 0.25},
      left = {'once', {'3,1'}, 0.25}
    },
    default = {
      right = {'loop', {'1-2,1'}, 0.25},
      left = {'loop', {'1-2,1'}, 0.25}
    },
    hurt = {
      right = {'loop', {'1-2,1'}, 0.25},
      left = {'loop', {'1-2,1'}, 0.25}
    },
    attack = {
      right = {'loop', {'1-2,1'}, 0.25},
      left = {'loop', {'1-2,1'}, 0.25}
    },
    rage = {
      right = {'loop', {'1-2,1'}, 0.25},
      left = {'loop', {'1-2,1'}, 0.25}
    },
    dyingattack = {
      right = {'loop', {'1-2,1'}, 0.25},
      left = {'loop', {'1-2,1'}, 0.25}
    }
  },
  enter = function(enemy)

  end,

  rage = function( enemy )
  enemy.state = 'rage'
    Timer.add(5, function() 
      if enemy.state ~= 'dying' and enemy.state ~= 'dyingattack' then
        enemy.state = 'default'
        enemy.maxx = enemy.position.x + math.random(48,60)
        enemy.minx = enemy.position.x - math.random(48,60)
        enemy.props.hp = enemy.hp
        enemy.hp = enemy.props.hp
      end
    end)
  end,

  attack = function(enemy)
  end,

  die = function(enemy)

  end,

  update = function(dt, enemy, player, level)
   

  end

}
