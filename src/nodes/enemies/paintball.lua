local Timer = require 'vendor/timer'
local Projectile = require 'nodes/projectile'
local NPC = require 'nodes/npc'

return {
  name = ducky,
  height = 48,
  width = 48,
  damage = 0,
  hp = 1000,
  speed = 20,
  jump_vel = 500,
  tokens = 0,
  vulnerabilities = {'paint'},
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },

  animations = {
    enter = {
      left = {'once', {'1-4,1'}, 0.25},
      right = {'once', {'1-4,2'}, 0.25}
    },
    default = {
      left = {'loop', {'7-9,1'}, 0.2},
      right = {'loop', {'7-9,2'}, 0.2}
    },
    jump = { 
      left = {'loop', {'11-13,1', '12,1', '11,1'}, .25},
      right = {'loop', {'11-13,2', '12,2', '11,2'}, .25}
    },
    attack = {
      left = {'loop', {'7-9,1'}, 0.2},
      right = {'loop', {'7-9,2'}, 0.2}
    },
    hurt = {
      left = {'loop', {'5,1'}, 0.4},
      right = {'loop', {'5,2'}, 0.4}
    },
    dying = {
      left = {'loop', {'5,1'}, 0.4},
      right = {'loop', {'5,2'}, 0.4}
    },
    waiting = {
      left = {'loop', {'1,1'}, 0.4},
      right = {'loop', {'1,2'}, 0.4}
    },
  },

  enter = function( enemy )
    enemy.last_jump = 0
    enemy.last_shot = 0
    enemy.frequency = math.random(1, 4)
    enemy.pause = false
    end,

  shoot_paintball = function( enemy, direction )
    enemy.last_shot = 0
    local node = {
      type = 'projectile',
      name = 'paintball_ammo',
      x = enemy.position.x - 120,
      y = enemy.position.y,
      width = 6,
      height = 6,
      properties = { generic = 'red', holderSave = enemy }
    }
    local paintball = Projectile.new( node, enemy.collider )
    paintball.enemyCanPickUp = true
    local level = enemy.containerLevel
    level:addNode(paintball)
    enemy:registerHoldable(paintball)
    enemy:pickup()
    enemy.currently_held:launch(enemy)
    --disallow anything from picking it up after thrown
    paintball.enemyCanPickUp = false

  end,

  die = function( enemy )
     local node = {
      type = 'npc',
      name = enemy.npc,
      x = enemy.position.x ,
      y = enemy.position.y,
      width = enemy.width,
      height = enemy.height,
      properties = { }
    }
    local npc = NPC.new( node, enemy.collider )
    local level = enemy.containerLevel
    level:addNode(npc)
  end,

  update = function ( dt, enemy, player )
    print(enemy.npc)
    if enemy.position.x > player.position.x then

      enemy.direction = 'left'
    else
      enemy.direction = 'right'
    end
    
    if enemy.canJump then
      enemy.last_jump = enemy.last_jump + dt*math.random()
      if enemy.last_jump > 2 and not enemy.pause then
        enemy.state = 'jump'
        enemy.jumpkill = false
        enemy.last_jump = 0
        enemy.velocity.y = -enemy.props.jump_vel
        Timer.add(.5, function()
          enemy.state = 'default'
          enemy.jumpkill = true
        end)
      end
    end
    --do not move enemy when jumping
    if math.abs(enemy.position.x - player.position.x) < 2 or enemy.state == 'dying' or enemy.state == 'hurt' then
      -- stay put
      enemy.velocity.x = 0
      enemy.state = 'waiting'
      enemy.pause = true
      enemy.last_shot =0
    else
      if enemy.state == 'waiting' then enemy.state = 'attack' end

      enemy.pause = false
      local direction = enemy.direction == 'left' and 1 or -1
      enemy.velocity.x =  direction * enemy.props.speed
    end
    --shoot paintball when not jumping
    enemy.last_shot = enemy.last_shot + dt

    if enemy.state ~= 'jump' then
      if enemy.last_shot > enemy.frequency and not enemy.pause then 
        local direction = enemy.direction == 'left' and 1 or -1
        enemy.props.shoot_paintball(enemy, direction) 
      end
    end
  end
}
