`timescale 1ns / 1ps

module bufferinput
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L,
	parameter NR_STREAMS = 16,
    parameter NR_STREAMS_LOG = 4)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out_0,
	output [0:DWIDTH-1] data_out_1,
	output [0:DWIDTH-1] data_out_2,
	output [0:DWIDTH-1] data_out_3);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
	 // RAM wires
	 wire [0:DWIDTH-1] ram_data_out[0:3],
							 ram_data_in[0:3]; //+ data_in wire
  
	 reg [0:10-1] rd_ptr, wr_ptr, shift_ptr;
	 integer i;

	 // Output + shift buffers
	 reg signed [0:DWIDTH-1] data_out_buf[0:3],
									 data_in_buf,
									 ram_in_buf[0:2];
	 
	 assign data_out_0 = data_out_buf[0];
	 assign data_out_1 = data_out_buf[1];
	 assign data_out_2 = data_out_buf[2];
	 assign data_out_3 = data_out_buf[3];
	 
	 assign ram_data_in[0] = data_in_buf;
	 assign ram_data_in[1] = ram_in_buf[0];
	 assign ram_data_in[2] = ram_in_buf[1];	
	 assign ram_data_in[3] = ram_in_buf[2];	
				 
	 // RAM enable wires + registers
	 reg shift_enable_buf, write_enable_buf;
	 wire shift_enable, write_enable;
	 assign shift_enable = shift_enable_buf;
	 assign write_enable = write_enable_buf;
			 
	 // Instantiate the RAM modules
	 // RAM_WIDTH, ADDRESS BITS
	 rom_mod #(16, 10)
		bram_0 (clk, rst, write_enable, wr_ptr, ram_data_in[0], rd_ptr, ram_data_out[0]);
	 rom_mod #(16, 10)
		bram_1 (clk, rst, shift_enable, shift_ptr, ram_data_in[0], rd_ptr, ram_data_out[1]);
    rom_mod #(16, 10)
		bram_2 (clk, rst, shift_enable, shift_ptr, ram_data_in[1], rd_ptr, ram_data_out[2]);
    rom_mod #(16, 10)
		bram_3 (clk, rst, shift_enable, shift_ptr, ram_data_in[2], rd_ptr, ram_data_out[3]);

	 // shift LUT similar to lab4
	 reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift
	 initial begin
		 // define lookup tables
		 for(i=0;i<L;i=i+1) begin
			  if(i*M/L == (i+1)*M/L)
					lookup_shift[i] = 0; //do not shift yet
			  else
					lookup_shift[i] = 1; //shift
		 end
 
		data_out_buf[0] 	<= 0;
		data_out_buf[1] 	<= 0;
		data_out_buf[2] 	<= 0;
		data_out_buf[3] 	<= 0;
		ram_in_buf[0]	 	<= 0;
		ram_in_buf[1]  	<= 0;
		ram_in_buf[2]  	<= 0;
		data_in_buf 		<= 0;
	 end

    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;

				shift_enable_buf <= 0;
				write_enable_buf <= 1;

				rd_ptr <= 0;
				wr_ptr <= 0;
				shift_ptr <= 0;
        end
        // !Reset => run
        else begin
						// Read handshake complete
						if (req_in && ack_in ) begin
						
							// if full
							if ((wr_ptr + 1) %1024 == rd_ptr) begin
								req_in_buf <= 0;
							end
							
							// new RAM input data
							data_in_buf <= data_in;
							
							wr_ptr <= (wr_ptr + 1) % 1024;
							 				              					 
							req_out_buf <= 1;                					  
						end			   				
				
						//Read handshake is pending then stop producing output. array is empty
						if ((req_in && !ack_in)) begin  
						
							req_out_buf <= 0;
						end 
										
						// Write handshake complete
						if (req_out && ack_out) begin  
							
							 // if empty
							 if (wr_ptr == rd_ptr) begin
								 req_out_buf <= 0; 
							 end
	
							 // RAM output data
							 data_out_buf[0] <= ram_data_out[0];
							 data_out_buf[1] <= ram_data_out[1];
							 data_out_buf[2] <= ram_data_out[2];
							 data_out_buf[3] <= ram_data_out[3];
							 
							 // RAM shift data
							 ram_in_buf[0] <= ram_data_out[0];
							 ram_in_buf[1] <= ram_data_out[1];
							 ram_in_buf[2] <= ram_data_out[2];
							 
							 // if the read pointer has made one round-trip of NR_STAGES, update.
							 if(rd_ptr == 0) begin
								shift_enable_buf <= lookup_shift[i];
								
								// shift array index
								i <= (i + 1) % L;
							end
							 
							 rd_ptr <= (rd_ptr + 1) % 1024;
							 shift_ptr <= rd_ptr;
						
							 req_in_buf <= 1; 
						end 

						//Write handshake is pending then stop acquiring output. array is full
						if ((req_out && !ack_out)) begin 
							req_in_buf <= 0;
						end 			            			  
						
						// Idle state
						if (!req_in && !ack_in && !req_out && !ack_out) begin                		
						  req_in_buf <= 1;					
						end
				
				end
    end

endmodule
