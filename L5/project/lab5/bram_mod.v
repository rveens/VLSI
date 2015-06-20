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
	reg [RAM_WIDTH-1:0] bram [(2**RAM_ADDR_BITS)-1:0];
	wire [RAM_ADDR_BITS-1:0] ram_wr_address, ram_rd_address;
	
	// output buffer
	reg [0:RAM_WIDTH-1] data_out_buf;
	assign out_data = data_out_buf;
	
	// reverse all address wires
	generate
		genvar j;
		for(j=0;j<RAM_ADDR_BITS;j=j+1) begin: reverse
			assign ram_wr_address[j] = write_address[j];
			assign ram_rd_address[j] = read_address[j];
		end
	endgenerate
	
	integer i;
	initial begin
		for(i=0;i<2**RAM_ADDR_BITS-1;i=i+1)
			bram[i] <= 0;
	end

	always @(posedge clk) begin
		if(rst) begin
			data_out_buf <= 0;
		end
		else begin
			if (write_enable) begin
				bram[ram_wr_address] <= in_data;
			end
			data_out_buf <= bram[ram_rd_address];
		end
	 end
endmodule
