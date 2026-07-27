# CLAUDE.md

"Journey to the Center of Hawkthorne" — a LÖVE (Love2D/Lua) recreation of the pixel game from
Community's *Digital Estate Planning*. This is the `8bitgentleman` fork being modernized. LÖVE
**11.5**, Lua 5.4.

## Branching model

- **`master`** — pristine mirror of `upstream/master` (`hawkthorne/hawkthorne-journey`, dormant).
  **Never commit here.** Sync only via `git fetch upstream && git checkout master && git merge
  --ff-only upstream/master`.
- **`develop`** — the fork's real trunk and where **all work lands directly**. Commit straight to
  `develop` (owner's workflow); the suite must be green + lint clean first. **No feature branches,
  no PRs** (neither upstream nor within the fork). The owner pushes `develop` to their fork.

## Versioning & changelog

The fork continues upstream's SemVer line (last upstream release: **v1.1.0**, 2024-11-22).
Versions are **local, lightweight git tags** (`vX.Y.Z`) — **we do not cut GitHub releases**.
`CHANGELOG.md` (Keep a Changelog format) is the human record; every tag has a matching
`## [X.Y.Z]` section, and the current changelog starts at **v1.1.1** (July 2026).

- **Every user-facing commit** — a fix, a gameplay/balance change, a new feature — adds a bullet
  under **`## [Unreleased]`** in `CHANGELOG.md`, under the right heading: `Added` / `Changed` /
  `Fixed` / `Removed` / `Deprecated`. A non-standard **`Internal`** heading holds dev-only tooling
  and tests (kept in the log, but out of the player-facing headings). Cite the issue number.
- **Pure bookkeeping** — handoff-doc edits, branch triage, record corrections — gets **no**
  changelog entry and **no** tag.
- **Cutting a version:** when the accumulated `[Unreleased]` work is worth a release, rename that
  heading to `## [X.Y.Z] - YYYY-MM-DD`, add a fresh empty `## [Unreleased]` above it, update the
  compare-link footnotes, and tag the commit: `git tag vX.Y.Z`. Choose the bump per SemVer —
  **patch** = bug fix / balance, **minor** = new backwards-compatible feature/content, **major** =
  save-breaking or removed content. Tags stay local; the owner may `git push --tags` at will.
- **Don't let `[Unreleased]` silently pile up:** right after a commit that completes a
  self-contained feature arc (the last slice of a multi-part port, the last phase of a spike,
  a standalone fix/feature with nothing left pending) — as opposed to a commit that's
  mid-arc (an intermediate phase, a prep step, a WIP slice) — proactively ask the owner whether
  to cut a version now, instead of waiting for a manual pass to reconstruct boundaries later.
  This is a nudge, not an auto-cut: the owner still decides whether and how to bump.

## Build / test / lint

Everything is driven by the `Makefile` (macOS + Linux; `make.ps1` is the Windows equivalent). The
Makefile **auto-downloads** the LÖVE binary and the `tmx2lua` map compiler into `bin/` on first
use, so a fresh checkout bootstraps itself over the network — no manual install needed.

```bash
make test        # LÖVE runs src --test; depends on `maps`. THE command to verify changes.
make run         # build maps, then launch the game (bin/love src)
make maps        # compile src/maps/*.tmx -> *.lua via bin/tmx2lua (required before run/test)
make lint        # lualint (relaxed) over src/**, excluding vendor/ and test/
make validate    # lint + scripts/validate.py (JSON/TMX/XML parse checks) — this is what CI runs
make clean       # wipes bin/ build/ venv/ node_modules/ src/maps/*.lua
```

- **CI** (`.github/workflows/build.yml`, Ubuntu 24.04, PRs → `master`): `xvfb-run make clean
  validate test`. Match this locally before pushing.
- **Lint one file:** `./scripts/lualint.lua -r src/<file>.lua` (exit 0 = clean; `-r` = relaxed).
- **Python tooling** (`validate`, `contributors`) needs a `venv`: `make venv` (only dep is jinja2).
- macOS can't build the Linux AppImage; that binary is produced on Linux/CI only.

## Tests

- Framework: **lunatest** (vendored, `src/test/lunatest.lua`); LÖVE wrapper `src/test/lovetest.lua`.
- Tests live in `src/test/test_*.lua`. Auto-discovered by filename prefix `test_`; test
  **functions** must also be named `test_*`. Assertions: `assert_true/false/equal`.
- **No per-file selector** — `--test` runs the whole suite. To iterate on one file, narrow
  temporarily. Baseline is **95 passed / 0 failed** with maps compiled.
- Common stubbing pattern: replace functions on the shared cached module tables (e.g.
  `Gamestate.switch`, `sound.playSfx`) — see `src/test/test_shopping.lua`.
- ⚠️ **Test files are discovered in filesystem order, which is NOT deterministic**, and every
  `require`d module is cached and shared. A suite that stubs or mutates shared global state at
  module load (or that kills a singleton) and doesn't restore it will cause **order-dependent
  flaky failures** in whatever suite happens to run after it. Save-and-restore anything global.

### Verifying gameplay changes — the scenario harness
`src/test/scenario.lua` is a **headless gameplay-driving harness** — this is how an agent proves a
gameplay change works without a window or a human. It boots a real `Level`, binds a fresh player
via the engine's own `restartLevel()`, injects scripted input, and steps `Level:update` at a fixed
`dt` (1/60) for reproducible physics. See `src/test/test_scenario.lua` for worked examples.

```lua
local Scenario = require 'test/scenario'
local s = Scenario.new('greendale-biology')  -- fixture: a plain side-scroller (see below)
s:step(6)                                     -- settle onto the floor
s:hold('RIGHT'); s:step(30); s:release('RIGHT')   -- continuous input (keyboard poll)
s:press('JUMP'); s:step(1); s:lift('JUMP')        -- discrete input (key events)
assert_true(s.player.velocity.y < 0)
s:teardown()                                  -- ALWAYS: restores keyboard + Player singleton
```

- **Fixture rule:** use a plain side-scrolling level with a `collision` tilelayer (e.g.
  `greendale-biology`). **`floorspace` rooms (`studyroom`) have no collision tilelayer** so the
  player falls through the floor; levels with moving platforms (`black-caverns`) need node init
  the harness doesn't perform. Pick simple flat levels for physics assertions.
- The harness swaps in the real `Player.realRefreshPlayer` and snapshots/restores the `Player`
  singleton on teardown, so it coexists with the singleton-mutating suites below.

## Architecture

- **Entry:** `src/main.lua` — owns all `love.*` callbacks, CLI parsing (`vendor/cliargs`), and
  translates raw keys → abstract actions before dispatching to the active gamestate. `--test`/`-t`
  sets `testing=true` and short-circuits update/draw/input.
- **Two state machines:**
  - `src/vendor/gamestate.lua` (hump-style) = the *screen* FSM. Every map, menu, and minigame is
    a gamestate; navigate with `Gamestate.switch(...)`.
  - `src/hawk/statemachine.lua` = a generic entity/behavior FSM (events/transitions).
- **Levels:** `src/level.lua` is the core gameplay gamestate — loads a compiled map (`vendor/tmx`),
  builds a collider (`vendor/hardoncollider`), instantiates nodes, and dispatches `on_collision`
  to `node:collide(...)`.
- **Two distinct collision systems — don't conflate them:**
  - **Terrain / floors / walls = tile-based**, handled by `src/hawk/collision.lua`
    (`move`/`move_x`/`move_y`/`stand`). The player moves through the world via
    `Player:updatePosition(map, dx, dy)` → `collision.move(map, ...)`, which reads the map's
    tilelayer **named `collision`** and resolves against tile ids (incl. slopes/one-way
    platforms). **HardonCollider is NOT what stops the player from falling through the floor.**
  - **Node interactions = HardonCollider** (`vendor/hardoncollider`). The player's `top_bb`/
    `bottom_bb` and each node's shape are registered here; overlaps fire `level.lua`'s
    `on_collision` → `node:collide(player, ...)`. This is enemies, doors, pickups, triggers — not
    terrain. `collider:update(dt)` (called in `Level:update`) is what fires these callbacks.
  - Some interior levels use a **`floorspace` objectgroup** (top-down-ish movement, e.g.
    `studyroom`) instead of a `collision` tilelayer entirely — a third movement model.
- **Player/entities:** `src/player.lua` (~36KB) + `playerAttack`/`playerEffects`/`character`.
  Entities are "nodes" in `src/nodes/` (~62: door, enemy, block, npc, key…, plus subdirs
  `enemies/ armor/ consumables/ materials/ cutscenes/`). Node pattern: table + metatable +
  `.new(node, collider, level)` factory, optional `:collide/:update/:draw`, marker flags like
  `isInteractive`/`isDoor`.
- **`Player` is a module-level singleton.** `Player.factory(collider)` creates-or-returns it;
  `Player.kill()` nils it; `refreshPlayer(collider)` (re)builds its bounding boxes against a
  level's collider. `getSingleton`/`setSingleton` exist for test harnesses to snapshot/restore it.
  Because it's shared and cached, tests that grab it at module load expect it to persist — see the
  test-order warning above.
- **`src/hawk/`** — the in-repo stdlib: `application` (singleton: config, 3 gamesave slots, i18n),
  `store` (JSON key-value save), `gamesave`, `collision` (`move_x`/`move_y`/`stand`/`scan_*`),
  `statemachine`, `middleclass` (OOP lib), `i18n`, `json`.
- **`src/vendor/`** — third-party: `gamestate`, `hardoncollider`, `anim8`, `tween`, `timer`,
  `TEsound`, `tmx`, `vector`, `cliargs`, `inspect`.
- **Input:** `src/inputcontroller.lua` — maps raw keys/gamepad/joystick to abstract actions
  (UP/DOWN/LEFT/RIGHT/JUMP/ATTACK/INTERACT/SELECT/START), remappable, persisted via `hawk/store`.
- **`src/app.lua`** = `require('hawk/application')()` — the global config/save/i18n singleton.

## Conventions

- 2-space indent, no tabs.
- **Requires** are slash-paths relative to `src/`, no extension: `require 'vendor/gamestate'`,
  `require 'hawk/i18n'`, `require 'nodes/door'`.
- **Two module patterns coexist:** game/vendor code uses `local T = {}; T.__index = T` + a `.new(...)`
  constructor; the `hawk/` stdlib uses **middleclass** (`middle.class('Name')`, `:initialize()`,
  `:include(mixin)`).
- **Lint** (`scripts/lualint.lua`) statically checks global usage. Relaxed mode flags *reads of
  undefined globals*. Use `declare`/`lint_ignore` helpers to silence intentional cases. `vendor/`
  and `test/` are exempt (so test-file lint is informational only).

## Gotchas

- **Compiled maps are gitignored** (`src/maps/*.lua`) — only `.tmx` is committed. Run `make maps`
  before `make run`/`make test` or levels won't load. `bin/` and `build/` are gitignored too.
- The real LÖVE config is **`src/conf.lua`** (root `conf.lua` is empty; the game runs from `src/`).
- Save data lives outside the repo in LÖVE identity `hawkthorne`; `--reset-saves` clears it.
- To read an **upstream** issue/PR thread, WebFetch the HTML page
  (`https://github.com/hawkthorne/hawkthorne-journey/pull/<N>`) — the GitHub MCP tools and
  `api.github.com` are scoped/blocked for upstream, but the rendered HTML works.
