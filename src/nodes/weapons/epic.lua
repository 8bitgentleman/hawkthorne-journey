-----------------------------------------------
-- mace.lua
-- Represents a mace that a player can wield or pick up
-- Created by NimbusBP1729
-----------------------------------------------

--
-- Creates a new mace object
-- @return the mace object created
local Timer = require 'vendor/timer'
local window = require 'window'
local camera = require 'camera'

return {
  hand_x = 15,
  hand_y = 30,
  frameAmt = 12,
  width = 44,
  height = 46,
  dropWidth = 24,
  dropHeight = 44,
  damage = 15,
  special_damage = {water = 6},
  bbox_width = 18,
  bbox_height = 18,
  bbox_offset_x = {4,19,25},
  bbox_offset_y = {4,9,23},
  hitAudioClip = 'mace_hit',
  magical = true,
  animations = {
    default = {'once', {'1,1'}, 1},
    defaultCharged = {'loop', {'1-4,1', '3,1','2,1'}, 0.2},
    wield = {'once', {'1,1','5,1','9,1'},0.2},
    wieldCharged = {'once', {'3,1', '7,1','11,1'},0.2}
  },
  action = "wieldaction3",

  update = function(dt, player, map)


  end
}
