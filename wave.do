onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/clk
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/ce
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/dout
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/din
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/mode
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/mtr
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/freq
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sync_n
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/byte_n
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/track
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/busy
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/we
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_clk
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_lba
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_buff_addr
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_buff_dout
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_buff_din
add wave -noupdate /tb_c1541_gcr/i_c1541_gcr/sd_buff_wr
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rst
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/track_d
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/mode_d
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/bit_clk_en
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/bit_clk_cnt
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/bit_cnt
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/s_enc_data
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_byte_cnt
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_sync_cnt
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_sync
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_byte_disk
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_byte_cpu
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/rd_state
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sector
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sector_max
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sector_header
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sector_data
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/hdr_cks
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/data_cks
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/id1
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/id2
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/buff_addr
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/buff_do
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/buff_di
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/buff_we
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/s_dec_ready
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/s_dec_valid
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/s_dec_data
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/m_dec_ready
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/m_dec_valid
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/m_dec_data
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/m_dec_sync
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sd_id1
add wave -noupdate -group Internal /tb_c1541_gcr/i_c1541_gcr/sd_id2
add wave -noupdate -radix unsigned /tb_c1541_gcr/nextsum
add wave -noupdate -radix unsigned /tb_c1541_gcr/ce_sum
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4328980370 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 313
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
WaveRestoreZoom {3946037837 fs} {4964300268 fs}
