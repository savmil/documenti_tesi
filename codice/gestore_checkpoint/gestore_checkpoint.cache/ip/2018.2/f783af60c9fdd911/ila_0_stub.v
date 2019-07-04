// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (lin64) Build 2258646 Thu Jun 14 20:02:38 MDT 2018
// Date        : Thu May 23 15:50:41 2019
// Host        : saverio-UX530UX running 64-bit Ubuntu 18.04.2 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2018.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14, probe15)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[9:0],probe1[4:0],probe2[9:0],probe3[35:0],probe4[35:0],probe5[35:0],probe6[35:0],probe7[1:0],probe8[1:0],probe9[1:0],probe10[31:0],probe11[1:0],probe12[31:0],probe13[31:0],probe14[4:0],probe15[35:0]" */;
  input clk;
  input [9:0]probe0;
  input [4:0]probe1;
  input [9:0]probe2;
  input [35:0]probe3;
  input [35:0]probe4;
  input [35:0]probe5;
  input [35:0]probe6;
  input [1:0]probe7;
  input [1:0]probe8;
  input [1:0]probe9;
  input [31:0]probe10;
  input [1:0]probe11;
  input [31:0]probe12;
  input [31:0]probe13;
  input [4:0]probe14;
  input [35:0]probe15;
endmodule
