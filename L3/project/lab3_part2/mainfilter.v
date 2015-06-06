`timescale 1ns / 1ps

module mainfilter #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input req_in,
                output  ack_in,
                input signed [0:DDWIDTH-1] data_in,
                input req_out,
                output  ack_out,
                output signed [0:DDWIDTH-1] data_out,
                input signed [0:CWIDTH-1] h_in);
     
	 // registers and wires used for merging all acknowledges of the subfilters
	 wire ack_in_split[2:0], ack_out_split[2:0];
	 reg ack_in_buf, ack_out_buf;
	 assign ack_in = ack_in_buf;
	 assign ack_out = ack_out_buf;
	
	 // wires for input and output passivators	
	 wire req_in_subfilter_pass[2:0], ack_in_pass_subfilter[2:0];
	 wire req_out_subfilter_pass[2:0], ack_out_subfilter_pass[2:0];
	 
	 // wires that carry all data through the filters
	 wire signed [0:DWIDTH-1] data_in_preproc_pass[2:0], 
					 data_in_pass_subfilter[2:0],
					 data_out_subfilter_pass[2:0],
					 data_out_pass_post[2:0];
	 wire signed [0:DDWIDTH-1] data_out_merged;
					 
	 // register to buffer the merged output data 
	 reg signed [0:DDWIDTH-1] data_out_buf;
	 assign data_out = data_out_buf;
	 
	 // wires used to carry the coefficients for each subfilter
	 wire signed [0:((NR_STAGES/2)*DWIDTH)-1] h_out_preproc_subfilter[2:0];
	 
	 // instantiate all components (preproc, 3x passivator, 3x fir, 3x passivator, postproc) 
	 preproc #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
			pre (clk, rst, 
				  data_in, data_in_preproc_pass[0], data_in_preproc_pass[1], data_in_preproc_pass[2],
				  h_in, h_out_preproc_subfilter[0], h_out_preproc_subfilter[1], h_out_preproc_subfilter[2]);
	
	 generate
        genvar i;
        for (i = 0; i < 3; i = i + 1) begin : stage
          passivator #(.DWIDTH(DWIDTH)) 
			 pass_in (req_in,ack_in_split[i],
						 data_in_preproc_pass[i],req_in_subfilter_pass[i],ack_in_pass_subfilter[i],
						 data_in_pass_subfilter[i]);
			 
			 subfilter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
		    sfil	(clk,rst,
					req_in_subfilter_pass[i],ack_in_pass_subfilter[i],
					data_in_pass_subfilter[i],req_out_subfilter_pass[i],ack_out_subfilter_pass[i], 
					data_out_subfilter_pass[i],h_out_preproc_subfilter[i]);
			 
			 passivator #(.DWIDTH(DWIDTH))
			 pass_out (req_out_subfilter_pass[i],ack_out_subfilter_pass[i],
						  data_out_subfilter_pass[i],req_out,ack_out_split[i],
						  data_out_pass_post[i]);
        end
    endgenerate	
	 
	postproc #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
	 post (clk,rst,
			 data_out_pass_post[0], data_out_pass_post[1], data_out_pass_post[2] , data_out_merged);
	 
	 
    always @(posedge clk) begin
		if(rst)begin
			ack_in_buf <= 0;
			ack_out_buf <= 0;
			data_out_buf <= 0;
		end
		else begin
			ack_in_buf  <= ack_in_split[0] & ack_in_split[1] & ack_in_split[2];
			ack_out_buf <= ack_out_split[0] & ack_out_split[1] & ack_out_split[2];
			data_out_buf <= data_out_merged;
		end
    end

endmodule
