local Timer = require 'vendor/timer'
local sound = require 'vendor/TEsound'

return {
  name = 'jellfish-strawberry',
  attack_sound = 'acorn_growl',
  die_sound = 'acorn_crush',
  position_offset = { x = 0, y = 4 },
  height = 48,
  width = 48,
  damage = 15,
  antigravity = true,
  jumpkill = false,
  hp = 1,
  tokens = 5,
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, 
                 -- with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },
  animations = {
    dying = {
      right = {'once', {'5,1'}, 0.25},
      left = {'once', {'5,1'}, 0.25}
    },
    default = {
      right = {'loop', {'1-4,1'}, 0.25},
      left = {'loop', {'1-4,1'}, 0.25}
    },
    hurt = {
      right = {'loop', {'5,1'}, 0.25},
      left = {'loop', {'5,1'}, 0.25}
    },
    attack = {
      right = {'loop', {'1-4,1'}, 0.25},
      left = {'loop', {'1-4,1'}, 0.25}
    },
    dyingattack = {
      right = {'once', {'5,1'}, 0.25},
      left = {'once', {'5,1'}, 0.25}
    }
  },
  enter = function(enemy)
    enemy.direction = math.random(2) == 1 and 'left' or 'right'
    enemy.maxx = enemy.position.x + 24
    enemy.minx = enemy.position.x - 24
    enemy.maxy = enemy.position.y + 24
    enemy.miny = enemy.position.y - 24
  end,

  attack = function(enemy)
    enemy.state = 'attack'
    enemy.jumpkill = false
    Timer.add(5, function() 
      if enemy.state ~= 'dying' and enemy.state ~= 'dyingattack' then
        enemy.state = 'default'
        enemy.maxx = enemy.position.x + 24
        enemy.minx = enemy.position.x - 24
        enemy.maxy = enemy.position.y + 24
        enemy.miny = enemy.position.y - 24
        enemy.jumpkill = false

      end
    end)
  end,

  die = function(enemy)
    if enemy.state == 'attack' then
      enemy.state = 'dyingattack'
    else
      sound.playSfx( "acorn_squeak" )
      enemy.state = 'dying'
    end
  end,

  update = function(dt, enemy, player, level)
    if enemy.state == 'dyingattack' then return end

    local rage_velocity = 1

    if enemy.state == 'attack' then
      rage_velocity = 4
    end

    if enemy.state == 'attack' then
      if enemy.position.y < player.position.y then
        enemy.direction = 'right'
      elseif enemy.position.y + enemy.props.width > player.position.y + player.width then
        enemy.direction = 'left'
      end
    else
      if enemy.position.y > enemy.maxy then
        enemy.direction = 'left'
      elseif enemy.position.y < enemy.miny then
        enemy.direction = 'right'
      end

    end
    
    if enemy.direction == 'left' then
      enemy.velocity.y = 20 * rage_velocity
    else
      enemy.velocity.y = -20 * rage_velocity
    end

  end
}
