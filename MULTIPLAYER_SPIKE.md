# Local Co-op — Spike A plan (grounded)

**Status:** planning doc, no code committed beyond the latent-bug fix noted below.
**Supersedes** the multiplayer section (§7) of `HAWKTHORNE_HANDOFF_v2.md`, which was tagged
📎 INHERITED (v1 research, never re-verified). Everything below was checked firsthand against
`develop` on 2026-07-21 — file:line references are real. Where §7 was wrong or optimistic, it's
called out.

---

## 0. Why this exists

§7 framed local co-op as "de-singleton three things — `Player`, `InputController.get`, global
`camera`." That framing is **partly wrong**. After reading the actual code, the picture is:

- **One** hard singleton is the real work (`Player`).
- The **node-collision layer is already per-player** — the single most load-bearing thing, and §7
  never mentioned it.
- Input is a **per-name registry**, not a hard singleton.
- The camera is a real shared module, but the recommended design keeps it shared, so it's a
  targeting change, not a teardown.

So the effort is more contained than §7 implied, but the shape is different — the work is
"turn `level.player` (one) into `level.players` (a list) and let the already-correct collision
routing do the rest," not "rip out three singletons."

---

## 1. Verified ground truth (firsthand, with file:line)

| Claim | Reality | Source |
|---|---|---|
| Node collision routing | **Already per-player.** `on_collision` reads `player = shape_a.player` (the bb's instance tag) and dispatches `node:collide(player, ...)` to that instance; handles player-vs-player with an early return. | `src/level.lua:30–46` |
| Collision boxes instance-tagged | **Yes.** `self.top_bb.player = self` / `self.bottom_bb.player = self` (original author flagged both `-- wat`). This is exactly what makes the routing above work per-instance. | `src/player.lua:209–210` |
| Base enemy targeting | **Parameterized.** `Enemy:update(dt, player, map)` receives the player; combat (`player:hurt`, `player.jumpDamage`, rebound) operates on the passed player. | `src/nodes/enemy.lua:446, 409, 432, 436` |
| Boss / special-node targeting | **NOT uniformly parameterized.** Several nodes reach the singleton directly via `Player.factory()` (cornelius, qfo, tSnake, laserlotusBoss, rainbowbeam, aliens). These need nearest-living-player logic. | `grep Player.factory src/nodes/enemies/*` |
| `Player` singleton | **Real, module-global.** `local player = nil` + `Player.factory()` create-or-return; `level.player = Player.factory(collider)`. This is the de-singleton surface. | `src/player.lua:43, 229`; `src/level.lua:162, 248` |
| Player singleton blast radius | `Player.factory()` reached in **~16 non-test files** (level, overworld, options, costumeselect, cheat, npc, vehicle, + ~7 enemy/npc nodes). Bounded, not sprawling. | `grep -rl Player.factory src/` |
| `InputController` | **Not a hard singleton.** `get(name)` is a per-name cache (`cached[name]`); the player already holds its own `plyr.controls = InputController.get()`. Everyone just calls it with no arg → `DEFAULT_PRESET`. | `src/inputcontroller.lua:80–86` |
| `camera` | **Real shared module singleton** (`local camera = {}` with `camera.x/y`), required in ~10+ files. Shared-camera design (below) keeps it as-is. | `src/camera.lua:2–10` |

### Already fixed (2026-07-21)
The latent `player`-vs-`self` bug §7 flagged is **fixed on `develop`**. Four `Player` methods
referenced the module-global `player` instead of `self` (three ladder-releases in the jump/swim
paths, `Player:die`, and `refreshPlayer`'s holdable re-pickup). Harmless in single-player (same
object), a real co-op defect otherwise. Now `self` throughout. 108 tests pass, lint clean.

---

## 2. The corrected blocker list

1. **`Player` lifecycle is single-instance.** `level.player` is one object; `Player.factory()`
   is create-or-return-the-one. **This is the spike.** Turn it into a list of players, each with
   its own bounding boxes registered on the level collider (each already self-tags via
   `bb.player = self`).
2. **Input device → player mapping.** The registry exists; what's missing is binding P2's
   `controls` to a distinct preset/device (e.g. P1 keyboard, P2 gamepad) and routing raw input
   events to the right player's `InputController`.
3. **Camera follows one player.** Needs a shared zoom-to-fit target computed from all living
   players (with a leash so they can't separate infinitely). No split-screen.
4. **Boss/special-node targeting reaches the singleton.** The ~7 nodes calling `Player.factory()`
   for "the player" need nearest-living-player instead. Base enemies are already fine.
5. **Per-player death/revive.** `level.player.character:respawn()` and death handling assume one;
   needs per-player state and a revive rule (co-op convention: revive on the other player, or
   respawn at a leash distance).

**Not a blocker (§7 got these wrong or missed them):**
- Node collision dispatch — already per-player. No work.
- Input as a "singleton" — it's a registry; no teardown.
- Camera as a "singleton to remove" — it stays; only its target changes.

---

## 3. Spike A — phased plan

**Goal of the spike (not shippable co-op — a proof):** two players, both keyboard-or-gamepad,
walking/jumping/attacking in one plain side-scroller (`greendale-biology`), sharing one
zoom-to-fit camera, with enemies that hit whichever player they touch. **Success = both players
provably independent** in the scenario harness. Explicitly *out* of the spike: menus, character
select for P2, overworld, save/load with two players, netcode.

### Phase 0 — instrument (½ day)
- Extend `src/test/scenario.lua` to spawn and drive **two** players (`spawn2`, per-player
  `hold/press` keyed by player index). This is the whole verification story — build it first so
  every later phase is provable headlessly. The harness already snapshots/restores the `Player`
  singleton; make it snapshot/restore a *list*.
- **Kill-criterion checkpoint:** if two players can't be registered on one collider without the
  HardonCollider shapes colliding pathologically, stop and reassess — that's the load-bearing
  assumption.

### Phase 1 — de-singleton Player behind a compatibility shim (2–3 days)
- Introduce `Player.all()` returning a list; keep `Player.factory(collider)` returning
  `players[1]` so the ~16 existing call sites keep working unchanged (shim, don't chase all
  sites yet).
- `level.player` → `level.players` internally; add `level.players[1]` alias where single-player
  code reads `level.player`. Register each player's `top_bb`/`bottom_bb` on `level.collider`.
- The already-correct `on_collision` routing (`level.lua:30–46`) should now deliver collisions to
  the right player with **zero changes** — verify that in the Phase-0 harness. If it doesn't,
  that's the real surprise and where the time goes.
- **Green gate:** full suite still 108-pass (single-player must be untouched by the shim).

### Phase 2 — second input (1–2 days)
- Bind `players[2].controls = InputController.get('gamepad')` (or a second keyboard preset).
- Route raw key/gamepad events in `main.lua` to the owning player's controller. The action
  abstraction already exists; this is wiring, not redesign.
- Harness proof: P1 holds RIGHT while P2 presses JUMP → P1 walks, P2 jumps, neither bleeds into
  the other. (This is the test the `self` bug fix was a prerequisite for.)

### Phase 3 — shared camera (1 day) — **done (centroid), zoom/leash deferred**
- Compute the camera target as the midpoint/bbox of all living players; clamp span with a leash
  so one can't drag the view off the other. Keep the single `camera` module — only its
  per-frame target math changes (likely in `level.lua`'s camera update, not `camera.lua` itself).
- **Shipped:** `Level:cameraFocus()` returns the centroid of all living players; `moveCamera`
  and `cameraPosition` (also used by enemy off-screen culling) both route through it. Single
  player = one-element centroid = byte-identical framing (proved by a parity test). `camera.lua`
  untouched.
- **Deferred (follow-ups, not blockers for the proof):** true zoom-to-fit and a separation
  leash. Both fight the current fixed-scale assumptions — the centering uses a constant
  `window.width / 2` (not `camera:getWidth()`), and `camera.max.x` is clamped once at enter to
  `map.width*tilewidth - window.width`. Changing scale per-frame makes those inconsistent, so
  the spike keeps a fixed scale; players walking far apart go off-screen (acceptable for a
  proof). Zoom-to-fit is a self-contained later task against `camera:setScale` + the clamp math.

### Phase 4 — targeting + death/revive (2–3 days)
- Replace `Player.factory()` in the ~7 boss/special nodes with a `level:nearestLivingPlayer(pos)`
  helper. Base enemies already take the player param — leave them.
- Per-player death: `players[i].dead`; level only fully game-overs when **all** are dead. Revive
  rule: respawn the dead player at the living player's position after a delay (simplest co-op
  convention; decide with owner).

**Spike total: ~1.5–2 weeks** to a harness-proven two-player side-scroller. That's the "prove the
architecture" milestone. Polished co-op (menus, P2 character select, overworld, save format) is a
separate, larger effort and explicitly *not* in Spike A.

---

## 4. Open questions to resolve firsthand (don't guess)

- **Does registering a second player's bbs on the live collider Just Work,** or does
  HardonCollider need per-player collision groups to stop the two players' own boxes from firing
  spurious overlaps? (Phase 0 answers this — it's the make-or-break.)
- **Overworld** (`src/overworld.lua` calls `Player.factory()`): is co-op even wanted there, or
  does the spike stay in levels only? (Owner call — probably levels-only for the spike.)
- **Revive convention:** respawn-on-partner vs. shared-lives vs. independent. (Design, not code.)
- **P2 character/costume:** the spike can hardcode P2's skin; real co-op needs a P2 select flow.

---

## 5. Relationship to remote MP (§7b) — unchanged, still gated

Remote MP's real risk is unchanged and §7 had it right: **retrofitting a fixed timestep** onto
variable-dt, float, unseeded-rng physics. Lockstep is dead on arrival. Prove fixed-timestep in a
standalone spike **before** any sockets. Local co-op (this doc) shares none of that risk — it's a
same-process, same-clock problem — so it's the correct first investment and a prerequisite either
way (you can't network what you can't run two-player locally).
