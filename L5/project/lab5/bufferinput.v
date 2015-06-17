`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15:53:07 06/16/2015 
// Design Name: 
// Module Name: bufferinput 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bufferinput
 #( parameter DWIDTH = 16,
 parameter DDWIDTH = 2*DWIDTH,
 parameter NR_STREAMS = 16,
 parameter NR_STREAMS_LOG = 4,
 parameter RAM_WIDTH = DWIDTH;
 parameter RAM_ADDR_BITS = <ram_addr_bits> )(
 input enable,
 input clk,
 input ack_in,
 output req_in,
 input [0:DWIDTH-1] data_in,
 input ack_out,
 output req_out,
 output [0:DWIDTH-1] data_out
 );


 (* RAM_STYLE="{AUTO | BLOCK | BLOCK_POWER1 | BLOCK_POWER2}" *)
 reg [RAM_WIDTH-1:0] bram1 [(2**RAM_ADDR_BITS)-1:0];
 reg [RAM_WIDTH-1:0] <output_dataA>, <output_dataB>;

 <reg_or_wire> [RAM_ADDR_BITS-1:0] <addressA>, <addressB>;
 <reg_or_wire> [RAM_WIDTH-1:0] <input_dataA>;
 
 /* circular buffer bureaucratic mess */
 reg [NR_STREAMS_LOG-1:0] rd_ptr, wr_ptr;
 
 // First buffer is used for output pipelining, the second one for storing 
 reg [NR_STREAMS_LOG-1:0] ram_output_buf[0:3];
 reg [NR_STREAMS_LOG-1:0] ram_shift_buf[0:2];
 
 // Stores if we have to shift or not
 reg to_shift_or_not_to_shift;
 integer i;
 
 always @(posedge clk) begin
 // Reset => initialize
	 if (rst) begin
			 req_in_buf <= 0;
			 req_out_buf <= 0;
			 sum <= 0; 
	 end
	 // !Reset => run
	 else begin
			 // Read handshake complete
			 if (req_in && ack_in) begin
				 <ram_name>[<addressA>] <= <input_dataA>;
				 <output_dataA> <= <ram_name>[<addressA>];
				 <output_dataB> <= <ram_name>[<addressB>]; 
				 req_out_buf <= 1; 
			 end 
			 
			 //Read handshake is pending then stop producing output
			 if (req_in && !ack_in) begin 
				req_out_buf <= 0;
			 end 
			 
			 // Write handshake complete
			 if (req_out && ack_out) begin 
				req_in_buf <= 1; 
			 end 

			 //Write handshake is pending then stop acquiring output.
			 if (req_out && !ack_out) begin 
				req_in_buf <= 0;
			 end 
			 
			 // Idle state
			 if (!req_in && !ack_in && !req_out && !ack_out) begin 
				req_in_buf <= 1; 
			 end
			 
			 if (write action issued) begin
					// if we are not full
					if (wr_ptr != (rd_ptr-1)%NR_STREAMS) begin
						req_in <= 0; //acknowledge
						
						// write the new sample into the ram
						ram1(wr_ptr) <= input_data;
						
						wr_ptr <= (wr_ptr + 1) % NR_STREAMS;
					end
			 end
			 
			 if (read action issued) begin
					// we can read until we read the write ptr (skip last sample for simplicity)
					if (rd_ptr != wr_ptr) begin
					
						// retrieve 4 new samples from RAM
						ram_output_buf[0] <= ram1(rd_ptr);
						ram_output_buf[1] <= ram2(rd_ptr);
						ram_output_buf[2] <= ram3(rd_ptr);
						ram_output_buf[3] <= ram4(rd_ptr);
						
						// write the shifted samples that were already in buf back
						ram2(rd_ptr-1) <= ram_output_buf[0];
						ram3(rd_ptr-1) <= ram_output_buf[1];
						ram4(rd_ptr-1) <= ram_output_buf[2];
						
						 // if the read pointer has made one round-trip, update.
						 if(rd_ptr == 0) begin
							to_shift_or_not_to_shift <= shift_lut[i];
							
							// shift array index
							i <= (i + 1) % L;
						 end
											
						rd_ptr <= (rd_ptr + 1) % NR_STREAMS;
					end
			 end
			 

			 
			 
		end
 end

endmodule	