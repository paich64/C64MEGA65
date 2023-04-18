SRC += ../crt_parser.vhd


DUT ?= crt_parser
GENERIC ?=


TB = tb_$(DUT)
SRC += $(TB).vhd
WAVE = $(TB).ghw
SAVE = $(TB).gtkw

sim: $(SRC)
	ghdl -i --std=08 --work=work $(SRC)
	ghdl -m --std=08 -fexplicit $(TB)
	ghdl -r --std=08 $(TB) $(GENERIC) --assert-level=error --wave=$(WAVE) --stop-time=200us

questa: $(SRC)
	vcom -2008 $(SRC)
	vsim $(TB)

show: $(WAVE)
	gtkwave $(WAVE) $(SAVE)

formal: $(DUT)_bmc/PASS
$(DUT)_bmc/PASS: $(DUT).sby $(DUT).psl $(DUT).vhd
	sby --yosys "yosys -m ghdl" -f $(DUT).sby

show_bmc:
	gtkwave $(DUT)_bmc/engine_0/trace.vcd $(DUT).gtkw

show_cover:
	gtkwave $(DUT)_cover/engine_0/trace.vcd $(DUT).gtkw

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

