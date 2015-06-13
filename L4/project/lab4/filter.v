`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input signed [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output signed [0:DWIDTH-1] data_out);
	
	// Output request register
	reg req_out_buf;
	assign req_out = req_out_buf;

	// Input request register
	reg req_in_buf;
	assign req_in = req_in_buf;
	
	// Accumulator and temporary buffer
	reg signed [0:DDWIDTH-8] sum; //25 bit!
	reg signed [0:DWIDTH-1] data_out_buf;
	assign data_out = data_out_buf;
	
	//coefficients data and lookup tables for the coef index and shift index
	reg signed [0:DWIDTH-1] mem[0:3],
									coef_buf,
									coef [0:CWIDTH-1], //** means 'power'
									lookup_coefIdx[0:L-1][0:3];
	reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift

	integer i, j, cnt;
	initial begin
		// import coefficients
		$readmemh("coef.txt", coef, 0, CWIDTH -1); 
		
		for (i = 0; i < L; i = i + 1) begin	
			for (j = 0; j < 4; j = j +1) begin
				lookup_coefIdx[i][j] = j*L + i*M%L;
			end
		end
		// define lookup tables
		for (i = 0; i < L; i = i + 1) begin		
			if(i*M/L == (i+1)*M/L)
				lookup_shift[i] = 0; //do not shift yet
			else
				lookup_shift[i] = 1; //shift	
		end		
	end
	
	// State machine variables
	reg [3:0] state;
	parameter input_data_requested 	= 1,
				 input_data_received 	= 2,
				 output_data_consumed 	= 3,
				 output_data_ready 		= 4,
				 data_processing_stage1 = 5,
				 data_processing_stage2 = 6,
				 waiting_for_ack 			= 7;
		  
	 // State machine that controls the flow control between testbench and filter
    always @(posedge clk) begin
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum <= 0;
				cnt <= 3;
				i <= 0;
				state <= 0;
        end
        else begin  
				case (state) 
					waiting_for_ack: begin
							if(req_in && ack_in)
								state <= input_data_received;
							
							if (req_out && ack_out)
								state <= output_data_consumed;
					end	
						
					input_data_requested: begin
							req_in_buf <= 1;
							state <= waiting_for_ack;
					end
					
					input_data_received: begin
							mem[0] <= data_in;
							
							req_in_buf <= 0;
							state <= data_processing_stage1;
					end
					
					// stage 1 of data processing to get the coefficients **pipelining**
					data_processing_stage1: begin
							// get coefficient for next run **reduce pipeline**
							coef_buf <= coef[lookup_coefIdx[i][cnt]];

							state <= data_processing_stage2;
					end
					
					// stage 2 of data processing to calculate one of the 4 taps
					data_processing_stage2: begin
							// shift the data, but only if we do not have to re-use it once more after this
							mem[cnt+lookup_shift[i]] <= mem[cnt];
							sum <= sum + mem[cnt]*coef_buf;
							
							cnt <= cnt - 1;

							if(cnt == 0)
									state <= output_data_ready;
							else
									state <= data_processing_stage1;
					end
					
					output_data_ready: begin
							data_out_buf <= sum[0:15];	
							cnt <= 3;
							
							req_out_buf <= 1;
							state <= waiting_for_ack;
					end
					
					output_data_consumed: begin
							// reset variables and increment index
							sum <= 0;		
							i <= (i + 1) % L;
							
							req_out_buf <= 0;
							if (lookup_shift[i] == 1)
								state <= input_data_requested;
							else
								state <= data_processing_stage1; //if the data is not shifted, we have to re-use it once more
					end
					
					default: begin
							state <= input_data_requested;
					end
				endcase  
			end
	 end
endmodule
