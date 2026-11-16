---
name: build-takeoff
description: The material-takeoff standard for any planner, estimator or configurator that turns a design into a bill of materials. Covers the four counting defects that make a takeoff lie (group-by-group counting instead of packing, a total that silently drops a class of parts, a "buy a few more" line patched on by different arithmetic, and a yield figure computed over a different set of parts than the buy), the piece-length-against-stock-length yield table that is usually the largest cost lever in the design, minimum viable dimension as a hard floor on every code path, weight and load and assembly order as design inputs rather than site problems, and the rule that a quantity stated twice will eventually be stated as two different numbers. Material- and stack-agnostic, the same arithmetic governs lumber, sheet goods, pipe, extrusion, cable, fabric and tile. Use when writing or auditing any code that computes quantities, cut lists, waste, yield or a shopping list, or when planning a home project that ends in a trip to the lumberyard. Triggers "cut list", "bill of materials", "BOM", "takeoff", "material estimate", "how many boards", "yield", "waste", "offcut", "nesting", "bin packing", "stock length", "shopping list", "how much lumber", "what do I need to buy".
---

# Getting a takeoff to tell the truth

Any tool that turns a design into a list of things to buy is doing bin packing, whether or not its
author knew that. This is the standard for doing it correctly, and the four ways it reliably goes
wrong.

It is the arithmetic layer under `build-planner`. That skill builds the tool; this one makes its
numbers right.

## The one law

**Pack every cut, once, over the whole build. Then read every other number off that pack.**

Piece count, waste, yield, cost and the shopping list are all views of a single packing result. The
moment any one of them is computed a second way, the document can contradict itself, and nothing in
the code will notice.

## The four defects

These travel together. Find one and go looking for the other three.

### 1. Counting group by group instead of packing

The natural way to count material is by group: so many wall pieces, so many shelf pieces, so many
rails, add them up. It overcounts every time, and the error grows with the number of groups, because
**each group leaves the same unused stub at the end of every one of its own boards.**

Fit cuts onto stock in one pass, longest first, charging the kerf per cut and an end trim per piece
of stock. First-fit decreasing is within a few percent of optimal and is about ten lines:

```js
function pack(cuts, stock, kerf) {
  const bins = [];
  for (const c of [...cuts].sort((a, b) => b.len - a.len)) {
    let bin = bins.find(b => b.left >= c.len + kerf);
    if (!bin) { bin = { left: stock, items: [] }; bins.push(bin); }
    bin.items.push(c); bin.left -= c.len + kerf;
  }
  return bins;
}
```

A real case: 52 rails at 17 3/8" pack five to a 96" board and leave 8 1/2" dead at the end of eleven
boards. Letting the different rail lengths share a board took the same 85 cuts from **17 boards to
14**. Three boards, free, from one function call.

### 2. A total that drops a class of parts

A takeoff grows a part at a time, and a class added late gets counted in one place and not another.
Look for a group that contributes to the piece count but not the stock count, usually because it was
assumed to come out of some other group's offcut.

Coming out of an offcut is a legitimate plan, but it is a claim with a capacity, and the capacity has
to be checked against the demand. If the planner says "from the offcuts, no extra stock" it owes you
the arithmetic.

### 3. A "buy a few more" line patched on by different arithmetic

When somebody notices defect 2, the usual repair is a shortfall line: *buy 5 more*. Now there are two
rules in the document, and the grand total almost never adds the patch in. A real plan stated its buy
three ways on one page:

| | Boards |
|---|---|
| Summary panel | 114 |
| Cut list, plus its "buy 5 more" line | 124 |
| Packing all 146 pieces properly | **119** |

Nobody catches this at the counter. They are five short or five over.

The fix is never a better patch. It is to delete the patch and pack the parts it was compensating
for.

### 4. Yield computed over a different set of parts than the buy

The subtlest one, because the number looks plausible. If the numerator is "length of the pieces I
know about" and the denominator is "stock I am buying", any part missing from the numerator reads as
waste.

That single mismatch made a plan report **118 ft of offcut at 86% used** when the truth was **32 ft
at 96.7%**. It would have sent someone looking for a saving that did not exist.

Derive both sides from the pack:

```js
const buyLen = cuts.reduce((a, c) => a + c.len, 0);
const bought = bins.length * stock;
const yield_ = buyLen / bought;
const offcut = bought - buyLen;
```

## The piece length decides the waste

This is usually the largest cost lever in the design and it is invisible on a drawing. Stock yields a
whole number of pieces, so one inch of piece length can cost a whole extra piece of stock per part.

Same material, same wall, same 97" stock:

| Piece length | Pieces per board | Material used |
|---|---|---|
| **96"** | 1 | **96.7%** |
| 90" | 1 | 90.6% |
| 84" | 1 | 84.8% |
| 72" | 1 | 74.7% |
| 48" | 2 | 89.7% |

Choosing 72" over 96" throws away a quarter of the material for a look. **Build this table before the
dimension is fixed, and put it in front of whoever is choosing.** A planner that offers preset
dimensions should show the yield on each preset, so the choice is priced at the moment it is made.

Two warnings:

