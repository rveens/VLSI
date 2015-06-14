`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    08:04:27 06/11/2015
// Design Name:
// Module Name:    rom_mod
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module rom_mod
       #(parameter ROM_WIDTH = 16,
         parameter ROM_ADDR_BITS = 10 )(
           input enable,
           input rst,
           input clk,
           input [ROM_ADDR_BITS-1:0] address,
           output data_ready,
           output [ROM_WIDTH-1:0] out_data);

reg [ROM_WIDTH-1:0] rom [0:(2**ROM_ADDR_BITS)-1]; //** means 'power'
reg [ROM_WIDTH-1:0] out_data_buf;
reg data_ready_buf;
assign out_data = out_data_buf;
assign data_ready = data_ready_buf;

initial
    $readmemh("coef.txt", rom, 0, 2**ROM_ADDR_BITS -1); // (multiple) space between pairs of hexadecimal values in coef.txt necessary!

always @(posedge clk)
    if(rst) begin
        out_data_buf <=0;
        data_ready_buf <= 0;

    end
    else begin
        // processor asks for memory value, the ROM will put it on line and tell that it's ready.
        // The processor has to pull the enable low whenever the data is extracted.
        if (enable) begin
            out_data_buf <= rom[address];
            data_ready_buf <= 1;
        end
        else begin
            data_ready_buf <= 0;
            out_data_buf <= 0;
        end
    end
endmodule
