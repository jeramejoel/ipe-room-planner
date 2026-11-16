---
name: build-planner
description: Build a single-file, zero-dependency 3D planner for a physical build (a workbench, shelving, a deck, a closet, a wall, a booth) that turns a parts list into an orbitable 3D model, a packed cut list, a shopping list and an ordered build guide, and runs on a phone at the lumberyard. Covers the file shape (one HTML file, importmap CDN, no build step), the parts-as-data model, measured-versus-assumed dimension provenance and what to do when two measurements disagree, the per-part detail sheet, assembly-manual line drawings generated from the same numbers as the model, the persistent checklist, selection and hover affordance in 3D, realistic lighting, shipping a whole-design rule behind a toggle, checking coverage by walking the surfaces, and the sweep-every-preset verification loop. Pairs with build-takeoff, which governs the arithmetic. Use when planning any home or shop build, or when a spatial problem needs a model rather than a document. Triggers "plan a build in 3D", "build planner", "workbench plan", "shelving plan", "deck plan", "closet plan", "cut sheet", "how do I lay this out", "model this room", "assembly guide", "single-file 3D", "plan my garage".
---

# A model you can interrogate

A static document about a physical build goes stale the moment a dimension changes, and nothing in it
notices. A planner re-runs the whole takeoff on every change, so a contradiction surfaces instead of
shipping.

That is the entire argument for building one. The 3D view is the part people notice; the value is
that the cut list, the shopping list and the build guide are all derived from the same numbers, so
they cannot disagree.

This skill is the tool. `build-takeoff` is the arithmetic inside it, and it is not optional: a
planner with a wrong takeoff is worse than a sketch, because it is believed.

## Start from the template

[`template/`](template/README.md) is a working planner with the room taken out: one HTML file that
opens from disk and publishes to GitHub Pages as is. Start a build with
`template/new-planner.sh "Garage Workbench"`, then edit only the ITEM block: the dimensions (each
tagged measured, assumed or chosen), the stock you can buy, the controls, the presets, and `build()`,
which returns the parts as boxes. Everything below comes with it.

## The file shape

**One HTML file. No build step, no package.json, no node_modules.**

That constraint is doing real work. The file opens from disk, deploys to GitHub Pages by pushing it,
survives being emailed to yourself, and still runs in two years when the toolchain you would have
picked has rotted.

```html
<script type="importmap">{"imports":{
  "three":"https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
  "three/addons/":"https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"}}</script>
```

Pin an exact version. Deploy with `gh api -X POST repos/{owner}/{repo}/pages` from `main` at the
root, so the phone in the garage opens the same file you are editing.

## Parts are data, geometry is derived

Everything downstream reads one array. Never hand-place a box in the scene and separately hand-type
its dimension into a table: that is the contradiction you built the tool to prevent.

```js
const PARTS = [
  { id:'leg', name:'Leg', n:4, w:3.5, h:34, d:3.5, mat:'2x4', at:[x,y,z] },
  ...
];
```

The 3D mesh, the dimension labels, the cut list rows, the shopping list and the build steps are all
functions of `PARTS`. Changing a number changes all five.

Drive the geometry from a few named constants, so a corrected measurement is one line and everything
downstream follows it. After any correction, search the source for the old value: a literal that
still matches is a dimension that did not move. Check each hit before changing it, because a computed
area can equal an old wall length by coincidence.

## Mark every dimension measured, assumed or chosen

This is the single highest-value feature and almost nobody builds it.

```js
const D = {
  wallLen:  { v: 239, src: 'measured' },
  ceiling:  { v: 124, src: 'assumed'  },
  boardLen: { v: 96,  src: 'chosen'   },
};
```

Surface the count of assumed dimensions in the header, and mark any part whose size depends on one. A
build fails on the dimension nobody checked, and the planner is the only place that knows which those
are. Print the tag where the cutting happens, not only in the file: a comment never reaches the
person holding the saw. Keep the README's caveat current in the same pass as the measurement, or it
will spend days claiming everything came from a drawing after two walls were measured.

**When two measurements disagree, raise a warning and refuse to average them.** On one job a hand
drawing gave a wall as 264" while three site measurements summed to 239". Averaging would have hidden
a 25" error; the warning sent someone back with a tape. Show the arithmetic, name the number you
suspect, and leave it unresolved until a human resolves it. Correcting one wall moves every wall that
joins it, which is too large a change to infer from two numbers.

The same goes for objects. When the drawing's box and the site's measurement cannot both fit where
they are drawn, they may be two different things. The drawing's 88" x 20" floor-to-ceiling box turned
out to be a 65" x 16" soffit with a 5'0" underside. Model the measured one and say what it replaced.

Let the user type a real measurement on site, keep it in `localStorage`, and give them a "copy
dimensions as code" button to put it back in the file.

## What the tool owes you

- **Views:** 3D plus front, top and each side. Orbit and pan, pinch and double-tap to zoom. An
  explode view, a cutaway that hides whatever is between the camera and the interior, and overall
  dimensions you can switch off.
- **Tap a part:** its cut drawn to scale, the quantity, any rip, which dimensions it depends on, a
  warning if one is assumed, and a tick that persists.
- **Cut list:** identical cuts grouped to 1/16", stock packed with kerf and end trim, the buy with
  its yield, and a cutting diagram per piece of stock. All of it per `build-takeoff`.
