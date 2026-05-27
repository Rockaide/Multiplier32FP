set_clock_latency -source -early -min -rise  0.0672814 [get_ports {clk}] -clock clk 
set_clock_latency -source -early -min -fall  0.0674784 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -min -rise  0.0672814 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -min -fall  0.0674784 [get_ports {clk}] -clock clk 
