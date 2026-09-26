// SPDX-FileCopyrightText: © 2025 XXX Authors
// SPDX-License-Identifier: Apache-2.0
//
// Digital-on-top integration experiment (asic_rd, 2026-09-25): the 8-bit
// parallel Wilkinson digital top plus one analog hard macro (minimum
// comparator) inside the wafer.space 0p5x1 pad ring, 3.3 V library set.

`default_nettype none

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
    )(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif

    input  wire clk,       // clock
    input  wire rst_n,     // reset (active low)

    input  wire [NUM_INPUT_PADS-1:0] input_in,   // Input value
    output wire [NUM_INPUT_PADS-1:0] input_pu,   // Pull-up
    output wire [NUM_INPUT_PADS-1:0] input_pd,   // Pull-down

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,   // Output enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,   // Input type (0=CMOS Buffer, 1=Schmitt Trigger)
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,   // Slew rate (0=fast, 1=slow)
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,   // Input enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,   // Pull-up
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,   // Pull-down

    inout  wire [NUM_ANALOG_PADS-1:0] analog  // Analog
);

    assign input_pu = '0;
    assign input_pd = '0;

    // Pad map (experiment):
    //   input[0] start, input[1] shift_en, input[2] compare_high[1], input[3] compare_high[2]
    //   bidir[0] (input) compare_high[3]
    //   bidir[1] acquire, [2] ramp_connect, [3] ramp_reset, [4] serial_data,
    //   [5] data_ready, [6] conversion_busy, [7] conversion_done,
    //   [11:8] conversion_timeout, [12] cmp0 output monitor, others 0
    //   analog[0] cmp0 sample, analog[1] cmp0 ramp, analog[2] cmp0 bias
    logic [NUM_BIDIR_PADS-1:0] bidir_is_input;
    assign bidir_is_input = {{(NUM_BIDIR_PADS-1){1'b0}}, 1'b1};
    assign bidir_oe = ~bidir_is_input;
    assign bidir_ie = bidir_is_input;
    assign bidir_cs = '0;
    assign bidir_sl = '0;
    assign bidir_pu = '0;
    assign bidir_pd = '0;

    wire start        = input_in[0];
    wire shift_en     = input_in[1];
    wire [3:0] compare_high;
    wire cmp0_dout;
    assign compare_high = {bidir_in[0], input_in[3], input_in[2], cmp0_dout};

    wire acquire, ramp_connect, ramp_reset, serial_data, data_ready;
    wire conversion_busy, conversion_done;
    wire [3:0] conversion_timeout;

    comparator_min cmp0 (
        `ifdef USE_POWER_PINS
        .vdd(VDD), .vss(VSS),
        `endif
        .sample(analog[0]), .ramp(analog[1]), .bias(analog[2]), .dout(cmp0_dout)
    );

    asic_digital_top digital (
        .clk(clk), .rst_n(rst_n), .start(start),
        .compare_high(compare_high), .shift_en(shift_en),
        .acquire(acquire), .ramp_connect(ramp_connect), .ramp_reset(ramp_reset),
        .serial_data(serial_data), .data_ready(data_ready),
        .conversion_busy(conversion_busy), .conversion_done(conversion_done),
        .conversion_timeout(conversion_timeout)
    );

    logic [NUM_BIDIR_PADS-1:0] outs;
    always_comb begin
        outs = '0;
        outs[1]    = acquire;
        outs[2]    = ramp_connect;
        outs[3]    = ramp_reset;
        outs[4]    = serial_data;
        outs[5]    = data_ready;
        outs[6]    = conversion_busy;
        outs[7]    = conversion_done;
        outs[11:8] = conversion_timeout;
        outs[12]   = cmp0_dout;
    end
    assign bidir_out = outs;

    logic _unused;
    assign _unused = &{bidir_in[NUM_BIDIR_PADS-1:1], analog[NUM_ANALOG_PADS-1:3]};

endmodule

`default_nettype wire
