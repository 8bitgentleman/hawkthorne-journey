-- Slowly, constantly homes in on the player -- unlike jellyfish-blueberry it
-- doesn't wait for the player to get close first. Floats freely (ignores
-- terrain collision), matching its antigravity/no floor_pushback behavior.
local Timer = require 'vendor/timer'

return {
  name = 'jellyfish-strawberry',
  die_sound = 'acorn_crush',
  height = 48,
  width = 48,
  bb_width = 48,
  bb_height = 48,
  damage = 15,
  jumpkill = false,
  hp = 6,
  vulnerabilities = {'blunt'},
  tokens = 3,
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },
  antigravity = true,
  chase_speed = 30,
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
  },

  attack = function(enemy)
    enemy.state = 'attack'
    Timer.add(30, function()
      if enemy.state ~= 'dying' then
        enemy.state = 'default'
      end
    end)
  end,

  update = function( dt, enemy, player )
    if enemy.state == 'dying' then return end

    enemy.direction = (enemy.position.x > player.position.x) and 'left' or 'right'

    local speed = enemy.props.chase_speed * dt
    local dx = player.position.x - enemy.position.x
    local dy = player.position.y - enemy.position.y

    if math.abs(dx) > 1 then
      enemy.position.x = enemy.position.x + speed * (dx > 0 and 1 or -1)
    end
    if math.abs(dy) > 1 then
      enemy.position.y = enemy.position.y + speed * (dy > 0 and 1 or -1)
    end
  end,

  floor_pushback = function() end,
}
