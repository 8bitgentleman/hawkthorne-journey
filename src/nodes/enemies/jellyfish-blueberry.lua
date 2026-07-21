-- Floats in place near its spawn point until the player gets close, then
-- chases them down. Faster / more aggressive variant of jellyfish-strawberry.
local Timer = require 'vendor/timer'

return {
  name = 'jellyfish-blueberry',
  die_sound = 'jellyfish_die',
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
  drift_speed = 30,
  chase_speed = 60,
  aggro_range = 100,
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

  enter = function(enemy)
    enemy.start_x = enemy.position.x
    enemy.start_y = enemy.position.y
    enemy.drift_top = enemy.start_y - enemy.height
  end,

  attack = function(enemy)
    enemy.state = 'attack'
    Timer.add(30, function()
      if enemy.state ~= 'dying' then
        enemy.state = 'default'
      end
    end)
  end,

  update = function( dt, enemy, player )
    enemy.direction = (enemy.position.x > player.position.x) and 'left' or 'right'

    local dx = player.position.x - enemy.position.x
    local dy = player.position.y - enemy.position.y
    local aggro = math.abs(dx) < enemy.props.aggro_range and math.abs(dy) < enemy.props.aggro_range

    if enemy.state == 'dying' then return end

    if aggro then
      enemy.state = 'attack'
      local speed = enemy.props.chase_speed * dt
      if math.abs(dx) > 1 then
        enemy.position.x = enemy.position.x + speed * (dx > 0 and 1 or -1)
      end
      if math.abs(dy) > 1 then
        enemy.position.y = enemy.position.y + speed * (dy > 0 and 1 or -1)
      end
    else
      enemy.state = 'default'
      -- gently drift up and down near the spawn point
      if enemy.position.y <= enemy.drift_top then
        enemy.drifting_down = true
      elseif enemy.position.y >= enemy.start_y then
        enemy.drifting_down = false
      end
      local speed = enemy.props.drift_speed * dt
      enemy.position.y = enemy.position.y + speed * (enemy.drifting_down and 1 or -1)
    end
  end,

  floor_pushback = function() end,
}
