`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.05.2019 16:15:34
// Design Name: 
// Module Name: counter_reg
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


module counter_reg
    #(parameter prova = "trovami" )
    (
		output reg [31:0] out,  // Output of the counter
		input wire enable,  // enable for counter
		input wire clk,  // clock Input
		input wire reset      // reset Input
    );

	always_ff @(posedge clk)   
	begin
	 if (reset) 
	 begin
	   out <= 32'b0 ;
	 end else if (enable) 
	 begin
	   out <= out + 1;
	 end
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