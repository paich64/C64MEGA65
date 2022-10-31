SRC += M2M/vhdl/2port2clk_ram.vhd
SRC += C64_MiSTerMEGA65/rtl/iec_drive/axi_expander.vhd
SRC += C64_MiSTerMEGA65/rtl/iec_drive/axi_shrinker.vhd
SRC += C64_MiSTerMEGA65/rtl/iec_drive/axi_gcr.vhd
SRC += C64_MiSTerMEGA65/rtl/iec_drive/c1541_gcr.vhd
SRC += C64_MiSTerMEGA65/rtl/iec_drive/tb_c1541_gcr.vhd
DUT ?= c1541_gcr

TB = tb_$(DUT)
WAVE = C64_MiSTerMEGA65/rtl/iec_drive/$(TB).ghw
SAVE = C64_MiSTerMEGA65/rtl/iec_drive/$(TB).gtkw

sim: $(SRC)
	ghdl -i --std=08 --work=work $(SRC)
	ghdl -m --std=08 -fexplicit $(TB)
	ghdl -r --std=08 $(TB) --assert-level=error --wave=$(WAVE) --stop-time=10ms

show: $(WAVE)
	gtkwave $(WAVE) $(SAVE)

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

