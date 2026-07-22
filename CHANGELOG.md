# Changelog

All notable changes to the `8bitgentleman` fork of *Journey to the Center of Hawkthorne*
are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions are
**local git tags** (`vX.Y.Z`) — there are no GitHub release objects. An `Internal` heading
(non-standard) records dev-only tooling and tests, kept out of the player-facing headings.

## [Unreleased]

### Added
- **Drop-in local co-op** (co-op spike Phase 2 completion) — a second player can now actually
  join a level by pressing **Start** on a free gamepad, and drop out again the same way (or by
  unplugging). Player 1 keeps the flexible keyboard-or-gamepad handling; player 2 claims the
  next free pad, and neither can hijack the other's device. Both walk/jump/attack independently,
  share one zoom-and-centroid camera and one health bar, and enemies hit whichever they touch.
  The **overworld stays single-player** — player 1 drives it and player 2 "comes along",
  reappearing automatically in the next level (`Level:spawnCoopPlayer` rebuilds them on each
  level's collider via the existing restart path). Input events are routed per-device to the
  owning player (`main.lua` + new `coop.lua`; `Level:keypressed/keyreleased` take a player index),
  and a downed-in-a-pit player 2 leashes back to player 1 rather than falling off-screen. Spike
  scope: levels only, player 2's skin is hardcoded, no P2 character-select/menus/save yet.
  The scenario harness's `spawn2` now delegates to `Level:spawnCoopPlayer`, so the existing
  two-player tests exercise the production build path; new `test_coop.lua` pins device ownership,
  join/drop, event routing, and the restart-rebuild.
- **Greendale speakeasy** — final slice of the teacher-lounge expansion (PR #2530), ported
  forward to LÖVE 11.5. Adds a hidden speakeasy reachable through Sophie's room (`sophieb`,
  rebuilt to house the entrance and Shirley's Sandwiches): a new `greendale-speakeasy` map with a
  house band and a `switch` node (a generic interact-to-toggle-a-save-flag node), plus the
  `todd-sandwich` NPC running the "special" behind the sandwich curtain. Removes the orphaned
  `rave-switch` node (a dead file with no map or code references).
- **Teacher-lounge questline** — second slice of the teacher-lounge expansion (PR #2530),
  ported forward to LÖVE 11.5. Wires the interconnected questline into the campus: the
  administration hallway now has a door to the bursar's office (connecting slice one's shop to
  the world), and the exterior/quad lead into a new teacher's lounge, lounge bathroom, three
  computer-wing rooms, Russell Borchert's secret lab, and the reopened Borchert pool. Adds the
  **Borchert**, **Raquel** (his emotion-processing computer), **Officer Cackowski**, and
  **Pierce hologram** NPCs; the **flashlight** and **rope** key items; and the trigger
  infrastructure the questline runs on — save-flag-gated `sprite`/`movingplatform` sprites (e.g.
  the exterior airplane banner that appears after buying the airplane improvement) and the
  City College mascot goat that stays hidden until the mascot heist is funded. Bugs fixed in the
  port: Raquel's "paintball" topic only bumped her side of the affection counter (not the
  player's, which drives the marriage threshold) so it never counted; and the revealed-but-locked
  hidden-door prompt was dead code (guarded by a `hiddable` typo) — the lounge vending-machine
  door now explains it still needs the rope instead of silently refusing.
- **Greendale bursar & campus-improvements shop** — first slice of the teacher-lounge
  expansion (PR #2530), ported forward to LÖVE 11.5. Adds a `bursar` NPC and a new
  `improvements` category to the shop system: the bursar sells one-off campus upgrades
  (airplane ad campaign, Pierce's hologram, Shirley's Sandwiches, the City College mascot
  heist) which record a save flag for the world to read instead of entering the player's
  inventory. Improvements are gated on the player's money and can't be sold back. This slice
  is the shop system, improvement items, and NPC; the in-world bursar's-office entrance lands
  with a later slice. Two upstream bugs were fixed in the port: the removed
  `love.graphics.newScreenshot` call now uses the async `captureScreenshot`, and the `iamount`
  variable-shadowing that would have zeroed every shop's sell count was dropped.
- **Underwater levels** — ported from the `underwater2` branch. Adds an oxygen/drowning
  system and supporting enemies, hazards, and art:
  - **Oxygen system:** the player gains an oxygen meter (`max_oxygen = 20`). While submerged in
    air-less liquid, `Player:suffocate()` drains oxygen instead of health on a timer; hitting zero
    kills the player. Oxygen refills fully on leaving the water and on level refresh. A HUD oxygen
    bar shows only while oxygen is below full.
  - **`liquid` node** gains a numeric `injure` + `injure_timer` mode that drains N oxygen every
    T seconds (distinct from the existing boolean `injure`, which drains health).
  - **Jellyfish enemies:** `jellyfish-strawberry` (slow, constantly homes in) and
    `jellyfish-blueberry` (drifts until the player is near, then chases faster) — both antigravity,
    6 HP, vulnerable to blunt attacks.
  - **`bubbles`** — decorative, peaceful floating bubbles that bob in place.
  - **`healing_floor`** — an invisible air-pocket zone that refills oxygen on contact.
  - **`killing_floor_underwater`** — an underwater variant of `killing_floor` for bottom hazards.
  - New assets: `underwater.png` tileset, jellyfish/bubbles sprites, HUD `oxygenbar.png`, and the
    `jellyfish_die.ogg` sound.
- **Santa's Grotto** — ported from the `santas-grotto` branch. A self-contained holiday
  side-room, reachable through a new `grotto` door in Winter Wonderland, housing the
  `christmas-pterodactyl` boss. The boss was reworked to the swooping bird boss from *Super
  Mario Land 2*: it cruises the ceiling, telegraphs above the player, then commits a fast dive
  at where the player was standing (a late sideways dodge beats it), bottoming out just above
  the floor before climbing back. 50 HP, vulnerable to blunt attacks. New `santas-grotto.tmx`
  map, `santas-grotto.png` tileset, and winter decoration sprites (toy + present boxes). The
  visible entrance-tile art for the Winter Wonderland door is a pending art follow-up; the door
  is functional (an invisible trigger) without it.

### Changed
- The `sophieb` room was widened and redrawn to add the speakeasy entrance and the Shirley's
  Sandwiches storefront (part of PR #2530).

### Fixed
- Several `Player` methods (jump/swim ladder-release, `die`, and `refreshPlayer`'s holdable
  re-pickup) referenced the module-global `player` singleton instead of `self`. Harmless in
  single-player (they're the same object) but a latent bug: any future second player would
  release *player 1's* ladder or re-pickup onto *player 1*. Now use `self` throughout.

### Internal
- Add `test_todd_sandwich.lua` — regression coverage for the Shirley's-Sandwiches NPC ported
  from PR #2530, whose tester reported an "endless loop of Shirley dialogue" / "not being able
  to get away". Drives the real Prompt/Dialog singletons through todd's `begin()` on all three
  branches (decline, accept, returning visit) and asserts each settles: the prompt clears, the
  menu closes once, and the player unfreezes (no re-prompt). The loop does not reproduce in the
  ported code; this pins that it stays fixed.
- Add `test_christmas_pterodactyl.lua` — pins the boss's dive FSM (patrol → telegraph → dive →
  recover) by driving the enemy prop table directly with fake enemy/player tables, no Level needed.
- Extend the scenario harness with two-player support (`spawn2`, per-player input via a `who`
  arg, two-player teardown) and add `test_scenario_coop.lua` — Phase 0 of the local co-op spike.
  Proves two `Player` instances register on one HardonCollider and move independently, with the
  existing `on_collision` routing delivering each hit to the right instance (no engine changes).
- Express the engine in terms of a player *list* behind a compatibility shim (co-op spike
  Phase 1): `Player.all()` and `level.players` (with `level.player` kept as a live alias of
  `players[1]`); `Level:update` now iterates the list. Single-player is byte-identical — the
  list always holds exactly the one live player.
- De-singleton the character object and engine-drive a second player (co-op spike Phase 2):
  split `character.current()` into a non-caching `character.build()` plus a thin caching
  wrapper (`current()`/`pick()` behaviour unchanged), so a second player can hold its own
  character/animation state. The scenario harness's `spawn2` now appends P2 to `level.players`
  and gives it a fresh `character.build()`, so `Level:update`'s list loop drives P2's input and
  physics with no harness poke; two new coop tests prove opposite-direction engine-driven
  movement and independent per-player animation state. Single-player untouched.
- Share one camera across players (co-op spike Phase 3): new `Level:cameraFocus()` returns the
  centroid of all living players, and both `moveCamera` and `cameraPosition` (the latter also
  drives enemy off-screen culling) track it. In single-player the one-element centroid is the
  exact old framing point, so the camera math is byte-identical (parity test added); with two
  players the shared view sits at their midpoint. `camera.lua` is untouched; true zoom-to-fit
  and a separation leash are deferred (they conflict with the fixed-scale centering/clamp math).
- Target bosses at the nearest living player instead of the singleton (co-op spike Phase 4a):
  new `Level:nearestLivingPlayer(pos)` (squared-distance scan over `level.players`), and the
  five boss/projectile sites that reached `Player.factory()` now use it — including three that
  captured the singleton at *module load* (`qfo`, `laserlotusBoss`, `cornelius`) and so could
  never have seen a second player. Each keeps a `player.factory()` fallback for the pre-`addNode`
  construction path (e.g. an on-load quest-mismatch `die`), so with one living player targeting
  is byte-identical. A dead `Player.factory()` local in `tSnake`'s `die` was removed. No
  death/revive changes here.
- Share one health bar across players (co-op spike Phase 4b): `Player:hurt` now drains an
  optional `self.shared_health` holder instead of `self.health`. In single-player the holder is
  `self` (byte-identical); in co-op every extra player's `shared_health` points at player 1, who
  physically holds the team's health — so damage to *any* player drains the one bar the HUD and
  the existing game-over check already read, and emptying it kills player 1 (firing the current
  game-over path) and marks the rest of the team out. No new per-player death/revive state; the
  rebound/invulnerability/hurt animation still stay on whoever actually took the hit. Three coop
  tests pin single-player parity, cross-player drain, and shared-zero game-over.

## [1.1.3] - 2026-07-20

### Fixed
- Players riding a **rising** moving platform no longer fall through it when the crouch
  bounding box flips mid-ascent (e.g. spamming attack/interact on a fast platform). `move_y`
  now keeps the rider attached while the platform's own upward motion is carrying them (#2427).

### Internal
- Extend the scenario harness with moving-platform helpers (`landOn`/`movingPlatforms`) and
  platform teardown, plus a regression test that a crouch-attacking rider stays bound to a
  rising platform for the whole ascent.

## [1.1.2] - 2026-07-20

### Changed
- Forest boulders (`breakable_block`s in `forest.tmx`) drop from 3 HP to 1 so the earliest
  breakable blocks aren't a slog (#2491).

### Internal
- Add a **headless scenario harness** (`src/test/scenario.lua`): boots a real `Level`, binds a
  fresh player, injects scripted input, and steps `Level:update` at a fixed `dt` — letting tests
  prove gameplay changes without a window or a human.
- Add regression tests (unit + end-to-end) pinning the #2584 ceiling-collision fix so the
  `move_y` downward guard and `canStand`/`attack` plumbing cannot silently regress (#2456, #2578).

## [1.1.1] - 2026-07-20

### Fixed
- Blacksmith shop no longer soft-locks: `ATTACK` now backs out of the top-level categories
  window, matching the on-screen "PRESS &lt;ATTACK&gt; TO GO BACK" prompt (previously only the
  unsurfaced `START`/Escape worked, trapping players in the menu) (#2608).

## [1.1.0] - 2024-11-22

- Last upstream release of [`hawkthorne/hawkthorne-journey`](https://github.com/hawkthorne/hawkthorne-journey/releases/tag/v1.1.0).
  Fork modernization continues above. (Changes between this release and 1.1.1 — the LÖVE 11.5 /
  love.js migration of late 2024 — predate this changelog and are not itemized here.)

[Unreleased]: https://github.com/8bitgentleman/hawkthorne-journey/compare/v1.1.3...HEAD
[1.1.3]: https://github.com/8bitgentleman/hawkthorne-journey/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/8bitgentleman/hawkthorne-journey/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/8bitgentleman/hawkthorne-journey/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/hawkthorne/hawkthorne-journey/releases/tag/v1.1.0
