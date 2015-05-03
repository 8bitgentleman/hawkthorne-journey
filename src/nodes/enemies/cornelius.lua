local Enemy = require 'nodes/enemy'
local gamestate = require 'vendor/gamestate'
local sound = require 'vendor/TEsound'
local Timer = require 'vendor/timer'
local Fireball = require 'nodes/fire_cornelius_big'
local utils = require 'utils'
local Dialog = require 'dialog'
local anim8 = require 'vendor/anim8'

local window = require 'window'
local camera = require 'camera'
local fonts = require 'fonts'

return {
  name = 'cornelius',
  attackDelay = 1,
  height = 192,
  width = 144,
  damage = 30,
  --attack_bb = true,
  jumpkill = false,
  knockback = 0,
  player_rebound = 400,
  antigravity = true,
  bb_width = 124,
  bb_height = 182,
  bb_offset = { x = 0, y = -5},
  attack_width = 40,
  velocity = {x = 0, y = 10},
  hp = 20,
  tokens = 100,
  dyingdelay = 2,
  fadeIn = true,
  --[[enterScript ={
          "{{grey}}Welcome{{white}}, you are the first to make it to the {{orange}}Throne of Hawkthorne{{white}}.",
          "Let me take a look at you...",
          "According to your {{olive}}complexion{{white}}, I think you might be... {{purple}}Abed{{white}}.",
        }, ]]
  deathScript ={
  		"{{grey}}*heavy breathing*{{white}} I suppose you're wondering,{{purple}} player{{white}}. ",
  		"Why record myself breathing weird and letting you destroy me?",
			"Because I am a man of {{red}}Honor!{{white}}",
			"So you've earned the pleasure of my death!",
  },
 
  tokenTypes = { -- p is probability ceiling and this list should be sorted by it, with the last being 1
    { item = 'coin', v = 1, p = 0.9 },
    { item = 'health', v = 1, p = 1 }
  },
  animations = {
     default = {
      right = {'loop', {'1,1'}, 0.25},
      left = {'loop', {'1,1'}, 0.25}
    },
    talking = {
      right = {'loop', {'1-3,1','2,1'}, 0.15},
      left = {'loop', {'1-3,1','2,1'}, 0.15}
    },
    attack = {
      right = {'loop', {'1-3,3','2,3'}, 0.1},
      left = {'loop', {'1-3,3','2,3'}, 0.1}
    },
    hurt = {
      right = {'loop', {'1-3,3','2,3'}, 0.1},
      left = {'loop', {'1-3,3','2,3'}, 0.1}
    },
    dying = {
      right = {'loop', {'1-3,1','2,1'}, 0.15},
      left = {'loop', {'1-3,1','2,1'}, 0.15}
    },
    enter = {
      right = {'once', {'1,1'}, 0.2},
      left = {'once', {'1,1'}, 0.2}
    },
    teleport = {
      right = {'loop', {'1-3,4','2,4'}, 0.1},
      left = {'loop', {'1-3,4','2,4'}, 0.1}
    },
  },

  enter = function( enemy )
    enemy.direction = math.random(2) == 1 and 'left' or 'right'
    enemy.directionY = math.random(2) == 1 and 'up' or 'down'
    --enemy.state = 'attack'
    enemy.dropmax = enemy.position.y + 5--336
    enemy.hatched = false
    enemy.last_teleport = 0
    enemy.last_attack = 0
    enemy.last_fireball = 0 
    enemy.swoop_speed = 150
    enemy.fly_speed = 75
    enemy.swoop_distance = 150
    enemy.swoop_ratio = 0.25
    sound.playMusic("cornelius-attacks")
    --player.cheatsEnabled = false

		if enemy.enterScript then
	    Dialog.new(enemy.enterScript, function() enemy.state = 'attack'
	      end, nil, 'small')
	  end
     
  end,

  fireball = function( enemy, player )
    enemy.last_fireball = 0 
    enemy.last_attack = 0
    local Fireball = require('nodes/fire_cornelius_big')
    local node = {
          type = 'fire_cornelius_big',
          name = 'fireball',
          x = player.position.x,
          y = enemy.position.y,
          width = 34,
          height = 110,
          properties = {}
        }
        local fireball = Fireball.new( node, enemy.collider )
        local level = enemy.containerLevel
        level:addNode(fireball)
  end,

  teleport = function ( enemy, player, dt )
    enemy.state = 'teleport'
    enemy.last_teleport = 0 
    enemy.last_attack = 0
    sound.playSfx("teleport")
    Timer.add(.5, function()  
      if enemy.position.x >= player.position.x then
        
        enemy.position.x = player.position.x - (math.abs((enemy.position.x+(enemy.width/2))-player.position.x))
        enemy.state = 'attack'
      elseif enemy.position.x <= player.position.x then
        enemy.position.x = player.position.x - (math.abs((enemy.position.x+(enemy.width/2))-player.position.x))
        enemy.state = 'attack'
      end
    end)  
  end,

  -- adjusts values needed to initialize swooping
  targetDive = function ( enemy, player, direction )
    enemy.fly_dir = direction
    enemy.launch_y = enemy.position.y
    local p_x = player.position.x - player.character.bbox.x
    local p_y = player.position.y - player.character.bbox.y
    enemy.swoop_distance = math.abs(p_y - enemy.position.y)
    enemy.swoop_ratio = math.abs(p_x - enemy.position.x) / enemy.swoop_distance
    -- experimentally determined max and min swoop_ratio values
    enemy.swoop_ratio = math.min(1.4, math.max(0.7, enemy.swoop_ratio))
  end,

  startDive = function ( enemy )
  enemy.last_attack = 0
  enemy.last_teleport = 0
    enemy.velocity.y = enemy.swoop_speed
  -- swoop ratio used to center bat on target
    enemy.velocity.x = -( enemy.swoop_speed * enemy.swoop_ratio ) * enemy.fly_dir
    Timer.add(.5, function()  
      enemy.velocity.y = -enemy.fly_speed
      enemy.velocity.x = -(enemy.swoop_speed / 1.5) * enemy.fly_dir
      print('undive')
    
    end)

  end,

  -- Compares vulnerabilities to a weapons special damage and sums up total damage
  calculateDamage = function(self, damage, special_damage)
    if not special_damage then
      if self.state =='teleport' then
        print('double damage')
        damage = 2*damage
        return damage
      else
        print('regular damage')
        return damage
      end
    end
    for _, value in ipairs(self.vulnerabilities) do
      if special_damage[value] ~= nil then
        if enemy.state =='teleport' then
          damage = (damage + special_damage[value])*2
          print('double damage')
        else
          damage = damage + special_damage[value]
          print('regular damage')
        end
      end
    end

    return damage
  end,

  die = function( enemy )
    sound.playMusic("cornelius-forfeiting")
    Dialog.new(enemy.deathScript, function()
      enemy:die()
      sound.playSfx("cornelius-ending")
      sound.stopMusic()

      local NodeClass = require('nodes/key')
      local node = {
        type = 'key',
        name = 'greendale',
        x = enemy.position.x + enemy.width / 2 ,
        y = enemy.position.y + enemy.height+48,
        width = 24,
        height = 24,
        properties = {info = "Congratulations. You have found the {{green_dark}}Greendale{{white}} key. If you want more to explore, you now have access to the {{green_dark}}Greendale{{white}} campus!",
                              'To get there, exit the study room then use the door to the left. Remember to bring the key!',
        },
      }
      local spawnedNode = NodeClass.new(node, enemy.collider)
      local level = gamestate.currentState()
      level:addNode(spawnedNode)

      end, nil, 'small')

  end,

  draw = function( enemy )
    fonts.set( 'small' )

    --love.graphics.setStencil( )

    local energy = love.graphics.newImage('images/enemies/bossHud/energy.png')
    local bossChevron = love.graphics.newImage('images/enemies/bossHud/bossChevron.png')
    local bossPic = love.graphics.newImage('images/enemies/bossHud/cornelius.png')

    energy:setFilter('nearest', 'nearest')
    bossChevron:setFilter('nearest', 'nearest')
    bossPic:setFilter('nearest', 'nearest')


    x, y = camera.x + window.width - 130 , camera.y + 10
--[[
    --draw HUD sprites
    love.graphics.setColor( 255, 255, 255, 255 )
    love.graphics.draw( bossChevron, x , y )
    love.graphics.draw( bossPic, x + 69, y + 10 )
    --print HUD text
    love.graphics.setColor( 0, 0, 0, 255 )
    love.graphics.printf( "QFO", x + 15, y + 15, 52, 'center' )
    love.graphics.printf( "BOSS", x + 15, y + 41, 52, 'center' )

    --create energy bar using stencils
    energy_stencil = function( x, y )
      love.graphics.rectangle( 'fill', x + 11, y + 27, 59, 9 )
    end
    love.graphics.setStencil(energy_stencil, x, y)
    local max_hp = 50
    local rate = 55/max_hp
    love.graphics.setColor(
      math.min(utils.map(enemy.hp, max_hp, max_hp / 2 + 1, 0, 255 ), 255), -- green to yellow
      math.min(utils.map(enemy.hp, max_hp / 2, 0, 255, 0), 255), -- yellow to red
      0,
      255
    )
    love.graphics.draw(energy, x + ( max_hp - enemy.hp ) * rate, y)

    love.graphics.setStencil( )
    love.graphics.setColor( 255, 255, 255, 255 )
    fonts.revert()]]
  end,

  update = function( dt, enemy, player, level )
    if enemy.dead then return end
    print(enemy.state)
    local direction = player.position.x > enemy.position.x + 70 and -1 or 1
    local offset = math.random(0,200)
    --print(direction)

    if enemy.state == 'default' and not enemy.hatched then
      enemy.hatched = true
      enemy.state = 'attack'
    elseif enemy.hatched then
        if enemy.position.y < enemy.dropmax then enemy.velocity.y = 0 end
      	enemy.rage = true
      	enemy.glow = true
      	enemy.lightning = true
      	--enemy.props.fire(enemy)
        enemy.last_teleport = enemy.last_teleport + dt
        enemy.last_attack = enemy.last_attack + dt
        enemy.last_fireball = enemy.last_fireball + dt 
        enemy.props.targetDive( enemy, player, -direction )
        
        if enemy.last_attack > 2 and enemy.last_teleport > 3 then
          --enemy.props.fireball( enemy, player )
          enemy.props.teleport( enemy, player, dt )
          --enemy.props.startDive ( enemy )
        end
      
    end

  	--[[if enemy.position.y < enemy.miny then
  	  	  		enemy.velocity.y = -enemy.velocity.y
  	  	  	elseif enemy.position.y > enemy.maxy then
  	  	  		enemy.velocity.y = -enemy.velocity.y
  	  	  	end    
   
    if not enemy.hatched then
            enemy.state = 'enter'
          elseif not enemy.hatched and enemy.position.y >= enemy.dropmax then
            enemy.hatched = true
            enemy.velocity.y = 0
            --Timer.add(2, function() enemy.hatched = true end)
          elseif enemy.hatched then
            --move the qfo up and down ( roughly a figure 8 )
            if enemy.position.x > enemy.maxx then
              enemy.direction = 'left'
            elseif enemy.position.x < enemy.minx then
                enemy.direction = 'right'
            end
            if enemy.position.y > enemy.maxy then
                enemy.directiony = 'down'
              elseif enemy.position.y < enemy.miny then
                enemy.directiony = 'up'
            end
      
            if enemy.direction == 'left' then
              enemy.velocity.x = 50
            else
              enemy.velocity.x = -50 
            end
            
            if enemy.directiony == 'up' then
              enemy.velocity.y = 15
            else
              enemy.velocity.y = -15 
            end
      
            --deal with enemy attacks
            enemy.last_attack = enemy.last_attack + dt
      
            local pause = 4
          
            if enemy.hp < 20 then
              pause = 0.7
            elseif enemy.hp < 50 then
              pause = 1
            end
              
      
            if enemy.last_attack > pause then
              
              enemy.last_attack = -0
            end
            if enemy.hatched then
              enemy.state = 'default'
            end
      
      
          end]]

  end
}