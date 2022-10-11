onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb_reu /tb_reu/cnt
add wave -noupdate -group tb_reu /tb_reu/clk
add wave -noupdate -group tb_reu /tb_reu/rst
add wave -noupdate -group tb_reu /tb_reu/dma_req
add wave -noupdate -group tb_reu /tb_reu/dma_cycle
add wave -noupdate -group tb_reu /tb_reu/dma_addr
add wave -noupdate -group tb_reu /tb_reu/dma_dout
add wave -noupdate -group tb_reu /tb_reu/dma_din
add wave -noupdate -group tb_reu /tb_reu/dma_we
add wave -noupdate -group tb_reu /tb_reu/ram_cycle
add wave -noupdate -group tb_reu /tb_reu/ram_cycle_reu
add wave -noupdate -group tb_reu /tb_reu/ram_addr
add wave -noupdate -group tb_reu /tb_reu/ram_dout
add wave -noupdate -group tb_reu /tb_reu/ram_din
add wave -noupdate -group tb_reu /tb_reu/ram_we
add wave -noupdate -group tb_reu /tb_reu/ram_cs
add wave -noupdate -group tb_reu /tb_reu/cpu_addr
add wave -noupdate -group tb_reu /tb_reu/cpu_dout
add wave -noupdate -group tb_reu /tb_reu/cpu_din
add wave -noupdate -group tb_reu /tb_reu/cpu_we
add wave -noupdate -group tb_reu /tb_reu/cpu_cs
add wave -noupdate -group tb_reu /tb_reu/irq
add wave -noupdate -group tb_reu /tb_reu/avm_read
add wave -noupdate -group tb_reu /tb_reu/avm_address
add wave -noupdate -group tb_reu /tb_reu/avm_writedata
add wave -noupdate -group tb_reu /tb_reu/avm_byteenable
add wave -noupdate -group tb_reu /tb_reu/avm_burstcount
add wave -noupdate -group tb_reu /tb_reu/avm_readdata
add wave -noupdate -group tb_reu /tb_reu/avm_readdatavalid
add wave -noupdate -group tb_reu /tb_reu/avm_waitrequest
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/clk_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/rst_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_ext_cycle_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_ext_cycle_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_addr_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_dout_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_din_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_we_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/reu_cs_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_write_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_read_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_address_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_writedata_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_byteenable_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_burstcount_o
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_readdata_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_readdatavalid_i
add wave -noupdate -group reu_mapper /tb_reu/i_reu_mapper/avm_waitrequest_i
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/reu_ext_cycle_d
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/reu_cs_d
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/reu_rd_fifo_ready
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/reu_rd_fifo_valid
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/active_s
add wave -noupdate -group reu_mapper -group Internal /tb_reu/i_reu_mapper/active
add wave -noupdate -expand -group reu /tb_reu/i_reu/clk
add wave -noupdate -expand -group reu /tb_reu/i_reu/reset
add wave -noupdate -expand -group reu /tb_reu/i_reu/cfg
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_req
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_cycle
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_addr
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_dout
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_din
add wave -noupdate -expand -group reu /tb_reu/i_reu/dma_we
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_cycle
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_addr
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_dout
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_din
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_we
add wave -noupdate -expand -group reu /tb_reu/i_reu/ram_cs
add wave -noupdate -expand -group reu /tb_reu/i_reu/cpu_addr
add wave -noupdate -expand -group reu /tb_reu/i_reu/cpu_dout
add wave -noupdate -expand -group reu /tb_reu/i_reu/cpu_din
add wave -noupdate -expand -group reu /tb_reu/i_reu/cpu_we
add wave -noupdate -expand -group reu /tb_reu/i_reu/cpu_cs
add wave -noupdate -expand -group reu /tb_reu/i_reu/irq
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/ff00_wr
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/op
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/stage
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/op_cur
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/op_dev
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/op_dat
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/op_act
add wave -noupdate -expand -group reu -expand -group Internal /tb_reu/i_reu/dma_we_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1883587786 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 204
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {42 us}