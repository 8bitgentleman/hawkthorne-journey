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

-- Fixed frame delta. Matches a steady 60fps; keeps physics integration
-- reproducible across runs (unlike the real game's variable dt).
local FIXED_DT = 1 / 60

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
-- Place the player and sync its collision shape to the new position.
-----------------------------------------------------------------------------
function Scenario:spawn(x, y)
  self.player.position = { x = x, y = y }
  self.player.velocity = { x = 0, y = 0 }
  self.player:moveBoundingBox()
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

-- Translate an action (e.g. 'RIGHT') to the raw key InputController watches.
function Scenario:_key(action)
  local key = self.controls.actionmap[action]
  assert(key ~= nil, "unknown action: " .. tostring(action))
  return key
end

-----------------------------------------------------------------------------
-- Begin holding a continuous action (movement). Persists across step() calls
-- until release()d. Mirrors a key being held down.
-----------------------------------------------------------------------------
function Scenario:hold(action)
  self._held[self:_key(action)] = true
  return self
end

-- Stop holding a continuous action.
function Scenario:release(action)
  self._held[self:_key(action)] = nil
  return self
end

-----------------------------------------------------------------------------
-- Fire a discrete button-down event (keypressed), routed through the level
-- exactly as main.lua's input dispatch would. Does NOT auto-release — use for
-- actions whose duration matters (e.g. JUMP: releasing early half-jumps). Pair
-- with lift() when the release should register.
-----------------------------------------------------------------------------
function Scenario:press(action)
  self.level:keypressed(action)
  return self
end

-- Fire a discrete button-up event (keyreleased).
function Scenario:lift(action)
  self.level:keyreleased(action)
  return self
end

-----------------------------------------------------------------------------
-- Fire a full press+release in one frame. Convenient for instantaneous
-- actions (ATTACK, INTERACT). Do NOT use for JUMP — an immediate release
-- half-jumps; use press()/lift() around some step()s instead.
-----------------------------------------------------------------------------
function Scenario:tap(action)
  self.level:keypressed(action)
  self.level:keyreleased(action)
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
  -- Restore the singleton exactly as we found it (see Scenario.new).
  Player.setSingleton(self._prevPlayer)
  self._prevPlayer = nil
  if self._savedRefresh then
    Player.refreshPlayer = self._savedRefresh
    self._savedRefresh = nil
  end
end

return Scenario
