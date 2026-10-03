`ifdef SLOT_1X1

// Power/ground pads for core and I/O
`define NUM_DVDD_PADS 6
`define NUM_DVSS_PADS 8

`define NUM_VDD_PADS 2
`define NUM_VSS_PADS 2

// Signal pads
`define NUM_INPUT_PADS 12
`define NUM_BIDIR_PADS 40
`define NUM_ANALOG_PADS 2

`endif

`ifdef SLOT_0P5X1

// Power/ground pads for core and I/O
`define NUM_DVDD_PADS 7
`define NUM_DVSS_PADS 7

// Experiment: second core pair (intended AVDD/AVSS position) replaces
// bidir[43:42] so every bond-pad position stays unchanged for COB.
`define NUM_VDD_PADS 2
`define NUM_VSS_PADS 2

// Signal pads
`define NUM_INPUT_PADS 4
`define NUM_BIDIR_PADS 42
`define NUM_ANALOG_PADS 6

`endif

`ifdef SLOT_1X0P5

// Power/ground pads for core and I/O
`define NUM_DVDD_PADS 7
`define NUM_DVSS_PADS 7

// asic_rd: second core pair (AVDD position) replaces bidir[45:44] so every
// bond-pad position stays unchanged for COB (same approach as the 0p5x1
// experiment, which passed the platform CoB precheck).
`define NUM_VDD_PADS 2
`define NUM_VSS_PADS 2

// Signal pads
`define NUM_INPUT_PADS 4
`define NUM_BIDIR_PADS 44
`define NUM_ANALOG_PADS 4

`endif

`ifdef SLOT_0P5X0P5

// Power/ground pads for core and I/O
`define NUM_DVDD_PADS 3
`define NUM_DVSS_PADS 3

`define NUM_VDD_PADS 1
`define NUM_VSS_PADS 1

// Signal pads
`define NUM_INPUT_PADS 4
`define NUM_BIDIR_PADS 38
`define NUM_ANALOG_PADS 4

`endif
