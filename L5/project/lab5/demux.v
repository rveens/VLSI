`timescale 1ns / 1ps

module demux
 #(parameter DWIDTH = 16,
	parameter NR_STREAMS = 16,
	parameter STREAMS_IDX = 0)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out);

	// Output request register
	reg req_out_buf;
	assign req_out = req_out_buf;

	// Input request register
	reg req_in_buf;
	assign req_in = req_in_buf;
	
	// Accumulator (assigned to output directly)
	reg signed [0:DWIDTH-1] data_out_reg;
	assign data_out = data_out_reg;
	
	reg [0:DWIDTH-1] str_cntr;
	
	always @(posedge clk) begin
		// Reset => initialize
		if (rst) begin
			req_in_buf <= 0;
			req_out_buf <= 0;
			data_out_reg <= 0;
			str_cntr <= 0;
		end
		// !Reset => run
		else begin
			// Input request & acknowledge => take the input & go back to computation a.s.a.p.
			if (req_in && ack_in) begin
				data_out_reg <= data_in;
								
				if (str_cntr < NR_STREAMS-1) begin//If the str_cntr is str_idx then read the data.			
				  str_cntr <= str_cntr + 1;
				end 
			   else begin	 
			     str_cntr <= 0;
			   end	
											
				if ( (str_cntr == STREAMS_IDX) ) begin	//so if the cnt is the index then get valid data until then stop.					  
				  req_out_buf <= 1;
				  req_in_buf <= 0;
				end
            				
			end
			
			//Read handshake is pending then stop producing output
			if (req_in && !ack_in) begin              
           req_out_buf <= 0;
         end
			
			
			// Output request & acknowledge => go back to computation a.s.a.p.
			if (req_out && ack_out) begin				
				req_out_buf <= 0;				
            req_in_buf <= 1;				
			end
			
			//Write handshake is pending then stop acquiring output.
         if (req_out && !ack_out) begin                			                  
			  req_in_buf <= 0;
         end 
			
			// If we need no inputs and have no outputs ready, then proceed with the computation
			if (!req_in && !req_out && !ack_in && !ack_out) begin	 
			  req_in_buf <= 1;
			end
		end
	end

endmodule
