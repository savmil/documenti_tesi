`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2019 21:28:55
// Design Name: 
// Module Name: flip_flop_d
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
module flip_flop_d (
input  wire data  , // Data Input
input  wire clk   , // Clock Input
output reg  q       // Q output
);
//-------------Code Starts Here---------
    always_ff @ ( posedge clk)
    begin
        q <= data;
    end
endmodule //End Of Module dff_sync_reset
