-----------------------------------------------------------------------------
-- test_scenario_coop.lua — Phase 0 kill-criterion for local co-op.
--
-- The make-or-break question for local co-op: can TWO Player instances be
-- registered on one level's HardonCollider and coexist — each with its own
-- top_bb/bottom_bb self-tagged via `bb.player = self` — WITHOUT their own
-- bounding boxes firing pathological collisions against each other, and with
-- level.lua's existing on_collision routing (which reads shape.player)
-- delivering each collision to the correct player instance?
--
-- These tests answer it headlessly. If two players couldn't share a collider,
-- the independent-movement and overlap tests below are exactly where it would
-- blow up.
--
-- Tile size on greendale-biology is 24px; spawns are expressed in tiles.
-----------------------------------------------------------------------------

local Scenario = require 'test/scenario'
local Player = require 'player'

local TILE = 24

-- Two players spawned a few tiles apart both settle onto the floor and stay
-- put. Proves both players' bounding boxes register on the one collider and
-- neither shoves the other around.
function test_two_players_register_and_settle()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x + 3 * TILE, base.y)

  s:step(20) -- let gravity settle both

  assert_true(s.player ~= s.player2, "the two players must be distinct instances")
  assert_true(s.player.top_bb ~= s.player2.top_bb, "each player has its own top_bb")
  assert_true(s.player.bottom_bb ~= s.player2.bottom_bb, "each player has its own bottom_bb")
  assert_equal(s.player, s.player.top_bb.player, "P1 top_bb self-tags to P1")
  assert_equal(s.player2, s.player2.top_bb.player, "P2 top_bb self-tags to P2")

  -- Both grounded, neither launched or NaN'd by a spurious collision. A grounded
  -- player carries one frame of gravity (~18 at this dt), so "landed" means
  -- solid ground plus a velocity far below the free-fall terminal (max_y=600) —
  -- not falling through and not ejected upward by a bogus player-vs-player hit.
  assert_true(s.player:solid_ground() ~= false, "P1 should be grounded")
  assert_true(s.player2:solid_ground() ~= false, "P2 should be grounded")
  assert_true(s.player.velocity.y >= 0 and s.player.velocity.y < 25,
    string.format("P1 landed, not free-falling/ejected; vy=%.2f", s.player.velocity.y))
  assert_true(s.player2.velocity.y >= 0 and s.player2.velocity.y < 25,
    string.format("P2 landed, not free-falling/ejected; vy=%.2f", s.player2.velocity.y))

  s:teardown()
end

-- Drive independent input into each player in the SAME frames: P1 walks right,
-- P2 jumps. Assert neither's motion bleeds into the other. This is the core
-- independence proof.
function test_players_move_independently()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x + 3 * TILE, base.y)
  s:step(8) -- settle both onto the floor

  local p1x0, p1y0 = s.player.position.x, s.player.position.y
  local p2x0, p2y0 = s.player2.position.x, s.player2.position.y

  assert_true(s.player2:solid_ground() ~= false, "P2 grounded before its jump")

  -- P1 holds RIGHT; P2 jumps (press, hold a few frames, then lift) — all
  -- interleaved across the same step()s.
  s:hold('RIGHT', 1)
  s:press('JUMP', 2)
  s:step(1)
  assert_true(s.player2.velocity.y < 0,
    string.format("P2 should have upward velocity after JUMP; vy=%.1f", s.player2.velocity.y))
  s:step(10)
  s:lift('JUMP', 2)
  s:step(10)
  s:release('RIGHT', 1)

  -- P1 moved right and did NOT jump (stayed on/near the floor line).
  assert_true(s.player.position.x > p1x0 + 1,
    string.format("P1 should have walked right; x0=%.1f x=%.1f", p1x0, s.player.position.x))
  assert_true(s.player.position.y <= p1y0 + 1,
    string.format("P1 should NOT have jumped; y0=%.1f y=%.1f", p1y0, s.player.position.y))

  -- P2 jumped (rose above its start) and did NOT walk right.
  assert_true(s.player2.position.y < p2y0 - 1,
    string.format("P2 should have risen from the jump; y0=%.1f y=%.1f", p2y0, s.player2.position.y))
  assert_true(math.abs(s.player2.position.x - p2x0) < 1,
    string.format("P2 should NOT have drifted horizontally; x0=%.1f x=%.1f", p2x0, s.player2.position.x))

  s:teardown()
end

