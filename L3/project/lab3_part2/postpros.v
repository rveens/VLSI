`timescale 1ns / 1ps

module preproc #(parameter NR_STAGES = 32,
                 parameter DWIDTH = 16,
                 parameter DDWIDTH = 2*DWIDTH,
                 parameter CWIDTH = NR_STAGES * DWIDTH)
       (input  clk,
        input  rst,
        output req_in,
        input  ack_in,
        input signed [0:DWIDTH-1] data_in,
        output req_out,
        input  ack_out,
        output signed [0:DWIDTH-1] data_out,
        input signed [0:CWIDTH-1] h_in);



always @(posedge clk) begin

end

endmodule
