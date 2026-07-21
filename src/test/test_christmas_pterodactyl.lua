-----------------------------------------------------------------------------
-- test_christmas_pterodactyl.lua — pins the santas-grotto boss's dive AI.
--
-- The boss is an antigravity flyer that moves by writing its own position in
-- update() (see enemy.lua: antigravity skips gravity but still calls update).
-- Its behaviour is pure position math, so we drive the props table directly
-- with fake enemy/player tables — no Level, collider, or window needed.
--
-- Target behaviour (Super Mario Land 2 bird boss): cruise the ceiling, then
-- telegraph, then commit a fast dive at where the player WAS standing.
-----------------------------------------------------------------------------

local props = require 'nodes/enemies/christmas-pterodactyl'

local DT = 1/60

-- A fresh boss enemy sitting at its spawn, with enter() already run.
local function newBoss()
  local enemy = {
    position = { x = 732, y = 228 },
    height = 48,
    width = 96,
    state = 'default',
    direction = 'right',
  }
  props.enter(enemy)
  return enemy
end

local function newPlayer(x, y)
  return { position = { x = x or 200, y = y or 312 }, dead = false }
end

-- Run n frames, returning the set of phases visited along the way.
local function run(enemy, player, frames)
  local seen = {}
  for _ = 1, frames do
    props.update(DT, enemy, player)
    seen[enemy.phase] = true
    assert_true(enemy.state == 'default' or enemy.state == 'attack',
      "boss must only ever be in an animated state, got: " .. tostring(enemy.state))
  end
  return seen
end

-- enter() sets up the cruise altitude and dive floor relative to spawn.
function test_enter_initializes_flight_envelope()
  local enemy = newBoss()
  assert_equal('patrol', enemy.phase)
  assert_equal(180, enemy.patrol_y, "cruise altitude is one body-height above spawn")
  assert_equal(228, enemy.dive_floor, "dive bottoms out at spawn altitude (just above the floor)")
end

-- Over a few seconds the boss cycles patrol -> telegraph -> dive -> recover -> patrol.
function test_boss_runs_the_full_dive_cycle()
  local enemy = newBoss()
  local player = newPlayer()
  local seen = run(enemy, player, 600) -- 10 seconds; PATROL_TIME is 2.2s

  assert_true(seen.telegraph, "boss should wind up (telegraph) before diving")
  assert_true(seen.dive, "boss should dive")
  assert_true(seen.recover, "boss should climb back out of the dive")
  assert_true(seen.patrol, "boss should return to patrolling for another pass")
end

-- The dive commits to the player's position at the moment the telegraph ends,
-- and it actually swoops downward toward the floor.
function test_dive_commits_toward_the_player_and_descends()
  local enemy = newBoss()
  local player = newPlayer(300, 312)

  -- Step until the first dive frame.
  local guard = 0
  while enemy.phase ~= 'dive' and guard < 1000 do
    props.update(DT, enemy, player)
    guard = guard + 1
  end
  assert_true(enemy.phase == 'dive', "boss reached the dive phase")
  assert_equal(300, enemy.dive_x, "dive locks onto the player's x at telegraph end")

  local yBefore = enemy.position.y
  props.update(DT, enemy, player)
  assert_true(enemy.position.y > yBefore, "the dive descends (y increases)")
end

-- No committing to a dive against a dead player (nothing to hit).
function test_boss_does_not_dive_at_a_dead_player()
  local enemy = newBoss()
  local player = newPlayer()
  player.dead = true

  local seen = run(enemy, player, 600)
  assert_true(seen.patrol, "boss keeps patrolling")
  assert_false(seen.dive == true, "boss must not dive at a corpse")
end
