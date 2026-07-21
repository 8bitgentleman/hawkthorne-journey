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

-- The bursar sells "improvements": campus upgrades that aren't inventory items.
-- Buying one records a save flag (itemInfo[4]) that the world reads, rather
-- than adding anything to the player's inventory. These tests drive
-- buy/sellSelectedItem directly with a stubbed save (self.db).

-- Build an improvements-mode context without init()/enter().
local function setupImprovements(money)
  state.improvements = true
  state.window = "purchaseWindow"
  state.buyAmount = 1
  state.sellAmount = 1
  state.itemSelection = 1
  state.tooltip = { shut = function() end }
  state.player = { money = money, inventory = { count = function() return 0 end } }
  state.flags = {}
  state.db = { set = function(_, key, value) state.flags[key] = value end }
end

-- it should set the improvement's save flag and deduct money on purchase
function test_buying_improvement_sets_flag_and_deducts_money()
  setupImprovements(5000)
  -- {name, stock, cost, save-flag}
  state.items = { { "mascot", 1, 1000, "mascot" } }
  state:buySelectedItem()
  assert_true(state.flags["mascot"], "buying should record the improvement's save flag")
  assert_equal(4000, state.player.money, "money should drop by the cost")
  assert_equal(0, state.items[1][2], "stock should decrement")
  assert_equal("messageWindow", state.window, "should land on the message window")
  state.improvements = false
end

-- it should not buy an improvement the player can't afford
function test_buying_improvement_requires_money()
  setupImprovements(500)
  state.items = { { "airplane", 1, 100000, "greendale-airplane" } }
  state:buySelectedItem()
  assert_nil(state.flags["greendale-airplane"], "must not set the flag when too poor")
  assert_equal(500, state.player.money, "money must be unchanged on a failed purchase")
  assert_equal("messageWindow", state.window)
  state.improvements = false
end

-- it should refuse to sell improvements (the player never owns them)
function test_selling_improvement_is_blocked()
  setupImprovements(5000)
  state:sellSelectedItem()
  assert_equal("messageWindow", state.window)
  assert_equal("You can't sell something you don't own.", state.message)
  state.improvements = false
end
