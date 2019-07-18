set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_i]
create_clock -period 10.000 -name synth_clk -waveform {0.000 5.000} -add [get_ports clk_i]

create_generated_clock -name clk_sck -source [get_ports clk_i] [get_pins -hierarchical *USRCCLKO]

set_property IOSTANDARD LVCMOS33 [get_ports avvia_ciclo]
set_property PACKAGE_PIN N17 [get_ports avvia_ciclo]
set_property PACKAGE_PIN H17 [get_ports icap_ready]
set_property IOSTANDARD LVCMOS33 [get_ports icap_ready]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN M18 [get_ports rst]

set_property IOSTANDARD LVCMOS33 [get_ports leggi_scrivi]
set_property PACKAGE_PIN J15 [get_ports leggi_scrivi]
set_property IOSTANDARD LVCMOS33 [get_ports reset_icap]
set_property PACKAGE_PIN V10 [get_ports reset_icap]

set_property IOSTANDARD LVCMOS33 [get_ports enable_counter]
set_property PACKAGE_PIN L16 [get_ports enable_counter]
set_property IOSTANDARD LVCMOS33 [get_ports enable_reg]
set_property PACKAGE_PIN M13 [get_ports enable_reg]
set_property IOSTANDARD LVCMOS33 [get_ports enable_clk]
set_property PACKAGE_PIN R15 [get_ports enable_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ritorno]
set_property PACKAGE_PIN V17 [get_ports ritorno]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports quad_spi_line_i]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports quad_spi_line_o]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports cs_n]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {h_c[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {h_c[1]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {h_c[2]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {h_c[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {h_c[4]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {h_c[5]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {h_c[6]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {h_c[7]}]
set_property INIT_00 256'h0000000000000000000000000000000000000000000000000000000000000000 [get_cells icap/frame_da_salvare/BRAM_SINGLE_MACRO_inst/genblk3_0.bram36_single_bl.bram36_single_bl]



set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT disable [current_design] # mi serve per dire che non deve fare multiboot ma reboot del fpga
set_property CONFIG_MODE SPIX1 [current_design] # vedere se si può togliere
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design] # vedere se si può togliere
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design] # vedere se si può togliere
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design] # vedere se si può togliere


create_pblock pblock_1
create_pblock pblock_registro
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list icap]]
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list c_r]]
#add_cells_to_pblock [get_pblocks pblock_registro] [get_cells -quiet [list c_r]]
resize_pblock [get_pblocks pblock_registro] -add {SLICE_X8Y158:SLICE_X47Y196}
resize_pblock [get_pblocks pblock_registro] -add {DSP48_X0Y64:DSP48_X0Y77}

set_property BITSTREAM.GENERAL.CRC DISABLE [current_design]
connect_debug_port dbg_hub/clk [get_nets clk_i_IBUF_BUFG]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_i_IBUF]
