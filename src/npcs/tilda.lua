-- inculdes

return {
    width = 32,
    height = 48,   
    animations = {
        default = {
            'loop',{'1,1','11,1'},.5,
        },
        walking = {
            'loop',{'1,1','2,1','3,1'},.2,
        },

    },

    walking = true,

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