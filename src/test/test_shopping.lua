-- Regression tests for issue #2608: "Unable to exit blacksmith inventory menu".
-- The shop advertises "PRESS <ATTACK> TO GO BACK" on every window and ATTACK
-- already backs out of the items and purchase windows, but the top-level
-- categories window used to ignore ATTACK, leaving the menu soft-locked (the
-- only exit was START/Escape, which the UI never surfaces).

-- Stub the shared, cached modules BEFORE requiring shopping so the module under
-- test resolves to the same tables (Lua caches `require`d modules).
local Gamestate = require 'vendor/gamestate'
local sound = require 'vendor/TEsound'

local switched -- captures the target passed to Gamestate.switch
Gamestate.switch = function(target) switched = target end
sound.playSfx = function() end

local state = require 'shopping'

-- Build a minimal categories-window context without running init()/enter()
-- (those need love.graphics and a real supplier).
local function setup()
  switched = nil
  state.window = "categoriesWindow"
  state.previous = "the_level" -- sentinel for the screen we should return to
  state.categories = {"weapons", "materials", "consumables"}
  state.supplier = {} -- empty: no category has stock, so JUMP is a no-op
  state.categorySelection = 1
  state.categoriesWindowLeft = 1
  state.buyAmount = 5
  state.sellAmount = 7
end

-- it should exit the shop when ATTACK is pressed on the categories window
function test_attack_exits_categories_window()
  setup()
  state:keypressed("ATTACK")
  assert_equal("the_level", switched, "ATTACK should switch back to the previous screen")
  assert_equal(1, state.buyAmount, "buyAmount should reset on exit")
  assert_equal(1, state.sellAmount, "sellAmount should reset on exit")
end

-- it should still exit the shop when START is pressed (pre-existing behaviour)
function test_start_exits_categories_window()
  setup()
  state:keypressed("START")
  assert_equal("the_level", switched, "START should switch back to the previous screen")
  assert_equal(1, state.buyAmount, "buyAmount should reset on exit")
  assert_equal(1, state.sellAmount, "sellAmount should reset on exit")
end

-- it should NOT exit the shop when a navigation key is pressed
function test_navigation_does_not_exit_categories_window()
  setup()
  state:keypressed("RIGHT")
  assert_nil(switched, "RIGHT should not exit the shop")
  assert_equal("categoriesWindow", state.window, "RIGHT should keep the categories window open")
end
