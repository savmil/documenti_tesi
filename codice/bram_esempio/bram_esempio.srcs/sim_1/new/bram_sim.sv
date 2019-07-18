`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2019 14:05:15
// Design Name: 
// Module Name: bram_sim
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


module bram_sim(

    );
	reg [9:0] ADDR;
	reg clk_i=0;
	reg EN;
	reg RST;
	wire [31:0] DO;
	reg REGCE;
	reg [31:0]DI;
	reg [3:0] WE;
	bram uut(
		.ADDR(ADDR),
		.CLK(clk_i),
		.DO(DO),
		.EN(EN),
		.REGCE(REGCE),
		.DI(DI),
		.RST(RST),
		.WE(WE)
		//input wire A4,
		//output reg O
    );
always #10 clk_i = ~clk_i;
	initial begin
	#50
	RST<=1'b0;
	REGCE<=1'b0;
	WE<=4'b0000;
	DI<=32'h00000000;
	#10
	EN<=1'b1;
	ADDR<=10'b0000000000;
	end;
endmodule
