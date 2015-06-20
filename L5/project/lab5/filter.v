`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L,
	parameter NR_STREAMS = 1024,
    parameter NR_STREAMS_LOG = 4)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out);
	 
	// wires
	wire [0:DWIDTH-1] mem_data_out[0:3],
							accmul_data_in[0:3];
	wire mem_ack_out, mem_req_out,
		  accmul_ack_in, accmul_req_in;

	// memory
	bufferinput #( .DWIDTH(DWIDTH), .NR_STREAMS(NR_STREAMS), .NR_STREAMS_LOG(NR_STREAMS_LOG) )
	memory_inst (clk, rst, req_in, ack_in, data_in, mem_req_out, mem_ack_out, 
	mem_data_out[0], mem_data_out[1], mem_data_out[2], mem_data_out[3]);

	// Instantiation of Passivator2
	passivator_4d #(.DWIDTH(DWIDTH)) 
	pas3 (mem_req_out, mem_ack_out, 
			mem_data_out[0], mem_data_out[1], mem_data_out[2], mem_data_out[3], accmul_req_in, accmul_ack_in, 
			accmul_data_in[0], accmul_data_in[1], accmul_data_in[2], accmul_data_in[3]);

	// Instantiation of the accumulate_multiply
	accumulate_multiply #(.DWIDTH(DWIDTH), .NR_STREAMS(NR_STREAMS), .NR_STREAMS_LOG(NR_STREAMS_LOG) ) 
	accmul_inst (clk, rst, accmul_req_in, accmul_ack_in, 
					 accmul_data_in[0], accmul_data_in[1], accmul_data_in[2], accmul_data_in[3], 
					 req_out, ack_out, data_out);
				   
    always @(posedge clk) begin

    end

endmodule
