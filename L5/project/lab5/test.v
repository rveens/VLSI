`timescale 1ns / 1ps

module multitest;

// Parameters
parameter DWIDTH = 16;
parameter FILTER_DWIDTH = 16;
parameter C_SLV_DWIDTH  = 32;
//Vary these parameters for testing the scalability
parameter NR_STREAMS = 1024;
parameter NR_STREAMS_LOG = 10;
parameter STR_IND = 0;



// Control ports
reg clk = 0;
reg rst = 1;

//Stream counter (change the width if needed.)
reg [0:NR_STREAMS_LOG-1] stream_in = 0;
reg [0:NR_STREAMS_LOG-1] stream_out = 0;


// Test to passivator1 ports
wire send_input;
wire ack_in;
wire signed [0:C_SLV_DWIDTH-1] data_in_pas1;

// Passivator2 to test ports
wire receive_output;
wire ack_out;
wire signed [0:C_SLV_DWIDTH-1] data_out_pas2;

//Randome variable
reg fifo_empty = 0;
reg fifo_full = 0;

 // FIFO READER
    wire fifo_RD_in_req;
    wire fifo_RD_in_ack;
    wire [0:C_SLV_DWIDTH-1] fifo_RD_in_data;
    wire fifo_RD_out_req;
    wire fifo_RD_out_ack;
    wire [0:C_SLV_DWIDTH-1] fifo_RD_out_data;

// FIFO WRITE
    wire fifo_WR_in_req;
    wire fifo_WR_in_ack;
    wire [0:C_SLV_DWIDTH-1] fifo_WR_in_data;
    wire fifo_WR_out_req;
    wire fifo_WR_out_ack;
    wire [0:C_SLV_DWIDTH-1] fifo_WR_out_data;

	 
 // Serialize sample-block
    wire serial_in_req;
    wire serial_in_ack;
    wire [0:C_SLV_DWIDTH-1] serial_in_data;
    wire serial_out_req;
    wire serial_out_ack;
    wire [0:FILTER_DWIDTH-1] serial_out_data;
	 
// Multiplex input samples with streams
   wire mux_in_req;
   wire mux_in_ack;
	wire [0:FILTER_DWIDTH-1] mux_in_data;
	wire mux_out_req;
	wire mux_out_ack;
	wire [0:FILTER_DWIDTH-1] mux_out_data;

// Filter serialized samples
    wire filter_in_req;
    wire filter_in_ack;
    wire [0:FILTER_DWIDTH-1] filter_in_data;
    wire filter_out_req;
    wire filter_out_ack;
    wire [0:FILTER_DWIDTH-1] filter_out_data;
	
// De-multiplex input samples with streams
    wire demux_in_req;
    wire demux_in_ack;
    wire [0:FILTER_DWIDTH-1] demux_in_data;
    wire demux_out_req;
    wire demux_out_ack;
    wire [0:FILTER_DWIDTH-1] demux_out_data;	 


    // Parallellize serial output from the sample into sample-block
    wire parallel_in_req;
    wire parallel_in_ack;
    wire [0:FILTER_DWIDTH-1] parallel_in_data;
    wire parallel_out_ready;
    wire parallel_out_enabled;
    wire [0:C_SLV_DWIDTH-1] parallel_out_data;



passivator #(.DWIDTH(C_SLV_DWIDTH) ) 
  pas0 (send_input,    ack_in,        data_in_pas1, 
        fifo_RD_in_req,  fifo_RD_in_ack,   fifo_RD_in_data);

fifo_reader #(C_SLV_DWIDTH)
  fifoRD (clk, rst, 
		  fifo_RD_in_req,   fifo_RD_in_ack,   fifo_RD_in_data, fifo_empty,           
        fifo_RD_out_req,  fifo_RD_out_ack,  fifo_RD_out_data);
    
	 
passivator #(.DWIDTH(C_SLV_DWIDTH))
  pas1 (fifo_RD_out_req,  fifo_RD_out_ack,   fifo_RD_out_data,
        serial_in_req,  serial_in_ack,   serial_in_data);
		  
par2ser #(FILTER_DWIDTH)
  p2s0 (clk, rst, 
		  serial_in_req,  serial_in_ack,   serial_in_data,            
        serial_out_req,   serial_out_ack,      serial_out_data);
    
	 
passivator #(.DWIDTH(FILTER_DWIDTH))
  pas2 (serial_out_req, serial_out_ack,  serial_out_data,
        mux_in_req,     mux_in_ack,       mux_in_data);


mux    #(.DWIDTH(FILTER_DWIDTH),.NR_STREAMS(NR_STREAMS),.STREAMS_IDX(STR_IND)) 
  my_mux (clk, rst, 
		 	 mux_in_req,  mux_in_ack,  mux_in_data, 
		 	 mux_out_req, mux_out_ack, mux_out_data);   
	 
	 
passivator #(.DWIDTH(FILTER_DWIDTH))
      pas3 (mux_out_req,  mux_out_ack,   mux_out_data, 
			  filter_in_req, filter_in_ack, filter_in_data);


// Instantiation of the filter
filter #(.DWIDTH(DWIDTH), .NR_STREAMS(NR_STREAMS), .NR_STREAMS_LOG(NR_STREAMS_LOG) ) 
filter_inst (clk, rst, 
             filter_in_req,  filter_in_ack,  filter_in_data, 
				 filter_out_req, filter_out_ack, filter_out_data);
				 				 
	
passivator #(.DWIDTH(FILTER_DWIDTH))
      pas4 (filter_out_req, filter_out_ack, filter_out_data, 
			   demux_in_req,   demux_in_ack,   demux_in_data);


demux    #(.DWIDTH(FILTER_DWIDTH),.NR_STREAMS(NR_STREAMS),.STREAMS_IDX(STR_IND)) 
   my_demux (clk, rst, 
			    demux_in_req,  demux_in_ack,  demux_in_data, 
			    demux_out_req, demux_out_ack, demux_out_data);


passivator #(.DWIDTH(FILTER_DWIDTH))
      pas5 (demux_out_req,   demux_out_ack,   demux_out_data,
            parallel_in_req, parallel_in_ack, parallel_in_data);
  
ser2par #(FILTER_DWIDTH)
     s2p0 (clk,  rst,
            parallel_in_req,     parallel_in_ack,  parallel_in_data,
            parallel_out_ready,  parallel_out_enabled,  parallel_out_data);


passivator #(.DWIDTH(C_SLV_DWIDTH)) 
  pas6 (parallel_out_ready,  parallel_out_enabled,  parallel_out_data, 
        fifo_WR_in_req,  fifo_WR_in_ack,   fifo_WR_in_data);	
		  
		  
fifo_writer #(C_SLV_DWIDTH)
  fifoWR (clk, rst, 
		  fifo_WR_in_req,   fifo_WR_in_ack,   fifo_WR_in_data,            
        fifo_WR_out_req,  fifo_WR_out_ack,  fifo_WR_out_data, fifo_full);
		  
		  
// Instantiation of Passivator2
passivator #(.DWIDTH(C_SLV_DWIDTH)) 
  pas7 ( fifo_WR_out_req,  fifo_WR_out_ack,   fifo_WR_out_data, 
        receive_output, ack_out,        data_out_pas2);	

// Input buffer
reg signed [0:C_SLV_DWIDTH-1] data_in = 0;
reg send_input_buf, receive_output_buf;
assign data_in_pas1 = data_in;
assign send_input = send_input_buf;
assign receive_output = receive_output_buf;


// Variables for handling the file I/O
integer input_file;
integer output_file;
integer io_error;
reg [0:639] io_error_str;

// The clock (100Mhz)
always #5 clk = ~clk;


// Process that reads the input samples from a file
always @(posedge clk) begin
	if ( (send_input && ack_in) || !send_input) begin
	
	     
			 // BIG ENDIAN
			 data_in[0:7] <= $fgetc(input_file);
			 data_in[8:15] <= $fgetc(input_file);
			 data_in[16:23] <= $fgetc(input_file);
			 data_in[24:31] <= $fgetc(input_file);
			 io_error <= $ferror(input_file, io_error_str);		
			  
		  send_input_buf <= 1;
	  	  receive_output_buf <= 1;
	end 
						
end



// Process that writes the 8 MSBs of the output to a file
always @(posedge clk) begin
	if (ack_out) begin
	
	
	   	// BIG ENDIAN FORMAT
			$fwrite(output_file, "%c", data_out_pas2[0:7]);
			$fwrite(output_file, "%c", data_out_pas2[8:15]);					
         $fwrite(output_file, "%c", data_out_pas2[16:23]);
			$fwrite(output_file, "%c", data_out_pas2[24:31]);	
	  		
	
	end  
	
	
end

initial begin
	// Wait 100 ns for global reset to finish
	#100;
	rst = 0;
	send_input_buf <= 0;
	receive_output_buf <= 0;

	// Open the files
	input_file = $fopen("input.bin", "rb");
	if (input_file == 0) begin
		$display("Error: Failed to open input file, input.bin\nExiting Simulation.");
		$finish;
	end
	output_file = $fopen("output.bin", "wb");
	if (output_file == 0) begin
		$display("Error: Failed to open output file, output.bin\nExiting Simulation.");
		$finish;
	end

	// Wait 100 ns
	#100;

	// While there is data available, send it to the filter
	io_error = 0;
	while (io_error == 0) @(posedge clk) begin
		// We keep signaling the filter until the input file has been processed
		send_input_buf <= 1;
		fifo_empty <= 0;
      fifo_full <=  0;
	end

	// Close the files
	$fclose(input_file);
	$fclose(output_file);
		
	// Stop the simulation
	#100;
	$fdisplay("Simulation ended\n");
	$stop;

end
      
endmodule
