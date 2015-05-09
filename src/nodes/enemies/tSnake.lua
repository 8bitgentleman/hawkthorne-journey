local Enemy = require 'nodes/enemy'
local gamestate = require 'vendor/gamestate'
local sound = require 'vendor/TEsound'
local Timer = require 'vendor/timer'
local Projectile = require 'nodes/projectile'
local sound = require 'vendor/TEsound'
local utils = require 'utils'

local window = require 'window'
local camera = require 'camera'
local fonts = require 'fonts'

return {
  name = 'tSnake',
  die_sound = 'snake_hurt',
  attackDelay = 1,
  height = 144,
  width = 48,
  bb_width = 30,
  bb_height = 144,
  damage = 40,
  --special_damage = {tsnake = 40},
  attack_bb = true,
  jumpkill = false,
  antigravity = true,
  knockback = 0,
  player_rebound = 200,
  attack_width = 10,
  --attack_offset = { x = -40, y = 10},
  velocity = {x = 0, y = -1},
  hp = 70,
  tokens = 15,
  hand_x = -40,
  hand_y = 69,
  dyingdelay = 2,
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },

  animations = {
    default = {
      right = {'loop', {'1-4,2',}, 0.15},
      left = {'loop', {'1-4,1',}, 0.15}
    },
    attack = {
      right = {'once', {'5-7,2'}, 0.15},
      left = {'once', {'5-7,1'}, 0.15}
    },
    dying = {
      right = {'once', {'9-14,2'}, 0.1},
      left = {'once', {'9-14,1'}, 0.1}
    },
    enter = {
      right = {'once', {'1,2'}, 0.25},
      left = {'once', {'1,1'}, 0.25}
    },
    hurt = {
      right = {'once', {'8,2'}, 0.25},
      left = {'once', {'8,1'}, 0.25}
    },
  },

  enter = function( enemy )
    enemy.direction = math.random(2) == 1 and 'left' or 'right'
    enemy.state = 'enter'
    enemy.original_pos =  {
      x = enemy.position.x,
      y = enemy.position.y
    }
    enemy.maxx = enemy.position.x + 24
    enemy.minx = enemy.position.x - 24
    enemy.diving = false
    enemy.hideTime = 0
    enemy.hidden = false
  end,

  die = function( enemy, player )
    local Player = require 'player'
    local player = Player.factory()
    local NodeClass = require('nodes/key')
    local node = {
      type = 'key',
      name = 'ferry',
      x = player.position.x+48,--2592,
      y = player.position.y+24,--742,
      width = 24,
      height = 24,
      properties = {},
    }
    local spawnedNode = NodeClass.new(node, enemy.collider)
    local level = gamestate.currentState()
    level:addNode(spawnedNode)
  end,

  draw = function( enemy )
    fonts.set( 'small' )

    love.graphics.setStencil( )

    local energy = love.graphics.newImage('images/enemies/bossHud/energy.png')
    local bossChevron = love.graphics.newImage('images/enemies/bossHud/bossChevron.png')
    local bossPic = love.graphics.newImage('images/enemies/bossHud/snakeBoss.png')


    energy:setFilter('nearest', 'nearest')
    bossChevron:setFilter('nearest', 'nearest')
    bossPic:setFilter('nearest', 'nearest')

    x, y = camera.x + window.width - 130 , camera.y + 10

    love.graphics.setColor( 255, 255, 255, 255 )
    love.graphics.draw( bossChevron, x , y )
    love.graphics.draw( bossPic, x + 69, y + 10 )

    love.graphics.setColor( 0, 0, 0, 255 )
    love.graphics.printf( "Trouser Snake", x + 10, y + 15, 100, 'left' , 0, .8, .8)
    love.graphics.printf( "BOSS", x + 15, y + 41, 52, 'center' )


    energy_stencil = function( x, y )
      love.graphics.rectangle( 'fill', x + 11, y + 27, 59, 9 )
    end
    love.graphics.setStencil(energy_stencil, x, y)
    local max_hp = 70
    local rate = 60/max_hp
    love.graphics.setColor(
      math.min(utils.map(enemy.hp, max_hp, max_hp / 2 + 1, 0, 255 ), 255), -- green to yellow
      math.min(utils.map(enemy.hp, max_hp / 2, 0, 255, 0), 255), -- yellow to red
      0,
      255
    )
    love.graphics.draw(energy, x + ( max_hp - enemy.hp ) * rate, y)

    love.graphics.setStencil( )
    love.graphics.setColor( 255, 255, 255, 255 )
    fonts.revert()
  end,

  attackRainbow = function( enemy, player, direction )
  	local Player = require 'player'
  	local player = Player.factory()
  	local node = {
      type = 'projectile',
      name = 'rainbowbeam_tsnake',
      x = enemy.position.x+enemy.attack_offset.x,
      y = enemy.position.y,
      width = 24,
      height = 24,
      properties = { }--velocity = (player.position.x - enemy.position.x), (player.position.y - enemy.position.y) }
    }
    
    local rainbowbeam = Projectile.new( node, enemy.collider )
    rainbowbeam.enemyCanPickUp = true
    local level = enemy.containerLevel
    level:addNode(rainbowbeam)
    --if enemy.currently_held then enemy.currently_held:throw(enemy) end
    rainbowbeam.velocity.x = math.random(10,100)--*direction
    Projectile.velocity = {10,200}--player.position.y--math.random(200,400)
    enemy:registerHoldable(rainbowbeam)
    enemy:pickup()
    enemy.currently_held:launch(enemy)
    --disallow any manicorn from picking it up after thrown
    rainbowbeam.enemyCanPickUp = false
  end,

  dive = function(enemy, dt)
    enemy.velocity.y = 200
    enemy.velocity.y = 200
    enemy.hideTime = math.random(.8,2)
    Timer.add(enemy.hideTime, function()
        enemy.state = 'default'
        enemy.velocity.y = 0
        enemy.props.positionChange(enemy)
   end)
  end,

  rise = function(enemy, dt)
    enemy.velocity.y = -200

    Timer.add(enemy.hideTime, function()
        enemy.velocity.y = 0
        enemy.diving = false
        enemy.last_jump = 0
    end)
  end,


  positionChange = function(enemy)
    local randOffest = math.random(-12,25)
    local position2 = enemy.original_pos.x + (144+randOffest)
    local position3 = enemy.original_pos.x + (288+randOffest)
    local positionChoice = math.random(1,3)

    if positionChoice == 1 then
      enemy.position.x = enemy.original_pos.x
    elseif positionChoice ==2 then
      enemy.position.x = position2
    elseif positionChoice == 3 then
      enemy.position.x = position3
    end
    enemy.props.rise(enemy, dt)
  end,

  update = function( dt, enemy, player, level )
    if enemy.dying then enemy.state = 'dying' end

    local direction = player.position.x > enemy.position.x + 40 and -1 or 1
    if enemy.position.y > player.position.y+24 then
      enemy.hidden = true
    else 
      enemy.hidden = false
    end

    if player.position.x > enemy.position.x + 24 then
      enemy.direction = 'right'
    else 
      enemy.direction = 'left'
    end


    enemy.last_jump = enemy.last_jump + dt
    
    local move_time = 2
    if enemy.last_jump >= move_time and not enemy.diving then
      enemy.diving = true
      enemy.props.dive(enemy, dt)
    end




    enemy.last_attack = enemy.last_attack + dt
    local pause = 2
    
    if enemy.hp < 20 then
        pause = 1
    elseif enemy.hp < 50 then
        pause = 1.5
    end
        
    if enemy.last_attack > pause and not enemy.hidden then
        local rand = math.random()
        enemy.state = 'attack'
        enemy.props.attackRainbow(enemy)
        enemy.last_attack = 0
        Timer.add(.5, function()
            enemy.state = 'default'
       end)
    end


  end
}