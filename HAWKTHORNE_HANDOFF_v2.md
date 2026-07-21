# Hawkthorne Modernization — Handoff v2

**Purpose:** Hand off to a fresh Claude Code session with read/write access to the fork
`8bitgentleman/hawkthorne-journey`. This **supersedes the original handoff.** It keeps the
strategic research from v1 but rewrites the operational parts around what was **actually
verified with running code and firsthand thread reads** in the last two sessions.

**Read this differently than v1.** Everything here is tagged:
- ✅ **VERIFIED** — checked this/last session by running code or reading the actual GitHub thread.
- 📎 **INHERITED** — carried forward from v1's research; still plausible but **secondhand, not
  re-verified.** Treat as leads, not facts. Several v1 "facts" turned out wrong (see §5).

**Project owner:** Matt Vogel (`8bitgentleman`, aka `mainmoniker`). A top-3 contributor to the
original game. This is him reviving his own long-stalled work on a dormant project — legitimate
succession, not a stranger's fork.

**Game:** "Journey to the Center of Hawkthorne" — a LÖVE (Love2D/Lua) recreation of the pixel
game from Community's *Digital Estate Planning* episode.

---

## 0. START HERE — current state & branching model

✅ **The fork's `master` is a byte-for-byte mirror of `upstream/master`** (0 commits ahead, 0
behind — verified with `git rev-list --left-right --count`). It is clean LÖVE 11.5 and the game
runs on it. **Keep it that way — it is a pristine upstream mirror, NOT a place to develop.**
(v1 wrongly believed master was stale/pre-11.5 and needed rebuilding from upstream — false.
But v1's instinct to have a *separate* integration branch was right, for a different reason:
committing to `master` would break clean upstream syncs. So we kept the integration branch and
dropped the "rebuild master" step.)

### ✅ Branching model — IN PLACE NOW
- **`master`** = pristine mirror of `upstream/master`. **Never commit here.** Sync only via
  fast-forward: `git fetch upstream && git checkout master && git merge --ff-only upstream/master`
  (`upstream` = `hawkthorne/hawkthorne-journey`, dormant, last commit 2024-11-26). Keeping it
  pristine is what keeps that ff-only sync working forever.
- **`develop`** = the fork's **real trunk / integration line**. ✅ Already created and pushed
  (`origin/develop`), cut from the clean `master` and carrying the two verified commits below.
  **This is the base for all new work.**
