module accumulate_multiply
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L,
	parameter NR_STREAMS = 16,
    parameter NR_STREAMS_LOG = 4)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in_0,
	input [0:DWIDTH-1] data_in_1,
	input [0:DWIDTH-1] data_in_2,
	input [0:DWIDTH-1] data_in_3,
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
    reg signed [0:DWIDTH-1] data_out_buf;
    assign data_out = data_out_buf;

	 //coefficients data and lookup tables for the coef index
    reg signed [0:DWIDTH-1] coef [0:CWIDTH-1], 
									 lookup_coefIdx[0:L-1],
									 coef_temp_buf[0:3];
	 //parameter offset_coefIdx[0:3] = {0*L, 1*L, 2*L, 3*L};

	 integer i, j;
	 
	 initial begin
		 // import coefficients
		 $readmemh("coef.txt", coef, 0, CWIDTH -1);

		 // define lookup tables
		  for (i = 0; i < L; i = i + 1) begin
				lookup_coefIdx[i] = i*M%L;
		  end
	 end
	
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 0;
            req_out_buf <= 0;
            data_out_buf <= 0;
				i	 <= 0;
				j	 <= 0;
				
				coef_temp_buf[0] <= 0;
				coef_temp_buf[1] <= 0;
				coef_temp_buf[2] <= 0;
				coef_temp_buf[3] <= 0;
        end
        // !Reset => run
        else begin
		  
            // Read handshake complete
            if (req_in && ack_in) begin
				
					// use buffered samples for faster processing
               data_out_buf <= data_in_0;//*coef_temp_buf[0] + 
										 //data_in_1*coef_temp_buf[1] + 
										// data_in_2*coef_temp_buf[2] + 
										 //data_in_3*coef_temp_buf[3];		
					
					// if all samples of one sample time are calculated, shift one index
					/*if(j == NR_STREAMS - 1) begin
						i <= (i + 1) % L;
						// load new buffer samples
						coef_temp_buf[0] <= coef[0*L + lookup_coefIdx[i+1]]; //[i+1] because not yet update
						coef_temp_buf[1] <= coef[1*L + lookup_coefIdx[i+1]];
						coef_temp_buf[2] <= coef[2*L + lookup_coefIdx[i+1]];
						coef_temp_buf[3] <= coef[3*L + lookup_coefIdx[i+1]];
						j <= (j + 1) % NR_STREAMS;
					end
					else begin
						j <= (j + 1) % NR_STREAMS;	
					end	*/
					
					req_out_buf <= 1;
            end			   				
				
			   //Read handshake is pending then stop producing output
				if (req_in && !ack_in) begin 
               req_out_buf <= 0;
            end 
								
            // Write handshake complete
            if (req_out && ack_out) begin
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
