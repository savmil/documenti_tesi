vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../scrittura_su_flash.srcs/sources_1/ip/ila/hdl/verilog" "+incdir+../../../../scrittura_su_flash.srcs/sources_1/ip/ila/hdl/verilog" \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../scrittura_su_flash.srcs/sources_1/ip/ila/hdl/verilog" "+incdir+../../../../scrittura_su_flash.srcs/sources_1/ip/ila/hdl/verilog" \
"../../../../scrittura_su_flash.srcs/sources_1/ip/ila/sim/ila.v" \

vlog -work xil_defaultlib \
"glbl.v"

