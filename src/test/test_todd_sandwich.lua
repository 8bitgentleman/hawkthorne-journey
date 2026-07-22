-- Regression tests for the Shirley's-Sandwiches NPC (todd-sandwich), ported from
-- upstream PR #2530. The tester report on that PR described "an endless loop of
-- Shirley dialogue" and "not being able to get away" — i.e. the prompt/menu never
-- released the player. These tests drive the real Prompt/Dialog singletons through
-- todd's begin() flow and assert it always settles: the prompt clears (no re-prompt),
-- the menu closes, and the player unfreezes on every branch.

local Prompt = require 'prompt'
local Dialog = require 'dialog'
local sound = require 'vendor/TEsound'
local todd = require 'npcs/todd-sandwich'

-- Board/Prompt play sfx on open/close; silence them (see test_shopping.lua).
local realPlaySfx = sound.playSfx

-- A menu stub that records the close() the NPC logic is supposed to call. It mirrors
-- the real Menu:close contract (unfreeze the player) without pulling in animations.
local function fakeMenu()
  return {
    state = 'closed',
    closeCount = 0,
    close = function(self, player)
      self.closeCount = self.closeCount + 1
      self.state = 'closing'
      player.freeze = false
    end,
  }
end

-- A save stub (npc.db) backed by a plain table so tests never touch real save data.
local function fakeDb(initial)
  local flags = {}
  for k, v in pairs(initial or {}) do flags[k] = v end
  return {
    get = function(self, key, default)
      local v = flags[key]
      if v == nil then return default end
      return v
    end,
    set = function(self, key, value) flags[key] = value end,
    flags = flags,
  }
end

local function fakeNpc(curtainFlag)
  return {
    menu = fakeMenu(),
    db = fakeDb({ ['sandwich-curtain'] = curtainFlag }),
  }
end

-- Route a button press the way main.lua does: prompt first, then dialog.
local function press(button)
  if Prompt.currentPrompt then
    Prompt.currentPrompt:keypressed(button)
  elseif Dialog.currentDialog then
    Dialog.currentDialog:keypressed(button)
  end
end

-- Play out the whole conversation the way main.lua + an impatient player would:
-- each tick, mash JUMP to advance/confirm whatever prompt or dialog is open, then
-- pump the singletons. A generous iteration cap stands in for the reported "endless
-- loop" — if the flow never releases we bail and let assertions fail rather than hang.
-- (JUMP never changes prompt selection, so any LEFT/RIGHT chosen beforehand sticks.)
local function settle()
  for _ = 1, 1000 do
    if not Prompt.currentPrompt and not Dialog.currentDialog then return true end
    press('JUMP')
    if Prompt.currentPrompt then Prompt.currentPrompt:update(1) end
    if Dialog.currentDialog then Dialog.currentDialog:update(1) end
  end
  return false
end

local function reset()
  Prompt.currentPrompt = nil
  Dialog.currentDialog = nil
  sound.playSfx = function() end
end

local function teardown()
  Prompt.currentPrompt = nil
  Dialog.currentDialog = nil
  sound.playSfx = realPlaySfx
end

-- Declining "The Special" should close the menu, unfreeze the player, leave the
-- curtain flag unset, and clear the prompt (no lingering re-prompt).
function test_todd_decline_settles()
  reset()
  local npc = fakeNpc(false)
  local player = { freeze = true }

  todd.begin(npc, player)
  assert_true(Prompt.currentPrompt ~= nil, "begin() should raise the Special prompt")

  -- selected defaults to 'No' (the last option); settle() confirms it with JUMP.
  assert_true(settle(), "the decline flow must settle, not loop forever")

  assert_nil(Prompt.currentPrompt, "prompt must clear after answering")
  assert_nil(Dialog.currentDialog, "no dialog should linger")
  assert_equal(1, npc.menu.closeCount, "menu must close exactly once")
  assert_false(player.freeze, "player must unfreeze")
  assert_false(npc.db:get('sandwich-curtain', false), "declining must not open the curtain")
  teardown()
end

-- Accepting "The Special" walks through a second dialog, then must set the curtain
-- flag, close the menu, and unfreeze the player.
function test_todd_accept_sets_flag_and_settles()
  reset()
  local npc = fakeNpc(false)
  local player = { freeze = true }

  todd.begin(npc, player)
  press('LEFT') -- move the selection from 'No' to 'Yes'

  -- settle() confirms the prompt, then advances the 'Yes' follow-up dialog to the
  -- terminal callback (which sets the curtain flag) — all in one JUMP-mashing loop.
  assert_true(settle(), "the accept flow must settle, not loop forever")

  assert_nil(Prompt.currentPrompt, "prompt must clear")
  assert_nil(Dialog.currentDialog, "no dialog should linger")
  assert_equal(1, npc.menu.closeCount, "menu must close exactly once")
  assert_false(player.freeze, "player must unfreeze")
  assert_true(npc.db:get('sandwich-curtain', false), "accepting must open the curtain")
  teardown()
end

-- Once the curtain is open, begin() should just play the wink line and release the
-- player — no prompt, no soft-lock on repeat visits.
function test_todd_returning_visit_settles()
  reset()
  local npc = fakeNpc(true)
  local player = { freeze = true }

  todd.begin(npc, player)
  assert_nil(Prompt.currentPrompt, "returning visits show a dialog, not a prompt")
  assert_true(Dialog.currentDialog ~= nil, "returning visit should show the wink line")

  assert_true(settle(), "the returning-visit flow must settle, not loop forever")

  assert_nil(Dialog.currentDialog, "no dialog should linger")
  assert_equal(1, npc.menu.closeCount, "menu must close exactly once")
  assert_false(player.freeze, "player must unfreeze")
  teardown()
end
