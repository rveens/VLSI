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
	
	// Accumulator (assigned to output directly)
	reg signed [0:33-1] sum;
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
	reg [0:DWIDTH-1]lookup_coefIdx[0:L-1]; //'1' means shift, '0' means no shift
	
	integer i, cnt;
	initial begin
		// import coefficients
		$readmemh("coef.txt", coef, 0, CWIDTH -1); 
		
		// define lookup tables
		for (i = 0; i < L; i = i + 1) begin
			if(i*M/L == (i+1)*M/L)
				lookup_shift[i] = 0; //do not shift yet
			else
				lookup_shift[i] = 1; //shift		
			lookup_coefIdx[i] = i*M%L;	
		end	 
	end
	
	integer c_idx;
	 // State machine that controls the flow control between testbench and filter
    always @(posedge clk) begin
        if (rst) begin
				state_busy <= 0;
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum <= 0;
				cnt <= 3;
				i <= 0;
				c_idx<=0;
        end
        else begin
            // Request for input sample is acknowledged. Start calculating
            if (req_in && ack_in) begin
					 if(lookup_shift[i-1] == 1 || i == 0)
						mem[0] <= data_in;
						
					 state_busy <= 1;
                req_in_buf <= 0;
            end
				
				// Process the output in 32 cycles. Then initiate a req_out to warn the output that a sample is ready
				if (state_busy && !req_out) begin
					// Shift through the data and calculate one tap every clock cycle
					
					// Do 160, then clock new data in.
					if(lookup_shift[i] == 1)
						mem[cnt+1] <= mem[cnt];
						
						c_idx = 	(cnt*L)+lookup_coefIdx[i];
						sum <= sum + mem[cnt]*coef[c_idx];
						cnt <= cnt - 1;
				
					// When a complete cycle is done (32 taps calculated), start to output the outcome
					if(cnt == 0) begin
						i <= (i + 1) % 160;
						cnt <= 3;
					
						data_out_buf <= sum[0:15];
						req_out_buf <= 1;
					end
				end
				
            // If req_out is acknowledged, reset all variables
            if (req_out && ack_out) begin
                req_out_buf <= 0;
					 
					 data_out_buf<=0;
					 sum <= 0;
					 
					 if(lookup_shift[i] == 1)
						state_busy <= 0;
					 else
						state_busy <= 1;	
            end
				
            // Wait until everyone is calmed down, then initiate new sample request
            if (!req_in && !req_out && !ack_in && !ack_out && !state_busy) begin   
                req_in_buf <= 1;
            end	
        end
    end
endmodule