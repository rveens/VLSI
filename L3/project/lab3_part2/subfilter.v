`timescale 1ns / 1ps

module subfilter #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                output req_in,
                input  ack_in,
                input signed [0:DWIDTH-1] data_in,
                output req_out,
                input  ack_out,
                output signed [0:DWIDTH-1] data_out,
                input [0:CWIDTH-1] h_in);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
  
    // Accumulator (assigned to output directly)
    reg signed [0:DDWIDTH-1] sum;
    assign data_out = sum[0:DWIDTH-1]; 
	
	 // Memory to store last 32 inputs and memory to store the coefficients.
	 reg signed [0:DWIDTH-1] mem[0:NR_STAGES-1];
	 wire signed [0:DWIDTH-1] coef[0:NR_STAGES-1];
	 
	 // State variables for FIR
	 reg state_busy;
	 reg [4:0] cnt;
	 
	 integer j;
	 initial begin
		for (j = 0; j < NR_STAGES; j = j + 1)begin : yolo_init
			mem[j] <= 0;
		end
	 end
	 
	 generate
		genvar i;
		for (i = 0; i < NR_STAGES; i = i + 1)begin : yolo
			assign coef[i] = h_in[i*DWIDTH +: DWIDTH];
		end
	endgenerate
	 
  
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
				state_busy <= 0;
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum <= 0;
				cnt <= NR_STAGES-1;
        end
        else begin
            // Request for input sample is acknowledged. Start calculating
            if (req_in && ack_in) begin
					 mem[0] <= data_in;
					 state_busy <= 1;
                req_in_buf <= 0;
            end
				
				// Process the output in 32 cycles. Then initiate a req_out to warn the output that a sample is ready
				if (state_busy && !req_out) begin
					// Shift through the data and calculate one tap every clock cycle
					mem[cnt+1] <= mem[cnt];
					
					
					sum <= sum + mem[cnt]*coef[cnt];
					cnt <= cnt - 1;
					
					// When a complete cycle is done (32 taps calculated), start to output the outcome
					if(cnt == 0) begin
						cnt <= NR_STAGES-1;
						req_out_buf <= 1;
					end
				end
				
            // If req_out is acknowledged, reset all variables
            if (req_out && ack_out) begin
                req_out_buf <= 0;
					 state_busy <= 0;
					 sum <= 0;
            end
				
            // Wait until everyone is calmed down, then initiate new sample request
            if (!req_in && !req_out && !ack_in && !ack_out && !state_busy) begin   
                req_in_buf <= 1;
            end
					
        end
    end

endmodule
