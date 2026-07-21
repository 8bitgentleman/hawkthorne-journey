-----------------------------------------------------------------------------
-- test_moving_platform_scenario.lua
--
-- Regression coverage for issue #2427: "the player sometimes falls through
-- moving platforms if they are crouching and spamming the attack or interact
-- key ... changing the movement line slightly can resolve it."
--
-- Root cause: a rider is bound to a platform via `player.currentplatform`, but
-- `collision.move_y` cleared that binding on every frame the platform moved *up*
-- -- the catch that keeps it only fires while the player is moving *down*. So a
-- rising platform carried the player only by luck of a one-frame gravity
-- re-catch each frame. That re-catch is marginal (it needs the player's feet at
-- or above the platform top), so any per-frame disturbance -- e.g. the crouch
-- bounding box flipping as the crouch/attack keys are worked, on a platform
-- moving fast enough -- let the rising platform slip out from under the player:
-- a fall-through. (Hence "changing the movement line slightly can resolve it" --
-- it shifts the timing of that race.)
--
-- The fix (collision.lua) keeps the player attached while the platform itself is
-- what is carrying them upward, so the carry runs every frame and no re-catch
-- race can drop them. The invariant asserted here -- a crouch-attacking rider
-- stays bound to a rising platform for the whole ascent -- is 0/N before the fix
-- and N/N after it.
-----------------------------------------------------------------------------

local Scenario = require 'test/scenario'

-- frozencave's vertical moving platform (path mostly vertical). Horizontal
-- platforms never exercise the rising-carry path this bug lives in.
local function verticalPlatform(s)
  for _, mp in ipairs(s:movingPlatforms()) do
    local a, b = mp.bspline:eval(0), mp.bspline:eval(1)
    if math.abs(b.y - a.y) > math.abs(b.x - a.x) then return mp end
  end
end

-- Riding a rising platform while crouching and spamming attack/interact (the
-- exact input from the issue), the player must stay bound to the platform -- and
-- on its surface -- the whole way up. Pre-fix the binding was dropped on every
-- rising frame.
function test_crouch_attacking_rider_stays_on_rising_platform()
  local s = Scenario.new('frozencave')
  s:step(2)  -- settle onto the platform's starting position
  local mp = verticalPlatform(s)
  assert_true(mp ~= nil, 'frozencave should have a vertical moving platform')

  s.player.godmode = true  -- isolate platform physics from enemy knockback
  assert_true(s:landOn(mp), 'player should land on and attach to the platform')

  local bbox = s.player.character.bbox
  local rising, attachedWhileRising, worstSink = 0, 0, 0
  for i = 1, 1200 do
    s:hold('DOWN')  -- crouch
    if i % 2 == 0 then s:tap('ATTACK') else s:tap('INTERACT') end  -- spam
    s:step(1)
    if mp.dy < -0.01 then  -- platform is rising this frame
      rising = rising + 1
      if s.player.currentplatform == mp then
        attachedWhileRising = attachedWhileRising + 1
      end
      -- how far the player's feet have sunk below the platform's top surface
      local sink = (s.player.position.y + bbox.height) - mp.y
      if sink > worstSink then worstSink = sink end
    end
  end
  s:release('DOWN')
  s:teardown()

  assert_true(rising > 60, 'the platform should spend many frames rising')
  -- The binding must hold for the entire ascent. This is the invariant the fix
  -- restores; pre-fix `attachedWhileRising` is 0.
  assert_equal(rising, attachedWhileRising,
    string.format('rider detached from the rising platform on %d/%d frames',
      rising - attachedWhileRising, rising))
  -- Staying bound must mean staying on the surface, not sinking through it.
  assert_true(worstSink < 4,
    string.format('rider sank %.1fpx below the rising platform surface', worstSink))
end
