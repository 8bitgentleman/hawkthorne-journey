-- Floorspace (top-down interior) coverage for the scenario harness, and a
-- regression guard for the teacher-lounge door-exit bug reported on PR #2530
-- ("trouble exiting the teacher-lounge doors / entering the bathroom").
--
-- Root cause: Door:switch (door.lua) rejects the exit when the door's bounding
-- box bottom is more than 10px from the player's feet. In a floorspace level the
-- player's feet sit at a *fixed* depth band (the footprint on the primary
-- walk-polygon), so a door is only reachable if its bb-bottom lands within 10px
-- of that band. The lounge `main` door does; the `bathroom` door's bb-bottom was
-- 25.7px too high, so pressing its button silently did nothing.

local Scenario = require 'test/scenario'
local Gamestate = require 'vendor/gamestate'

local REACH_SLOP = 10 -- must mirror the `> 10` gate in Door:switch

local function feet(player)
  local _, _, _, y2 = player.bottom_bb:bbox()
  return y2
end

local function doorBottom(level, name)
  local _, _, _, wy2 = level.doors[name].node.bb:bbox()
  return wy2
end

-- Boot a floorspace level with the door transition captured instead of executed:
-- Door:switch calls Gamestate.currentState():exit(level, to) on a successful
-- exit, which would tear down the world. We record the call instead so the test
-- can assert the door fired (or didn't). Returns the scenario and an `exits`
-- list that each successful door-exit appends "<level>/<to>" to.
local function boot(name)
  local s = Scenario.new(name)
  local exits = {}
  local current = Gamestate.currentState()
  current.name = name
  current.exit = function(_, level, to) exits[#exits + 1] = level .. '/' .. to end
  return s, exits
end

-- Hold RIGHT until the player's x reaches targetX (or we give up). Small steps so
-- we don't overshoot narrow door bands.
local function walkTo(s, targetX)
  for _ = 1, 60 do
    if s.player.position.x >= targetX then break end
    s:hold('RIGHT'); s:step(2); s:release('RIGHT')
  end
end

-- Entering a floorspace level should build the player's footprint and keep them
-- planted on the walk-polygon rather than dropping through the floor.
function test_floorspace_player_does_not_fall_through()
  local s = boot('greendale-lounge')

  s:step(6)
  local settled = s.player.position.y
  assert_true(s.player.footprint ~= nil,
    "entering a floorspace level should build the player's footprint")

  s:step(60) -- keep simulating with no input
  local later = s.player.position.y
  assert_true(later < 336,
    string.format("player fell through the floor (y=%.1f past map bottom)", later))
  assert_true(math.abs(later - settled) < 4,
    string.format("player should stay planted, not drift (y %.1f -> %.1f)", settled, later))

  s:teardown()
end

-- The bathroom door was the reported bug: its bb-bottom sat too high above the
-- floorspace feet band, so Door:switch's 10px gate rejected every exit. Assert
-- both the geometry (reachable) and the behaviour (pressing its button fires the
-- transition to the bathroom).
function test_lounge_bathroom_door_is_reachable_and_exits()
  local s, exits = boot('greendale-lounge')
  s.player.inventory.hasKey = function() return true end -- the door is flashlight-gated
  s:step(8)

  -- Walk into the bathroom door's x-span (object x=72, width=24 -> [72,96]).
  walkTo(s, 80)

  local gap = math.abs(doorBottom(s.level, 'bathroom') - feet(s.player))
  assert_true(gap <= REACH_SLOP,
    string.format("bathroom door unreachable: bb-bottom %.1fpx from feet (gate is %dpx)",
      gap, REACH_SLOP))

  -- LEFT is the bathroom door's button; with the door reachable it must exit.
  s:press('LEFT'); s:step(1); s:lift('LEFT'); s:step(1)
  assert_equal('greendale-lounge-bathroom/main', exits[1],
    "pressing the bathroom door's button should exit into the bathroom")

  s:teardown()
end

-- Control: the lounge `main` door (an instant door on the left wall) has always
-- worked. Walking left into it should fire its exit — proving the harness drives
-- real door transitions, not just the fixed one.
function test_lounge_main_door_exits()
  local s, exits = boot('greendale-lounge')
  s:step(8)

  s:hold('LEFT'); s:step(20); s:release('LEFT'); s:step(1)
  assert_true(#exits > 0, "walking into the instant main door should fire an exit")
  assert_equal('greendale-exterior/admin4', exits[1],
    "the lounge main door should exit to the exterior")

  s:teardown()
end
