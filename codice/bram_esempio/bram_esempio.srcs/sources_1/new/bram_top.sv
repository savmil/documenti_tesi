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
   reg O;
   reg A0;
   reg A1;
   reg A2;
   reg A3;
   reg A4;
   reg [35:0] d;
   reg [35:0] in;
   reg [1:0] value;
   reg [0:0] wea;
   //reg [9:0] addra;
   	bram prim(addra,clk_i,d,1'b1,1'b0,36'h00000000,1'b0,4'b0000 );
   	//blk_mem_gen_0 br(addra,clk_i,in,d,wea);
   	//blk_mem_gen_0 b(addra,clk_i,d);
      reg l;
   	initial
   	begin
   		l<=1'b1;
   		wea<=1'b0;
   		//addra<=10'h003;
         in<=36'h000000000;
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
	ila_0 ila(
	.clk(clk_i),
	.probe0(d));				
   // End of ROM32X1_inst instantiation
					
					
endmodule
