-----------------------------------------------------------------------------
-- coop.lua — persistent local co-op session state.
--
-- Holds the one piece of co-op intent that must outlive an individual level:
-- WHO is player 2 and WHICH gamepad they own. Because it is module-cached it
-- survives level switches, so player 2 "comes along" through the overworld
-- (which builds no second player) and is rebuilt in the next real level.
--
-- Device model (owner's call, 2026-07-22):
--   * Player 1 keeps the existing flexible keyboard-or-gamepad behavior.
--   * Player 2 claims the next free gamepad via a drop-in join (START on a pad
--     player 1 is not already using) and can drop back out.
--   * Only two players are supported in the spike.
--
-- This module is deliberately pure — no love.* calls, no Level/Player reach —
-- so its device-ownership logic is unit-testable headlessly. The actual player
-- instance lives on the Level (Level:spawnCoopPlayer); main.lua wires raw input
-- events to this module's decisions.
-----------------------------------------------------------------------------

local InputController = require 'inputcontroller'

-- The raw gamepad button LÖVE reports for Start. Join and drop both key off it;
-- matches DEFAULT_ACTIONMAP.gamepad.START in inputcontroller.lua.
local START_BUTTON = 'start'

local coop = {}

-- The joystick object player 2 owns, or nil when there is no second player.
local p2joystick = nil
-- Player 2's InputController, bound to that joystick (nil when no P2).
local p2controls = nil

-- Is a second player currently joined?
function coop.active()
  return p2joystick ~= nil
end

-- Player 2's controller (nil when no P2).
function coop.p2Controls()
  return p2controls
end

-- The joystick player 2 owns (nil when no P2).
function coop.p2Device()
  return p2joystick
end

-- Which player index owns a raw input device? The keyboard and any gamepad that
-- is not player 2's belong to player 1 (who keeps the flexible keyboard-or-pad
-- behavior); player 2's own gamepad belongs to player 2.
function coop.owner(joystick)
  if joystick ~= nil and joystick == p2joystick then return 2 end
  return 1
end

-- Would this gamepad press start a co-op join? True only when there is no P2
-- yet and the press is Start on a gamepad player 1 is not already using
-- (p1joystick is player 1's current gamepad, or nil when player 1 is on the
-- keyboard — in which case any pad's Start joins).
function coop.isJoinPress(joystick, key, p1joystick)
  if p2joystick ~= nil then return false end
  if joystick == nil then return false end
  if joystick == p1joystick then return false end
  return key == START_BUTTON
end

-- Is this press player 2 asking to drop out (Start on their own pad)?
function coop.isDropPress(joystick, key)
  return p2joystick ~= nil and joystick == p2joystick and key == START_BUTTON
end

-- Bind player 2 to a joystick, building its gamepad-mapped controller. Returns
-- the controller so the caller can hand it to Level:spawnCoopPlayer.
function coop.join(joystick)
  p2joystick = joystick
  -- Start from the default preset, then switch onto the joystick — switch()
  -- sets .joystick and loads that pad's gamepad actionmap, exactly as it does
  -- for player 1 when they pick up a gamepad.
  p2controls = InputController.new('coop-p2')
  p2controls:switch(joystick)
  return p2controls
end

-- Player 2 leaves co-op; the game reverts to single-player device handling.
function coop.drop()
  p2joystick = nil
  p2controls = nil
end

-- Test support: clear all co-op intent. The module is cached and shared, so a
-- suite that joins a player must reset or it leaks into whatever runs next.
function coop.reset()
  p2joystick = nil
  p2controls = nil
end

return coop
