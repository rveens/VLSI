`timescale 1ns / 1ps

module filter #(parameter NR_STAGES = 32,
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
                input signed [0:CWIDTH-1] h_in);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
  
    // Accumulator (assigned to output directly)
    reg signed [0:DDWIDTH-1] sum;
    assign data_out = sum[0:DWIDTH-1]; //this one is truncated from 0:31 -> 0:15. If i make this explicit, it will use one DSP unit more (?)
	 
	 // Extra variables
	 reg state_busy;
	 reg signed [0:DDWIDTH-1] mem[0:NR_STAGES-1]; //must be 32-bit, else not enough place to do multiplication
	 integer cnt;
	 
    initial begin
			for(cnt = 0; cnt < 32; cnt = cnt + 1) begin
				mem[cnt] = 0;
			end
	 end
  
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
            // Input request & acknowledge => take the input & go back to computation a.s.a.p.
            if (req_in && ack_in) begin
					 mem[0] <= data_in;
					 state_busy <= 1;
                req_in_buf <= 0;
            end
				
				if (state_busy && !req_out_buf ) begin //processing part
					mem[cnt+1] <= mem[cnt];
					sum <= sum + mem[cnt]*h_in[cnt*DWIDTH +: DWIDTH];
					cnt <= cnt - 1;
					
					if(cnt == 0) begin
						cnt <= NR_STAGES-1;
						req_out_buf <= 1;
					end
				end
				
            // Output request & acknowledge => go back to computation a.s.a.p.
            if (req_out && ack_out) begin
                req_out_buf <= 0;
					 
					 sum <= 0; //reset sum
					 state_busy <= 0;
            end
				
            // If we need no inputs and have no outputs ready, then proceed with the computation
            if (!req_in && !req_out && !ack_in && !ack_out && !state_busy) begin   
                req_in_buf <= 1;
            end
					
        end
    end

endmodule
