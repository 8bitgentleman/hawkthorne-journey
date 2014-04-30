-- inculdes


return {
    width = 48,
    height = 48, 
    maxx = 48,
    min = 0,  
    animations = {
        default = {
            'loop',{'1,1'},.5,
        },
        wolf = {
            'loop',{'8,1'},.5,
        },
        walking = {
            'loop',{'8,1','9,1'},.2,
        },
        woman_walking = {
            'loop',{'1,1','2,1','3,1'},.2,
        },
        wolf_attack = {
            'loop',{'7,1','10,1'},.2,
        },
        wolf_hurt = {
            'once',{'8,1'},.2,
        },
        wolf_die = {
            'loop',{'11,1'},.2,
        },
        wolf_transform = {
            'once',{'5,1','6,1'},.2,
        },
    },

    walking = true,
    walk_speed = 36,
    state = wolf_walking,
    
    enter = function(npc, previous)
    	npc.state = 'wolf'
    end,


    talk_items = {
    { ['text']='i am done with you' },
    { ['text']='i will wear your skin' },
    { ['text']='madam, i am on a quest', ['option']={
        { ['text']='more...', ['option']={
        }},
        { ['text']='i am done with you' },
        { ['text']='throne of hawkthorne' },
        { ['text']='for your hand' },
    }},
    { ['text']='stand aside' },
    },


    collide = function(npc, node, dt, mtv_x, mtv_y)
        if npc.state == 'wolf_hurt' and node.hurt then
            -- 5 is minimum player damage
            node:hurt(5)
        end
    end,
    
 	update = function(dt, npc, player)
 	    if npc.state== 'wolf' or npc.state == 'walking' then
            npc.busy = true
            return
        end
    end,

    hurt = function(npc, player)
    	if player.position >= npc.minx and player.position <= npc.maxx then
    			npc.state = 'wolf_attack'
    	else
    	end

    end,


    talk_responses = {
    ['madam, i am on a quest']={
        "I can help with that",
        "I have information on many topics...",
    },
	['i will wear your skin']={
        "My skin is my own.",
    },
		['stand aside']={
        "Fine!  Go then! Just like everyone else!",
    },
    ['throne of hawkthorne']={
        "The throne is in Castle Hawkthorne, north of here.",
    "You unlock the castle with the white crystal of discipline, which you must free from the black caverns.",
    },
	
    },
    tickImage = love.graphics.newImage('images/npc/hilda_heart.png'),

}