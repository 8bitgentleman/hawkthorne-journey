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
  frameAmt = 9,
  width = 44,
  height = 46,
  dropWidth = 24,
  dropHeight = 44,
  damage = 15,
  projectile = "waterSpout",
  throwDelay = 0.24,
  special_damage = {water = 6},
  bbox_width = 18,
  bbox_height = 18,
  bbox_offset_x = {4,19,25},
  bbox_offset_y = {4,9,23},
  hitAudioClip = 'mace_hit',
  magical = true,
  animations = {
    default = {'once', {'1,1'}, 1},
    defaultCharged = {'loop', {'2-7,1'}, 0.1},
    wield = {'once', {'1,1','5,1','9,1','5,1',},0.2},
    wieldCharged = {'once', {'1,1','5,1','9,1','5,1',},0.2}
  },
  action = "wieldaction3",
  actionwalk = "wieldaction3",
  actionjump = "wieldaction3",

  --[[update = function(dt, player, map)
        weapon.chargeUpTime = weapon.chargeUpTime + dt
        if weapon.chargeUpTime >= 3 then
          weapon.chargeUpTime = 0
          weapon.charged = true
          weapon.animation = weapon.defaultChargedAnimation
        end
      end]]

  wield = function( node )
    weapon.player.wielding = true
      --changes the animation is weapon is charged
    if weapon.animation then
      if weapon.charged then
        weapon.animation = weapon.wieldChargedAnimation
        weapon.charged = false
      else
        weapon.animation = weapon.wieldAnimation
      end
      weapon.animation:gotoFrame(1)
      weapon.animation:resume()
    end
    --changes the wield action between ranged and melee if the weapon is charged or not
    if weapon.charged then
      if weapon.player:isWalkState(weapon.player.character.state) then
        weapon.player.character.state = weapon.actionwalk
      elseif weapon.player:isJumpState(weapon.player.character.state) then
        weapon.player.character.state = weapon.actionjump
      else
        weapon.player.character.state = weapon.action
      end
      weapon.player.character:animation():gotoFrame(1)
      weapon.player.character:animation():resume()
    else
      weapon.collider:setSolid(weapon.bb)
      weapon.player.character.state = weapons.action
    end
    
    
    weapon.player.character:animation():gotoFrame(1)
    weapon.player.character:animation():resume()

    if weapon.charged then
      --weapon:throwProjectile()
    end

    if weapon.attackAudioClip then
      sound.playSfx( weapon.attackAudioClip )
    end
  end,

  throwProjectile = function( )
    if not weapon.player then return end
    local ammo = require('items/weapons/'..weapon.projectile)
    local currentWeapon = nil
    local page = nil
    local index = nil
    if not currentWeapon then
      currentWeapon, page, index = weapon.player.inventory:search(ammo)
    end
    if not currentWeapon then
      weapon.player.holdingAmmo = false
      weapon:deselect()
      weapon.player.doBasicAttack = true
      return
    end
    weapon.player.inventory.selectedWeaponIndex = index
    weapon.player.holdingAmmo = true

    Timer.add(weapon.throwDelay, function()
      currentWeapon:use(weapon.player, weapon)
      end)
  end,
}