- **All work lands directly on `develop`** (owner's workflow, confirmed 2026-07). Commit straight
  to `develop` once the suite is green + lint clean. **No feature branches, no PRs** (neither
  upstream nor within the fork). The owner pushes `develop` to their fork. `master` stays pristine.
- Periodically: sync `master` from upstream (ff-only, above), then `git checkout develop &&
  git rebase master` to carry the integration line forward.

✅ **The two verified commits already live on `develop` (and on `claude/new-session-q1adh6`):**
1. `Fix stuck blacksmith shop menu (#2608)` — real bug fix + 3 tests.
2. `Add regression tests pinning the #2584 ceiling-collision fix (#2427, #2578)`.

Both pass the full suite (**91 passed, 0 failed, 0 skipped**) and lint clean. `develop` is the
seed of the new trunk; everything from here enters `develop` via feature-branch PRs.

---

## 1. Environment & tooling — ✅ ALL VERIFIED THIS SESSION

- **Install LÖVE 11.5:** `sudo apt-get install -y love`. A `dpkg` desktop-mime trigger error
  appears at the end — **harmless**; `love --version` → `LOVE 11.5`. (The official AppImage
  download from github.com is proxy-blocked; `apt` is the working path.)
- **Install the linter's Lua:** `sudo apt-get install -y lua5.4 && sudo ln -sf /usr/bin/lua5.4
  /usr/local/bin/lua` (repo's `scripts/lualint.lua` has a `#!/usr/bin/env lua` shebang).
- **Run the suite:** `xvfb-run -a love src --test` (needs a virtual display; `xvfb-run`
  preinstalled). Harness = a lunatest fork under `src/test/`, auto-discovering `test_*.lua`.
- **Lint a file:** `./scripts/lualint.lua -r src/<file>.lua` (exit 0 = clean). CI lints all
  non-vendor, non-test `.lua`; `src/test/` is excluded (so test-file lint is informational).
- **CI reference:** `.github/workflows/build.yml` runs `make clean validate test` under `xvfb`
  on `ubuntu-24.04`.

### ⭐ Maps now compile — the v1 "tmx2lua is blocked" wall is GONE. ✅
v1 said map-dependent tests couldn't run because the `tmx2lua` **release binary** is proxy-blocked.
True — but the **source repo clones fine** and builds with the preinstalled Go toolchain:
```bash
git clone --depth 1 https://github.com/hawkthorne/tmx2lua /tmp/tmx2lua-src
cd /tmp/tmx2lua-src && go build -o tmx2lua .     # pulls one module dep via proxy.golang.org; works
mkdir -p /home/user/hawkthorne-journey/bin
cp tmx2lua /home/user/hawkthorne-journey/bin/tmx2lua
cd /home/user/hawkthorne-journey && make maps    # compiles all 100 .tmx -> .lua
```
`bin/` and `src/maps/*.lua` are **gitignored** — build artifacts, never commit them. With maps
compiled, the **full suite is 91 passed / 0 failed / 0 skipped** (the previously-skipped
`test/test_maps` now runs). Rebuild maps at the start of any session that needs map-dependent
tests or wants to load real levels.

---

## 2. Repo & access reality — ✅ VERIFIED

| Repo | Role | State |
|---|---|---|
| `8bitgentleman/hawkthorne-journey` | **the fork** | `master` = pristine mirror of upstream (clean 11.5); **`develop`** = the live trunk. ~28 feature branches of stranded work. |
| `hawkthorne/hawkthorne-journey` | **upstream** (org) | Dormant, last commit 2024-11-26. Also 11.5. |
| `niamu/hawkthorne-return` | separate Clojure browser-MP rewrite | Abandoned 2017. Reference only (§7c). |

- ✅ **Push works** on the fork (v1's 403 fear is gone — the last session pushed twice).
- ⚠️ **GitHub MCP tools are scoped to the fork only.** Reading upstream issues/PRs (where the
  history lives) via `mcp__github__*` returns "repository not configured." **Workaround that
  worked:** `WebFetch` on the **HTML** page (`https://github.com/hawkthorne/hawkthorne-journey/
  pull/NNNN`). The `api.github.com` endpoints return 403 through the proxy; the HTML pages
  render fine. Use HTML-page WebFetch for any upstream thread you need to read.

**Fork feature-branch inventory (📎 INHERITED, ~28 — the stranded-work goldmine):**
`acorn_flame` (#2535) · `caveblocks` (#2491) · `teacher-lounge` (#2530) · `hippy_grab` (#2534) ·
`paintball` (#2481, real WIP) · `blacksmith_burned` · `VoLBrews` · `castle-hawkthorne-tower` ·
`newcastletileset` · `village-forest-maze` · `santas-grotto` · `underwater2` · `oxygen` ·
`notes-inventory` · `minimal-hud-redesign` · `moneymoneymoney` · `multi-map` · `leaderboard` ·
`mobile` · `piZero` · `npc-gravity` · `hammer` · `bomb` · `showHide` · `love10` ·
`LoubiTek-acorn` · `fix-neil`. Categorize each into **revive / salvage-parts / archive** before
touching. Only "revive" branches enter the per-feature-PR loop.

---

## 3. Work completed (apply-first is already done; here's what landed)

### #2608 — stuck blacksmith shop menu ✅ FIXED, tested, pushed
- **Root cause (verified in code):** `src/shopping.lua` advertises "PRESS \<ATTACK\> TO GO BACK"
  on every window; ATTACK backs out of the items window (→categories) and purchase window
  (→items), but the **top-level categories window had no ATTACK handler** (only RIGHT/LEFT/JUMP).
  The only real exit was START/Escape, never surfaced → soft-lock. A real user was stuck (Aug 2025).
- **Fix:** added an `elseif button == "ATTACK"` branch to `state:categoriesWindowKeypressed`
  doing `Gamestate.switch(self.previous)` + reset `buyAmount`/`sellAmount` + `confirm` sfx —
  mirroring the existing START handler.
- **Test:** `src/test/test_shopping.lua` (3 cases) — ATTACK exits, START still exits, nav keys
  don't. Stubs `Gamestate.switch`/`sound.playSfx` via the shared cached module tables.

### Collision family — #2456/#2578 VERIFIED ✅ · #2427 OPEN/UNFIXED ⚠️
- ✅ **Merged PR #2584 ("Addresses two common collision issues", Jun 2022, closes #2456/#2578)
  is present and intact in the current tree** (`ff9fe9c`): the `move_y` downward guard
  (`slope_y >= new_y`), `Player:canStand`/`attack(map)`, and the `level.lua` map plumbing are
  all in place. Follow-up `#2590` (`7ea098f`) also present.
- ✅ That fix shipped **with zero automated coverage** — its author wrote on-thread *"I'm not
  sure how to have a repeatable test with being hit by a bat."* Added `src/test/
  test_collision_ceiling.lua` (3 tests) pinning the underlying `collision.move_y` /
  `collision.stand` behaviour. **Proven genuine:** reverting the `slope_y >= new_y` guard makes
  the key test fail with the exact bug symptom (player warps y=30 → y=12); with the guard it passes.
- ✅ **#2578 / #2456 — now VERIFIED end-to-end (PR #48, `ceiling-collision-scenario-tests`).**
  Added `src/test/test_collision_ceiling_scenario.lua` (3 tests) that drive the **real** Level +
  Player update loop through the scenario harness: the actual bat knockback impulse
  (`player.velocity.y = -450`) into a low ceiling stops cleanly at the underside and never clips;
  the "ceiling edge + gravity down-tick" warp is pinned (reverting the `slope_y >= new_y` guard
  fails it — player warps box-top 246 → 199, i.e. clips up onto the ceiling); and `Player:canStand`
  refuses to stand up into a low ceiling. This is the gameplay-level companion the #2584 author
  said he couldn't write. Suite: **98 passed** (was 95).
- ⚠️ **#2427 — CORRECTION: this is OPEN and UNFIXED, not "already fixed."** The v2 claim above
  ("strong evidence both are fixed, close as resolved") was **wrong for #2427**: PR #2584 closed
  #2456/#2578, NOT #2427. The #2427 thread (issue, not PR) is open with no closing commit and no
  maintainer verdict. It is a real, timing/geometry-dependent bug: "falling through moving
  platforms when crouching and spamming attack/interact," and the reporter noted "changing the
  movement line slightly can resolve it." **Do NOT close it.**
  - **Reproduction attempt (parked, PR #48 session):** the scenario harness *can* drive
    moving-platform levels once you run the `node:enter()` hooks that `Level:restartLevel()` skips
    (they build each platform's Bspline — `movingplatform.lua:110`; without them `update` crashes
    at `:194 attempt to index field 'bspline'`). Vertical platforms are the candidates
    (frozencave mp2/mp3, black-caverns mp1/mp6; horizontal ones like black-caverns-2's never
    stress the fall-through). Riding a vertical platform **downward** with crouch + attack/interact
    spam for 240 frames did NOT reproduce (player stayed glued, feet-gap 0). Two harness gaps block
    a faithful repro and must be solved first: (1) **reliable platform attachment** — the player
    only rides while `player.currentplatform == platform`, which is set by HardonCollider firing
    `MovingPlatform:collide` on bb overlap; spawning the player *on* a platform doesn't reliably
    trigger it, so upward-motion trials were invalid. (2) **state leak** — `map.moving_platforms`
    accumulates across scenarios in one test process (black-caverns-2 reported 5 platforms after
    black-caverns ran); a clean harness extension needs teardown for this or it causes the exact
    order-dependent flakiness this doc warns about elsewhere.
  - **Next step for #2427:** a dedicated harness task (land-player-on-platform helper + moving-
    platform teardown), then sweep the vertical platforms for the crouch+spam fall-through, then
    fix. It is NOT a quick verify.

### Scenario harness — headless gameplay verification ✅ BUILT, tested, deterministic
This is the big one for AI-driven work: **agents can now assert on real gameplay** (physics,
movement, jumping) without a window or a human. Before this, tests could only exercise pure
logic (cheats, inventory, collision math); anything that needed a *running level with a player*
had no harness.

- **`src/test/scenario.lua`** — boots a real `Level` headlessly, binds a fresh player via the
  engine's own `restartLevel()`, injects scripted input, and steps `Level:update` at a fixed
  `dt` (1/60) so runs are reproducible. API: `Scenario.new(level)`, `spawn(x,y)`,
  `hold/release` (continuous keyboard actions), `press/lift/tap` (discrete key events),
  `step(frames)`, `teardown()`.
- **`src/test/test_scenario.lua`** — 4 self-tests proving it drives real gameplay: gravity makes
  a mid-air player fall, holding RIGHT walks the player, a JUMP press produces upward velocity
  once grounded, and teardown restores the keyboard. These double as usage examples.
- **Fixture rule (important):** use a plain side-scrolling level with a `collision` tilelayer
  (the tests use **`greendale-biology`**). **Do NOT use `studyroom`** — it's a `floorspace`
  room with no collision layer, so the player falls straight through the floor. Levels with
  moving platforms (`black-caverns`) also need node init the harness doesn't do (bspline crash).
- **Two shared-singleton hazards found & fixed** (the pre-AI architecture bites here):
  1. `test_cheat`/`test_inventory` permanently stub `Player.refreshPlayer` on the cached module
     to skip the collider dependency, and never restore it. The harness needs the *real* method
     to build bounding boxes, so `player.lua` now stashes a pristine `Player.realRefreshPlayer`;
     the harness swaps it in for its lifetime and restores whatever it found on teardown.
  2. `Player` is a module-level singleton; `test_cheat` grabs it once at load and expects it to
     persist across its tests. The harness's `Player.kill()` was destroying it, causing
     **order-dependent flakiness** (green ~2/3 of runs). Added `Player.getSingleton()` /
     `Player.setSingleton()` — the harness snapshots the singleton on setup and restores it on
     teardown, so other suites are unaffected regardless of test-run order. **Now green 5/5.**
- **Result:** `make test` = **95 passed, 0 failed, 0 error(s)** (was 91), deterministic across
  runs. `player.lua` and both test files lint clean.
- **Production footprint** (kept minimal, all documented, none used at runtime): three additions
  to `src/player.lua` — the `realRefreshPlayer` reference and the `get/setSingleton` pair.

### Supporting housekeeping ✅
- **`CLAUDE.md` created at repo root** — documents the branching model, the **macOS-native,
  self-bootstrapping** build/test/lint flow (the Makefile auto-downloads the LÖVE binary +
  `tmx2lua` to `bin/`; **no `apt-get`/`xvfb` needed** — corrects v1's Linux-centric assumptions),
  the test harness, architecture, and gotchas.
- **Stale branch `claude/new-session-q1adh6` deleted** (confirmed already merged into `develop`
  before deletion — its work is the #2608 fix + collision tests above).

---

## 4. ✅ VERIFIED corrections to v1's research (I read these threads firsthand)

**These overturn specific v1 claims. Do not act on v1's version of them.**

| Item | v1 said | ✅ What the actual thread says | Action |
|---|---|---|---|
| **#1913 enemy follow-freeze** | "niamu blessed a stand-beside-attack design; CalebJohn: 'shouldn't be too hard' — **best next code win.**" | Issue #1913 is **open with ZERO comments** (author CalebJohn: "not really sure what this would look like"). No blessing, no such quote exists in it. | **Downgrade.** Not a blessed quick win. |
| **PR #2229** (the real attempt at #1913/#2036) | (not clearly flagged) | **niamu CLOSED it (May 2015) as "too big of a core gameplay change… a level design issue instead."** 8bitgentleman & niamu openly disagreed on approach in-thread. | The one time this was tried, the lead maintainer backed it out. **Needs a fresh design decision from the owner before any revival — do not just re-implement.** |
| **#2491 `caveblocks`** | Ship level+HP changes, drop the manual black outlines (niamu's SVG objection). | ✅ **Accurate.** niamu supports lower forest-block HP; niamu + edisonout object to hand-painted outlines (keep art "pure" for future SVG/programmatic borders); 8bitgentleman conceded but "the tileset and level changes are solid." | Ship level + HP-to-1 only; rework/drop outlines. **Genuinely the cleanest quick win now.** |
| **#2584 / #2456 / #2578** | #2578 "partially fixed, bat path unverified." | ✅ **Fixed + now verified end-to-end.** Merged fix intact; unit tests + scenario tests (PR #48) drive the real Level/Player loop, including the bat-knockback ceiling case the author couldn't test. | Re-confirm done; close #2456/#2578. |
| **#2427** | "likely already fixed." | ❌ **WRONG — open & unfixed.** #2584 closed #2456/#2578, not #2427. Timing/geometry-dependent moving-platform fall-through; no closing commit, no maintainer verdict. | **Do NOT close.** Needs harness work + a real fix (see §3). |

---

## 5. 📎 INHERITED strategic context (from v1 — NOT re-verified; treat as leads)

*The following came from v1's research pass. Given §4 showed v1's summaries are sometimes wrong,
**re-read the actual thread (HTML-page WebFetch) before acting on any of these.***

### 5a. Stranded PR / branch revival ranking (📎)
1. **#2491 `caveblocks`** — best quick win (level+HP only; drop outlines). *This one is ✅ verified — see §4.*
2. **#2442 New Player HUD** — blockers (📎): flashing potion icons desync (wants static art);
   ammo-text spacing; effect-icon mismatch. Author went silent. High value.
3. **#2534 `hippy_grab`** — real bugs found by a community tester (player frozen when grabbed;
   phantom attack; airborne-blink). Never got a maintainer verdict — the owner must weigh in.
4. **#2535 `acorn_flame`** — author called it a *discussion prompt* ("teach mechanics without
   text; we never came to a consensus"), not a finished feature. Downgrade.
5. **#2530 `teacher-lounge`** — big content win but 4 open design questions + needs splitting into
   smaller PRs. Not a quick win.
6. **#2439 Boss HUD** — 📎 dead (author disowned it; bitrotted, missing `qfoBoss` asset). Reference only.
- **#2315 villager dialog** is a *spec*, not code — reviving = implementing from scratch.

### 5b. Content roadmap (📎)
- **ADR voice actor (#2211):** niamu personally held the (real episode ADR) actor's contact,
  willing to record; blocker = the script. Dormant since 2015 — **perishable, confirm
  reachability before investing writing time.**
- **Accepted story spine = the ADR script:** per-island Cornelius "head" cutscenes as
  pinch-points that branch on Pierce vs. Not-Pierce; keep the Pierce-direct opening. Nailing this
  one script unblocks story + audio together.
- **"NPCs behave like enemies"** (killable, fight back, pursue) underpins blacksmith
  repercussions (#2195), the "join Cornelius" heel-turn, and **Paintball (#2481)**. Build once, reuse thrice.
- **Paintball (#2481):** recoverable, not greenfield — owner had "almost all the code," full
  design (inventory→paintball gun; Greendale NPCs turn hostile; City College Dean as boss),
  accepted sfx. WIP branch `paintball`. Missing art: rollerblading/glee-club/ambient-student enemies.
- **Gay Island (#2341):** agreed it needs a redesign; enemies rehomed not deleted. Sprites drawn;
  #2341 has zero comments (never advanced past the pitch) — pure integration work.
- **Hilda/blacksmith/carpenter questline (#2315):** richest designed block; gated on multi-quest
  (#2495). Accepted: visible Harvest-Moon heart/smiley affection meter; trees cut via *interact*
  (not attack) or just make sticks abundant.

### 5c. Decisions Ledger (📎 — what maintainers reportedly already settled)
*Honor or overturn knowingly; as the new de-facto maintainer with AI bandwidth the owner may
legitimately lift old constraints — but deliberately, not by accident.*

**✅ Reportedly ACCEPTED:**
- **"Consolidate, don't expand"** standing mandate (moratorium on new content; #1407, reaffirmed
  #2206). Frame new work as *finishing/tightening* existing systems — **unless the owner
  consciously lifts it.**
- Story canon: NPCs *almost became sentient / Abed's additions* — NOT a heroic "free the
  townspeople" quest.
- Per-island Pierce/Not-Pierce Cornelius cutscenes; keep the Pierce-direct opening.
- NPCs-as-enemies pillar; the "join Cornelius" heel-turn after killing the blacksmith.
- Blacksmith repercussions (#2195): vendor price hikes + witness mechanic.
- Wall/rack weapons realized as real pickups (#2173), safe because item persistence (#2170) merged.
- Multi-quest (#2495) accepted but **gated on a quest-module refactor**; niamu's rule: "any
  multi-part quest must be a single quest item."
- Visible Harvest-Moon heart/smiley affection meter.

**❌ Reportedly REJECTED — don't re-propose blind:**
- "Liberate Hawkthorne from evil King Cornelius" as the main arc.
- Editing out the Pierce-direct opening for "inclusiveness."
- Blocking Hilda's marriage after you kill the blacksmith (niamu veto; she weds regardless).
- Inventory-shrink / weapon-encumbrance anti-farming (niamu veto; solved by item persistence).
- Hiding the affection level (visible meter won).
- Cutting trees via the *attack* button (collision ambiguity) — use interact / abundant sticks.
- Forced Hilda flee/chase cutscene ("cutscenes are a nightmare to code").
- Deleting manicorns/wipes (rehome them in the Gay Island redesign).
- Heavy Community references for their own sake (allowed only if diegetic + subtle).

---

## 6. Codebase architecture snapshot (📎 mostly, engine ✅)

- **Engine:** ✅ LÖVE 11.5 (`src/conf.lua`), physics module disabled (custom tile collision).
  2× integer scale (logical 528×336, window 1056×672).
- **Entry:** `src/main.lua` owns LÖVE callbacks, CLI, input routing.
- **Two state machines:** `src/vendor/gamestate.lua` (hump — screen FSM; every map is a
  gamestate) + `src/hawk/statemachine.lua` (entity/behavior FSM).
- **Levels:** ~100 Tiled `.tmx` in `src/maps/`, compiled to Lua by `tmx2lua` (see §1).
  `src/level.lua` = generic level gamestate.
- **Player/entities:** `src/player.lua` (~36KB). Entities are "nodes" in `src/nodes/`; base
  `enemy.lua`/`npc.lua`. Character *skin* separate from Player object (20 characters).
- **Input:** `src/inputcontroller.lua` — action-based abstraction (UP/DOWN/LEFT/RIGHT/JUMP/
  ATTACK/INTERACT/SELECT/START), remappable, kbd+gamepad+joystick. The key enabler for local co-op.
- **`src/hawk/`** = mini-stdlib (application singleton, store, gamesave, i18n, json, middleclass
  OOP, collision, statemachine).
- **Collision:** `src/hawk/collision.lua` — `move_x`/`move_y`/`stand`/`scan_*`. The #2584 guard
  lives in `move_y`'s downward block branch (`slope_y >= new_y`). Now unit-tested (§3).
- **Known tech-debt umbrella (📎):** #2544 (move map loading to STI + newer HardonCollider) —
  the biggest structural lever *and* the biggest single effort; v1 tied fullscreen distortion
  (#307) and collision edge-cases to it.

---

## 7. Multiplayer (📎 INHERITED from v1's deep dive — re-scope before committing)

- **7a. Local co-op** (~2 wk spike, 6–8 wk polished): input already action-based; enemy targeting
  already parameterized; collision boxes instance-tagged. Blockers: three singletons — `Player`,
  `InputController.get`, global `camera`. **Latent bug to fix regardless:** `Player:update`/`:die`
  reference module-global `player` instead of `self` (`player.lua` ~497-510, 687) — becomes a
  real 2-player bug. Recommended Phase-1: de-singleton Player+Input, shared zoom-to-fit camera
  with a leash (not split-screen), nearest-living-player targeting, per-player death/revive.
- **7b. Remote MP** (months): lockstep is off the table (variable timestep, unseeded rng, float
  physics). Recommended: host-authoritative state replication with `enet` (LÖVE bundles it),
  relay actions, interpolate remotes. **#1 hidden cost: retrofitting a fixed timestep — prove it
  in a standalone spike before sockets.**
- **7c. `niamu/hawkthorne-return`:** the lead maintainer's own Clojure browser-MP attempt,
  abandoned 2017 (his last branch tore the MP server back out). **Reference only** — but its
  architecture (authoritative server / clients-send-inputs / same-physics-server-side / per-level
  interest filtering / fixed tick) independently matches 7b, corroborating that design.

---

## 8. Recommended sequencing (momentum ladder)

1. **Housekeeping:** confirm `develop` is the fork's default branch (owner's manual step, §0).
   The shop fix + collision tests are already on `develop`. `claude/new-session-q1adh6` can be
   deleted once you've confirmed `develop` has everything.
2. ✅ **#2491 `caveblocks`** — DONE. Forest boulder HP 3→1 landed on `develop` (`19c97d9b`,
   98 passed). Black-caverns art + material.lua sprite-override rejected (vetoed outlines / scope
   creep). See §11.
3. ✅ **#2578 / #2456 verified end-to-end** (PR #48) — done. **#2427 is open & unfixed** (not a
   close): it needs a dedicated harness task (reliable land-player-on-platform + moving-platform
   teardown) then a real fix. See §3 for the parked investigation + repro obstacles.
4. **#2442 New HUD** — ✅ thread verified (this session): the PR is **open/stalled, NOT rejected**
   (last activity Sept 2015). edisonout's fix-list, which the owner agreed with: swap flashing
   potion icons → static images, fix the saving-icon/weapon-ammo overlap, fix weapon-amount
   spacing. 2015 code won't apply to today's tree — treat as "reimplement the agreed fixes," not
   "revive the branch."
5. **The fork in the road (owner's creative call):** either content ("feel like the show" — Gay
   Island integration, Hilda questline + quest-module refactor, revive Paintball) and/or **local
   co-op Spike A**. First decide consciously whether to keep or lift "consolidate, don't expand."
6. **Big swing:** remote MP, gated behind the fixed-timestep spike.

**Do NOT lead with #1913** (v1's top pick) — §4 shows it's unblessed and the one attempt was
backed out as too invasive. If the owner wants it, it needs a fresh design decision first.

---

## 9. Contributor / maintainer map (📎, for weighting old discussions)

| Handle | Real name | Role |
|---|---|---|
| `niamu` | Brendon Walsh | **Lead maintainer**; most authoritative verdicts; ADR-actor contact; author of `hawkthorne-return` |
| `8bitgentleman` | **Matt Vogel** | **The owner**; author of much of the open backlog |
| `CalebJohn` | Caleb John | Core contributor |
| `kyleconroy` | Kyle Conroy | Early lead (called the #1407 moratorium) |
| `edisonout` | — | HUD/dialog/quest-refactor work |
| `Protuhj` | — | Authored the merged #2584 collision fix (2022) |
| `bucketh3ad` | — | New HUD (#2442) |
| `jimp-29` / `didory123` | — | Level design; brokered the Gay Island dispute |

---

## 10. Quick-reference: session bootstrap checklist

```bash
# 1. Confirm engine + tooling
love --version                      # expect LOVE 11.5   (apt-get install -y love if missing)
which lua || sudo ln -sf /usr/bin/lua5.4 /usr/local/bin/lua

# 2. Build tmx2lua from source + compile maps (only if you need map-dependent tests/levels)
git clone --depth 1 https://github.com/hawkthorne/tmx2lua /tmp/tmx2lua-src
(cd /tmp/tmx2lua-src && go build -o tmx2lua .) && mkdir -p bin && cp /tmp/tmx2lua-src/tmx2lua bin/
make maps

# 3. Green baseline  (macOS-native — the Makefile self-bootstraps LOVE + tmx2lua into bin/;
#    steps 1-2 above are the Linux path and are NOT needed on macOS. See CLAUDE.md.)
make test                           # expect 95 passed, 0 failed, 0 error(s)

# 4. Base YOUR harness-assigned branch on develop (the trunk), PR into develop; never commit
#    directly to master or develop.   git fetch origin && git checkout -b <your-branch> origin/develop
./scripts/lualint.lua -r src/<file>.lua       # lint before commit

# 5. To read an UPSTREAM issue/PR thread (MCP is fork-scoped): WebFetch the HTML page
#    https://github.com/hawkthorne/hawkthorne-journey/pull/<N>   (api.github.com is 403; HTML works)
```

---

## 11. #2491 `caveblocks`: surgical port ✅ DONE

**Landed directly on `develop`** (commit `19c97d9b`). `make test` → **98 passed / 0 failed**. TMX
validates. Owner's workflow: **all work stays on `develop` on the fork — no feature branches, no
PRs (upstream or otherwise).**

**What shipped — the ONE blessed change:** in `src/maps/forest.tmx`, the three `breakable_block`
boulders (objects at x/y = 1704/336, 1752/336, 2592/384; all `sprite=boulder`) drop `hp` **3 → 1**.
That's the entire diff — 3 lines, zero format churn (develop's `forest.tmx` is still the pre-2015
format, so none of the branch's `id=`/`renderorder`/`nextobjectid` noise came along).

**Where HP lives (answered):** NOT a central constant. Each `breakable_block` authors its own `hp`
in the map object's properties; `breakable_block.lua:94` reads `node.properties.hp or frames`
(`frames` = sprite-width ÷ block-width is the only fallback, used when a block sets no `hp`). So the
`.tmx` is genuinely the only place to change it — no Lua edit needed.

**Rejected (evidence-based), per the hard rule below:**
- **Black-caverns art (`5c81269a`)** — all 3 binary files (`blackcavernsplatform.png`,
  `sandplatformbreak.png`, `black-caverns.png` tileset). Extracted both versions and pixel-diffed:
  each just overlays develop's clean art with busy scribbly crack/vein linework — **exactly the
  hand-painted outlines niamu/edisonout vetoed**. Regression, not improvement. Left out.
- **`material.lua` sprite-override feature** — scope creep; HP lives in the `.tmx`, nothing blessed
  depends on it. Left out.

**Intentionally NOT touched (out of blessed scope):** other maps still carry higher-HP breakable
blocks — `forest-hidden.tmx` (one `hp=3`, one `hp=4`), `test-level.tmx` (one `hp=3`),
`valley-hills{,-2}.tmx` (two `hp=2` each). The blessed commit only edited `forest.tmx`, so these
were left as-is. Owner confirmed: keep it to `forest.tmx` only. If "forest boulders shouldn't be a
slog" is the real intent, `forest-hidden.tmx` is the natural follow-up candidate.

--- historical recon (kept for reference) ---

**The task was:** hand-port ONLY the maintainer-blessed changes from `origin/caveblocks` onto a
fresh branch cut from `develop`. Owner's explicit instruction: *"be careful with 2491 and only
bring in the very specific parts we need."*

### ⛔ HARD RULE: do NOT merge, rebase, or cherry-pick `origin/caveblocks`.
Recon (`git diff` vs merge-base, this session) shows why:
- The branch **forks from a 2015 merge-base and is 100 commits behind `develop`** (~11 years drift).
- It touches **68 files, mostly stale binary art reverts** that would **regress current sprites** —
  e.g. `weapons/axe.png` 18550→**655 B**, `dagger.png` 19013→**395 B**, `keyshardbottom.png`
  2994→**211 B**. These are old/placeholder art the current tree long since replaced. A merge or
  wholesale cherry-pick drags all of it in. **Reject the art reverts and the hand-painted outlines
  (niamu/edisonout vetoed outlines — keep art "pure").**

### The 4 branch commits (for reference, NOT to cherry-pick):
`2ba002ca` Rock HP and Interactable node visibility · `ad926317` foreground visibility ·
`01a15473` bone items, tile tweaks, foreground fixes · `5c81269a` black-caverns tileset + platforms.

### In-scope (blessed): port these hunks by hand onto a fresh `develop`-based branch
1. **Forest-block HP-to-1** — the actual reason niamu blessed it. ⚠️ **NOT in `material.lua`.**
   Its `material.lua` hunk is a *sprite-override feature* (`node.properties.sprite/width/height`),
   not an HP change. **First job: find where block/rock HP actually lives** — likely a
   `src/nodes/materials/*.lua` file (e.g. `rock.lua`) or the tile `properties` in `forest.tmx`.
2. **Black-caverns tileset + platform level work** (`5c81269a`) — verify it's still an improvement
   over current `develop` art before porting; it may be superseded.
3. **Decide consciously** whether the `material.lua` sprite-override feature is wanted at all — it's
   a clean addition (develop's `material.lua` == the 2015 base, so it applies without conflict) but
   it's scope creep beyond "lower the block HP." Default: **leave it out** unless a blessed change
   depends on it.

### Verify each ported hunk
`make test` (baseline **98 passed**) after each change; `make run` and walk the affected level
(forest / black-caverns) to eye-check. Lint touched `.lua`. One PR into `develop` when green.

---

*End of handoff v2. Start at §0, do the branch merge, then §8. For the immediate next task see §11.*
