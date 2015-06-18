`timescale 1ns / 1ps
module passivator_4d
  #(parameter DWIDTH = 8)
   (input req1,
    output ack1,
    input [0:DWIDTH-1] data0,
	 input [0:DWIDTH-1] data1,
	 input [0:DWIDTH-1] data2,
	 input [0:DWIDTH-1] data3,
    input req2,
    output ack2,
    output [0:DWIDTH-1] data4,
	 output [0:DWIDTH-1] data5,
	 output [0:DWIDTH-1] data6,
	 output [0:DWIDTH-1] data7);

    // Passivator behaviour
    assign ack1 = (req1 & req2);
    assign ack2 = ack1;
   
    // Data passthrough
    assign data4 = data0;
	 assign data5 = data1;
	 assign data6 = data2;
	 assign data7 = data3;
endmodule
