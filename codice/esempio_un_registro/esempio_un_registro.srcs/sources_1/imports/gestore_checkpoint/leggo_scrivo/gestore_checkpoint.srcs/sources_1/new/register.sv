`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2019 10:38:34
// Design Name: 
// Module Name: register
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

module register
	#(parameter prova = "trovami" )
    (
		output reg [31:0] out,  // Output of the counter
		input wire [31:0] in,
		input wire clk,  // clock Input
		input wire enable, // clock Input
		input wire rst  // clock Input
    );
    genvar i;
    for(i=0; i<32; i=i+1) 
    begin
        fdre fdre_inst(.C(clk),.CE(enable),.R(rst),.D(in[i]),.Q(out[i]));
	end
	/*ila_0 ILA_inst (
    .clk(clk),
    .probe0(clk), // input [0 : 0] PROBE0
    .probe1(reset), // input [0 : 0] PROBE1
    .probe2(enable), // input [0 : 0] PROBE2
    .probe3(out[0]), // input [0 : 0] PROBE3
    .probe4(out[1]), // input [0 : 0] PROBE4
    .probe5(out[2]), // input [0 : 0] PROBE5
    .probe6(out[3]), // input [0 : 0] PROBE6
    .probe7(out[4]),
    .probe8(out[5]),
    .probe9(out[6]),
    .probe10(out[7]),
    .probe11(out[8]),
    .probe12(out[9]),
    .probe13(out[10]),
    .probe14(out[11]),
    .probe15(out[12]),
    .probe16(out[13]),
    .probe17(out[14]),
    .probe18(out[15]),
    .probe19(out[16]),
    .probe20(out)
 );*/
endmodule