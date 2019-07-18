`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.07.2019 08:53:07
// Design Name: 
// Module Name: top_module
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


module top_module(
	input wire clk_i,
	input wire rst_i,
	input wire enable_counter,
	output reg [7:0] h_c
    );

reg [31:0] counter;
reg [31:0] counter1;

 reg [9:0] addr;//indirizzo dato alla bram
 reg en_bram;// abilito le operazioni sulla bram
 reg [35:0] val_bram;//indirizzo letto dalla BRAM di cui fare il checkpoint
 
register c_r 
  (.in(),.out(counter),.enable(enable_counter),.clk(clk_i),.rst(rst_i));
register c_r_1 
  (.in(32'hFFFFFFFF),.out(counter1),.enable(enable_counter),.clk(clk_i),.rst(rst_i));
bram frame_da_salvare(addr,clk_i,val_bram,en_bram,1'b0,36'h000000000,rst_i,4'b0000);

always @(posedge clk_i)
begin
	h_c<=counter[31:25];
end
endmodule