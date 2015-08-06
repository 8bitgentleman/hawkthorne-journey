-- inculdes

return {
  width = 32,
  height = 48,  
  animations = {
    default = {
      'loop',{'1,2'},.5,
    },
    walking = {
      'loop',{'1,2'},.2,
    },
  },

  noinventory = "(The monkey points forward eagerly.)",
  nocommands = "(The monkey blows a raspberry at you.)",

  stare = true,

  enter = function(npc, previous)
    local paintball = npc.db:get('paintball', true)
    if paintball == true then
      npc.state = 'hidden'
      npc.collider:setGhost(npc.bb)

      local Enemy = require 'nodes/enemy'
      local node = {
        x = npc.position.x,
        y = npc.position.y,
        type = 'enemy',
        properties = {
            enemytype = 'paintball',
            sheet = 'paintball_todd',
            npc = 'todd',
            generic = true,
            canJump = true
          }
      }
      local tp = Enemy.new(node, npc.collider, Enemy.type)
      npc.containerLevel:addNode(tp)
      --perhaps the NPC should be removed here as well to 'clean up' the level
    end
  end,

  talk_items = {
    { ['text']='i am done with you' },
    { ['text']='Who is a good monkey?' },
    { ['text']='Did you see a purple pen?' },
    { ['text']='Hello!' },
  },

  talk_responses ={
    ['Hello!']={
      "Ook, ook, eek!",
    },
    ['Who is a good monkey?']={
      "SCREE!!!",
    },
    ['Did you see a purple pen?']={
      "(The monkey is more interested in the spoon than talking to you.)"
    },
  },
}