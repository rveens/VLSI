`timescale 1ns / 1ps

module postproc #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input signed [0:DWIDTH-1] data_in_0,
					 input signed [0:DWIDTH-1] data_in_1,
					 input signed [0:DWIDTH-1] data_in_2,
                output signed [0:DDWIDTH-1] data_out);
  
	 // input/output buffering
	 reg signed [0:DWIDTH-1] data_in_buf[2:0];
	 reg signed [0:DDWIDTH-1] data_out_buf;
	
	 assign data_out = data_out_buf;
	 
    always @(posedge clk) begin
		  if(rst) begin
				data_in_buf[0] <= 0;
				data_in_buf[1] <= 0;
				data_in_buf[2] <= 0;				
				data_out_buf   <= 0;
		  end
		  else begin
				data_in_buf[0] <= data_in_0;
				data_in_buf[1] <= data_in_1;
				data_in_buf[2] <= data_in_2;
				data_out_buf[0:15] <= data_in_buf[0];
		  end  
    end

endmodule
