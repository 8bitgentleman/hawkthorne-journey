-----------------------------------------------------------------------------
-- scenario.lua — headless gameplay-driving harness for tests.
--
-- Boots a real Level, positions the player, injects scripted input, and steps
-- the level update loop at a fixed dt so gameplay behaviour can be asserted on
-- deterministically — without a window, a keyboard, or a human.
--
-- This is a test *helper*, not a suite: its filename does not start with
-- `test_`, so lovetest's auto-discovery skips it. Require it from a test with
--   local Scenario = require 'test/scenario'
--
-- Example:
--   local s = Scenario.new('greendale-biology') -- boots the level, player at 'main'
--   s:hold('RIGHT'); s:step(30)               -- walk right for 30 frames
--   s:release('RIGHT')
--   s:press('JUMP'); s:step(10); s:lift('JUMP')  -- a held jump
--   assert_true(s.player.position.x > startX)
--   s:teardown()                              -- ALWAYS call (restores globals)
--
-- Continuous actions (movement) use hold/release (keyboard polling). Discrete
-- actions use press/lift (keypressed/keyreleased events); tap() is press+lift
-- in one frame for instantaneous actions like ATTACK.
--
-- Fixture note: use a plain side-scrolling level with a `collision` tilelayer
-- (e.g. 'greendale-biology'). 'floorspace' rooms (studyroom) have no collision
-- layer, so the player falls through the floor. Moving-platform levels
-- (frozencave, black-caverns) ARE drivable — Scenario.new runs each platform's
-- node:enter() to build its Bspline; see landOn()/movingPlatforms() below.
-----------------------------------------------------------------------------

local Level = require 'level'
local Player = require 'player'
local InputController = require 'inputcontroller'
local character = require 'character'
local coop = require 'coop'

