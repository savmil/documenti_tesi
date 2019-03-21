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
reg [31:0]  icap_data;
reg         icap_write_int;
reg         icap_enable;
always @(posedge clk_i)
    begin
    
    icap_enable<=en_i;
    icap_write_int<=write_i;
    
    icap_data[31] <= data_i[24];
    icap_data[30] <= data_i[25];
    icap_data[29] <= data_i[26];
    icap_data[28] <= data_i[27];
    icap_data[27] <= data_i[28];
    icap_data[26] <= data_i[29];
    icap_data[25] <= data_i[30];
    icap_data[24] <= data_i[31];
    
    icap_data[23] <= data_i[16];
    icap_data[22] <= data_i[17];
    icap_data[21] <= data_i[18];
    icap_data[20] <= data_i[19];
    icap_data[19] <= data_i[20];
    icap_data[18] <= data_i[21];
    icap_data[17] <= data_i[22];
    icap_data[16] <= data_i[23];
    
    icap_data[15] <= data_i[8];
    icap_data[14] <= data_i[9];
    icap_data[13] <= data_i[10];
    icap_data[12] <= data_i[11];
    icap_data[11] <= data_i[12];
    icap_data[10] <= data_i[13];
    icap_data[9] <= data_i[14];
    icap_data[8] <= data_i[15];
    
    icap_data[7] <= data_i[0];
    icap_data[6] <= data_i[1];
    icap_data[5] <= data_i[2];
    icap_data[4] <= data_i[3];
    icap_data[3] <= data_i[4];
    icap_data[2] <= data_i[5];
    icap_data[1] <= data_i[6];
    icap_data[0] <= data_i[7];
    end
ICAPE2#
(   .DEVICE_ID(0'h03631093),
    .ICAP_WIDTH("X32"),
    .SIM_CFG_FILE_NAME("None")
    )
    
    ICAPE2_inst(.O(data_o),
    .CLK(clk_i),
    .CSIB(icap_enable),
    .I(icap_data),
    .RDWRB(icap_write_int)
    );
    
endmodule
