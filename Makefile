all:
	vlog glbl.v
	vlog -sv C64_MiSTerMEGA65/rtl/reu.v
	vcom M2M/vhdl/axi_fifo.vhd
	vcom M2M/vhdl/avm_cache.vhd
	vcom M2M/vhdl/avm_pause.vhd
	vcom MEGA65/vhdl/reu_mapper.vhd
	vcom MEGA65/vhdl/avm_memory.vhd
	vcom M2M/vhdl/avm_memory_pause.vhd
	vcom MEGA65/vhdl/tb_reu.vhd
	vsim -vopt -voptargs=+acc glbl tb_reu -do wave.do

clean:
	rm -rf work

