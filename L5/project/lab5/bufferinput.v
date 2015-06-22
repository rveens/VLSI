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
	 
	 // state
	 reg [0:1] state;
	 parameter shift 	 = 1,
				  noshift = 2;
	 
	 // RAM wires
	 wire [0:DWIDTH-1] ram_data_out[0:3],
							 ram_data_in[0:2]; //+ data_in wire
  
	 reg [0:NR_STREAMS_LOG-1] write_ptr, read_ptr, feedback_ptr;
	 integer lookup_shift_index, streamcounter;

	 // Output + shift buffers
	 reg signed [0:DWIDTH-1] data_out_buf[0:3],
									 ram_in_buf[0:2];
	 
	 assign data_out_0 = data_out_buf[0];
	 assign data_out_1 = data_out_buf[1];
	 assign data_out_2 = data_out_buf[2];
	 assign data_out_3 = data_out_buf[3];
	 
	 assign ram_data_in[0] = ram_in_buf[0];
	 assign ram_data_in[1] = ram_in_buf[1];	
	 assign ram_data_in[2] = ram_in_buf[2];	
				 
	 // RAM enable wires + registers
	 reg write_enable_buf, feedback_enable_buf;
	 wire write_enable, feedback_enable;
	 assign write_enable = write_enable_buf;
	 assign feedback_enable = feedback_enable_buf;
			 
	 // Instantiate the RAM modules
	 // RAM_WIDTH, ADDRESS BITS
	 rom_mod #(16, NR_STREAMS_LOG)
		bram_0 (clk, rst, write_enable, write_ptr, data_in, read_ptr, ram_data_out[0]);
	 rom_mod #(16, NR_STREAMS_LOG)
		bram_1 (clk, rst, feedback_enable, feedback_ptr, ram_data_in[0], read_ptr, ram_data_out[1]);
    rom_mod #(16, NR_STREAMS_LOG)
		bram_2 (clk, rst, feedback_enable, feedback_ptr, ram_data_in[1], read_ptr, ram_data_out[2]);
    rom_mod #(16, NR_STREAMS_LOG)
		bram_3 (clk, rst, feedback_enable, feedback_ptr, ram_data_in[2], read_ptr, ram_data_out[3]);

	 // shift LUT similar to lab4
	 reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift
	 integer i;
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
		state 				<= 0;									
		streamcounter 		<= 0;
	 end

    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
				lookup_shift_index <= 0;
				write_enable_buf <= 1; // staat even op 1
				feedback_enable_buf <= 1; // staat even op 1

				write_ptr <= 0;
				read_ptr <= 0;
				feedback_ptr <= 0;
        end
        // !Reset => run
        else begin
					case (state)
						noshift: begin
							if (req_out && ack_out) begin
								 // 1) write sample into ram
									// nothing because of noshift
								 // 2) read four samples from ram for calculation
								 data_out_buf[0] <= ram_data_out[0];
								 data_out_buf[1] <= ram_data_out[1];
								 data_out_buf[2] <= ram_data_out[2];
								 data_out_buf[3] <= ram_data_out[3];
								 // 3) write back three of the four samples back into ram
									// read anyway
								 ram_in_buf[0] <= ram_data_out[0];
								 ram_in_buf[1] <= ram_data_out[1];
								 ram_in_buf[2] <= ram_data_out[2];
								 // 4) increment index_ptr
								 write_ptr <= (write_ptr+1)%NR_STREAMS;
								 read_ptr  <= write_ptr;
								 feedback_ptr <= read_ptr;
								 // 5) update feedback enable
								 if (feedback_ptr == NR_STREAMS-1) begin
									feedback_enable_buf <= 0;
								 end
							end
							
							if (req_out && !ack_out) begin
								// do nothing
							end
						
							// Idle state
							if (!req_in && !ack_in && !req_out && !ack_out) begin                		
								req_out_buf <= 1;
							end
							
							streamcounter <= (streamcounter+1)%NR_STREAMS;
							if (streamcounter == NR_STREAMS-1) begin
								state <= 0; // go to default
								req_in_buf <= 0;
								req_out_buf <= 0;
								write_enable_buf <= 0;
							end
						end
						
						shift: begin
							// Read handshake complete
							if (req_in && ack_in) begin		              					 
								 // 1) write sample into ram
								 // direct pin (data_in)
								 // 2) read four samples from ram for calculation
								 data_out_buf[0] <= ram_data_out[0];
								 data_out_buf[1] <= ram_data_out[1];
								 data_out_buf[2] <= ram_data_out[2];
								 data_out_buf[3] <= ram_data_out[3];
								 // 3) write back three of the four samples back into ram
								 ram_in_buf[0] <= ram_data_out[0];
								 ram_in_buf[1] <= ram_data_out[1];
								 ram_in_buf[2] <= ram_data_out[2];
								 // 4) increment index_ptr
								 write_ptr <= (write_ptr+1)%NR_STREAMS;
								 read_ptr  <= write_ptr;
								 feedback_ptr <= read_ptr;
								 // 5) update feedback enable
								 //if (feedback_ptr == NR_STREAMS-1) begin
								 //feedback_enable_buf <= 1;
								 //end
								 
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
							
							streamcounter <= (streamcounter+1)%NR_STREAMS;
							if (streamcounter == NR_STREAMS-1) begin
								//state <= 0; // go to default
								//req_in_buf <= 0;
								//req_out_buf <= 0;
								//write_enable_buf <= 0;
							end
								
						end
						
						default: begin
						
							// calc initial
							lookup_shift_index <= (lookup_shift_index + 1)%L;
							if (lookup_shift[lookup_shift_index] == 1) begin
								state <= shift;
							end else begin
								state <= shift;						
							end
						end	
				endcase
			end
    end

endmodule
