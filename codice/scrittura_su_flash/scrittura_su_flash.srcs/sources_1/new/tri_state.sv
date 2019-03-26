`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2019 14:13:00
// Design Name: 
// Module Name: tri_state
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


module tri_state(
        input wire in,
        
        input wire rw,
        input wire out,
        output reg ino
    );
    assign ino =in ? rw : out;
endmodule
