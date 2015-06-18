`timescale 1ns / 1ps
module rom_mod
       #(parameter RAM_WIDTH = 16,
         parameter RAM_ADDR_BITS = 10 )(
           input clk,
			  input rst,
			  input write_enable,
           input [RAM_ADDR_BITS-1:0] in_address,
			  input [RAM_WIDTH-1:0] in_data,
			  input [RAM_ADDR_BITS-1:0] out_address,
           output [RAM_WIDTH-1:0] out_data);

always @(posedge clk)
    if(rst) begin
    
	 end
    else begin
		if(write_enable) begin
			//do not write new data in RAM
		end
		else begin
		
		end
	 end
endmodule
