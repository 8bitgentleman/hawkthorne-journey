-----------------------------------------------
-- throwingKnifeItem.lua
-- The code for the bomb, when it is in the players inventory.
-----------------------------------------------
local Projectile = require 'nodes/projectile'
local GS = require 'vendor/gamestate'
return{
  name = "bomb_throwable",
  description = "Bomb",
  type = "weapon",
  subtype = "projectile",
  damage = '2',
  special_damage = 'fire= 4',
  info = 'a set of 5 bombs',
  MAX_ITEMS = 99,
  quantity = 5,
  directory = 'weapons/',
}