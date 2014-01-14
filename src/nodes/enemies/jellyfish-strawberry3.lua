local Timer = require 'vendor/timer'
local sound = require 'vendor/TEsound'

return {
    name = 'kungpaochicken',
    die_sound = 'acorn_crush',
    position_offset = { x = 0, y = 0 },
    height = 48,
    width = 48,
    damage = 15,
    antigravity = true,
    jumpkill = false,
    hp = 3,
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
            left = {'once', {'1,1'}, 0.25},
            right = {'once', {'1,1'}, 0.25}
        },
        swimming = {
            left = {'loop', {'1-4,1'}, 0.25},
            right = {'loop', {'1-4,1'}, 0.25}
        },
        attack = {
            right = {'loop', {'1-4,1'}, 0.25},
             left = {'loop', {'1-4,1'}, 0.25}
        },
        still = {
            left = {'loop', {'1,1'}, 0.25},
            right = {'loop', {'1,1'}, 0.25}
        }
    },
    enter = function( enemy )
        enemy.direction = math.random(2) == 1 and 'left' or 'right'
    end,
    update = function( dt, enemy, player, level )
        if enemy.deadthen then return end

        local direction = player.position.x > enemy.position.x and -1 or 1

        if enemy.position.y < player.position.y then
            enemy.velocity.y = 40 * direction
        elseif enemy.position.y > player.position.y then
            enemy.velocity.y = 40 * direction
        end
        
        if enemy.position.x < player.position.x then
            enemy.velocity.x = 40 * direction
        elseif enemy.position.y > player.position.x then
            enemy.velocity.x = 40 * -direction
        end
    end
}





