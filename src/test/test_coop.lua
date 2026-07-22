-----------------------------------------------------------------------------
-- test_coop.lua — the drop-in second-player plumbing (Phase 2 completion).
--
-- Two layers under test:
--   1. coop.lua — pure device-ownership logic (which pad is whose, when a press
--      is a join/drop). No love window needed.
--   2. The production Level seams that turn that intent into a live player:
--      Level:spawnCoopPlayer / removeCoopPlayer, restartLevel auto-rebuild, and
--      Level:keypressed player-index routing. Driven through the scenario harness.
--
-- The scenario suite (test_scenario_coop.lua) already proves two players coexist
-- on one collider and move independently; those tests now run THROUGH
-- Level:spawnCoopPlayer (scenario.spawn2 delegates to it), so this file focuses
-- on the input-routing and lifecycle pieces the harness doesn't exercise.
-----------------------------------------------------------------------------

local coop = require 'coop'
local Scenario = require 'test/scenario'

local TILE = 24

-- A stand-in for a LÖVE gamepad joystick: identity comparison is all coop's
-- predicates need, plus the two methods InputController:switch calls when coop
-- binds player 2 to it.
local function fakePad(name)
  return {
    isGamepad = function() return true end,
    getName = function(self) return name or 'FakePad' end,
  }
end

-- Keyboard events carry no joystick; coop.owner(nil) must be player 1.
function test_owner_keyboard_is_player_one()
  coop.reset()
  assert_equal(1, coop.owner(nil), "keyboard (nil device) belongs to player 1")
end

-- Any gamepad that isn't player 2's belongs to player 1 (flexible P1).
function test_owner_unclaimed_pad_is_player_one()
  coop.reset()
  assert_equal(1, coop.owner(fakePad()), "an unclaimed pad belongs to player 1")
end

-- Start on a free pad player 1 isn't using is a join; other buttons are not.
function test_join_press_detection()
  coop.reset()
  local pad = fakePad()
  assert_true(coop.isJoinPress(pad, 'start', nil),
    "Start on a free pad (P1 on keyboard) is a join")
  assert_false(coop.isJoinPress(pad, 'a', nil),
    "a non-Start button is not a join")
  assert_false(coop.isJoinPress(pad, 'start', pad),
    "Start on the pad player 1 is already using is NOT a join (it's P1's pause)")
end

-- The join -> owner -> drop lifecycle, exercising the real controller binding.
function test_join_and_drop_lifecycle()
  coop.reset()
  assert_false(coop.active(), "no second player before a join")

  local pad = fakePad('P2 Pad')
  local controls = coop.join(pad)

  assert_true(coop.active(), "joined -> a second player is active")
  assert_equal(pad, coop.p2Device(), "coop tracks player 2's pad")
  assert_equal(controls, coop.p2Controls(), "join returns the bound controller")
  assert_equal(pad, controls.joystick, "player 2's controller polls their own pad")
  assert_equal(2, coop.owner(pad), "player 2's pad now belongs to player 2")
  assert_false(coop.isJoinPress(pad, 'start', nil),
    "with a P2 already joined, no further joins")
  assert_true(coop.isDropPress(pad, 'start'), "Start on P2's own pad is a drop")

  coop.drop()
  assert_false(coop.active(), "dropped -> back to single player")
  assert_equal(1, coop.owner(pad), "after a drop the pad reverts to player 1")
  coop.reset()
end

-- Level:keypressed with a player index of 2 must drive ONLY player 2 (jump),
-- leaving player 1 untouched — the routing that lets a P2 button never move P1.
function test_keypressed_routes_to_second_player()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x + 3 * TILE, base.y)
  s:step(8) -- settle both onto the floor

  local p1vy0 = s.player.velocity.y

  -- Route a JUMP through the real Level:keypressed with player index 2.
  s.level:keypressed('JUMP', 2)
  s:step(1)

  assert_true(s.player2.velocity.y < 0,
    "player 2 should jump when the event is routed to index 2")
  assert_true(s.player.velocity.y >= p1vy0,
    "player 1 must NOT jump from a player-2-routed event")

  s:teardown()
end

-- Level:removeCoopPlayer drops player 2 from the live list and off the collider.
function test_remove_coop_player_cleans_up()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x + 3 * TILE, base.y)
  s:step(6)

  assert_equal(2, #s.level.players, "two players are live before removal")

  s.level:removeCoopPlayer()

  assert_equal(1, #s.level.players, "player 2 removed from the live list")
  assert_equal(s.player, s.level.players[1], "player 1 remains as players[1]")

  -- Stepping must not crash or drive the departed player.
  s:step(5)

  -- The scenario's own player2 handle is stale now; drop it so teardown doesn't
  -- try to remove already-removed collider shapes.
  s.player2 = nil
  s.controls2 = nil
  s:teardown()
end

-- With co-op active, restartLevel (the single per-level player-build point) must
-- rebuild player 2 automatically — this is what makes P2 "come along" across
-- door/level switches without a re-join.
function test_restart_level_rebuilds_second_player()
  local s = Scenario.new('greendale-biology') -- resets coop intent
  local base = s.level.default_position
  s:spawn(base.x, base.y)

  -- Simulate a standing co-op session (as if P2 had joined earlier).
  coop.join(fakePad('P2 Pad'))

  s.level:restartLevel()

  assert_equal(2, #s.level.players,
    "restartLevel auto-spawns player 2 when co-op is active")
  local p2 = s.level.players[2]
  assert_true(p2 ~= s.level.player, "the rebuilt player 2 is a distinct instance")
  assert_equal(s.level.player, p2.shared_health,
    "rebuilt player 2 shares player 1's health bar")

  coop.reset()
  s:teardown()
end
