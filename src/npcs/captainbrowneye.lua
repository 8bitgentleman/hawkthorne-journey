-- inculdes

return {
  width = 45,
  height = 45,  
  greeting = 'Can you {{red_dark}}help{{white}} me? ', 
  noinventory = 'All I have is the clothes on me back.',
  --nocommands = '',
  stare = true,
  animations = {
    default = {
      'loop',{'1,1'},.5,
    },
  },

  talk_items = {
    { ['text']='i am done with you' },
    { ['text']='Where is your leg?' },
    { ['text']='Help!' },
    { ['text']='Who are you?' },
  },
  talk_responses = {
    ["Who are you?"]={
      "I'm the Captain Browneye.  I pilot the ferry between the Islands of Gay and the Black Caverns.",
    },
    ["Help!"]={
      "A massive snake has destroyed the docks and stole the keys to my ferry!",
      "Once that beast is out of the way I can take you to the Black Caverns if you like.",
    },
    ["Where is your leg?"]={
      "Arr Beware!",
      "I've been battle the beast for years but all I have to show for it is a missing leg!",
    },
  },
}