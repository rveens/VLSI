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
     
	 // wires preproc -> subfilter
	 wire [0:((NR_STAGES/2)*DWIDTH)-1] h0_out_preproc_subfilter;
	 wire [0:((NR_STAGES/2)*DWIDTH)-1] h1_out_preproc_subfilter; // todo verbinden
	 wire [0:((NR_STAGES/2)*DWIDTH)-1] h01_out_preproc_subfilter; // todo verbinden
	 
	 // wires preproc -> passivator
	 wire [0:DWIDTH-1] data_in_a_preproc_pass;
	 wire [0:DWIDTH-1] data_in_b_preproc_pass; // todo verbinden
	 wire [0:DWIDTH-1] data_in_a_b_preproc_pass; // todo verbinden
	 
	 // wires subfilter -> passivator
	 wire req_in_pass_subfilter;
	 
	 // wires passivator -> subfilter
	 wire ack_in_pass_subfilter;
	 wire [0:DWIDTH-1] data_in_pass_subfilter; // todo splitsen in a,b,c data_in
	 
	  // wires subfilter -> passivator2
    wire req_out_subfilter_pass;
	 wire ack_out_subfilter_pass;
    wire [0:DWIDTH-1] data_out_subfilter_pass;
	 
	 wire [0:DWIDTH-1] data_out_pass_post;
  
    // instantiate preproc, subfilter, postproc, 2x passivator.	 
	 preproc #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
			pre (clk,
				  rst,
				  data_in,
				  data_in_a_preproc_pass,
				  data_in_a_b_preproc_pass,
				  data_in_b_preproc_pass,
				  h_in,
				  h0_out_preproc_subfilter,
				  h1_out_preproc_subfilter,
				  h01_out_preproc_subfilter);
	
	 passivator #(.DWIDTH(DWIDTH))
			 pass (req_in,
					 ack_in,
					 data_in_a_preproc_pass,
					 req_in_subfilter_pass,
					 ack_in_pass_subfilter,
					 data_in_pass_subfilter);
	
	 subfilter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
			sfil	(clk,
                rst,
                req_in_subfilter_pass,
                ack_in_pass_subfilter,
                data_in_pass_subfilter,
                req_out_subfilter_pass,
                ack_out_subfilter_pass, 
                data_out_subfilter_pass, 
                h0_out_preproc_subfilter // fixme: h0 sfilter 1 doet enkel h0? dit is nu (stages/2)*DWIDTH ipv CWIDTH
					 ); 
  
   
  
	 passivator #(.DWIDTH(DWIDTH))
			pass2 (req_out_subfilter_pass,
					 ack_out_subfilter_pass,
					 data_out_subfilter_pass,
					 req_out,
					 ack_out,
					 data_out_pass_post);
	 
	 
		
	 postproc #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
          post (clk,
                rst,
                data_out_pass_post,
                data_out // split by 3
					 );
	
    always @(posedge clk) begin
    end

endmodule
