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
 parameter RAM_WIDTH = DWIDTH,
 parameter RAM_ADDR_BITS = 10, 
 parameter L = 160,
 parameter M = 147)(
 input clk,
 input rst,
 input ack_in,
 output req_in,
 input [0:DWIDTH-1] data_in,
 input ack_out,
 output req_out,
 output [0:DWIDTH-1] data_out_0,
 output [0:DWIDTH-1] data_out_1,
 output [0:DWIDTH-1] data_out_2,
 output [0:DWIDTH-1] data_out_3
 );
 
 // request registers
 reg req_in_buf, req_out_buf;
 
 assign req_out = req_out_buf;
 assign req_in = req_in_buf;
 
 // RAM address pointers
 wire [0:RAM_ADDR_BITS-1] rd_ptr, wr_ptr, shift_ptr;
 reg [0:RAM_ADDR_BITS-1] rd_ptr_buf, wr_ptr_buf, shift_ptr_buf;
 assign rd_ptr = rd_ptr_buf;
 assign wr_ptr = wr_ptr_buf;
 assign shift_ptr = shift_ptr_buf;
 
 // RAM wires
 wire [0:DWIDTH-1] ram_data_out[0:3],
						 ram_data_in[0:2]; //+ data_in wire

 // Output + shift buffers
 reg [0:DWIDTH-1] data_out_buf[0:3],
						data_in_buf[0:2];
 
 assign data_out_0 = data_out_buf[0];
 assign data_out_1 = data_out_buf[1];
 assign data_out_2 = data_out_buf[2];
 assign data_out_3 = data_out_buf[3];
 assign ram_data_in[0] = data_in_buf[0];
 assign ram_data_in[1] = data_in_buf[1];
 assign ram_data_in[2] = data_in_buf[2];						 
						 
 // RAM enable wires + registers
 reg shift_enable_buf, write_enable_buf;
 wire shift_enable, write_enable;
 assign shift_enable = shift_enable_buf;
 assign write_enable = write_enable_buf;
 integer i;	
						 
 // Instantiate the RAM modules **RAM modules currently have no functionality**
 rom_mod #(.RAM_WIDTH(RAM_WIDTH), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
	bram_0 (clk, rst, write_enable, wr_ptr, data_in, rd_ptr, ram_data_out[0]);
 rom_mod #(.RAM_WIDTH(RAM_WIDTH), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
	bram_1 (clk, rst, shift_enable, shift_ptr, ram_data_in[0], rd_ptr, ram_data_out[1]);
 rom_mod #(.RAM_WIDTH(RAM_WIDTH), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
	bram_2 (clk, rst, shift_enable, shift_ptr, ram_data_in[1], rd_ptr, ram_data_out[2]);
 rom_mod #(.RAM_WIDTH(RAM_WIDTH), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
	bram_3 (clk, rst, shift_enable, shift_ptr, ram_data_in[2], rd_ptr, ram_data_out[3]);

 // shift LUT similar to lab4
 reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift
 initial begin
    // define lookup tables
        if(i*M/L == (i+1)*M/L)
            lookup_shift[i] = 0; //do not shift yet
        else
            lookup_shift[i] = 1; //shift
 end
 
 always @(posedge clk) begin
 // Reset => initialize
	 if (rst) begin
			 req_in_buf <= 0;
			 req_out_buf <= 0;

			 data_out_buf[0] <= 0;
			 data_out_buf[1] <= 0;
			 data_out_buf[2] <= 0;
			 data_out_buf[3] <= 0;
			 data_in_buf[0] <= 0;
			 data_in_buf[1] <= 0;
			 data_in_buf[2] <= 0;
			 
			 write_enable_buf <= 1;
			 shift_enable_buf <= 0;
			 rd_ptr_buf <= 0;
			 wr_ptr_buf <= 0;
			 shift_ptr_buf <= 0;
	 end
	 // !Reset => run
	 else begin
			 // Read handshake complete
			 if (req_in && ack_in) begin
				
				// new sample received, update write pointer
				wr_ptr_buf <= (wr_ptr_buf + 1) % NR_STREAMS;
				
				req_out_buf <= 1; 
			 end 
			 
			 //Read handshake is pending then stop producing output
			 if (req_in && !ack_in) begin 
				req_out_buf <= 0;
			 end 
			 
			 // Write handshake complete
			 if (req_out && ack_out) begin 
					// we can read until we read the write ptr (skip last sample for simplicity)
					if (rd_ptr_buf != wr_ptr_buf) begin
					
						// RAM output data
						data_out_buf[0] <= ram_data_out[0];
						data_out_buf[1] <= ram_data_out[1];
						data_out_buf[2] <= ram_data_out[2];
						data_out_buf[3] <= ram_data_out[3];
						
						// Update shift buffers
						data_in_buf[0]	<= ram_data_out[0];
						data_in_buf[1] <= ram_data_out[1];
						data_in_buf[2] <= ram_data_out[2];
						
						 // if the read pointer has made one round-trip of L, update.
						 if(rd_ptr_buf == 0) begin
							shift_enable_buf <= lookup_shift[i];
							
							// shift array index
							i <= (i + 1) % L;
						 end
						
						// Update address pointer						
						rd_ptr_buf <= (rd_ptr_buf + 1) % NR_STREAMS;
						shift_ptr_buf <= rd_ptr_buf - 1;
					end
			 
					//if we are not full
					if (wr_ptr != (rd_ptr-1)%NR_STREAMS) begin
						req_in_buf <= 1; 
					end
					else begin
						req_in_buf <= 0; 
					end
			 end 

			 //Write handshake is pending then stop acquiring output.
			 if (req_out && !ack_out) begin 
				req_in_buf <= 0;
			 end 
			 
			 // Idle state
			 if (!req_in && !ack_in && !req_out && !ack_out) begin 
				req_in_buf <= 1; 
			 end
		end
 end

endmodule	