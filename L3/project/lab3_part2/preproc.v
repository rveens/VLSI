`timescale 1ns / 1ps

module preproc #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input signed [0:DWIDTH-1] data_in,
                output signed [0:DWIDTH-1] data_out, // split by 3
                input signed [0:CWIDTH-1] h_in,
					 output signed [0:CWIDTH-1] h_out // split into h0, h1, h0_1
					 );
  
	 // input/output buffering
	 reg signed [0:DWIDTH-1] data_out_buf;
	 reg signed [0:CWIDTH-1] h_out_buf;
	
	 assign data_out = data_out_buf;
	 assign h_out = h_out_buf;
	 
    always @(posedge clk) begin
		  if(rst) begin
			  data_out_buf <= 0;
			  h_out_buf <= 0;
		  end
		  else begin
			  data_out_buf <= data_in;
			  h_out_buf <= h_in;
		  end
    end

endmodule