`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.05.2019 07:56:02
// Design Name: 
// Module Name: comparator
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


module comparator(
	input wire clk,
	input wire [31:0] first_operand,
	input wire [31:0] second_operand,
	output reg [31:0] result
    );

	always_comb
    begin
    	for (int i=0; i < 32; i++) 
    	begin
    		if (first_operand[i]==1 & second_operand[i]==1)
    		begin
    			result[i]<=1'b0;
    		end
    		else
    		begin
    			result[i]<=second_operand[i];
    		end
    	end

    end
endmodule