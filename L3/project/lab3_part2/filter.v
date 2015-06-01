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
	 
	 	 
	 // extra stuff
	 reg [0:(CWIDTH/2)-1] h0;
	 reg [0:(CWIDTH/2)-1] h1;
	 reg [0:(CWIDTH/2)-1] h0_1;
	 wire [0:DWIDTH-1] a0_1;
	 
	 assign a0_1 = a0 + a1;
	 
	 // split coefficients
	 integer i;
	 initial begin
			for (i = 0; i < (CWIDTH/2)-1; i = i + 1) begin
				h0[i] <= h_in[i*2];
				h1[i] <= h_in[i*2 + 1];
				h0_1[i] <= h_in[i*2] + h_in[i*2 + 1];
			end
	 end
  
	 // instantiate subfirs
	 // use a0 and even of h_in (H0)
	 passivator #(.DWIDTH(DWIDTH)) pass_H0 ();
	 subfilter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
		subfilterH0 (clk, rst, req_in1/*?*/, ack_in1/*?*/, a0, req_out1/*?*/, ack_out1/*?*/, data_out1/*?*/, h0
	 );
	 
	 // use a0+a1 and even + uneven of h_in (H0+H1)
	 subfilter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
		subfilterH0_1 (clk, rst, req_in1/*?*/, ack_in1/*?*/, a0_1, req_out1/*?*/, ack_out1/*?*/, data_out1/*?*/, h0_1
	 );
	 
	 // use a1 and uneven of h_in (H1)
	 subfilter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
		subfilterH1 (clk, rst, req_in1/*?*/, ack_in1/*?*/, a1, req_out1/*?*/, ack_out1/*?*/, data_out1/*?*/, h1
	 );
  
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
                b0 <= a0;
                b1 <= a1;
                req_in_buf <= 0;
                req_out_buf <= 1;
            end
            // Output request & acknowledge => go back to computation a.s.a.p.
            if (req_out && ack_out) begin
                req_out_buf <= 0;
            end
            // If we need no inputs and have no outputs ready, then proceed with the computation
            if (!req_in && !req_out && !ack_in && !ack_out) begin   
                req_in_buf <= 1;
            end
        end
    end

endmodule
