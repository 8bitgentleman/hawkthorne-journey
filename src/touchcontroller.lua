local TouchController = {}

TouchController.touches = {}

local cutoff = 100 -- 100 pixels TODO this should be set in new

function TouchController:new()

end

function TouchController:touchreleased(id, x, y)
  local touch = self.touches[id]
  self.touches[id] = nil
  if touch.swiped then return end

  if math.abs(x - touch.start_x) < cutoff and math.abs(y - touch.start_y) < cutoff then
    local right_quadrant = love.graphics.getWidth()-(love.graphics.getWidth()/3)
    local left_quadrant = love.graphics.getWidth()/3
    local upper_quadrant = love.graphics.getHeight()/2
  
    if x > right_quadrant and y > upper_quadrant then return 'tap_right' end
    if x < left_quadrant and y > upper_quadrant then return 'tap_left' end
    if x < right_quadrant and x > left_quadrant and y > upper_quadrant then print('interact') return 'tap_center_down' end
    if x < right_quadrant and x > left_quadrant and y < upper_quadrant then print('select') return 'tap_center_up' end
    if x < left_quadrant and y < upper_quadrant then print('start') return 'tap_left_up' end 
  end
end

function TouchController:touchpressed(id, x, y)
  self.touches[id] = {start_x = x, start_y = y, swiped = false}
end

function TouchController:touchmoved(id, x, y)
  local touch = self.touches[id]
  local osx = touch.start_x
  local osy = touch.start_y

  local swipe_direction = nil

  if math.abs(x - touch.start_x) > math.abs(y - touch.start_y) then
      if math.abs(x - touch.start_x) > cutoff then
        if x - osx < 0 then swipe_direction = 'swipe_left'
        else swipe_direction = 'swipe_right'
        end
      end
  elseif math.abs(x - touch.start_x) < math.abs(y - touch.start_y) then
      if math.abs(y - touch.start_y) > cutoff then
        if y - osy < 0 then swipe_direction = 'swipe_up'
        else swipe_direction = 'swipe_down'
        end
      end
  end

  if swipe_direction ~= nil then
    self.touches[id].swiped = true
    self.touches[id].direction = swipe_direction
    self.touches[id].start_x = x
    self.touches[id].start_y = y
    return swipe_direction
  end
end

function TouchController:getSwipe()
  for id, touch in pairs(self.touches) do
      if touch.swiped == true then
          return touch
      end
  end
  return nil
end

function TouchController:getTouch(id)
  return self.touches[id]
end

return TouchController
