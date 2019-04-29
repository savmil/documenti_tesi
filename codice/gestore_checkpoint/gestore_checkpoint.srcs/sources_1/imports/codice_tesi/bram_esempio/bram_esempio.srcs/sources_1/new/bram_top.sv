`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2019 23:34:22
// Design Name: 
// Module Name: bram_top
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


module bram_top(
	input wire clk_i,
	input reg[9:0] addra,
	//output reg led,
	output reg [15:0] data
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
   reg O;
   reg A0;
   reg A1;
   reg A2;
   reg A3;
   reg A4;
   reg [31:0] d;
   reg [1:0] value;
   /*ROM32X1 #(
      .INIT(32'h00000001) // Contents of ROM
   ) ROM32X1_inst (
      .O(O),   // ROM output
      .A0(1), // ROM address[0]
      .A1(1), // ROM address[1]
      .A2(1), // ROM address[2]
      .A3(1), // ROM address[3]
      .A4(1)  // ROM address[4]
   );*/
   //blk_mem_gen ins(addra,clk_i,32'h00000000,data,1'b0);
  //blk_mem_gen ins1(addr,clk_i,data);
   //dist_mem_gen_0 ins2(d,data);
   	bram prim(addra,clk_i,d,1'b1,1'b0,32'h00000000,1'b0,4'b0000 );
   	reg l;
   	initial
   	begin
   		l<=1'b1;
   		//addra<=10'b1111111111;
   	end
   always @(posedge clk_i)

					begin
						
							data<=d[15:0];
							//addra<=10'b0000000000;
							//d<=4'b0000;
							//addr[1]<=1'b1;
							//addr[2]<=1'b1;
							//addr[3]<=1'b1;
							//addr[4]<=1'b0;
							//addr <=2'b11;
							l<=value[0];
						
					end
   // End of ROM32X1_inst instantiation
					
					
endmodule