- **Build guide:** opens with what to measure before cutting, generated from the dimension table,
  then the ordered steps. Every step says what fastens to what.
- **Checks:** a sweep over every preset that fails on a part that does not fit its stock, on any
  `NaN` reaching the output, and on any constraint the build itself declares.
- **Copy as text:** every sheet, for a phone at the counter.

## Drawings from the same numbers

Generate the line drawings as inline SVG from `PARTS`, never by hand. A hand-drawn figure is a second
source of truth and it will drift.

One visual language, held across every drawing: thin dark outlines, one material tone, one accent,
numbered badges. Show front and back when fastening happens from behind. Keep it at the level of an
assembly manual, which means no shading, no perspective, and one idea per figure.

Break long numbered steps onto their own lines. Dense numbered text under a diagram is where these
documents become unreadable.

## Make selection obvious

A planner is only useful if tapping a part tells you about that part, and that requires the part to
look selected.

**A dim emissive tint is not a selected state**, especially against a dark or busy model. Draw a
tinted face plus an edge cage in the part's own local group so the marker follows any rotation the
part carries. Accent colour for selected, white at low opacity for hover, and a pointer cursor on
anything pickable.

Line width is not settable in WebGL on most platforms, so an outline alone stays a hairline whatever
you ask for. **The translucent fill is what makes it read.** Raycast hover once per animation frame
and never rebuild the scene for it.

## Light it like a room

Two settings separate a model that reads as a space from one that reads as a diagram, and neither is
about adding lights:

```js
renderer.toneMapping = THREE.ACESFilmicToneMapping;   // not the default NoToneMapping
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
```

Without tone mapping any emissive above white clips flat and a dark interior crushes to one dead
value. Without an environment, standard materials have no specular term at all, which is why wood
renders as matte cardboard.

Then carry the mood with **exposure**, not with light intensity. Leave the lights where they
physically are and open the stop for a dark room, the way a camera does. Scale `envMapIntensity` with
the mood as well: a black room reflects almost nothing, a daylit one reflects a great deal.

## Ship a whole-design rule behind a toggle

A rule that applies everywhere (lock every part to one grid, close every run with a ripped piece,
hold every gap at exactly 1") changes the cut list everywhere. Ship it behind a toggle, measure the
plan both ways on the same build, and print the table where the decision is made.

Re-derive the counts before publishing that table. One shipped with a stock count and a yield column
that were both wrong, so two settings appeared to differ by 0.6 points when neither figure meant
anything, and the comparison hid the fact that one setting won on every other axis. A cost table is
only as good as the counting rules behind it.

## Persist the user's work, not your state

`localStorage` holds the cut and hung ticks, site measurements, and which panel group was open. Key
the ticks by a part signature rather than an index, so they survive a change to the parts list.

## Check coverage by walking the surfaces

An audit that walks the parts can only report on parts that exist. A surface with nothing on it has
no parts, so that audit never sees it, and a bare stretch sits there passing every check.

Walk each surface instead, subtract what the parts cover and what legitimately stands against it, and
report what is left. On one job this found a 7 1/2" full-height face between a corner and a door with
nothing over it, which the parts-based audit had never looked at.

When a check comes back clean, ask what it is incapable of seeing.

## Verification

The planner is a measuring instrument. Check it the way you would check one.

1. **Drive the running page and scrape its own numbers.** Do not read the source and reason about
   what it should say.
2. **Sweep every preset and every toggle**, not one configuration. Assert on `NaN`, `undefined`,
   `Infinity`, unexpanded template literals and console errors at each.
3. **Re-derive the material arithmetic independently**, in a few lines of Python, and compare against
   the page.
4. **Read every summary against the detail under it.** Two numbers that cannot both be true is a
   defect, even when each is individually defensible.
5. **Measure the layout at 375px** rather than eyeballing it: compare `scrollWidth` against
   `clientWidth` on every bar. Controls that are cut off with no way to reach them do not look broken
   in a screenshot.

## Diff before replacing the file

A planner that ships as one self-contained file invites replacing the whole thing with a newer copy
from somewhere else. If that copy predates a fix, the fix is gone and nothing fails. This has already
happened once: a correction was lost when the file was overwritten with an older copy and had to be
found and redone. Diff the two before replacing, and run the sweep after.

**The same hazard applies to the working tree.** A planner's kit folder sitting untracked beside the
file is one `git clean -fd` away from gone, and a clean tree looks like success. Commit new work
early rather than carrying it uncommitted through a long session, especially in a checkout something
else is also working in.

## Organise it like a tool

Header for the sheets you read, a side rail for where you look, a bottom bar for camera and light, a
right rail for detail, and a panel for what you change. Two surfaces competing for one region is how
it gets confusing: if the detail tray and the settings panel share the right rail, opening either
must close the other.

Put the depth behind disclosure. A settings panel that shows forty controls at once is a wall; the
same controls in seven named groups, one open and remembered, is a tool. Same for a long view list:
keep the common views open and fold the rest away, and open a group automatically when the current
selection lives inside it.

## Keep the build-specific parts out

Wall elevations, cleat profiles, lighting scenes and anything else that belongs to one job stays in
that job's planner. What travels is the shape of the file, the parts-as-data model, the dimension
provenance, the takeoff and the verification loop.
