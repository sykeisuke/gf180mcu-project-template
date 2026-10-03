# Digital-on-top chip experiment: asic_rd digital top + analog hard macro in the 0p5x1 ring

Branch: `digital-on-top-chip-core` (on top of `avdd-core-pair-experiment`,
i.e. upstream `0de7e394` + the second core supply pair).
Date: 2026-09-25/26. Companion of `asic_rd/experiments/digital_on_top/`.

## Question

Can the asic_rd analog blocks be dropped into the provider template's
digital P&R flow as hard macros — pad ring, 3.3 V library, PDN, routing,
DRC, LVS all handled by LibreLane (digital-on-top, as recommended in the
2026-09-18 design review) — including the connection from an analog pad to
the macro?

## What was built

- `src/chip_core.sv`: the asic_rd 8-bit parallel Wilkinson digital top
  (`src/asic_digital_top.v`, `parallel_wilkinson_controller.v`,
  `serial_readout.v`, vendored) plus one `comparator_min` hard macro
  (`ip/comparator_min/`: GDS/LEF/lib/blackbox/SPICE made by asic_rd's
  `make_macro.sh`). Pad map in the file header.
- `librelane/macros/macros_3v3.yaml`: SRAMs replaced by the comparator macro
  at (900, 2000); `PDN_MACRO_CONNECTIONS`; `librelane/pdn/pdn_cmp.tcl`
  (Metal4 straps centred on the macro's Metal3 power bars).
- Analog pads 0..2 changed from `asig_5p0` to `bi_a` (bidirectional pad with
  analog pass; digital driver/receiver tied off) so that the core-side `ANA`
  pin can be routed; see findings.
- `scripts/chip_flow.py`: the Chip flow plus an `Odb.UnspecialAnalogNets`
  step (kept for the asig case; unused with bi_a). `run-chip.sh` runs it with
  the LibreLane-matched OpenROAD build.
- KLayout DRC workers limited to 4 (10 workers exhaust the 8 GB Docker VM
  on this die).

```sh
./run-chip.sh --tag <tag>                  # full flow, ~65 min on an M-series laptop
./run-chip.sh --last-run --from <Step>     # resume
```

## Result (run `chip_bia5`, SLOT=0p5x1, SCL=gf180mcu_as_sc_mcu7t3v3, PAD=gf180mcu_ocd_io)

| Check | Result |
| --- | --- |
| Detailed-route DRC | 0 |
| Magic DRC / KLayout DRC (all decks except CUP) | 0 / 0 |
| KLayout density | 0 |
| Antenna (nets / pins) | 0 / 0 |
| Netgen LVS | 0 errors — with the analog pad nets **present and routed** (checked in the DEF: pad `ANA` pin to `cmp0/sample,ramp,bias` on Metal2/3) |
| Setup / hold, 9 corners | 0 / 0 (worst 24.4 ns / 0.35 ns at 25 MHz) |
| Instances | 180184 (33599 standard cells incl. fill, 7 % utilization) |

Render: `final_chip/chip_top_small.png`; metrics: `final_chip/metrics.csv`.

## Findings (each cost a failed run)

1. **`asig_5p0` cannot be routed by the digital router.** Its only pin is
   the bond pad itself: 2.54 um Metal2 fingers surrounded by Metal2/3/4
   obstructions; TritonRoute generates no access points (`#macroNoAp = 3`)
   and crashes (`frAccessPoint` assertion) when asked to route the net.
   Consequently the template leaves analog pads unrouted: their nets are
   SPECIAL (bond-pad terminals), the router skips them, and **LVS passes
   with the macro inputs floating** — a silent failure worth knowing about.
   `scripts/chip_flow.py` shows how to hand those nets to the router (split
   the bond-pad terminal onto its own net, clear SPECIAL); it gets as far as
   the pin-access crash. Using asig pads therefore means either a manual
   wide-metal connection (special wires added by a step) or a routable pad.
2. **`bi_a` works, but needs three fixes**: (a) Yosys reads pads from
   Liberty, which lacks `ANA` → `EXTRA_VERILOG_MODELS` with the PDK's
   blackbox; (b) OpenROAD's linker also uses Liberty and silently drops the
   `ANA` connection (warning ORD-2001 only; LVS still passes because the
   netlist lost the pin too) → `scripts/patch_pad_libs.py` adds the pin to
   copies of the three 3.3 V-corner pad libraries and `PAD_LIBS` points at
   them; (c) the pad-ring script only creates bond-pad terminals for masters
   listed in `PAD_PLACE_IO_TERMINALS` → add `gf180mcu_ocd_io__bi_a/PAD`.
3. Nested generate blocks change pad instance names
   (`analog[i].routable.pad`); the slot YAML must follow.
4. Running LibreLane through its Python API needs
   `/foss/tools/openroad-librelane/bin` first in PATH (the CLI wrapper does
   this); the default OpenROAD lacks the STA "scene" API.
5. `KLAYOUT_DRC_OPTIONS.workers: max` (10 × ~1.2 GB) exhausts an 8 GB Docker
   VM on the 0p5x1 die: two decks return empty results. 4 workers fit.
6. `PDN_MACRO_CONNECTIONS` and the macro grid work exactly as for the
   template's SRAM; `-offset` is the strap centreline.

## Open

- Pad choice for the real chip: `bi_a` (routable, but a pass device in the
  analog path) vs `asig_5p0` (diodes only, but needs a hand-drawn
  connection). Decision for the analog owner; spec currently says asig.
- The comparator here is the v0.5 placeholder; repeat with the 0.6 cell /
  comparator macros.

## Precheck (gf180mcu-precheck, `--slot 0p5x1 --cob`, on `chip_bia5` GDS)

| Check | Result |
| --- | --- |
| Design name / slot dimensions | match |
| COB pad mask | **"Pad mask matches!"** |
| KLayout density | clear (real fill this time, no empty-core artifact) |
| KLayout antenna | clear |
| Magic DRC | clear |
| KLayout DRC | clear |

Log: `precheck_bia5.log` (not committed). The GDS is therefore a candidate for
the platform upload (platform.wafer.space) as a further check, with a
placeholder comparator.

## 1x0p5 slot (branch `slot-1x0p5`, 2026-10-02)

The 0.5x1 slot sold out; the project moves to **1x0.5** (die 3.932 x 2.531 mm,
core 3.048 x 1.647 mm, 4 analog pads on the west edge, one core supply pair
by default). Changes against the 0p5x1 branch: `SLOT_1X0P5` gets a second
core pair in place of `bidir[45:44]` (north-west corner, next to the default
pair; bond-pad positions unchanged, 44 bidir pads left), the analog pad
instance names in `slot_1x0p5.yaml`, the macro moved to (1500, 1200), and
`run-chip.sh` takes `SLOT=` (default `1x0p5`).

Run `chip_1x0p5b` (3.3 V `as_sc_mcu7t3v3`, `ocd_io`, `bi_a` analog pads):

| Check | Result |
| --- | --- |
| Routing / Magic / KLayout DRC, density | 0 / 0 / 0 / 0 |
| Antenna | 0 |
| Netgen LVS | 0, analog pad-to-macro nets routed (checked in the DEF) |
| Setup / hold, 9 corners | 0 / 0 (worst 24.1 ns / 0.35 ns) |
| Macro power connectivity | all VDD/VSS shapes connected |
| Instances | 200491 (36280 std cells incl. fill) |

Render: `final_chip_1x0p5/chip_top_small.png`; metrics: `final_chip_1x0p5/metrics.csv`.
Precheck (`gf180mcu-precheck --slot 1x0p5 --cob`, run 2026-10-03): design name
and slot dimensions match, **COB pad mask matches**, KLayout density, antenna,
Magic DRC and KLayout DRC all clear.
