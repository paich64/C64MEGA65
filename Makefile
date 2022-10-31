all:
	vcom M2M/vhdl/2port2clk_ram.vhd
	vcom C64_MiSTerMEGA65/rtl/iec_drive/axi_expander.vhd
	vcom C64_MiSTerMEGA65/rtl/iec_drive/axi_shrinker.vhd
	vcom C64_MiSTerMEGA65/rtl/iec_drive/axi_gcr.vhd
	vcom C64_MiSTerMEGA65/rtl/iec_drive/c1541_gcr.vhd
	vcom C64_MiSTerMEGA65/rtl/iec_drive/tb_c1541_gcr.vhd
	vsim -vopt -voptargs=+acc glbl tb_c1541_gcr -do wave.do


clean:
	rm -rf work

