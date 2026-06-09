set_clock_latency -source -early -max -rise  -0.168128 [get_ports {clk}] -clock clk 
set_clock_latency -source -early -max -fall  -0.183973 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -rise  -0.168128 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -fall  -0.183973 [get_ports {clk}] -clock clk 
