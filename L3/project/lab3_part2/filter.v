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

    // Split input into 2 samples
    wire signed [0:DWIDTH-1] a0, a1;
    assign {a0, a1} = data_in;
    
    // Buffer and combine 2 samples into output
    reg signed [0:DWIDTH-1] b0, b1;
    assign data_out = {b0, b1};
	 
	 reg busy;
	 wire [0:DWIDTH-1] a0_filter;
	 reg [0:DWIDTH-1] a0_buf; 
	 assign a0_filter = a0_buf;
	 
	 wire [0:DWIDTH-1] b0_filter;
	 
	 reg req_out_filter_buf;
	 assign req_out_filter = req_out_filter_buf;
	 
	 reg req_in_filter_buf;
	 assign req_in_filter = req_in_filter_buf;
	 
	 wire ack_in_filter;
	 wire ack_out_filter;
	 
	 
	 mainfilter #(NR_STAGES, DWIDTH, DDWIDTH, CWIDTH) main
						(clk,
                   rst,
                   req_in_filter,
                   ack_in_filter,
                   a0_filter,
                   req_out_filter,
                   ack_out_filter,
                   b0_filter,
							h_in);
	 
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            b0 <= 0;
            b1 <= 0;
        end
        // !Reset => run
        else begin
            // Input request & acknowledge => take the input & go back to computation a.s.a.p.
            if (req_in && ack_in) begin
					req_in_filter_buf <= 1;
					if ( req_in_filter && ack_in_filter ) begin
						a0_buf <= a0;
						req_in_buf <= 0;
						req_in_filter_buf <= 0;
						req_out_filter_buf <= 1;
						busy <= 1;
					end
            end
				
				if (busy && ack_out_filter) begin
					req_out_buf <= 1;
					if( req_out && ack_out ) begin
						b0 <= b0_filter;
						req_out_filter_buf <= 0;
						req_out_buf <= 0;
						busy <= 0;
					end
				end
				
            // If we need no inputs and have no outputs ready, then proceed with the computation
            if (!req_in && !req_out && !ack_in && !ack_out && !busy) begin   
                req_in_buf <= 1;
            end
        end
    end

endmodule
