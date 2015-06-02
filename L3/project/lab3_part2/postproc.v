`timescale 1ns / 1ps

module postproc #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input signed [0:DWIDTH-1] data_in,
                output signed [0:DWIDTH-1] data_out // split by 3
					 );
  
	 // input/output buffering
	 reg signed [0:DWIDTH-1] data_in_buf;
	 reg signed [0:DWIDTH-1] data_out_buf;
	
	 assign data_out = data_out_buf;
	 
    always @(posedge clk) begin
		  if(rst) begin
				data_in_buf <= 0;
				data_out_buf <= 0;
		  end
		  else begin
				data_in_buf <= data_in;
				data_out_buf <= data_in_buf;
		  end
		  
    end

endmodule
