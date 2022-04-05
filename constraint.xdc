# Eval_Bd page 30
set_property VCCAUX_IO DONTCARE [get_ports {sys_clk_p}]
set_property IOSTANDARD LVDS [get_ports {sys_clk_p}]
set_property LOC E19 [get_ports {sys_clk_p}]

set_property VCCAUX_IO DONTCARE [get_ports {sys_clk_n}]
set_property IOSTANDARD LVDS [get_ports {sys_clk_n}]
set_property LOC E18 [get_ports {sys_clk_n}]

# Eval_Bd page 44
set_property IOSTANDARD LVCMOS18 [get_ports {RX_In}]
set_property LOC AU33 [get_ports {RX_In}]
set_property IOSTANDARD LVCMOS18 [get_ports {TX_Out}]
set_property LOC AU36 [get_ports {TX_Out}]

# LEDS
#set_property PACKAGE_PIN AM39 [get_ports {LED1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED1}]
#set_property PACKAGE_PIN AN39 [get_ports {LED2}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED2}]
#set_property PACKAGE_PIN AR37 [get_ports {LED3}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED3}]
#set_property PACKAGE_PIN AT37 [get_ports {LED4}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED4}]
#set_property PACKAGE_PIN AR35 [get_ports {LED5}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED5}]
#set_property PACKAGE_PIN AP41 [get_ports {LED6}]
#set_property IOSTANDARD LVCMOS18 [get_ports {LED6}]
#set_property PACKAGE_PIN AP42 [get_ports GPIO_LED_6_LS]
#set_property IOSTANDARD LVCMOS18 [get_ports GPIO_LED_6_LS]
#set_property PACKAGE_PIN AU39 [get_ports GPIO_LED_7_LS]
#set_property IOSTANDARD LVCMOS18 [get_ports GPIO_LED_7_LS]