# Ipe Room Planner: handoff for Claude Code

## What this is
A single-file 3D planner (index.html, Three.js r160 from jsDelivr) for a black music room
with floating ipe slat panels, back-lit LEDs, a double-walled control/vocal booth,
a draped fabric ceiling and layered rugs. It includes per-wall cut sheets, a full
materials/cut list and a build guide. No build step: open index.html in a browser.

## Goal
Publish it as a simple static website on GitHub Pages from Jerame's personal GitHub
so friends can open it from a link on their phones.

## Steps for Claude Code
1. `git init` in this folder, commit index.html, README.md, CLAUDE.md.
2. Create a public repo on the personal account, e.g. `gh repo create ipe-room-planner --public --source=. --push`.
3. Turn on Pages from the main branch root:
   `gh api -X POST repos/{owner}/ipe-room-planner/pages -f "source[branch]=main" -f "source[path]=/"`
4. Wait for the first Pages build, then print the URL: `https://<user>.github.io/ipe-room-planner/`.
5. Open the URL on a phone-sized viewport and confirm the 3D view, Build guide and Controls load.

## Code map (all in index.html)
- Constants and room geometry: `WALLS`, `AMPW`, `AMPSIDES`, `BOOTHW`, `RUNS` (every ipe run).
- Panel math: `layout()` (panel sizes, rails, weights, stats), `railYs()`, `splitSlats()`.
- Booth framing: `frameWall()`, `boothFraming()`.
- 3D: `buildRoom()`, `buildExploded()`, `buildSection()`, lighting in `applyLighting()`.
- Outputs: `wallSheet()` (per-wall cut sheet), `buildCutList()`, `buildGuide()`.
- Units are inches everywhere. Plan origin is the NW interior corner, +X east, +Y south.

## Things to keep
- No em dashes in any user-facing text.
- Keep it self-contained and buildless. `index.html` plus `vendor/` is the whole thing, and
  Pages serves it as is. three.js r160 is vendored, unmodified, under `vendor/three/`,
  because a planner you open at the lumberyard cannot need signal. Do not put it back on a
  CDN, and do not add a bundler.
- Wall lengths and the overhang were measured on site 2026-11-15 and the code says so at
  `ROOM_W` and `OH_W`. Stud and obstacle positions are still scaled from the hand drawing:
  field-measure those before trusting cut lengths.
- The board length is a setting now (`state.stock`, `STOCK_LENGTHS`), with a confirmed /
  assumed tag beside it, because the whole buy is packed onto it. It still says assumed.
  Tap 8 ft to see why it matters: at a true 96" the main band cannot be cut at all.
- One spare rate (`SPARE`) and one screw length (`SCREW`, derived from the rail and board
  thickness) feed every line that names them. Do not restate either as a literal.
