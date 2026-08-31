# Padring experiment: second core supply pair on the 0p5x1 ring

Branch: `avdd-core-pair-experiment` (based on upstream `main` commit
`0de7e394`, the frozen asic_rd baseline).

## Question being answered

wafer.space issues no written confirmations (provider reply, 2026-08-30);
acceptance authority is the automated precheck and COB checks on
platform.wafer.space. This experiment empirically answers Gate A item WS-06 of
the asic_rd project:

> May one bidirectional pad position in the `0p5x1` default ring be re-typed
> into a second `gf180mcu_ocd_io__vdd/vss` core pair — keeping every bond-pad
> position unchanged for COB — so the analog core supply (AVDD) is separately
> measurable?

Note that all grounds are tied together on the default COB breakout, so only
the AVDD side can ever be separately measured.

## Modification (two files)

- `src/slot_defines.svh`: `SLOT_0P5X1` now has `NUM_VDD_PADS 2`,
  `NUM_VSS_PADS 2`, `NUM_BIDIR_PADS 42` (was 1/1/44).
- `librelane/slots/slot_0p5x1.yaml`: `PAD_WEST` positions of `bidir[43]` and
  `bidir[42]` are replaced by `vss_pads[1].pad` and `vdd_pads[1].pad`.
  Pad count and positions are unchanged.

The `1x1` slot already uses two core pairs upstream, so the concept is
template-supported; this experiment tests it on the half-width ring with the
3.3 V library set (`gf180mcu_as_sc_mcu7t3v3` + `gf180mcu_ocd_io`).

In this experiment the second pair still ties to the common `VDD`/`VSS` nets
(geometric/DRC feasibility first). Splitting `AVDD` into its own net is a
follow-up once the ring passes.

## How to run

Requires Docker. Uses the same pinned IIC-OSIC-TOOLS image as asic_rd
(LibreLane and ciel are included; nix is not required).

```sh
./run-experiment.sh build      # clones the pinned PDK (multi-GB, once), builds the padring
./run-experiment.sh precheck   # runs wafer-space/gf180mcu-precheck on the produced GDS
```

The final authority is uploading the GDS to <https://platform.wafer.space>
and passing its precheck and COB checks.

## Pass/fail interpretation

- Pass: freeze the `0p5x1` + second-core-pair plan; proceed to the AVDD net
  split and record the result in asic_rd `docs/PDK_PAD_SUPPLY_FREEZE.md`
  (WS-06).
- Fail on a rule tied to pad typing: fall back to the `1x1` slot (two core
  pairs upstream) or drop separate AVDD measurement; record either way.
