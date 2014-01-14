local Timer = require 'vendor/timer'
local sound = require 'vendor/TEsound'

return {
    name = 'kungpaochicken',
    die_sound = 'acorn_crush',
    position_offset = { x = 0, y = 0 },
    height = 48,
    width = 24,
    damage = 15,
    antigravity = true,
    jumpkill = false,
    hp = 10,
    tokens = 5,
    tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
        { item = 'coin', v = 1, p = 0.9 },
        { item = 'health', v = 1, p = 1 }
    },
    animations = {
        dying = {
            right = {'once', {'5,1'}, 0.25},
            left = {'once', {'5,1'}, 0.25}
        },
        default = {
            right = {'loop', {'1-4,1'}, 0.25},
            left = {'loop', {'1-4,1'}, 0.25}
        },
        hurt = {
          right = {'loop', {'5,1'}, 0.25},
             left = {'loop', {'5,1'}, 0.25}
         },
        enter = {
            left = {'once', {'1,2'}, 0.25},
            right = {'once', {'1,3'}, 0.25}
        },
        swimming = {
            left = {'loop', {'1-4,2'}, 0.25},
            right = {'loop', {'1-4,3'}, 0.25}
        },
        attack = {
            right = {'loop', {'1-4,2'}, 0.25},
             left = {'loop', {'1-4,3'}, 0.25}
        },
        still = {
            left = {'loop', {'1-4,1'}, 0.25},
            right = {'loop', {'1-4,1'}, 0.25}
        }
    },
    enter = function( enemy )
        enemy.direction = math.random(2) == 1 and 'left' or 'right'
    end,
    update = function( dt, enemy, player, level )
        if enemy.deadthen then return end
        
        local direction = player.position.x > enemy.position.x and -1 or 1

        if enemy.velocity.y > 1 then
            enemy.state = 'swimming'
            enemy.jumpkill = false
            enemy.velocity.y = math.random()
        elseif math.abs(enemy.velocity.y) < 1 then
            enemy.state = 'default'
            enemy.jumpkill = true
            enemy.velocity.y = 0
            if enemy.state ~= 'still' then
                enemy.velocity.x = 40 * direction
            end
        end
     
        if enemy.position.x - player.position.x < 2 then
            enemy.direction = 'right'
        else
            enemy.direction = 'left'
        end
        if math.abs(enemy.position.x - player.position.x) < 2 then
            enemy.state = 'still'
            enemy.last_jump = enemy.last_jump + dt
            if enemy.last_jump > 0.5 then
                enemy.state = 'swimming'
                enemy.jumpkill = false
                enemy.last_jump = math.random()
                enemy.velocity.y = -48
                enemy.drop = true
            end
        end
    end
}
