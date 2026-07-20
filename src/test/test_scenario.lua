-----------------------------------------------------------------------------
-- test_scenario.lua — self-tests for the headless gameplay harness.
--
-- These prove the Scenario helper actually drives real gameplay: physics
-- stepping (gravity), continuous input (walking), and discrete input events
-- (jumping). They double as usage examples for writing gameplay tests.
-----------------------------------------------------------------------------

local Scenario = require 'test/scenario'

-- Gravity + the step loop: dropped in mid-air, the player should fall.
function test_gravity_pulls_the_player_down()
  local s = Scenario.new('greendale-biology')
  -- Start clearly airborne, above the 'main' spawn.
  s:spawn(s.level.default_position.x, s.level.default_position.y - 60)
  local startY = s.player.position.y

  s:step(12)

  assert_true(s.player.position.y > startY,
    string.format("expected the player to fall (y increases); startY=%.1f endY=%.1f",
                  startY, s.player.position.y))
  s:teardown()
end

-- Continuous input: holding RIGHT should move the player right.
function test_holding_right_walks_the_player()
  local s = Scenario.new('greendale-biology')
  s:step(6) -- let the player settle onto the floor
  local startX = s.player.position.x

  s:hold('RIGHT')
  s:step(30)
  s:release('RIGHT')

  assert_true(s.player.position.x > startX + 1,
    string.format("expected the player to move right; startX=%.1f endX=%.1f",
                  startX, s.player.position.x))
  s:teardown()
end

-- Discrete input event: a JUMP press should launch the player upward
-- (negative y velocity) once grounded.
function test_pressing_jump_launches_the_player()
  local s = Scenario.new('greendale-biology')
  s:step(8) -- settle firmly onto solid ground so the jump is allowed
  assert_true(s.player:solid_ground() ~= false,
    "player should be grounded before the jump test")

  s:press('JUMP')
  s:step(1) -- the queued 'jump' event is consumed on the next update

  assert_true(s.player.velocity.y < 0,
    string.format("expected upward velocity after JUMP; velocity.y=%.1f",
                  s.player.velocity.y))
  s:lift('JUMP')
  s:teardown()
end

-- Teardown restores the real love.keyboard.isDown for later suites.
function test_teardown_restores_the_keyboard()
  local original = love.keyboard.isDown
  local s = Scenario.new('greendale-biology')
  assert_true(love.keyboard.isDown ~= original, "stub should be installed")
  s:teardown()
  assert_true(love.keyboard.isDown == original, "teardown should restore the original")
end
