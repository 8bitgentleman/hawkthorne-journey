local Timer = require 'vendor/timer'
local sound = require 'vendor/TEsound'

return {
  name = 'jellyfish-blueberry',
  die_sound = 'acorn_crush',
  position_offset = { x = 0, y = 0 },
  height = 48,
  width = 48,
  bb_width = 48,
  bb_height = 48,
  bb_offset = {x=0, y=0},
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
    enemy.start_y = enemy.position.y
    enemy.end_y = enemy.start_y - (enemy.height*2)
    enemy.start_x = enemy.position.x
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
    if enemy.position.x > player.position.x then
    enemy.direction = 'left'
    else
        enemy.direction = 'right'
    end
    if enemy.state == 'default' then
      if enemy.position.x ~= enemy.start_x  and (math.abs(enemy.position.x - enemy.start_x) > 3) then
        if enemy.position.x > enemy.start_x then
          enemy.direction = 'left' 
          enemy.position.x = enemy.position.x - 60*dt
        else
          enemy.direction = 'right' 
          enemy.position.x = enemy.position.x + 60*dt
        end
      end
      if enemy.position.y > enemy.start_y then
        enemy.going_up = true
      end
      if enemy.position.y < enemy.end_y then
        enemy.going_up = false
      end
      if enemy.going_up then
        enemy.position.y = enemy.position.y - 30*dt
      else
        enemy.position.y = enemy.position.y + 30*dt
      end
      elseif enemy.state == 'default' and player.position.y <= enemy.position.y + 100 then
        if player.position.x < enemy.position.x then
          -- player is to the right
          if player.position.x + player.width + 50 >= enemy.position.x then
            enemy.state = 'attack'
          end
        else
          -- player is to the left
          if player.position.x - 50 <= enemy.position.x + enemy.width then
            enemy.state = 'attack'
          end
        end
      end
    
    if enemy.state == 'attack' then
      local rage_factor = 2
      if(math.abs(enemy.position.x - player.position.x) > 1) then
        if enemy.direction == 'left' then
          enemy.position.x = enemy.position.x - 30*dt*rage_factor
        else
          enemy.position.x = enemy.position.x + 30*dt*rage_factor
        end
      end
      if (math.abs(enemy.position.y - player.position.y) > 1) then
        if enemy.position.y < player.position.y then
          enemy.position.y = enemy.position.y + 30*dt*rage_factor
        else
          enemy.position.y = enemy.position.y - 30*dt*rage_factor
        end
      end
    end
  end,
  floor_pushback = function() end,
}
