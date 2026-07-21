-- Flying holiday boss modelled on the swooping bird boss from Super Mario Land 2:
-- it cruises across the top of the arena, telegraphs, then commits to a fast dive
-- at where the player was standing. Body contact deals the damage; the dive is the threat.

local PATROL_SPEED    = 90    -- px/s while cruising the ceiling
local TELEGRAPH_SPEED = 140   -- px/s sliding into position above the player (the "tell")
local DIVE_SPEED      = 300   -- px/s while swooping
local CLIMB_SPEED     = 150   -- px/s climbing back to cruise altitude
local PATROL_TIME     = 2.2   -- seconds cruising before committing to a dive
local TELEGRAPH_TIME  = 0.55  -- windup the player can read and dodge

-- Move `current` toward `target` by at most `step` (never overshoots).
local function approach(current, target, step)
  if current < target then return math.min(current + step, target) end
  if current > target then return math.max(current - step, target) end
  return current
end

return{
  name = 'christmas-pterodactyl',
  isBoss = true,
  die_sound = 'acorn_crush',
  position_offset = { x = 0, y = -1 },
  height = 48,
  width = 96,
  bb_width = 96,
  bb_height = 48,
  enterScript = {'squaaaagh! squaaaagh', },
  damage = 10,
  hp = 50,
  vulnerabilities = {'blunt'},
  tokens = 1,
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },
  antigravity = true,
  animations = {
    dying = {
      right = {'once', {'5,1'}, 0.4},
      left = {'once', {'5,1'}, 0.4}
    },
    default = {
      right = {'loop', {'1-2,1'}, 0.1},
      left = {'loop', {'1-2,2'}, 0.1}
    },
    hurt = {
      right = {'loop', {'1-2,1'}, 0.1},
      left = {'loop', {'1-2,2'}, 0.1}
    },
    attack = {
      right = {'loop', {'3-4,1'}, 0.05},
      left = {'loop', {'3-4,2'}, 0.05}
    },
  },
  enter = function(enemy)
    enemy.patrol_y   = enemy.position.y - enemy.height   -- cruise altitude
    -- The boss is authored to spawn just above the floor, so a dive bottoms out
    -- at spawn altitude: deep enough to hit a grounded player, never through the floor.
    enemy.dive_floor = enemy.position.y
    enemy.start_x    = enemy.position.x
    enemy.patrol_min = enemy.start_x - 480                   -- left/right bounds of the cruise
    enemy.patrol_max = enemy.start_x + 48
    enemy.patrol_dir = -1
    enemy.phase      = 'patrol'
    enemy.phase_timer = 0
  end,
  -- The dive is time-driven from update(); contact must not hijack the FSM, so this is a no-op.
  attack = function() end,
  update = function( dt, enemy, player )
    if enemy.state == 'dying' then return end

    local px = player.position.x

    if enemy.phase == 'patrol' then
      enemy.state = 'default'
      enemy.position.y = approach(enemy.position.y, enemy.patrol_y, CLIMB_SPEED * dt)
      enemy.position.x = enemy.position.x + enemy.patrol_dir * PATROL_SPEED * dt
      if enemy.position.x <= enemy.patrol_min then
        enemy.position.x = enemy.patrol_min
        enemy.patrol_dir = 1
      elseif enemy.position.x >= enemy.patrol_max then
        enemy.position.x = enemy.patrol_max
        enemy.patrol_dir = -1
      end
      enemy.direction = enemy.patrol_dir < 0 and 'left' or 'right'
      enemy.phase_timer = enemy.phase_timer + dt
      if enemy.phase_timer >= PATROL_TIME and not player.dead then
        enemy.phase = 'telegraph'
        enemy.phase_timer = 0
      end

    elseif enemy.phase == 'telegraph' then
      -- Hold altitude, slide over the player and face them: the readable windup.
      enemy.state = 'default'
      enemy.position.y = approach(enemy.position.y, enemy.patrol_y, CLIMB_SPEED * dt)
      enemy.position.x = approach(enemy.position.x, px, TELEGRAPH_SPEED * dt)
      enemy.direction = px < enemy.position.x and 'left' or 'right'
      enemy.phase_timer = enemy.phase_timer + dt
      if enemy.phase_timer >= TELEGRAPH_TIME then
        enemy.dive_x = px   -- commit to where the player is NOW; a dodge beats it
        enemy.phase = 'dive'
        enemy.phase_timer = 0
      end

    elseif enemy.phase == 'dive' then
      enemy.state = 'attack'
      enemy.direction = enemy.dive_x < enemy.position.x and 'left' or 'right'
      enemy.position.x = approach(enemy.position.x, enemy.dive_x, DIVE_SPEED * dt)
      enemy.position.y = enemy.position.y + DIVE_SPEED * dt
      if enemy.position.y >= enemy.dive_floor then
        enemy.position.y = enemy.dive_floor
        enemy.phase = 'recover'
        enemy.phase_timer = 0
      end

    elseif enemy.phase == 'recover' then
      enemy.state = 'default'
      enemy.position.y = approach(enemy.position.y, enemy.patrol_y, CLIMB_SPEED * dt)
      if enemy.position.x < enemy.patrol_min then
        enemy.position.x = approach(enemy.position.x, enemy.patrol_min, PATROL_SPEED * dt)
      elseif enemy.position.x > enemy.patrol_max then
        enemy.position.x = approach(enemy.position.x, enemy.patrol_max, PATROL_SPEED * dt)
      end
      enemy.direction = px < enemy.position.x and 'left' or 'right'
      if enemy.position.y <= enemy.patrol_y then
        enemy.phase = 'patrol'
        enemy.phase_timer = 0
      end
    end
  end,
  floor_pushback = function() end,
}
