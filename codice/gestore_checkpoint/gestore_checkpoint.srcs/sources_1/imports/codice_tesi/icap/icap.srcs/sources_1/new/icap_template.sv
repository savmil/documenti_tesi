`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2019 23:37:27
// Design Name: 
// Module Name: icap_template
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module icap_template( 
    input wire clk_i,
    input wire [31:0] data_i,
    input wire write_i,
    input wire en_i,
    output reg [31:0] data_o
);
reg [31:0]  icap_data_in;
reg [31:0]  icap_data_out;
reg         icap_write_int;
reg         icap_enable;
always @(posedge clk_i)
    begin
    
    icap_enable<=en_i;
    icap_write_int<=write_i;
    
    icap_data_in[31] <= data_i[24];
    icap_data_in[30] <= data_i[25];
    icap_data_in[29] <= data_i[26];
    icap_data_in[28] <= data_i[27];
    icap_data_in[27] <= data_i[28];
    icap_data_in[26] <= data_i[29];
    icap_data_in[25] <= data_i[30];
    icap_data_in[24] <= data_i[31];
    
    icap_data_in[23] <= data_i[16];
    icap_data_in[22] <= data_i[17];
    icap_data_in[21] <= data_i[18];
    icap_data_in[20] <= data_i[19];
    icap_data_in[19] <= data_i[20];
    icap_data_in[18] <= data_i[21];
    icap_data_in[17] <= data_i[22];
    icap_data_in[16] <= data_i[23];
    
    icap_data_in[15] <= data_i[8];
    icap_data_in[14] <= data_i[9];
    icap_data_in[13] <= data_i[10];
    icap_data_in[12] <= data_i[11];
    icap_data_in[11] <= data_i[12];
    icap_data_in[10] <= data_i[13];
    icap_data_in[9] <= data_i[14];
    icap_data_in[8] <= data_i[15];
    
    icap_data_in[7] <= data_i[0];
    icap_data_in[6] <= data_i[1];
    icap_data_in[5] <= data_i[2];
    icap_data_in[4] <= data_i[3];
    icap_data_in[3] <= data_i[4];
    icap_data_in[2] <= data_i[5];
    icap_data_in[1] <= data_i[6];
    icap_data_in[0] <= data_i[7];



    data_o[31] <= icap_data_out[24];
    data_o[30] <= icap_data_out[25];
    data_o[29] <= icap_data_out[26];
    data_o[28] <= icap_data_out[27];
    data_o[27] <= icap_data_out[28];
    data_o[26] <= icap_data_out[29];
    data_o[25] <= icap_data_out[30];
    data_o[24] <= icap_data_out[31];

    data_o[23] <= icap_data_out[16];
    data_o[22] <= icap_data_out[17];
    data_o[21] <= icap_data_out[18];
    data_o[20] <= icap_data_out[19];
    data_o[19] <= icap_data_out[20];
    data_o[18] <= icap_data_out[21];
    data_o[17] <= icap_data_out[22];
    data_o[16] <= icap_data_out[23];

    data_o[15] <= icap_data_out[8];
    data_o[14] <= icap_data_out[9];
    data_o[13] <= icap_data_out[10];
    data_o[12] <= icap_data_out[11];
    data_o[11] <= icap_data_out[12];
    data_o[10] <= icap_data_out[13];
    data_o[9] <= icap_data_out[14];
    data_o[8] <= icap_data_out[15];

    data_o[7] <= icap_data_out[0];
    data_o[6] <= icap_data_out[1];
    data_o[5] <= icap_data_out[2];
    data_o[4] <= icap_data_out[3];
    data_o[3] <= icap_data_out[4];
    data_o[2] <= icap_data_out[5];
    data_o[1] <= icap_data_out[6];
    data_o[0] <= icap_data_out[7];

    end
ICAPE2#
(   .DEVICE_ID(32'h13631093),
    .ICAP_WIDTH("X32"),
    .SIM_CFG_FILE_NAME("None")
    )
    
    ICAPE2_inst(.O(icap_data_out),
    .CLK(clk_i),
    .CSIB(icap_enable),
    .I(icap_data_in),
    .RDWRB(icap_write_int)
    );
    
endmodule
