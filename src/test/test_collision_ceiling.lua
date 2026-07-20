-- Regression tests for the collision fix in merged PR #2584
-- ("Addresses two common collision issues"), which relates to:
--   #2456 - crouch/attack/ceiling collision family (closed by #2584)
--   #2578 - "Wall clipping": a bat knockback pushes the player through a ceiling
--   #2427 - falling through moving platforms while crouching + spamming keys
--
-- PR #2584 added a guard in collision.move_y so that, while moving DOWN, the
-- collision code can never snap the player UP onto a block tile that is above
-- the player's new position (which would warp them into the geometry). The PR
-- author noted a bat-knockback scenario was not repeatably testable at the
-- gameplay level; these tests pin the underlying move_y behaviour instead, so
-- the fix cannot silently regress.

local collision = require "src/hawk/collision"

-- A 10x10 map of 24px tiles. Tile id 0 is a plain (non-sloped, non-special)
-- solid block. move_y iterates map.moving_platforms, so it must be present.
local function blockmap()
  local tiles = {}
  tiles[11] = { id = 0 } -- one solid block at column 0, row 1 (top edge y = 24)
  return {
    width = 10,
    height = 10,
    tilewidth = 24,
    tileheight = 24,
    tilelayers = { { name = 'collision', tiles = tiles } },
    moving_platforms = {},
  }
end

local function newplayer()
  return { velocity = { y = 0 } }
end

-- The bug: while moving down a small amount, the block tile at row 1 (top edge
-- y = 24) sits ABOVE the player's new position. Pre-#2584 the code returned
-- slope_y - height (= 12), warping the player upward into the ceiling. The
-- guard must instead let the player continue to new_y.
function test_move_y_down_does_not_warp_up_into_ceiling()
  local map = blockmap()
  -- player at y=28 (inside row 1), moving down by 2 -> new_y = 30.
  -- The scanned block's top (24) is above new_y (30): must NOT snap up.
  local result = collision.move_y(map, newplayer(), 4, 28, 12, 12, 0, 2)
  assert_equal(30, result,
    "moving down must not warp the player up onto a block tile above them")
end

-- Guard must not break legitimate landings: a genuine downward collision onto
-- the block (top edge at or below new_y) should still stop the player with
-- their feet on the tile.
function test_move_y_down_still_lands_on_block_below()
  local map = blockmap()
  -- player at y=10 falling by 10 -> new_y = 20; block top at 24 is below/at
  -- reach, so the player should land with feet at 24 => y = 24 - height(12) = 12.
  local result = collision.move_y(map, newplayer(), 4, 10, 12, 12, 0, 10)
  assert_equal(12, result,
    "a real downward collision onto a block below must still stop the player")
end

-- collision.stand (used by Player:canStand, which gates standing up after a
-- crouch/attack near a low ceiling) must report false when a block occupies
-- the space the taller hitbox would expand into.
function test_stand_blocked_by_ceiling_returns_false()
  local map = blockmap()
  -- Row 1's block has its underside at y=48. Put the ducked hitbox just below
  -- it (y=50) and try to reclaim full height by growing upward into the block.
  local can = collision.stand(map, newplayer(), 4, 50, 12, 12, 24)
  assert_false(can, "must not be able to stand up into a solid ceiling tile")
end
