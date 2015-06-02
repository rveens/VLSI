`timescale 1ns / 1ps


module firwrapper #(
    parameter NR_STAGES = 32,
    parameter DWIDTH = 16,
    parameter CWIDTH = NR_STAGES * DWIDTH,
    parameter DDWIDTH = 2 * DWIDTH) (
		input  clk,
                input  rst,
                output req_in,
                input  ack_in,
                input  [0:DDWIDTH-1] data_in,
                output req_out,
                input  ack_out,
                output [0:DDWIDTH-1] data_out,
					 input h,
					 input h_enabled);

	reg [0:CWIDTH-1] h_in = 0;

	filter #(NR_STAGES, DWIDTH, DDWIDTH, CWIDTH) firfilter
		  (clk,
                   rst,
                   req_in,
                   ack_in,
                   data_in,
                   req_out,
                   ack_out,
                   data_out,
			h_in);

    generate
        genvar i;
        for (i = CWIDTH-1; i > 4; i = i - 4) begin : coef_delayline
	 	 	 always @(posedge clk) begin
		 	 	  if (h_enabled) begin
					 	 h_in[i]   <= h_in[i-1];
					 	 h_in[i-1] <= h_in[i-2];
					 	 h_in[i-2] <= h_in[i-3];
					 	 h_in[i-3] <= h_in[i-4];
		  	 	  end
	 	 	  end
        end
    endgenerate
	 always @(posedge clk) begin
	 	 if (h_enabled) begin
		 	 h_in[0] <= h;
		 	 h_in[1] <= h_in[0];
		 	 h_in[2] <= h_in[1];
		 	 h_in[3] <= h_in[2];
	 	 end
	 end
endmodule
