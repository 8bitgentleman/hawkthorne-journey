local TouchController = {}

TouchController.touches = {}

local cutoff = 100 -- 100 pixels

function TouchController:new()

end

function TouchController:touchreleased(id, x, y)
  local touch = self.touches[id]

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
                      dx = 0, dy = 0}
end

function TouchController:touchmoved(id, x, y)
  local touch = self.touches[id]
  local odx = touch.dx
  local ody = touch.dy
  local dx = x - touch.x
  local dy = y - touch.y

  self.touches[id].x = x
  self.touches[id].y = y
  self.touches[id].dx = dx
  self.touches[id].dy = dy
end

return TouchController
