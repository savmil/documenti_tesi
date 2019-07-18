`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2019 21:55:39
// Design Name: 
// Module Name: inst_bram
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


module inst_bram(
	input wire clk_i,
	output reg led
    );

//   ROM32X1   : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (ROM32X1_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // ROM32X1: 32 x 1 Asynchronous Distributed (LUT) ROM (Mapped to a SliceM LUT6)
   //          Artix-7
   // Xilinx HDL Language Template, version 2018.2

   

   // End of ROM32X1_inst instantiation
					
					
	//bram i_bram(,clk_i,,led,,,,);	
	//blk_mem_gen gen(,clk_i,,,,);
	reg [15:0]spo;
	wire [5:0]a;
	bram ins(1,0,0,0,0,led);
	//dist_mem_gen_0 d(a,spo);
	initial 
	begin
		led<=1;
	end
   always @(posedge clk_i)
   begin
   	if (led==1) 
   	begin
   		led <=0;
   	end
   	else
	begin
   	led<=1;
   	end 
   end
endmodule
