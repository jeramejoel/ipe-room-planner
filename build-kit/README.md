# Home build kit

A small toolkit for planning physical builds around the house: a workbench, shelving, a deck, a
closet, a wall. It came out of planning [the ipe board wall](../README.md) in this repo, which is why
it lives here, but nothing in it is specific to that room.

It is two skills and a template.

| | What it is |
|---|---|
| [`skills/build-planner`](skills/build-planner/SKILL.md) | How to build a one-file 3D planner for a build: parts as data, dimension provenance, the detail sheet, the drawings, selection and lighting, and how to verify the thing. |
| [`skills/build-takeoff`](skills/build-takeoff/SKILL.md) | The arithmetic that makes its numbers true: pack the cut list, price the piece length, set a floor the material can hold, and say one number everywhere. |
| [`skills/build-planner/template`](skills/build-planner/template/README.md) | A working planner with the room taken out. Start here for a new build. |

## Install

```bash
./build-kit/install.sh
```

That symlinks both skills into `~/.claude/skills`, so Claude picks them up in any project. Editing a
file here takes effect immediately; re-run only when a skill is added or renamed. `install.sh check`
reports what is linked, `install.sh remove` unlinks them again.

## Start a new build

Ask Claude to "plan a garage workbench in 3D", or do it by hand:

```bash
./build-kit/skills/build-planner/template/new-planner.sh "Garage Workbench"
```

That creates `~/Documents/dev/garage-workbench-planner/` with the planner, a check script, a README
and a first commit. Pass a second argument to put it somewhere else. Then fill in the ITEM block at
the top of `index.html`: the dimensions (each tagged measured, assumed or chosen), the stock you can
buy, the controls, the presets, and `build()`, which lists the parts as boxes. Run `./check.sh`
before committing.

## What you get without writing it

- 3D, front, top and side views. Orbit or pan, pinch and double-tap zoom, explode, cutaway, overall
  dimensions.
- Tap a part: its cut drawn to scale, how many, any rip, which dimensions it depends on, a warning
  when one is assumed, and a tick kept on the phone.
- A cut list grouped at 1/16", stock packed with kerf and end trim, what to buy with its yield, and a
  cutting diagram per board.
- A build guide that opens with what to measure before cutting, written from the dimensions.
- A headless sweep over every preset that exits non-zero on a failure, so it can gate a commit.
- Every sheet copies as text, for a phone at the store.

## The short version

If you read nothing else:

- **Measure before you cut.** The hand drawing of the music room had one wall 25" too long and
  nothing about it looked wrong.
- **Never average two measurements that disagree.** Show the arithmetic, name the number you suspect,
  go back with a tape.
- **Pack the cut list, do not add up the groups.** Group-by-group counting wasted a board at the end
  of every group and got one buy wrong three different ways in a single document.
- **The piece length decides the waste.** 96" pieces out of 97" boards uses 96.7% of the wood. 72"
  pieces out of the same boards uses 74.7%.
- **Count operations, not parts.** The most expensive thing in the ipe build was not the ipe. It was
  one groove run down 122 boards.

The plain-English version of all of this, with the house context, is in the Obsidian vault under
`4 - Personal/House`, starting at **Build Method**.
