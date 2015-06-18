`timescale 1ns / 1ps
module rom_mod
       #(parameter RAM_WIDTH = 16,
         parameter RAM_ADDR_BITS = 10 )(
           input clk,
			  input rst,
			  input write_enable,
           input [0:RAM_ADDR_BITS-1] write_address,
			  input [0:RAM_WIDTH-1] in_data,
			  input [0:RAM_ADDR_BITS-1] read_address,
           output [0:RAM_WIDTH-1] out_data);

   (* RAM_STYLE="block" *)
   reg [0:RAM_WIDTH-1] bram [0:(2**RAM_ADDR_BITS)-1];
   
	// output buffer
	reg [0:RAM_WIDTH-1] data_out_buf;
	assign out_data = data_out_buf;


	always @(posedge clk) begin
		if(rst) begin
    
		end
		else begin
			if (write_enable)
				bram[write_address] <= in_data;
			data_out_buf <= bram[read_address];
		end
	 end
endmodule
