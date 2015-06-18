`timescale 1ns / 1ps

module par2ser
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 32)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DDWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
    // Accumulator (assigned to output directly)
    reg signed [0:DWIDTH-1] sum [0:1];
	 reg signed [0:DWIDTH-1] data_in_buf [0:1];
	 reg [0:2] idx;
	 reg output_set_flag;
	
    assign data_out = sum[idx];
//    assign data_out = data_in_buf[idx];
	 
  
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            sum[0] <= 0;	
				sum[1] <= 0;	
				data_in_buf[0] <= 0;
				data_in_buf[1] <= 0;
            idx <= 0;	
            output_set_flag <= 0;				
        end
        // !Reset => run
        else begin
		  
            // Read handshake complete
            if (req_in && ack_in) begin
              data_in_buf[0] <= data_in[0:DWIDTH-1];
				  data_in_buf[1] <= data_in[DWIDTH:DDWIDTH-1];
				  req_in_buf <= 0;
				  req_out_buf <=1;
				  idx <=0 ;
				  
//				  sum[0] <= data_in_buf[0];
//				  sum[1] <= data_in_buf[1];
				  
				  
//				  output_set_flag <= 1;
				  
/*				  if (output_set_flag) begin
				    req_in_buf <= 0;
				    req_out_buf <= 1;
                idx <= 0;				
				  end
*/
				  
            end			   				
				
		      //Read handshake is pending then stop producing output
			   if (req_in && !ack_in) begin              
               req_out_buf <= 0;
            end 
								
            // Write handshake complete
            if (req_out && ack_out) begin
                if (idx ==1) begin
						sum[0] <= data_in_buf[0];
						sum[1] <= data_in_buf[1];
						req_in_buf <= 1;
						idx <= 0;
                end else begin
				      idx <= idx + 1;						
				      req_out_buf <= 1;
                end				
            end 

            //Write handshake is pending then stop acquiring output.
            if (req_out && !ack_out) begin                			                  
				   req_in_buf <= 0;
            end 			            			  
				
            // Idle state
            if (!req_in && !ack_in && !req_out && !ack_out) begin                		
              req_in_buf <= 1;					
//				  idx <= 0;	
            end
				
        end
    end

endmodule
