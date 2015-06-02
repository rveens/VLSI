`timescale 1ns / 1ps

module filtertest;

// Parameters
parameter NR_STAGES = 32;
parameter DWIDTH = 16;
parameter DDWIDTH = 2 * DWIDTH;
parameter CWIDTH = NR_STAGES * DWIDTH;

// Clock & Reset signals
reg clk;
reg rst;

// Coefficient wires
wire [0:CWIDTH-1] h_in;

// Input port
wire in_req;
wire in_ack;
wire [0:DDWIDTH-1] in_data;

// Output port
wire out_req;
wire out_ack;
wire [0:DDWIDTH-1] out_data;

// Instantiation of the filter
filter #(.NR_STAGES(NR_STAGES), .DWIDTH(DWIDTH), .DDWIDTH(DDWIDTH), .CWIDTH(CWIDTH))
  my_filter (clk, rst, in_req, in_ack, in_data, out_req, out_ack, out_data, h_in
);

// Input port buffers
reg in_ack_buf = 0;
assign in_ack = in_ack_buf;
reg [0:DDWIDTH-1] in_data_buf;
assign in_data = in_data_buf;

// Output port buffers
reg out_ack_buf = 0;
assign out_ack = out_ack_buf;

// Coefficient port buffers
reg signed [0:DWIDTH-1] h [0:NR_STAGES-1];

// Assign the filter coefficient registers to the correct wires
generate
    genvar i;
    for (i = 0; i < NR_STAGES; i = i + 1) begin : stage
        assign h_in[i*DWIDTH:(i+1)*DWIDTH-1] = h[i];
    end
endgenerate

// Variables for handling the file I/O
integer input_file;
integer output_file;
integer io_error;
reg [0:639] io_error_str;

// The clock (100Mhz)
always #5 clk = ~clk;

// Registers that store random numbers for acknowledge randomization
reg random_in = 0;
reg random_out = 0;

// Process that reads the input samples from a file
always @(posedge clk) begin
    if (in_req && !in_ack) begin
        in_data_buf[0:7] = $fgetc(input_file);
        in_data_buf[8:15] = $fgetc(input_file);
        //in_data_buf[16:23] = $fgetc(input_file);
        //in_data_buf[24:31] = $fgetc(input_file);
        io_error <= $ferror(input_file, io_error_str);
        in_ack_buf <= 1;
    end
    else if (!in_req && in_ack) begin
        in_ack_buf <= 0 | random_in;
    end
end

// Process that writes the 8 MSBs of the output to a file
always @(posedge clk) begin
    if (out_req && !out_ack) begin
        $fwrite(output_file, "%c", out_data[0:7]);
        $fwrite(output_file, "%c", out_data[8:15]);
        //$fwrite(output_file, "%c", out_data[16:23]);
        //$fwrite(output_file, "%c", out_data[24:31]);
        out_ack_buf <= 1;
    end
    else if (!out_req && out_ack) begin
        out_ack_buf <= 0 | random_out;
    end
end

initial begin
    // Initialize Inputs
    clk = 0;
    rst = 1;
    in_data_buf = 0;

    // Set the filter coefficients
    // Below are the coefficients for a low-pass filter
    h[0] = 0;
    h[1] = 0;
    h[2] = 0;
    h[3] = 0;
    h[4] = 0;
	 h[5]  = 4*256;
    h[6]  = 4*256;
    h[7]  = 5*256;
    h[8]  = 7*256;
    h[9]  = 9*256;
    h[10] = 11*256;
    h[11] = 12*256;
    h[12] = 14*256;
    h[13] = 15*256;
    h[14] = 16*256;
    h[15] = 17*256;
    h[16] = 17*256;
    h[17] = 16*256;
    h[18] = 15*256;
    h[19] = 14*256;
    h[20] = 12*256;
    h[21] = 11*256;
    h[22] = 9*256;
    h[23] = 7*256;
    h[24] = 5*256;
    h[25] = 4*256;
    h[26] = 4*256;
    h[27] = 0;
    h[28] = 0;
    h[29] = 0;
    h[30] = 0;
    h[31] = 0;

    // Wait 100 ns for global reset to finish
    #100;
    rst = 0;

    // Open the input and output files
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
        random_in <= $random;
        random_out <= $random;
    end

    // Close the input and output files
    $fclose(input_file);
    $fclose(output_file);
    
    // Stop the simulation
    #100;
    $fdisplay("Simulation ended\n");
    $stop;

end
      
endmodule
