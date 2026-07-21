-----------------------------------------------------------------------------
-- test_buoyancy.lua — floaty underwater movement.
--
-- Covers the three moving parts of the 'buoyant' liquid behaviour:
--   * the liquid node toggles player.submerged on entry/exit,
--   * being submerged softens the fall (reduced gravity, low terminal speed),
--   * JUMP becomes a repeatable swim stroke that needs no solid ground.
-- Plus a regression pin: suffocation must NOT set rebounding (that flag gates
-- out movement/jump input — an earlier port froze the controls every tick).
--
-- NB: a scenario test that fails an assertion before s:teardown() leaks the
-- Player singleton / keyboard stub into later suites (e.g. test_cheat). Keep
-- these assertions robust so teardown always runs.
-----------------------------------------------------------------------------

local Scenario = require 'test/scenario'
local Liquid = require 'nodes/liquid'

-- A buoyant liquid submerges the player on contact and un-submerges on exit.
-- Built directly on the metatable so we exercise the collide wiring without
-- needing a collider or sprite (Liquid.new loads graphics).
function test_buoyant_liquid_toggles_submerged()
  local liquid = setmetatable({ buoyant = true }, Liquid)
  local player = { isPlayer = true, submerged = false }

  liquid:collide(player, 1/60)
  assert_true(player.submerged, "entering a buoyant liquid should submerge the player")

  liquid:collide_end(player, 1/60)
  assert_false(player.submerged, "leaving a buoyant liquid should un-submerge the player")
end

-- A non-buoyant liquid leaves submerged untouched (guards the flag against
-- every other liquid in the game).
function test_plain_liquid_does_not_submerge()
  local liquid = setmetatable({ buoyant = false }, Liquid)
  local player = { isPlayer = true, submerged = false }

  liquid:collide(player, 1/60)
  assert_false(player.submerged, "a non-buoyant liquid must not submerge the player")
end

-- Submerged, the player still sinks but noticeably slower than in open air.
function test_buoyancy_softens_the_fall()
  local dry = Scenario.new('greendale-biology')
  dry:spawn(dry.level.default_position.x, dry.level.default_position.y - 60)
  dry.player.submerged = false
  dry:step(6)
  local dryFall = dry.player.velocity.y
  dry:teardown()

  local wet = Scenario.new('greendale-biology')
  wet:spawn(wet.level.default_position.x, wet.level.default_position.y - 60)
  wet.player.submerged = true
  wet:step(6)
  local wetFall = wet.player.velocity.y
  wet:teardown()

  assert_true(dryFall > 0, "sanity: the dry player should be falling")
  assert_true(wetFall > 0, "submerged player should still sink, not float straight up")
  assert_true(wetFall < dryFall * 0.6,
    string.format("submerged fall (%.1f) should be well under the dry fall (%.1f)",
                  wetFall, dryFall))
end

-- A JUMP while submerged is a swim stroke: upward velocity, no solid ground
-- required. Six submerged frames put the player clearly airborne first.
function test_swim_stroke_pushes_up_without_ground()
  local s = Scenario.new('greendale-biology')
  s:spawn(s.level.default_position.x, s.level.default_position.y - 60)
  s.player.submerged = true
  s:step(6) -- fall past fall_grace so the player is genuinely off the ground
  assert_true(s.player:solid_ground() == false, "player should be airborne for this stroke")
  assert_true(s.player.velocity.y > -120, "sinking, so a swim stroke is allowed")

  s:press('JUMP')
  s:step(1)

  assert_true(s.player.velocity.y < 0,
    string.format("swim stroke should push the player upward; velocity.y=%.1f",
                  s.player.velocity.y))
  s:lift('JUMP')
  s:teardown()
end

-- Regression pin: suffocation drains oxygen but must leave rebounding false so
-- the player keeps control underwater.
function test_suffocate_keeps_movement_control()
  local s = Scenario.new('greendale-biology')
  s.player.oxygen = s.player.max_oxygen
  s.player.rebounding = false

  s.player:suffocate(5)

  assert_true(s.player.rebounding == false,
    "suffocate must not set rebounding — that flag would freeze the controls")
  assert_true(s.player.dead == false, "one 5-point tick should not kill a full-oxygen player")
  assert_equal(s.player.max_oxygen - 5, s.player.oxygen, "suffocate should drain oxygen")
  s:teardown()
end
