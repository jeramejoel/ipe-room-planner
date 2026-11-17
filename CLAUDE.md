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
- Keep it one self-contained file so Pages serves it as is.
- Wall lengths and the overhang were measured on site 2026-11-15 and the code says so at
  `ROOM_W` and `OH_W`. Stud and obstacle positions are still scaled from the hand drawing:
  field-measure those before trusting cut lengths.
- `STOCK=97` carries no provenance and the entire buy rests on it. The main band is cut at
  96", so a true 8 ft board does not fit. Confirm the real length with the supplier.
