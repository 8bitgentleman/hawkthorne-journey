local Timer = require 'vendor/timer'

return {
  name = ducky,
  height = 48,
  width = 48,
  damage = 0,
  hp = 1000,
  speed = 20,
  jump_vel = 500,
  tokens = 0,
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
      left = {'once', {'11-13,1', '12,1', '11,1'}, .25},
      right = {'once', {'11-13,2', '12,2', '11,2'}, .25}
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
  },

  enter = function( enemy )
    enemy.last_jump = 0
    print(enemy.canJump)
  end,

  update = function ( dt, enemy, player )
    if enemy.position.x > player.position.x then
      enemy.direction = 'left'
    else
      enemy.direction = 'right'
    end
    if enemy.canJump then
      enemy.last_jump = enemy.last_jump + dt*math.random()
      if enemy.last_jump > 2 then
        print('jump')
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
    if math.abs(enemy.position.x - player.position.x) < 2 or enemy.state == 'dying' or enemy.state == 'hurt' then
      -- stay put
      enemy.velocity.x = 0
    else
      local direction = enemy.direction == 'left' and 1 or -1
      enemy.velocity.x =  direction * enemy.props.speed
    end
  end
}
