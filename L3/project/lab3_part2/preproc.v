`timescale 1ns / 1ps

module preproc #(parameter NR_STAGES = 32,
                parameter DWIDTH = 16,
                parameter DDWIDTH = 2*DWIDTH,
                parameter CWIDTH = NR_STAGES * DWIDTH)
               (input  clk,
                input  rst,
                input signed [0:DDWIDTH-1] data_in,
                output signed [0:DWIDTH-1] data_a_out,
					 output signed [0:DWIDTH-1] data_a_b_out,
					 output signed [0:DWIDTH-1] data_b_out,
                input signed [0:CWIDTH-1] h_in,
				    output signed [0:((NR_STAGES/2)*DWIDTH)-1] h0_out,
					 output signed [0:((NR_STAGES/2)*DWIDTH)-1] h01_out,
					 output signed [0:((NR_STAGES/2)*DWIDTH)-1] h1_out
					 );
  
	 // output buffering
	 reg signed [0:DWIDTH-1] data_a_out_buf, data_a_b_out_buf, data_b_out_buf;
	 reg signed [0:((NR_STAGES/2)*DWIDTH)-1] h0_out_buf;
	 reg signed [0:((NR_STAGES/2)*DWIDTH)-1] h01_out_buf;
	 reg signed [0:((NR_STAGES/2)*DWIDTH)-1] h1_out_buf;
	
	 assign data_a_out = data_a_out_buf;
	 assign data_a_b_out = data_a_b_out_buf;
	 assign data_b_out = data_b_out_buf;

	 assign h0_out = h0_out_buf;
	 assign h01_out = h01_out_buf;
	 assign h1_out = h1_out_buf;
	 
	 // split input
	 wire signed [0:DWIDTH-1] a, b;
    assign {a, b} = data_in;
	 
	 // split h_in into h0, h1, h01
	 wire signed [0:((NR_STAGES/2)*DWIDTH)-1] h0;
	 wire signed [0:((NR_STAGES/2)*DWIDTH)-1] h01;
	 wire signed [0:((NR_STAGES/2)*DWIDTH)-1] h1;
	 
	 function integer get_odd_even_index;
	 input integer givenindex;
	 begin
		if (givenindex % 2 == 1)
			begin
				givenindex = givenindex + 1;
			end
			$display("hoi %d", (givenindex / 2));
		get_odd_even_index = (givenindex / 2);
	 end
	 endfunction;
	 
		
	 generate
		genvar i;
		assign  h1[0*DWIDTH +: DWIDTH] = h_in[1*DWIDTH +: DWIDTH];
		for (i = 0; i < NR_STAGES-1; i = i + 1)begin : yolo_coef
			if (i % 2 == 0)
				begin
					assign  h0[get_odd_even_index(i)*DWIDTH +: DWIDTH] = h_in[i*DWIDTH +: DWIDTH];
				end
			else	
				begin
					assign  h1[get_odd_even_index(i)*DWIDTH +: DWIDTH] = h_in[i*DWIDTH +: DWIDTH];
				end
		end
		
		for (i = 0; i < NR_STAGES/2; i = i + 1)begin : yolo_coef_h01
			assign h01[i*DWIDTH +: DWIDTH] = h0[i*DWIDTH +: DWIDTH] + h1[i*DWIDTH +: DWIDTH];
		end
	 endgenerate
	 
    always @(posedge clk) begin
		  if(rst) begin
			  data_a_out_buf <= 0;
			  data_a_b_out_buf <= 0;
			  data_b_out_buf <= 0;
			  h0_out_buf <= 0;
			  h01_out_buf <= 0;
			  h1_out_buf <= 0;
		  end
		  else begin
			  data_a_out_buf <= a;
			  h0_out_buf <= h0;
			  
			  data_a_b_out_buf <= a + b;
			  h01_out_buf <= h01;
			  
			  data_b_out_buf <= b;
			  h0_out_buf <= h0;
		  end
    end

endmodule