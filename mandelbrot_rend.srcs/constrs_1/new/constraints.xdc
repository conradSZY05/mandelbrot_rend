# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
	
	
# LEDs out
set_property PACKAGE_PIN U16 [get_ports {data_o[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[0]}]
set_property PACKAGE_PIN E19 [get_ports {data_o[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[1]}]
set_property PACKAGE_PIN U19 [get_ports {data_o[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[2]}]
set_property PACKAGE_PIN V19 [get_ports {data_o[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[3]}]
set_property PACKAGE_PIN W18 [get_ports {data_o[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[4]}]
set_property PACKAGE_PIN U15 [get_ports {data_o[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[5]}]
set_property PACKAGE_PIN U14 [get_ports {data_o[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[6]}]
set_property PACKAGE_PIN V14 [get_ports {data_o[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_o[7]}]
	
	
# USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports rx]						
	set_property IOSTANDARD LVCMOS33 [get_ports rx]
	
# reset button (up)
set_property PACKAGE_PIN T18 [get_ports reset]						
    set_property IOSTANDARD LVCMOS33 [get_ports reset]