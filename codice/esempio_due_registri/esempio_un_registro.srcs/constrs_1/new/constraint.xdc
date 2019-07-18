set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_i]
create_clock -period 10.000 -name synth_clk -waveform {0.000 5.000} -add [get_ports clk_i]


set_property IOSTANDARD LVCMOS33 [get_ports rst_i]
set_property PACKAGE_PIN M18 [get_ports rst_i]


set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {h_c[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {h_c[1]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {h_c[2]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {h_c[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {h_c[4]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {h_c[5]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {h_c[6]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {h_c[7]}]


set_property IOSTANDARD LVCMOS33 [get_ports enable_counter]
set_property PACKAGE_PIN M13 [get_ports enable_counter]


create_pblock pblock_c_r
add_cells_to_pblock [get_pblocks pblock_c_r] [get_cells -quiet [list c_r]]
resize_pblock [get_pblocks pblock_c_r] -add {SLICE_X54Y82:SLICE_X61Y92}
resize_pblock [get_pblocks pblock_c_r] -add {DSP48_X1Y34:DSP48_X1Y35}
resize_pblock [get_pblocks pblock_c_r] -add {RAMB18_X1Y34:RAMB18_X1Y35}
resize_pblock [get_pblocks pblock_c_r] -add {RAMB36_X1Y17:RAMB36_X1Y17}
