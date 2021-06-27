## Generated SDC file "fpga_toy.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"

## DATE    "Thu Apr 15 00:37:36 2021"

##
## DEVICE  "10M16SAE144C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {FPGA_CLK_50M} -period 20.000 -waveform { 0.000 10.000 } [get_ports {FPGA_CLK_50M}]
create_clock -name {FPGA_CLK2_50M} -period 20.000 -waveform { 0.000 10.000 } [get_ports {FPGA_CLK2_50M}]


#**************************************************************
# Create Generated Clock
#**************************************************************


create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 115 -divide_by 288 -master_clock {FPGA_CLK_50M} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {f7_count[0]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|clk[0]}] -divide_by 2 -master_clock {pll0|altpll_component|auto_generated|pll1|clk[0]} 
create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 115 -divide_by 576 -master_clock {FPGA_CLK_50M} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 115 -divide_by 1152 -master_clock {FPGA_CLK_50M} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[2]}] 
create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[3]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 23 -divide_by 576 -master_clock {FPGA_CLK_50M} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[3]}] 


#create_generated_clock -name {hcq} -source [get_pins {pll0|altpll_component|auto_generated|pll1|clk[2]}] -edges { 1 512 640 } -master_clock {pll0|altpll_component|auto_generated|pll1|clk[2]} [get_registers {hcq}] 

derive_pll_clocks


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

