local TouchController = {}

TouchController.touches = {}

local cutoff = 100 -- 100 pixels TODO this should be set in new

function TouchController:new()

end

function TouchController:touchreleased(id, x, y)
  local touch = self.touches[id]
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
  else
      if math.abs(x - touch.start_x) > math.abs(y - touch.start_y) then
          if x - touch.start_x < 0 then return 'swipe_left'
          else return 'swipe_right'
          end
      else
          if y - touch.start_y < 0 then return 'swipe_up'
          else return 'swipe_down'
          end
      end
  end
end

function TouchController:touchpressed(id, x, y)
  self.touches[id] = {start_x = x, start_y = y, x = x, y = y,
                      dx = 0, dy = 0, swiped = false}
end

function TouchController:touchmoved(id, x, y)
  local touch = self.touches[id]
  local osx = touch.start_x
  local osy = touch.start_y

  self.touches[id].x = x
  self.touches[id].y = y
  self.touches[id].dx = x - touch.x
  self.touches[id].dy = y - touch.y

  if math.abs(x - touch.start_x) > math.abs(y - touch.start_y) then
      if math.abs(x - touch.start_x) > cutoff then
        self.touches[id].swiped = true
        self.touches[id].start_x = x
        self.touches[id].start_y = y
        if x - osx < 0 then return 'swipe_left'
        else return 'swipe_right'
        end
      end
  elseif math.abs(x - touch.start_x) < math.abs(y - touch.start_y) then
      if math.abs(y - touch.start_y) > cutoff then
        self.touches[id].swiped = true
        self.touches[id].start_x = x
        self.touches[id].start_y = y
        if y - osy < 0 then return 'swipe_up'
        else return 'swipe_down'
        end
      end
  end
end

return TouchController
