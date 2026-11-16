# Build planner template

A single-file 3D planner for anything that ends in a cut list: a shelf, a workbench, a wall of panels, a booth. It is the engine of the ipe room planner (`jeramejoel/ipe-room-planner`, 15 to 16 November 2026) with the room taken out, so the next build starts with the tooling already working.

## Start a new one

```bash
./new-planner.sh "Garage Workbench"
```

That makes `~/Documents/dev/garage-workbench-planner/` with `index.html`, `check.sh`, a README and a first commit. Then edit the ITEM block and run `./check.sh`.

## What you write: the ITEM block

Only the first block of the first script changes per build.

- `dims`: every number from the site, a drawing or a decision, each tagged `measured` (with its date), `assumed` or `chosen`.
- `stock`: what you can buy. Boards carry thickness, width and the lengths sold; sheets carry thickness and sheet size.
- `controls`: sliders (`range`), switches (`toggle`) and choices (`seg`), in sections.
- `defaults` and `presets`: the settings the checks sweep.
- `build(S, D)`: returns `parts`, `context`, `warns` and `guide`. A part is a box: `{id, name, stock, at:[x,y,z], size:[x,y,z], from:[dim keys]}` in inches, x right, y up, z toward you. `at` is the corner nearest the origin.

## What the engine does with it

- Draws every part in 3D with grain, edges and shadows. Views: 3D, front, top, left and right. Orbit or pan, pinch and double-tap zoom, explode, cutaway of the room walls and overall dimensions.
- Tap a part: its cut drawn to scale, how many, any rip, which dims it depends on and whether any are assumed, and a "cut" tick kept on the device.
- Cut list: identical cuts grouped at 1/16", boards packed first-fit with kerf and an end trim, sheets packed in strips, the boards and sheets to buy with yield, and a cutting diagram for each.
- Build guide: a "Before you cut" section written from the dims (what to measure first, what is measured and when), then the item's own steps.
- Checks: the same sweep over every preset: parts fit their stock, no NaN or template text in the cut list or guide, every part packs, and the item's warnings. The pill in the header counts problems, warnings and assumed dims.
- Controls: presets, the item's controls, and a dims editor for site measurements. Edits stay on the device until "Copy dims as code" puts them back in the file, which stays the source of truth.
- Copy as text on every sheet, for a phone at the store.

## Checks from the command line

```bash
./check.sh index.html
```

Runs every preset in headless Chrome with no WebGL, prints PASS or FAIL per preset with each problem, lists the assumed dims, and exits 1 on any failure. The same output is at `index.html?check` in a browser.

## Going further

The ipe planner has pieces this template leaves out because they were specific to that room: French cleat profiles extruded from a 2D shape, wall elevations with per-wall cut sheets, lighting scenes with bloom, LED and string lights, procedural rugs, and a component catalogue. Lift them from `ipe-room-planner/index.html` when a build needs them; the code map is in its `CLAUDE.md`.

The method behind all of it is `../SKILL.md`.
