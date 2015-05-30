`timescale 1ns / 1ps

module filter #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                output req_in,
                input  ack_in,
                input  [0:DDWIDTH-1] data_in,
                output req_out,
                input  ack_out,
                output [0:DDWIDTH-1] data_out,
                input  [0:CWIDTH-1] h_in);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
  
    // Accumulator (assigned to output directly)
	 reg signed [0:DDWIDTH-1] subsum;
    reg signed [0:DDWIDTH-1] sum;
    assign data_out = sum;
	 
	 // Busy register to indicate that filter is busy
	 reg busy_buf;
	 reg [4:0] cnt; 
	 reg [0:DDWIDTH-1] mem[0:NR_STAGES-1];
	 integer i;
	 
	 initial begin
		cnt = 0;
		for(i = 0; i < 32; i = i + 1) begin
			mem[i] = 0;
		end
	 end
	 
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf 	<= 0;
            req_out_buf <= 0;
				busy_buf		<= 0;
            sum 			<= 0;
        end
        // !Reset => run
        else begin
            // Input request & acknowledge => take the input & go back to computation a.s.a.p.
            if (req_in && ack_in) begin
                //sum <= data_in;
					 mem[0] = data_in;
					 for(i = 1; i < 32; i = i + 1)begin
					 	 mem[i] = mem[i-1];
					 end
					 
                req_in_buf <= 0;
					 busy_buf 	<= 1;
            end
				
				// Data processing loop
				if (busy_buf == 1) begin
					// todo: calculate next tap
					subsum <= subsum +  h_in[cnt*DWIDTH +: DWIDTH]*mem[cnt];
					
					// this if may contain a bug, since its not executed like c code
					if (cnt == 31) begin
						sum <= subsum;
						busy_buf 	<= 0;
						cnt 			<= 0;
						req_out_buf <= 1;
					end
					
					cnt <= cnt + 1;
				end
				
            // Output request & acknowledge => go back to computation a.s.a.p.
            if (req_out && ack_out) begin
                req_out_buf <= 0;
					 subsum <= 0;
            end
				
            // If we need no inputs and have no outputs ready, then proceed with the computation
            if (!req_in && !req_out && !ack_in && !ack_out && !busy_buf) begin   
                req_in_buf <= 1;
            end
        end
    end

endmodule
