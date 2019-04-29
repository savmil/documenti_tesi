vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../gestore_checkpoint.srcs/sources_1/ip/ila_2/hdl/verilog" "+incdir+../../../../gestore_checkpoint.srcs/sources_1/ip/ila_2/hdl/verilog" \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/opt/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../gestore_checkpoint.srcs/sources_1/ip/ila_2/sim/ila_2.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

