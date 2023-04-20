onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_clk
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_rst
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_clk
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_rst
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_clk
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_rst
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_addr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_writedata
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_ce
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_we
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_readdata
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_wait
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/qnice_length
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_loading
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_id
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_exrom
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_game
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_laddr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_size
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_num
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_type
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_raddr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_bank_wr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_lo_ram_data
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_hi_ram_data
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/main_ram_data_to_c64
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_write
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_read
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_address
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_writedata
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_byteenable
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_burstcount
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_readdata
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_readdatavalid
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/hr_waitrequest
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_roml
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_romh
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_umaxromh
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_ioe
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_iof
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_mem_write
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_mem_ce
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_addr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_data
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_ram_addr
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_freeze_key
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_mod_key
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_nmi_ack
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/tb_running
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_exrom
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_game
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_mem_ce_out
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_mem_write_out
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_io_rom
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_io_rd
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_io_data
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_addr_out
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_bank_lo
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_bank_hi
add wave -noupdate -group tb /tb_sw_cartridge_wrapper/cart_nmi
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_clk_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_rst_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_addr_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_writedata_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_ce_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_we_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_readdata_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_wait_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/qnice_length_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_addr_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_data_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_ioe_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_iof_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_loading_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_mem_ce_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_mem_write_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_ram_addr_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_ram_data_i
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_romh_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_roml_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_umaxromh_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_freeze_key_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_mod_key_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_nmi_ack_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_running_o
add wave -noupdate -group tester_sim /tb_sw_cartridge_wrapper/i_tester_sim/tb_length
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/clk32
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/reset_n
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_loading
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_id
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_exrom
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_game
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_laddr
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_size
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_num
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_type
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_raddr
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/cart_bank_wr
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/exrom
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/game
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/romL
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/romH
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/UMAXromH
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/IOE
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/IOF
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/mem_write
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/mem_ce
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/mem_ce_out
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/mem_write_out
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/IO_rom
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/IO_rd
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/IO_data
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/addr_in
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/data_in
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/addr_out
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/bank_lo
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/bank_hi
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/freeze_key
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/mod_key
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/nmi
add wave -noupdate -expand -group cartridge /tb_sw_cartridge_wrapper/i_cartridge/nmi_ack
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/mask_lo
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/geo_bank
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOE_bank
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOF_bank
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOE_wr_ena
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOF_wr_ena
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/force_ultimax
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/exrom_overide
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/game_overide
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/lobanks
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/hibanks
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/bank_cnt
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOE_ena
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOF_ena
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOE_rd
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/IOF_rd
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/romL_we
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/romH_we
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/old_ioe
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/old_iof
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/stb_ioe
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/stb_iof
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/ioe_wr
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/ioe_rd
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/iof_wr
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/old_freeze
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/freeze_req
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/old_nmiack
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/freeze_ack
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/freeze_crt
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/cart_disable
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/allow_bank
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/ram_bank
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/reu_map
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/clock_port
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/rom_kbb
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/cs_ioe
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/cs_iof
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/init_n
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/allow_freeze
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/saved_d6
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/count
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/count_ena
add wave -noupdate -expand -group cartridge -expand -group Internal /tb_sw_cartridge_wrapper/i_cartridge/label1/old_id
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/clk_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/rst_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/req_start_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/req_address_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/req_length_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/resp_status_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/resp_error_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/resp_address_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_write_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_read_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_address_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_writedata_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_byteenable_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_burstcount_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_readdata_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_readdatavalid_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/avm_waitrequest_i
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_bank_laddr_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_bank_size_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_bank_num_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_bank_raddr_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_bank_wr_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_loading_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_id_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_exrom_o
add wave -noupdate -group crt_parser /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/cart_game_o
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/state
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/wide_readdata
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/wide_readdata_valid
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/read_pos
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/req_address
add wave -noupdate -group crt_parser -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_parser/end_address
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/clk_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/rst_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/req_start_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/req_address_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/req_length_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/resp_status_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/resp_error_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/resp_address_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bank_lo_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bank_hi_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_write_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_read_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_address_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_writedata_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_byteenable_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_burstcount_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_readdata_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_readdatavalid_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_waitrequest_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_bank_laddr_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_bank_size_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_bank_num_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_bank_raddr_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_bank_wr_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_loading_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_id_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_exrom_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/cart_game_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_address_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_data_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_lo_wren_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_lo_q_i
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_hi_wren_o
add wave -noupdate -group crt_loader /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/bram_hi_q_i
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_write
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_read
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_address
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_writedata
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_byteenable
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_burstcount
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_readdata
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_readdatavalid
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_parser_waitrequest
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_write
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_read
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_address
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_writedata
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_byteenable
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_burstcount
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_readdata
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_readdatavalid
add wave -noupdate -group crt_loader -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/avm_cacher_waitrequest
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/clk_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/rst_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_valid_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_bank_laddr_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_bank_size_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_bank_num_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_bank_raddr_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_bank_wr_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bank_lo_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bank_hi_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_write_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_read_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_address_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_writedata_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_byteenable_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_burstcount_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_readdata_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_readdatavalid_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/avm_waitrequest_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_address_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_data_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_lo_wren_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_lo_q_i
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_hi_wren_o
add wave -noupdate -group crt_cacher /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bram_hi_q_i
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/state
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/lobanks
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/hibanks
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/cart_valid_d
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bank_lo_d
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/bank_hi_d
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/hi_load
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/hi_load_done
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/lo_load
add wave -noupdate -group crt_cacher -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/i_crt_loader/i_crt_cacher/lo_load_done
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_clk_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_rst_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_addr_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_data_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_ce_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_we_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_data_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_wait_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_clk_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_rst_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_loading_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_id_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_exrom_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_game_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_laddr_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_size_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_num_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_type_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_raddr_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_wr_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_lo_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_hi_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_bank_wait_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_ram_addr_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_lo_ram_data_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/main_hi_ram_data_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_clk_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_rst_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_write_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_read_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_address_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_writedata_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_byteenable_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_burstcount_o
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_readdata_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_readdatavalid_i
add wave -noupdate -group sw_cartridge_wrapper /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_waitrequest_i
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_req_status
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_req_length
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_req_valid
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_resp_status
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_resp_error
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_resp_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_stat_data
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_hr_ce
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_hr_addr
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_hr_wait
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_hr_data
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_hr_byteenable
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_write
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_read
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_writedata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_byteenable
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_burstcount
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_readdata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_readdatavalid
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/qnice_avm_waitrequest
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_req_length
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_req_valid
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_resp_status
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_resp_error
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_resp_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_write
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_read
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_writedata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_byteenable
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_burstcount
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_readdata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_readdatavalid
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_qnice_waitrequest
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_write
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_read
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_writedata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_byteenable
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_burstcount
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_readdata
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_readdatavalid
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_crt_waitrequest
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bram_address
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bram_data
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bram_lo_wren
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bram_hi_wren
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_lo
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_hi
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_wait
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_loading
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_id
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_exrom
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_game
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_laddr
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_size
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_num
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_type
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_raddr
add wave -noupdate -group sw_cartridge_wrapper -expand -group Internal /tb_sw_cartridge_wrapper/i_sw_cartridge_wrapper/hr_bank_wr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {555000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 216
configure wave -valuecolwidth 332
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
WaveRestoreZoom {0 ps} {1257130 ps}
