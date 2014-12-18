return {
  name = 'health',
  width = 13,
  height = 12,
  value = 10,
  frames = '1-2,1',
  speed = 0.3,
  rarity = 3,
  onPickup = function( player, value )
      player.health = math.min( player.health + value, player.max_health )
  end
}
