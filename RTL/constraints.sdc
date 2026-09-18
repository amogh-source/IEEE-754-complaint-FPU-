set EXTCLK "clk" ;
set_units -time 1.0ns ;
set EXTCLK_PERIOD 20.0;
create_clock -name "$EXTCLK" -period "$EXTCLK_PERIOD" -waveform "0
[expr $EXTCLK_PERIOD/2]" [get_ports clk]

set SKEW 0.200
set_clock_uncertainty $SKEW [get_clocks $EXTCLK]