-- Fixed frame delta. Matches a steady 60fps; keeps physics integration
-- reproducible across runs (unlike the real game's variable dt).
local FIXED_DT = 1 / 60

-- Physical keys for a second (co-op) player, chosen to be DISJOINT from the
-- default preset's keys (up/down/left/right/space/a/d/s/escape). Because the
-- keyboard is stubbed with a single shared held-key table, two players can only
-- be polled independently if their action->key maps don't overlap: P1 holding
-- 'right' must not also register as P2's RIGHT. Distinct keys give us that for
-- free without per-player keyboard stubs.
local P2_ACTIONMAP = {
  UP = 'i', DOWN = 'k', LEFT = 'j', RIGHT = 'l',
  JUMP = 'rshift', ATTACK = 'u', INTERACT = 'o',
  SELECT = 'p', START = 'backspace',
}

local Scenario = {}
Scenario.__index = Scenario

-----------------------------------------------------------------------------
-- Boot a level headlessly with a fresh player.
-- @param name  level name (e.g. 'greendale-biology'), same string Level.new
--              expects (see the fixture note above)
-- @param opts  optional table: { x=, y= } spawn override (defaults to the
--              level's 'main' door position)
-- @return Scenario
-----------------------------------------------------------------------------
function Scenario.new(name, opts)
  opts = opts or {}

  local self = setmetatable({}, Scenario)

  -- Other test suites (e.g. test_cheat, test_inventory) permanently stub
  -- Player.refreshPlayer on this shared module to dodge the collider
  -- dependency. We DO have a real collider and need the genuine method to build
  -- the player's bounding boxes, so swap the pristine reference in for the
  -- scenario's lifetime; teardown() restores whatever was there before.
  self._savedRefresh = Player.refreshPlayer
  Player.refreshPlayer = Player.realRefreshPlayer

  -- Snapshot the current Player singleton and clear it so the scenario builds a
  -- fresh, isolated player. Other suites (e.g. test_cheat) grab the singleton
  -- once at module load and expect it to survive across their tests; teardown()
  -- restores this snapshot so they're unaffected no matter the test-run order.
  self._prevPlayer = Player.getSingleton()
  Player.kill()

  -- Clear any leaked co-op intent so each scenario boots single-player and
  -- restartLevel doesn't auto-spawn a stale player 2. spawn2() below drives the
  -- second player explicitly instead.
  coop.reset()

  self.level = Level.new(name)

  -- Level.new leaves level.player bound to a stale global (nil until the game
  -- has a live player). restartLevel() is what the real Level:enter calls to
  -- (re)bind the singleton player via Player.factory, refresh it against the
  -- collider, and set the level boundary — mirror that so the level is in the
  -- same shape it would be during normal play.
  self.level:restartLevel()
  self.player = self.level.player
  self.player:setSpriteStates(self.player.current_state_set or 'default')
  self.controls = self.player.controls

  -- Level.new leaves the level idle; update/keypressed no-op until active.
  self.level.state = 'active'
  self.player.freeze = false

  -- No physical joystick in headless mode — force the keyboard code path in
  -- InputController:isDown so our love.keyboard.isDown stub takes effect.
  self.controls.joystick = nil

  -- Moving-platform levels need each platform's node:enter() run to build its
  -- Bspline path — Level:enter does this (level.lua:416) but restartLevel(),
  -- which the harness calls instead, skips it. Without a bspline the first
  -- MovingPlatform:update crashes at ':194 attempt to index field bspline'.
  -- Run enter() here so moving-platform fixtures (frozencave, black-caverns…)
  -- are drivable. Teardown resets map.moving_platforms so it can't leak.
  self:_enterMovingPlatforms()

  -- Install the keyboard stub, remembering the original to restore on teardown.
  self._held = {}
  self._realIsDown = love.keyboard.isDown
  local held = self._held
  love.keyboard.isDown = function(key)
    return held[key] == true
  end

  local spawn = { x = opts.x, y = opts.y }
  if spawn.x == nil then spawn.x = self.level.default_position.x end
  if spawn.y == nil then spawn.y = self.level.default_position.y end
  self:spawn(spawn.x, spawn.y)

  return self
end

-----------------------------------------------------------------------------
-- Place an arbitrary player instance and sync its collision shapes.
-----------------------------------------------------------------------------
function Scenario:_place(player, x, y)
  player.position = { x = x, y = y }
  player.velocity = { x = 0, y = 0 }
  player:moveBoundingBox()
  return self
end

-----------------------------------------------------------------------------
-- Place the (first) player and sync its collision shape to the new position.
-----------------------------------------------------------------------------
function Scenario:spawn(x, y)
  return self:_place(self.player, x, y)
end

-----------------------------------------------------------------------------
-- Spawn a SECOND player on the same level collider — the co-op kill-criterion.
--
-- Deliberately built with Player.new (NOT Player.factory): factory is
-- create-or-return-the-one module singleton, so a second call would just hand
-- back player 1. Player.new constructs a fresh, independent instance and, via
-- its refreshPlayer, registers this player's own top_bb/bottom_bb on the shared
-- level collider (each self-tagged `bb.player = self`, exactly like player 1).
--
-- This instance is intentionally NOT stored in the module singleton, so the
-- existing getSingleton/setSingleton snapshot in Scenario.new/teardown fully
-- covers the two-player case with no extra bookkeeping — player 1 remains the
-- singleton; player 2 is a plain instance we drop on teardown.
--
-- Player 2 gets its own InputController preset with keys disjoint from player 1
-- (see P2_ACTIONMAP) so per-player input helpers can drive them independently.
--
-- Phase 2: P2 is given its OWN character object (character.build(), not the
-- shared character.current() singleton P1 holds) so its animation/sprite state
-- is independent, and P2 is APPENDED to self.level.players so the engine's own
-- Level:update player-list loop drives it — no direct harness poke (see step()).
-----------------------------------------------------------------------------
function Scenario:spawn2(x, y)
  assert(self.player2 == nil, 'spawn2 already called for this scenario')

  -- Distinct controller with keys DISJOINT from player 1 (P2_ACTIONMAP) so P2's
  -- polled input doesn't alias P1's in the one shared held-key table. new(name,
  -- map) with a table map loads it directly and never touches the controls db.
  local controls = InputController.new('coop-p2', P2_ACTIONMAP)
  controls.joystick = nil -- force the keyboard path, like the harness's P1
  self.controls2 = controls

  -- Build player 2 through the SAME production path the running game uses: fresh
  -- instance, own character, shared_health -> P1, appended to level.players so
  -- Level:update's player-list loop drives it. Passing our disjoint-key
  -- controller makes these headless tests exercise Level:spawnCoopPlayer for real.
  local p2 = self.level:spawnCoopPlayer(controls)
  self.player2 = p2
  self:_place(p2, x, y)
  return self
end

-----------------------------------------------------------------------------
-- Moving platforms
-----------------------------------------------------------------------------

-- Build the Bspline for every moving platform the map instantiated (see the
-- note in Scenario.new). Safe to call once; no-op on levels without any.
function Scenario:_enterMovingPlatforms()
  local mps = self.level.map.moving_platforms
  if not mps then return end
  for _, mp in ipairs(mps) do
    if mp.enter and not mp.bspline then mp:enter() end
  end
end

-- The map's live list of moving platforms (in map order).
function Scenario:movingPlatforms()
  return self.level.map.moving_platforms or {}
end

-----------------------------------------------------------------------------
-- Land the player on a moving platform and wait until the engine actually
-- attaches them (player.currentplatform == platform). Spawning the player
-- exactly *on* a platform does NOT reliably fire the HardonCollider overlap
-- that sets currentplatform; dropping onto it from just above does, via the
-- move_y "caught above a platform, moving down" path. Returns true once
-- attached, false if it never latched within `maxFrames`.
-----------------------------------------------------------------------------
function Scenario:landOn(platform, maxFrames)
  maxFrames = maxFrames or 180
  local p = self.player
  local bbox = p.character.bbox
  -- Centre the player horizontally on the platform, feet a hair above its top,
  -- then let gravity drop them onto it.
  p.position = {
    x = platform.x + platform.width / 2 - bbox.width / 2,
    y = platform.y - bbox.height - 1,
  }
  p.velocity = { x = 0, y = 0 }
  p:moveBoundingBox()
  for _ = 1, maxFrames do
    self:step(1)
    if p.currentplatform == platform then return true end
  end
  return p.currentplatform == platform
end

-- Which player's controls does an index refer to? `who` defaults to 1, so every
-- existing single-player call site keeps working unchanged.
function Scenario:_controlsFor(who)
  if who == 2 then
    assert(self.controls2, 'spawn2() must be called before driving player 2')
    return self.controls2
  end
  return self.controls
end

-- Translate an action (e.g. 'RIGHT') to the raw key the given player's
-- InputController watches. Per-player because P1 and P2 map actions to
-- different physical keys.
function Scenario:_key(action, who)
  local key = self:_controlsFor(who).actionmap[action]
  assert(key ~= nil, "unknown action: " .. tostring(action))
  return key
end

-----------------------------------------------------------------------------
-- Begin holding a continuous action (movement) for player `who` (default 1).
-- Persists across step() calls until release()d. Mirrors a key being held down.
-- Because P1/P2 use disjoint physical keys, both players' holds coexist in the
-- one shared held-key table.
-----------------------------------------------------------------------------
function Scenario:hold(action, who)
  self._held[self:_key(action, who)] = true
  return self
end

-- Stop holding a continuous action for player `who` (default 1).
function Scenario:release(action, who)
  self._held[self:_key(action, who)] = nil
  return self
end

-----------------------------------------------------------------------------
-- Fire a discrete button-down event for player `who` (default 1). Does NOT
-- auto-release — use for actions whose duration matters (e.g. JUMP: releasing
-- early half-jumps). Pair with lift() when the release should register.
--
-- Player 1 routes through Level:keypressed (the full main.lua dispatch: node
-- interactions then the player). Player 2 — which the level's single-player
-- dispatch knows nothing about — is driven directly on its own instance. For
-- the movement primitives this spike cares about (JUMP) that's equivalent; the
-- level's node-interaction pass is out of scope for Phase 0.
-----------------------------------------------------------------------------
function Scenario:press(action, who)
  if who == 2 then
    self.player2:keypressed(action, self.level.map)
  else
    self.level:keypressed(action)
  end
  return self
end

-- Fire a discrete button-up event for player `who` (default 1).
function Scenario:lift(action, who)
  if who == 2 then
    self.player2:keyreleased(action, self.level.map)
  else
    self.level:keyreleased(action)
  end
  return self
end

-----------------------------------------------------------------------------
-- Fire a full press+release in one frame for player `who` (default 1).
-- Convenient for instantaneous actions (ATTACK, INTERACT). Do NOT use for
-- JUMP — an immediate release half-jumps; use press()/lift() around step()s.
-----------------------------------------------------------------------------
function Scenario:tap(action, who)
  self:press(action, who)
  self:lift(action, who)
  return self
end

-----------------------------------------------------------------------------
-- Advance the simulation by `frames` fixed-dt updates (default 1 frame).
-- Runs the full Level:update loop each frame — player physics, collider
-- resolution, nodes — so post-step state reflects real gameplay.
-----------------------------------------------------------------------------
function Scenario:step(frames, dt)
  frames = frames or 1
  dt = dt or FIXED_DT
  for _ = 1, frames do
    -- Phase 2: P2 is in self.level.players, so Level:update's player-list loop
    -- drives it (input poll + physics) in the same pass as P1 before this frame's
    -- collider:update fires. The harness no longer direct-drives P2 — its
    -- continuous input (hold) flows through the engine via P2's own controller
    -- polling the stubbed keyboard, exactly like P1.
    self.level:update(dt)
  end
  return self
end

-----------------------------------------------------------------------------
-- Restore patched globals and drop the singleton player. ALWAYS call this at
-- the end of a scenario (e.g. in a test's teardown) so later tests see a clean
-- love.keyboard and a fresh player.
-----------------------------------------------------------------------------
function Scenario:teardown()
  if self._realIsDown then
    love.keyboard.isDown = self._realIsDown
    self._realIsDown = nil
  end
  self._held = {}
  -- Reset the map's moving-platform list. It lives on the require()-cached map
  -- table, so without this it accumulates platforms across scenarios in one
  -- test process (and chain platforms spawn extra entries mid-run) — the exact
  -- order-dependent leakage the suite warns about elsewhere.
  if self.level and self.level.map then
    self.level.map.moving_platforms = {}
  end
  -- Drop player 2's shapes off the collider. The collider is per-scenario
  -- (Level.new mints a fresh one), so this can't leak across scenarios — but
  -- player 2 is never the module singleton, so nothing else would clean it up.
  -- The singleton snapshot/restore below is unaffected: it only ever tracked
  -- player 1.
  if self.player2 then
    local p2 = self.player2
    -- Remove P2 from the engine's player list so a subsequent Level:update (or a
    -- later scenario reusing the cached level) can't drive a torn-down player.
    for i = #self.level.players, 1, -1 do
      if self.level.players[i] == p2 then table.remove(self.level.players, i) end
    end
    if p2.top_bb then self.level.collider:remove(p2.top_bb) end
    if p2.bottom_bb then self.level.collider:remove(p2.bottom_bb) end
    if p2.attack_box and p2.attack_box.bb then
      self.level.collider:remove(p2.attack_box.bb)
    end
    self.player2 = nil
    self.controls2 = nil
  end

  -- Restore the singleton exactly as we found it (see Scenario.new).
  Player.setSingleton(self._prevPlayer)
  self._prevPlayer = nil
  if self._savedRefresh then
    Player.refreshPlayer = self._savedRefresh
    self._savedRefresh = nil
  end
end

return Scenario