- **Confirm the real stock length before trusting a margin.** Nominal 8 ft is often exactly 96", and
  then a 96" piece has no trim at all and cannot be squared. The margin you think you have may be
  zero.
- **Test the clever idea before believing it.** Buying longer stock for the shorter pieces looked
  like an obvious saving. Modelled honestly it was 10 fewer boards and about one point of yield, for
  a second delivery and 12 ft lengths to carry. The plain single-length buy won. Model the
  alternative; most of them lose.

## Minimum viable dimension

Geometry will happily hand you a part the material cannot hold. A 1/2" x 96" strip of dense hardwood
satisfies the arithmetic, splits on the first fastener, and cannot be ripped safely.

Every material has a floor. Set it as a constant, enforce it on **every** code path, and say what
enforcing it costs.

The failure mode is two paths with two floors. One real planner had `MIN_RIP = 1"` on one branch and
`GRID_MIN = 0.5"` on another, so one layout mode quietly produced slivers the other had been written
to prevent. Tie them together:

```js
const MIN_RIP = 1;
const GRID_MIN = MIN_RIP;   // not a second, looser floor
```

The mirror image is just as wasteful: a piece an eighth under full width consumes a whole board to
remove almost nothing, and it is a fussy cut. Push that eighth into a gap or a reveal where nobody
will find it.

Enforcing a floor always costs something, usually a wider gap or reveal somewhere. **Say so in the
output.** When a plan stopped producing slivers it started leaving 1 3/8" of extra reveal across two
edges, and the sheet had to stop claiming "nothing bare" and name the new number instead. A plan that
hides the cost of its own rule is worse than one without the rule.

When the cost is adjustable, show the range instead of arguing about it. Sweeping one parameter
across its settings is usually a small table, and it turns an argument into a choice:

| Gap | Bespoke pieces |
|---|---|
| 3/4" | 20 |
| 7/8" | 17 |
| 1" | 21 |
| 1 1/8" | 17 |
| 1 1/4" | 19 |

An eighth of an inch, invisible at arm's length on a 5 1/2" board, was worth four fewer one-off cuts.

## Say one number

If a plan states a quantity twice, it will eventually state two different numbers, and the reader has
no way to know which to act on. Compute once; have every surface read from it.

Reading each summary line against the detail underneath it, looking for two numbers that cannot both
be true, is cheap, needs no tooling, and catches all four defects above.

## Weight, load and order are design inputs

These get decided in the plan whether or not anyone decides them, and a takeoff that lists only
quantities will not raise any of them.

- **Weight per piece, against who is lifting it.** Set the ceiling before sizing the parts and check
  every part against it. Around 75 lb is the practical limit for one person placing something
  overhead with care. The heaviest panel on one job came out at 63 lb, which was design, not luck.
- **Total load and where it goes.** Know the load per linear foot and what carries it into structure.
  2,300 lb spread over 44 ft of wall is about 52 lb per foot, which a cleat into studs carries
  without comment. The number that matters is per fixing, not the headline total.
- **What fastens to what, in order.** Any part that cannot be installed after its neighbours is a
  plan defect found at the worst possible moment. Emit the assembly as a sequence, not a set.
- **What gets sealed in.** Anything behind the finished work has to be right the first time or
  reachable. Wiring especially. Access is a dimension too.

## Count operations, not just parts

The expensive thing is often not the material. In one build it was a 1/2" x 1/4" groove run full
length down 122 boards: one fence setting, 122 passes, and the single largest block of shop time in
the project. The material list said nothing about it.

A takeoff that lists parts and not operations will mis-rank the work. Emit both.

- Count the operations per part and multiply. A one-minute job on 122 parts is two hours.
- Anything repeated at one machine setting is worth batching, and worth saying so in the plan.
- Anything that dominates the schedule is the thing to design out, not the material to economise on.

## Audit checklist

Run this against any takeoff, including one you wrote:

- [ ] Every cut packed onto real stock lengths in one pass, including anything meant to come from
      another part's offcut.
- [ ] Piece count, stock count, waste and yield all derived from that one pack.
- [ ] No "buy N more" line anywhere. If one exists, find the parts it compensates for and pack them.
- [ ] Yield numerator and denominator cover the same set of parts.
- [ ] A yield figure shown for every candidate dimension the tool offers.
- [ ] Real stock length confirmed, with trim remaining.
- [ ] One minimum-dimension constant, enforced on every path, with its cost stated in the output.
- [ ] Every quantity stated exactly once across every surface.
- [ ] Every part under the lifting limit, load per fixing known, assembly emitted as an order.
- [ ] Operations listed, not only parts.
- [ ] Spares named separately from the buy count, never folded into it.

## Verification

Do not trust the tool to check itself; that is how all four defects survive.

1. **Re-derive the buy independently.** Pull the demand out of the running tool, pack it in a few
   lines of Python, and compare. Agreement is strong evidence; disagreement is a defect in one of
   them.
2. **Sweep every option.** Run every preset and every toggle and record the headline numbers. A
   defect that only appears at one setting is still a defect.
3. **Read the document against itself.** Two numbers on one page that cannot both be true is the
   cheapest finding there is.
