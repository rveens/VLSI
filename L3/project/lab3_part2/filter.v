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

   

    // Input request registers
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
	 reg req_in_filter_buf;
	 assign req_in_filter = req_in_filter_buf;
	 
	  // Output request registers
    reg req_out_buf;
    assign req_out = req_out_buf;
	 
	 reg req_out_filter_buf;
	 assign req_out_filter = req_out_filter_buf;

    // Split input into 2 samples
    wire signed [0:DWIDTH-1] a0, a1;
    assign {a0, a1} = data_in;
    
    // Buffer and combine 2 samples into output
    reg signed [0:DWIDTH-1] b0, b1;
    assign data_out = {b0, b1};
	 
	 //input
	 wire [0:DWIDTH-1] a0_filter;
	 wire [0:DWIDTH-1] b0_filter;
	 reg signed [0:DWIDTH-1] a0_filter_buf; 
	 assign a0_filter = a0_filter_buf;
	 
	 // Extra wires and flags
	 reg hold_cons, hold_prod;
	 
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
				req_in_filter_buf  <= 0;
				req_out_filter_buf <= 0;
            b0 <= 0;
            b1 <= 0;
				hold_prod <= 0;
				hold_cons <= 0;
				a0_filter_buf <= 0;
        end
        // !Reset => run
        else begin
				///////// Input data processing (Testbench => Mainfilter)
	
				// if not busy, place new request
				if (!req_in && !ack_in && !hold_prod) begin
					req_in_buf <= 1;
				end
				
				// warn mainfilter that there is data available
				if (req_in && ack_in) begin
					a0_filter_buf <= a0;
					req_in_buf <= 0;
					req_in_filter_buf <= 1;
					hold_prod <= 1;
				end
				
				// If mainfilter acknowledges, start retrieving new sample
				if (req_in_filter && ack_in_filter) begin
					a0_filter_buf <= 0;
					req_in_filter_buf <= 0;
					hold_prod <= 0; //main filter may still be busy but this does not matter, since it will just not acknowledge
				end
		  
		  
				////////// Output data processing (Mainfilter => Testbench)
				
				// If nothing at the output, issue request
				if (!req_out_filter && !ack_out_filter && !hold_cons) begin
					req_out_filter_buf <= 1;
				end
				
				// If the request is ack-ed, process data and warn testbench
				if (req_out_filter && ack_out_filter) begin
					req_out_filter_buf <= 0;
					req_out_buf <= 1;
					hold_cons <= 1;
				end
				
				// Process to testbench
				if (req_out && ack_out) begin
					b0 <= b0_filter;
					req_out_buf <= 0;
					hold_cons <= 0;
				end
				
				
        end
    end

endmodule
