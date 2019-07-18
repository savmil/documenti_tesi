`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.06.2019 13:18:28
// Design Name: 
// Module Name: FDRE
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


module fdre(
	input wire C,
	input wire CE,
	input wire D,
	input wire R,
	output reg Q
    );

//    FDRE     : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (FDRE_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // FDRE: D Flip-Flop with Clock Enable and Synchronous Reset
   //       Kintex UltraScale
   // Xilinx HDL Language Template, version 2018.2

   FDRE #(
      .INIT(1'b0),          // Initial value of register, 1'b0, 1'b1
      // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
      .IS_C_INVERTED(1'b0), // Optional inversion for C
      .IS_D_INVERTED(1'b0), // Optional inversion for D
      .IS_R_INVERTED(1'b0)  // Optional inversion for R
   )
   FDRE_inst (
      .Q(Q),   // 1-bit output: Data
      .C(C),   // 1-bit input: Clock
      .CE(CE), // 1-bit input: Clock enable
      .D(D),   // 1-bit input: Data
      .R(R)    // 1-bit input: Synchronous reset
   );

   // End of FDRE_inst instantiation
					
					
endmodule