-- Fully OVERLAPPING players: spawn P2 on top of P1 so both players' bounding
-- boxes overlap, then step. on_collision's `if shape_a.player and shape_b.player
-- then return end` guard must absorb every player-vs-player pair — no launch,
-- no NaN, no crash. This is the pathological case the kill-criterion asks about.
function test_overlapping_players_do_not_collide_pathologically()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x, base.y) -- exact same spot: boxes fully overlap

  s:step(20)

  -- Both remain finite and roughly at rest on the floor; neither was ejected.
  for _, p in ipairs({ s.player, s.player2 }) do
    assert_true(p.velocity.x == p.velocity.x, "velocity.x must not be NaN")
    assert_true(p.velocity.y == p.velocity.y, "velocity.y must not be NaN")
    assert_true(math.abs(p.velocity.x) < 50, "no horizontal ejection from overlap")
    assert_true(p:solid_ground() ~= false, "still grounded after overlapping")
  end

  s:teardown()
end

-- Engine-driven independence (Phase 2): P2 is now in level.players, so ONLY
-- Level:update (via step) moves both players — the harness no longer direct-drives
-- P2. P1 holds RIGHT and P2 holds LEFT in the same frames; each player's own
-- InputController polls its own keys through the engine loop and they diverge,
-- with no cross-bleed. This is the engine-driven movement proof.
function test_players_engine_driven_opposite_directions()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x + 4 * TILE, base.y)
  s:spawn2(base.x + 1 * TILE, base.y)
  s:step(8) -- settle both onto the floor

  -- The engine owns P2: it must be in the level's live player list.
  local inList = false
  for _, p in ipairs(s.level.players) do
    if p == s.player2 then inList = true end
  end
  assert_true(inList, "P2 must be in level.players so the engine drives it")

  local p1x0 = s.player.position.x
  local p2x0 = s.player2.position.x

  -- Opposite continuous inputs in the same frames, delivered only through the
  -- stubbed keyboard + each player's own controller polling inside Level:update.
  s:hold('RIGHT', 1)
  s:hold('LEFT', 2)
  s:step(20)
  s:release('RIGHT', 1)
  s:release('LEFT', 2)

  assert_true(s.player.position.x > p1x0 + 1,
    string.format("P1 should have walked right; x0=%.1f x=%.1f", p1x0, s.player.position.x))
  assert_true(s.player2.position.x < p2x0 - 1,
    string.format("P2 should have walked left; x0=%.1f x=%.1f", p2x0, s.player2.position.x))
  assert_true(s.player.velocity.x > 0, "P1 velocity points right")
  assert_true(s.player2.velocity.x < 0, "P2 velocity points left")

  s:teardown()
end

-- Independent character state (Phase 2): P1 and P2 hold DISTINCT character
-- objects, and driving one into a walk animation must not change the other's
-- idle state. Engine-driven — only step()/Level:update advances the animation
-- via each player's own character:update.
function test_players_have_independent_character_state()
  local s = Scenario.new('greendale-biology')
  local base = s.level.default_position
  s:spawn(base.x, base.y)
  s:spawn2(base.x + 3 * TILE, base.y)
  s:step(8) -- settle both

  assert_true(s.player.character ~= s.player2.character,
    "each player must own a distinct character object")

  -- Walk P1; leave P2 idle. P1's character.state becomes a walk state while
  -- P2's stays idle — proof the sprite/animation state does not bleed across.
  s:hold('RIGHT', 1)
  s:step(10)
  s:release('RIGHT', 1)

  assert_equal('walk', s.player.character.state,
    "P1 (walking) should be in the walk state")
  assert_equal('idle', s.player2.character.state,
    "P2 (idle) should stay idle — character state must not cross-bleed")

  s:teardown()
end

-- The two-player scenario must leave the module singleton exactly as it found
-- it — player 2 is a plain instance, never the singleton, so teardown's
-- existing snapshot/restore covers it.
function test_two_player_teardown_restores_singleton()
  local before = Player.getSingleton()
  local s = Scenario.new('greendale-biology')
  s:spawn2(s.level.default_position.x + 3 * TILE, s.level.default_position.y)
  assert_true(Player.getSingleton() == s.player, "P1 is the singleton during the scenario")
  assert_true(s.player2 ~= Player.getSingleton(), "P2 is NOT the singleton")
  s:teardown()
  assert_true(Player.getSingleton() == before, "teardown restores the prior singleton")
end
