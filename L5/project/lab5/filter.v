`timescale 1ns / 1ps

module filter
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
	output [0:DWIDTH-1] data_out);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
    // Accumulator (assigned to output directly)
    reg signed [0:DWIDTH-1] sum;
    assign data_out = sum;
	 
	 // RAM wires and registers
	 reg ram_enable_buf; 
	 wire ram_enable;
	 assign ram_enable = ram_enable_buf;
	 
	 reg [0:NR_STREAMS_LOG-1] ram_address_ptr; 
	 wire [0:NR_STREAMS_LOG-1] ram_address;
	 assign ram_address = ram_address_ptr;
	 
	 wire [0:DWIDTH-1] ram_data_out[0:3];
	 reg signed [0:DWIDTH-1] ram_data_out_buf[0:3];
	 
	 // pipeline stage
	 reg signed [0:DDWIDTH-1] pl_mul_to_add_buf[0:3];
	 
	 // input buffer
	 reg signed [0:DWIDTH-1] data_in_buf;
	 wire [0:DWIDTH-1] data_in_wire;
	 assign data_in_wire = data_in_buf;
	 
	 // Instantiate the RAM modules
	 // RAM_WIDTH, ADDRESS BITS
	 rom_mod #(16, NR_STREAMS_LOG)
		bram_0 (clk, rst, ram_enable, ram_address, data_in_wire, ram_data_out[0]);
	 rom_mod #(16, NR_STREAMS_LOG)
		bram_1 (clk, rst, ram_enable, ram_address, ram_data_out[0], ram_data_out[1]);
    rom_mod #(16, NR_STREAMS_LOG)
		bram_2 (clk, rst, ram_enable, ram_address, ram_data_out[1], ram_data_out[2]);
    rom_mod #(16, NR_STREAMS_LOG)
		bram_3 (clk, rst, ram_enable, ram_address, ram_data_out[2], ram_data_out[3]);

	 // intialize buffers
	 reg shift_enable;
	 integer shift_idx;
	 reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift
	 reg signed [0:DWIDTH-1] coef [0:CWIDTH-1], lookup_coefIdx[0:L-1][0:3], coef_preproc[0:3];
	 
	 reg signed [0:DDWIDTH+1] circ_buf[0:NR_STREAMS-1];
	 integer buf_ptr;
	 
	 integer i, j;
	 initial begin
		for(i = 0; i < 4; i = i + 1) begin
			pl_mul_to_add_buf[i] <= 0;
			ram_data_out_buf[i] <= 0;
		end
		
		// define shift LUT
		for(i=0;i<L;i=i+1) begin
		  if(i*M/L == (i+1)*M/L)
				lookup_shift[i] = 0; //do not shift yet
		  else
				lookup_shift[i] = 1; //shift
		end
		
		// define coef LUT
	   for (i = 0; i < L; i = i + 1) begin
			for(j = 0; j < 4; j = j + 1) begin
				lookup_coefIdx[i][j] = j*L + i*M%L;
			end
	   end
		
		for (i = 0; i < NR_STREAMS; i = i + 1) begin
			circ_buf[i] <= 0;
		end
		
		// import coefficients
		$readmemh("coef.txt", coef, 0, CWIDTH -1);
	end

    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum <= 0;	
				shift_idx <=0;
				buf_ptr <= 0;
				shift_enable <= 0;
				data_in_buf <= 0;
				ram_enable_buf <= 1;
				ram_address_ptr <= 0;
        end
        // !Reset => run
        else begin

            // Read handshake complete
            if (req_in && ack_in) begin
					 // shift data in.
					 data_in_buf <= data_in; 
					 ram_enable_buf <= 1;
					 
					 req_in_buf <= 0;
            end
				
				// data shifted in
				if (ram_enable_buf== 1) begin
					ram_enable_buf <= 0;
				end
								
            // Write handshake complete
            if (req_out && ack_out) begin                				   
				   if(ram_address_ptr == NR_STREAMS-1) begin
						shift_enable <= lookup_shift[shift_idx];
						shift_idx <= (shift_idx + 1) % L;
					end

				   if(shift_enable == 1) begin
						req_in_buf <= 1;
					end
					else begin
						// nothing to do
					end
					req_out_buf <= 0;					
            end             			  
				
            // Idle state
            if (!req_in && !ack_in && !req_out && !ack_out && ram_enable_buf == 0) begin   
				
					 //retrieve samples
					 ram_data_out_buf[0] <= ram_data_out[0];
					 ram_data_out_buf[1] <= ram_data_out[1];
					 ram_data_out_buf[2] <= ram_data_out[2];
					 ram_data_out_buf[3] <= ram_data_out[3];
					 
					 //multiply with coefficients **todo**
					 pl_mul_to_add_buf[0] <= ram_data_out_buf[0]*coef_preproc[0];
					 pl_mul_to_add_buf[1] <= ram_data_out_buf[1]*coef_preproc[1];
					 pl_mul_to_add_buf[2] <= ram_data_out_buf[2]*coef_preproc[2];
					 pl_mul_to_add_buf[3] <= ram_data_out_buf[3]*coef_preproc[3];
					 
					 //accumulate and output
					 circ_buf[buf_ptr]	<= 	pl_mul_to_add_buf[0] +  
													   pl_mul_to_add_buf[1] + 
													   pl_mul_to_add_buf[2] + 
													   pl_mul_to_add_buf[3];
					
					 // put data from previous stream on output
					 sum <= circ_buf[(buf_ptr+2)%NR_STREAMS][3:DWIDTH+2];		 
					 ram_address_ptr <= (ram_address_ptr + 1) % NR_STREAMS;		
					 buf_ptr <= (buf_ptr + 1)%((NR_STREAMS));	
					 
					 // preprocess next coefficients
					  coef_preproc[0] <= coef[lookup_coefIdx[shift_idx][0]];
					  coef_preproc[1] <= coef[lookup_coefIdx[shift_idx][1]];
					  coef_preproc[2] <= coef[lookup_coefIdx[shift_idx][2]];
					  coef_preproc[3] <= coef[lookup_coefIdx[shift_idx][3]];

			       req_out_buf <= 1;	
            end
				
        end
    end

endmodule
