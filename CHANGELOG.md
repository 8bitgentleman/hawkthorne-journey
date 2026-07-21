# Changelog

All notable changes to the `8bitgentleman` fork of *Journey to the Center of Hawkthorne*
are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions are
**local git tags** (`vX.Y.Z`) — there are no GitHub release objects. An `Internal` heading
(non-standard) records dev-only tooling and tests, kept out of the player-facing headings.

## [Unreleased]

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
