`timescale 1ns / 1ps

module preproc #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input signed [0:DDWIDTH-1] data_in,
                output signed [0:DWIDTH-1] data_out_0,
					 output signed [0:DWIDTH-1] data_out_1,
					 output signed [0:DWIDTH-1] data_out_2,
                input signed [0:CWIDTH-1] h_in,
					 output signed [0:CWIDTH-1] h_out_0,
					 output signed [0:CWIDTH-1] h_out_1,
					 output signed [0:CWIDTH-1] h_out_2);
  
	 // input/output buffering
	 reg signed [0:DWIDTH-1] data_out_buf[0:2];
	 reg signed [0:CWIDTH-1] h_out_buf[0:2];
	
	 assign data_out_0 = data_out_buf[0];
	 assign data_out_1 = data_out_buf[1];
	 assign data_out_2 = data_out_buf[2];
	 
	 assign h_out_0 = h_out_buf[0];
	 assign h_out_1 = h_out_buf[1];
	 assign h_out_2 = h_out_buf[2];
	 
	 /* TODO: actually need to split data and coefficients here */
	 // split input
	 wire signed [0:DWIDTH-1] a, b;
    assign {a, b} = data_in;
	 
    always @(posedge clk) begin
		  if (rst) begin
			  data_out_buf[0] <= 0;
			  data_out_buf[1] <= 0;
			  data_out_buf[2] <= 0;
			  h_out_buf[0] <= 0;
			  h_out_buf[1] <= 0;
			  h_out_buf[2] <= 0;
		  end
		  else begin
			  data_out_buf[0] <= a;
			  data_out_buf[1] <= a+b;
			  data_out_buf[2] <= b;
			  h_out_buf[0] <= h_in;
			  h_out_buf[1] <= h_in;
			  h_out_buf[2] <= h_in;
		  end
    end
endmodule