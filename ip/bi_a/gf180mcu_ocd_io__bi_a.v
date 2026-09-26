// Blackbox of the GF180 ocd_io bidirectional pad with analog pass (bi_a),
// copied from the PDK's gf180mcu_ocd_io__blackbox(_pp).v. Needed because the
// pad library's Liberty view omits the ANA pin, so Yosys (which reads the
// pads from Liberty) would otherwise reject the .ANA connection.
(* blackbox *)
module gf180mcu_ocd_io__bi_a (
`ifdef USE_POWER_PINS
    inout  DVDD,
    inout  DVSS,
    inout  VDD,
    inout  VSS,
`endif
    input  CS,
    input  SL,
    input  IE,
    input  OE,
    input  PU,
    input  PD,
    input  A,
    inout  ANA,
    input  PDRV0,
    input  PDRV1,
    inout  PAD,
    output Y
);
endmodule
