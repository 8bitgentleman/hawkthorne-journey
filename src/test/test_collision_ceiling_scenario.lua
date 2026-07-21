-- End-to-end (gameplay-level) regression tests for the ceiling-collision family
-- fixed by merged PR #2584 ("Addresses two common collision issues"):
--   #2456 - attack/stand after a crouch under a low ceiling clips the player up
--   #2578 - a bat knockback (or standing at a ceiling edge) warps the player up
--           through a ceiling tile
--
-- test_collision_ceiling.lua already pins the underlying collision math in
-- isolation. These tests are the companion the PR author explicitly could NOT
-- write at the time -- on the #2578 thread: "I'm not sure how to have a
-- repeatable test with being hit by a bat to knock you into the ceiling."
--
-- They drive the *real* Level + Player update loop through the headless
-- scenario harness: real map geometry, real Player:updatePosition ->
-- collision.move, real crouch-aware bounding box. A solid ceiling tile is added
-- to a plain side-scrolling level's collision layer, then the exact in-game bat
-- knockback impulse (Enemy:collide sets player.velocity.y = -450, enemy.lua) is
-- applied and the physics stepped at a fixed dt.

local Scenario = require 'test/scenario'

-- greendale-biology is a plain side-scroller with a `collision` tilelayer and no
-- moving platforms, so the harness can drive it deterministically. The player
-- spawns over open ground; the tiles directly above the spawn column are empty,
-- which is where we drop a synthetic ceiling.
local FIXTURE = 'greendale-biology'

-- Return the map's `collision` tilelayer (the one collision.lua reads).
local function collision_layer(map)
  for _, layer in ipairs(map.tilelayers) do
    if layer.name == 'collision' then return layer end
  end
  error('fixture ' .. FIXTURE .. ' has no collision tilelayer')
end

-- Drop a solid block tile (id 0) into the cell containing world (x, y).
-- Returns the tile's top and bottom (underside) world-y edges.
local function put_ceiling(map, x, y)
  local layer = collision_layer(map)
  local col = math.floor(x / map.tilewidth) + 1
  local row = math.floor(y / map.tileheight)
  layer.tiles[row * map.width + col] = { id = 0 }
  return row * map.tileheight, (row + 1) * map.tileheight
end

-- Boot the fixture and let gravity settle the player onto the floor.
local function settled_scenario()
  local s = Scenario.new(FIXTURE)
  s:step(30)
  return s
end

-- #2578, the actual bat scenario: a knockback impulse launches the player up
-- into a low ceiling. The player must be stopped cleanly at the ceiling's
-- underside and never pass through it, then fall back to the floor -- not clip
-- up and stick on top of the geometry.
function test_bat_knockback_stops_at_ceiling_and_returns()
  local s = settled_scenario()
  local p = s.player
  local floorY = p.position.y
  local cx = p.position.x + p.character.bbox.width / 2

  -- Ceiling with its underside ~19px above the player's head (box top).
  local ceilTop, ceilUnder = put_ceiling(s.level.map, cx, floorY - 34)

  -- The exact impulse Enemy:collide applies to the player on a hit.
  p.velocity.y = -450

  local minY = p.position.y
  for _ = 1, 120 do
    s:step(1)
    minY = math.min(minY, p.position.y)
  end

  -- The player's box top never rises above the ceiling tile's top edge
  -- (a clip-through would leave them sitting on top of it, box top < ceilTop).
  assert_true(minY >= ceilTop,
    string.format("knockback clipped through ceiling: minY=%.1f < ceilTop=%.1f",
                  minY, ceilTop))
  -- Sanity: they actually reached the ceiling (the impulse was strong enough).
  assert_true(minY <= ceilUnder + 1,
    "player did not reach the ceiling; impulse/geometry is wrong for this test")
  -- And gravity brings them back down to the floor.
  assert_true(math.abs(p.position.y - floorY) < 1,
    string.format("player did not settle back on the floor: y=%.1f floor=%.1f",
                  p.position.y, floorY))

  s:teardown()
end

-- #2578, the down-branch guard specifically (collision.move_y's `slope_y >= new_y`).
-- Reproduces the "standing at a ceiling edge" state end-to-end: the player's box
-- top sits inside a ceiling tile's vertical span and gravity applies a small
-- downward tick. Pre-#2584 the downward scan found that tile *above* the new
-- position and returned `slope_y - height`, warping the player up onto the
-- ceiling. With the guard, they simply continue to fall.
--
-- Removing the `slope_y >= new_y` guard in collision.move_y makes this fail
-- (the player warps from a box top of ~246 up to ~199) -- so it pins the fix.
function test_ceiling_edge_downtick_does_not_warp_up()
  local s = settled_scenario()
  local p = s.player
  local cx = p.position.x + p.character.bbox.width / 2

  -- A ceiling tile straddling the player's head, then embed the box top inside
  -- the tile's vertical span -- the exact ceiling-edge state the bug needs.
  local ceilTop, ceilUnder = put_ceiling(s.level.map, cx, p.position.y - 10)
  p.position.y = ceilTop + 6
  p:moveBoundingBox()
  p.velocity.y = 20 -- a gentle, gravity-like downward tick

  local before = p.position.y
  s:step(1)

  assert_true(p.position.y >= before,
    string.format("player warped UP through the ceiling: %.1f -> %.1f (tile %.0f..%.0f)",
                  before, p.position.y, ceilTop, ceilUnder))
  s:teardown()
end

-- #2456: crouched under a ceiling too low to stand under, the player must not be
-- able to reclaim full height (which pre-#2584 clipped them up into the ceiling).
-- Player:canStand -> collision.stand gates standing up; it must report false.
function test_cannot_stand_up_into_low_ceiling()
  local s = settled_scenario()
  local p = s.player
  local cx = p.position.x + p.character.bbox.width / 2
  local grow = p.character.bbox.height - p.character.bbox.duck_height

  -- Ceiling low enough that a full-height hitbox would intersect it but a ducked
  -- one fits: underside just inside the standing box's headroom.
  put_ceiling(s.level.map, cx, p.position.y - grow + 4)

  assert_false(p:canStand(s.level.map),
    "player must not be able to stand up into a solid ceiling tile")
  s:teardown()
end
