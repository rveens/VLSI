`timescale 1ns / 1ps

module fifo_writer #(
    parameter DWIDTH = 32)(
    input clk,
    input rst,
	 output req_in,
    input  ack_in,
    input [0 : DWIDTH-1] data_in,
	 output req_out,
    input ack_out,
    output [0 : DWIDTH-1] data_out,
	 input fifo_full);	
	
    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;

    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
	reg stop_flag;
	
    // Accumulator (assigned to output directly)
    reg signed [0:DWIDTH-1] data_out_reg;
    assign data_out = data_out_reg;
	 
initial begin
    req_in_buf <= 0;
    req_out_buf <= 0;
    data_out_reg <= 0;
end
  
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            data_out_reg <= 0;			
            stop_flag <= 0;			
        end
        // !Reset => run
        else begin
		  
            // Read handshake complete
            if (req_in && ack_in) begin
               data_out_reg <= data_in;	
			   
               if (fifo_full == 0) begin
                 req_out_buf <= 1;                					  
               end else begin
			     req_out_buf <= 1;
				 stop_flag <= 1;
			     req_in_buf <= 0;
               end			   
			   
            end			   				
				
			//Read handshake is pending then stop producing output
			if (req_in && !ack_in) begin              
               req_out_buf <= 0;
            end 
								
            // Write handshake complete
            if (req_out && ack_out) begin     
			
                 if(stop_flag) begin
				   req_out_buf <= 0;
				   stop_flag <= 0;
                 end				
				 
                req_in_buf <= 1;		
            end 

            //Write handshake is pending then stop acquiring output.
            if (req_out && !ack_out) begin        
			  req_in_buf <= 0;
            end 			            			  
				
            // Idle state
            if (!req_in && !ack_in && !req_out && !ack_out) begin              
                req_in_buf <= 1;				  
            end
				
        end
    end

endmodule
