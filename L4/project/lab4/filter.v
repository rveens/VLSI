`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 10, //made it 10, because it has to store 4*160 coefficients
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
	
	// Accumulator
	reg signed [0:DDWIDTH-8] sum; //25 bit!
	reg signed [0:DWIDTH-1] data_out_buf;
	assign data_out = data_out_buf;
	
	// We have to store M items to do the complete calculation
	reg signed [0:DWIDTH-1] mem [0:3];
	 
	// State variables for FIR
	reg state_busy;

	//coefficients data
	reg signed [0:DWIDTH-1] coef [0:CWIDTH-1]; //** means 'power'
	
	//Lookup tables for the coefficient index and if we have to shift or not
	reg [0:L-1]lookup_shift; //'1' means shift, '0' means no shift
	reg [0:DWIDTH-1]lookup_coefIdx[0:L-1][0:3]; //'1' means shift, '0' means no shift
	
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
	
	integer y,z, x, c_idx;
	
	parameter input_data_requested = 1,
				 input_data_received = 2,
				 output_data_consumed = 3,
				 output_data_ready = 4,
				 data_processing = 5,
				 waiting_for_ack = 6;
		  
	reg [3:0] state;

	 // State machine that controls the flow control between testbench and filter
    always @(posedge clk) begin
        if (rst) begin
				state_busy <= 0;
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum <= 0;
				cnt <= 3;
				i <= 0;
				c_idx =0;
				y = 0;
				z = 0;
				x = 0;
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
               //state_busy <= 1;
               req_in_buf <= 0;

					state <= data_processing;
			end	
			data_processing: begin
					mem[cnt+lookup_shift[i]] <= mem[cnt];
					c_idx = lookup_coefIdx[i][cnt];
						
					sum <= sum + mem[cnt]*coef[c_idx];
					cnt <= cnt - 1;

                // When a complete cycle is done (32 taps calculated), start to output the outcome
                if(cnt == 0) begin
							state <= output_data_ready;
                end
			end
			output_data_ready: begin
					cnt <= 3;
					data_out_buf <= sum[0:15];			
					req_out_buf <= 1;

					state <= waiting_for_ack;
			end
			output_data_consumed: begin
					req_out_buf <= 0;
               sum <= 0;
					
					i <= (i + 1) % 160;
					 
					if (lookup_shift[i])
						state <= input_data_requested;
					else
						state <= data_processing;
			end		
			default:
					state <= input_data_requested;
      endcase  
    
		end
	 end
endmodule
