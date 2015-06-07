`timescale 1ns / 1ps

module preproc #(parameter NR_STAGES = 32,
                 parameter DWIDTH = 16,
                 parameter DDWIDTH = 2*DWIDTH,
                 parameter CWIDTH = NR_STAGES * DWIDTH)
       (input  clk,
        input  rst,
        input signed [0:DDWIDTH-1] data_in,
        output signed [0:DWIDTH] data_out_0,
        output signed [0:DWIDTH] data_out_1,
        output signed [0:DWIDTH] data_out_2,
        input signed [0:CWIDTH-1] h_in,
        output signed [0:((NR_STAGES/2)*DWIDTH)-1] h_out_0,
        output signed [0:((NR_STAGES/2)*DWIDTH)-1] h_out_1,
        output signed [0:((NR_STAGES/2)*DWIDTH)-1] h_out_2);

// split input
wire signed [0:DWIDTH-1] a, b;
assign {a, b} = data_in;

// buffers for output data
reg signed [0:DWIDTH] data_out_buf[0:2],
    a_buf,
    b_buf,
    ab_buf; // 16 + 1 bit for overflow with a + b

assign data_out_0 = data_out_buf[0];
assign data_out_1 = data_out_buf[1];
assign data_out_2 = data_out_buf[2];

// buffers for output coefficients
reg signed [0:((NR_STAGES/2)*DWIDTH)-1] h_out_buf[0:2];
assign h_out_0 = h_out_buf[0];
assign h_out_1 = h_out_buf[1];
assign h_out_2 = h_out_buf[2];

// split coefficients to enable realtime switching between coefficients
wire signed [0:((NR_STAGES/2)*DWIDTH)-1] h0, h1, h01;
generate
    genvar i;
for (i = 0; i < NR_STAGES/2; i = i + 1)begin : yolo_coef
    assign  h0[i*DWIDTH +: DWIDTH] = h_in[2*i*DWIDTH +: DWIDTH];
    assign  h1[i*DWIDTH +: DWIDTH] = h_in[(2*i+1)*DWIDTH +: DWIDTH];
    assign h01[i*DWIDTH +: DWIDTH] = h0[i*DWIDTH +: DWIDTH] + h1[i*DWIDTH +: DWIDTH];
end
endgenerate

    // processing loop
    always @(posedge clk) begin
        if (rst) begin
            data_out_buf[0] <= 0;
            data_out_buf[1] <= 0;
            data_out_buf[2] <= 0;
            h_out_buf[0] <= 0;
            h_out_buf[1] <= 0;
            h_out_buf[2] <= 0;
        end
        else begin
            a_buf <= a;
            b_buf <= b;
            ab_buf <= a + b;

            data_out_buf[0] <= a_buf;
            data_out_buf[1] <= ab_buf[0:DWIDTH];
            data_out_buf[2] <= b_buf;
            h_out_buf[0] <= h0;
            h_out_buf[1] <= h01;
            h_out_buf[2] <= h1;
        end
    end
    endmodule
