----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- MEGA65 main file that contains the whole machine
--
-- based on C64_MiSTer by the MiSTer development team
-- powered by MiSTer2MEGA65 done by sy2002 and MJoergen in 2023
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.globals.all;
use work.types_pkg.all;
use work.qnice_tools.all;

library xpm;
use xpm.vcomponents.all;

entity MEGA65_Core is
port (
   CLK                      : in  std_logic;                 -- 100 MHz clock
   RESET_M2M_N              : in  std_logic;                 -- Debounced system reset in system clock domain

   -- Share clock and reset with the framework
   main_clk_o               : out std_logic;                 -- CORE's 54 MHz clock
   main_rst_o               : out std_logic;                 -- CORE's reset, synchronized

   --------------------------------------------------------------------------------------------------------
   -- QNICE Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- Get QNICE clock from the framework: for the vdrives as well as for RAMs and ROMs
   qnice_clk_i              : in  std_logic;

   -- Video and audio mode control
   qnice_dvi_o              : out std_logic;                 -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_video_mode_o       : out natural range 0 to 3;      -- HDMI 1280x720 @ 50 Hz resolution = mode 0,
                                                             -- HDMI 1280x720 @ 60 Hz resolution = mode 1,
                                                             -- PAL 576p in 4:3 and 5:4 are modes 2 and 3
   qnice_scandoubler_o      : out std_logic;                 -- 0 = no scandoubler, 1 = scandoubler
   qnice_audio_mute_o       : out std_logic;
   qnice_audio_filter_o     : out std_logic;
   qnice_zoom_crop_o        : out std_logic;
   qnice_ascal_mode_o       : out std_logic_vector(1 downto 0);
   qnice_ascal_polyphase_o  : out std_logic;
   qnice_ascal_triplebuf_o  : out std_logic;

   -- Flip joystick ports
   qnice_flip_joyports_o    : out std_logic;

   -- On-Screen-Menu selections
   qnice_osm_control_i      : in  std_logic_vector(255 downto 0);

   -- QNICE general purpose register
   qnice_gp_reg_i           : in  std_logic_vector(255 downto 0);

   -- Core-specific devices
   qnice_dev_id_i           : in  std_logic_vector(15 downto 0);
   qnice_dev_addr_i         : in  std_logic_vector(27 downto 0);
   qnice_dev_data_i         : in  std_logic_vector(15 downto 0);
   qnice_dev_data_o         : out std_logic_vector(15 downto 0);
   qnice_dev_ce_i           : in  std_logic;
   qnice_dev_we_i           : in  std_logic;

   --------------------------------------------------------------------------------------------------------
   -- Core Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- M2M's reset manager provides 2 signals:
   --    m2m:   Reset the whole machine: Core and Framework
   --    core:  Only reset the core
   main_reset_m2m_i         : in  std_logic;
   main_reset_core_i        : in  std_logic;

   main_pause_core_i        : in  std_logic;

   -- On-Screen-Menu selections
   main_osm_control_i       : in  std_logic_vector(255 downto 0);

   -- QNICE general purpose register converted to main clock domain
   main_qnice_gp_reg_i      : in  std_logic_vector(255 downto 0);

   -- Video output
   main_video_ce_o          : out std_logic;
   main_video_ce_ovl_o      : out std_logic;
   main_video_retro15kHz_o  : out std_logic;
   main_video_red_o         : out std_logic_vector(7 downto 0);
   main_video_green_o       : out std_logic_vector(7 downto 0);
   main_video_blue_o        : out std_logic_vector(7 downto 0);
   main_video_vs_o          : out std_logic;
   main_video_hs_o          : out std_logic;
   main_video_hblank_o      : out std_logic;
   main_video_vblank_o      : out std_logic;

   -- Audio output (Signed PCM)
   main_audio_left_o        : out signed(15 downto 0);
   main_audio_right_o       : out signed(15 downto 0);

   -- M2M Keyboard interface (incl. drive led)
   main_kb_key_num_i        : in  integer range 0 to 79;     -- cycles through all MEGA65 keys
   main_kb_key_pressed_n_i  : in  std_logic;                 -- low active: debounced feedback: is kb_key_num_i pressed right now?
   main_drive_led_o         : out std_logic;
   main_drive_led_col_o     : out std_logic_vector(23 downto 0);

   -- Joysticks and paddles input
   main_joy_1_up_n_i        : in  std_logic;
   main_joy_1_down_n_i      : in  std_logic;
   main_joy_1_left_n_i      : in  std_logic;
   main_joy_1_right_n_i     : in  std_logic;
   main_joy_1_fire_n_i      : in  std_logic;
   main_joy_2_up_n_i        : in  std_logic;
   main_joy_2_down_n_i      : in  std_logic;
   main_joy_2_left_n_i      : in  std_logic;
   main_joy_2_right_n_i     : in  std_logic;
   main_joy_2_fire_n_i      : in  std_logic;
   main_pot1_x_i            : in  std_logic_vector(7 downto 0);
   main_pot1_y_i            : in  std_logic_vector(7 downto 0);
   main_pot2_x_i            : in  std_logic_vector(7 downto 0);
   main_pot2_y_i            : in  std_logic_vector(7 downto 0);

   --------------------------------------------------------------------------------------------------------
   -- Provide support for external memory (Avalon Memory Map)
   --------------------------------------------------------------------------------------------------------

   main_avm_write_o         : out std_logic;
   main_avm_read_o          : out std_logic;
   main_avm_address_o       : out std_logic_vector(31 downto 0);
   main_avm_writedata_o     : out std_logic_vector(15 downto 0);
   main_avm_byteenable_o    : out std_logic_vector( 1 downto 0);
   main_avm_burstcount_o    : out std_logic_vector( 7 downto 0);
   main_avm_readdata_i      : in  std_logic_vector(15 downto 0);
   main_avm_readdatavalid_i : in  std_logic;
   main_avm_waitrequest_i   : in  std_logic;

   --------------------------------------------------------------------
   -- C64 specific ports that are not supported by the M2M framework
   --------------------------------------------------------------------

   -- C64 Expansion Port (aka Cartridge Port) control lines
   -- *_dir=1 means FPGA->Port, =0 means Port->FPGA
   cart_ctrl_en_o           : out std_logic;
   cart_ctrl_dir_o          : out std_logic;
   cart_addr_en_o           : out std_logic;
   cart_haddr_dir_o         : out std_logic;
   cart_laddr_dir_o         : out std_logic;
   cart_data_en_o           : out std_logic;
   cart_data_dir_o          : out std_logic;

   -- C64 Expansion Port (aka Cartridge Port)
   cart_reset_o             : out std_logic;
   cart_phi2_o              : out std_logic;
   cart_dotclock_o          : out std_logic;

   cart_nmi_i               : in  std_logic;
   cart_irq_i               : in  std_logic;
   cart_dma_i               : in  std_logic;
   cart_exrom_i             : in  std_logic;
   cart_game_i              : in  std_logic;

   cart_ba_io               : inout std_logic;
   cart_rw_io               : inout std_logic;
   cart_roml_io             : inout std_logic;
   cart_romh_io             : inout std_logic;
   cart_io1_io              : inout std_logic;
   cart_io2_io              : inout std_logic;

   cart_d_io                : inout unsigned(7 downto 0);
   cart_a_io                : inout unsigned(15 downto 0)
);
end entity MEGA65_Core;

architecture synthesis of MEGA65_Core is

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal main_clk                   : std_logic;               -- Core main clock
signal main_rst                   : std_logic;

---------------------------------------------------------------------------------------------
-- main_clk (MiSTer core's clock)
---------------------------------------------------------------------------------------------

-- C64 specific signals for PAL/NTSC and core speed switching
signal core_speed                 : unsigned(1 downto 0);    -- see clock.vhd for details
signal c64_ntsc                   : std_logic;               -- global switch: 0 = PAL mode, 1 = NTSC mode
signal c64_clock_speed            : natural;                 -- clock speed depending on PAL/NTSC
signal c64_exp_port_mode          : natural range 0 to 2;    -- Expansion Port: Use hardware, simulate REU, simulate cartridge (.crt file)

-- C64 RAM
signal main_ram_addr              : unsigned(15 downto 0);         -- C64 address bus
signal main_ram_data_from_c64     : unsigned(7 downto 0);          -- C64 RAM data out
signal main_ram_we                : std_logic;                     -- C64 RAM write enable
signal main_ram_data_to_c64       : std_logic_vector(7 downto 0);  -- C64 RAM data in
signal main_ram_data              : std_logic_vector(7 downto 0);
signal main_crt_lo_ram_data       : std_logic_vector(7 downto 0);
signal main_crt_hi_ram_data       : std_logic_vector(7 downto 0);

-- RAM Expansion Unit
signal main_ext_cycle             : std_logic;
signal main_reu_cycle             : std_logic;
signal main_reu_addr              : std_logic_vector(24 downto 0);
signal main_reu_dout              : std_logic_vector( 7 downto 0);
signal main_reu_din               : std_logic_vector( 7 downto 0);
signal main_reu_we                : std_logic;
signal main_reu_cs                : std_logic;

signal main_map_write             : std_logic;
signal main_map_read              : std_logic;
signal main_map_address           : std_logic_vector(31 downto 0);
signal main_map_writedata         : std_logic_vector(15 downto 0);
signal main_map_byteenable        : std_logic_vector( 1 downto 0);
signal main_map_burstcount        : std_logic_vector( 7 downto 0);
signal main_map_readdata          : std_logic_vector(15 downto 0);
signal main_map_readdatavalid     : std_logic;
signal main_map_waitrequest       : std_logic;

signal main_avm_reu_write         : std_logic;
signal main_avm_reu_read          : std_logic;
signal main_avm_reu_address       : std_logic_vector(31 downto 0);
signal main_avm_reu_writedata     : std_logic_vector(15 downto 0);
signal main_avm_reu_byteenable    : std_logic_vector( 1 downto 0);
signal main_avm_reu_burstcount    : std_logic_vector( 7 downto 0);
signal main_avm_reu_readdata      : std_logic_vector(15 downto 0);
signal main_avm_reu_readdatavalid : std_logic;
signal main_avm_reu_waitrequest   : std_logic;

-- TBD: Signals from the framework to the cartridge.v module
signal main_cartridge_loading     : std_logic;
signal main_cartridge_id          : std_logic_vector(15 downto 0);
signal main_cartridge_exrom       : std_logic_vector( 7 downto 0);
signal main_cartridge_game        : std_logic_vector( 7 downto 0);
signal main_cartridge_bank_laddr  : std_logic_vector(15 downto 0);
signal main_cartridge_bank_size   : std_logic_vector(15 downto 0);
signal main_cartridge_bank_num    : std_logic_vector(15 downto 0);
signal main_cartridge_bank_type   : std_logic_vector( 7 downto 0);
signal main_cartridge_bank_raddr  : std_logic_vector(24 downto 0);
signal main_cartridge_bank_wr     : std_logic;

signal main_crt_busy              : std_logic;
signal main_crt_hi_load           : std_logic;
signal main_crt_hi_address        : std_logic_vector(31 downto 0);
signal main_crt_lo_load           : std_logic;
signal main_crt_lo_address        : std_logic_vector(31 downto 0);
signal main_bram_lo_address       : std_logic_vector(12 downto 0);
signal main_bram_lo_data          : std_logic_vector( 7 downto 0);
signal main_bram_lo_wren          : std_logic;
signal main_bram_hi_address       : std_logic_vector(12 downto 0);
signal main_bram_hi_data          : std_logic_vector( 7 downto 0);
signal main_bram_hi_wren          : std_logic;

signal main_avm_crt_write         : std_logic;
signal main_avm_crt_read          : std_logic;
signal main_avm_crt_address       : std_logic_vector(31 downto 0);
signal main_avm_crt_writedata     : std_logic_vector(15 downto 0);
signal main_avm_crt_byteenable    : std_logic_vector( 1 downto 0);
signal main_avm_crt_burstcount    : std_logic_vector( 7 downto 0);
signal main_avm_crt_readdata      : std_logic_vector(15 downto 0);
signal main_avm_crt_readdatavalid : std_logic;
signal main_avm_crt_waitrequest   : std_logic;

signal main_crt_bank_lo           : std_logic_vector(6 downto 0);
signal main_crt_bank_hi           : std_logic_vector(6 downto 0);
signal main_crt_bank_lo_d         : std_logic_vector(6 downto 0);
signal main_crt_bank_hi_d         : std_logic_vector(6 downto 0);

---------------------------------------------------------------------------------------------
-- qnice_clk
---------------------------------------------------------------------------------------------

-- OSM selections within qnice_osm_control_i
constant C_MENU_EXP_PORT_HW   : natural := 6;
constant C_MENU_EXP_PORT_REU  : natural := 7;
constant C_MENU_EXP_PORT_CRT  : natural := 8;
constant C_MENU_FLIP_JOYS     : natural := 13;
constant C_MENU_8580          : natural := 18;
constant C_MENU_IMPROVE_AUDIO : natural := 19;
constant C_MENU_8521          : natural := 22;
constant C_MENU_HDMI_16_9_50  : natural := 29;
constant C_MENU_HDMI_16_9_60  : natural := 30;
constant C_MENU_HDMI_4_3_50   : natural := 31;
constant C_MENU_HDMI_5_4_50   : natural := 32;
constant C_MENU_CRT_EMULATION : natural := 35;
constant C_MENU_HDMI_ZOOM     : natural := 36;
constant C_MENU_HDMI_FF       : natural := 37;
constant C_MENU_HDMI_DVI      : natural := 38;
constant C_MENU_VGA_RETRO     : natural := 39;

-- RAMs for the C64
signal qnice_c64_ram_data           : std_logic_vector(7 downto 0);  -- C64's actual 64kB of RAM
signal qnice_c64_ram_we             : std_logic;
signal qnice_c64_mount_buf_ram_data : std_logic_vector(7 downto 0);  -- Disk mount buffer
signal qnice_c64_mount_buf_ram_we   : std_logic;

-- QNICE signals passed down to main.vhd to handle IEC drives using vdrives.vhd
signal qnice_c64_qnice_ce     : std_logic;
signal qnice_c64_qnice_we     : std_logic;
signal qnice_c64_qnice_data   : std_logic_vector(15 downto 0);

attribute mark_debug : string;
attribute mark_debug of main_crt_bank_lo         : signal is "true";
attribute mark_debug of main_crt_bank_hi         : signal is "true";
attribute mark_debug of c64_exp_port_mode        : signal is "true";
attribute mark_debug of main_avm_write_o         : signal is "true";
attribute mark_debug of main_avm_read_o          : signal is "true";
attribute mark_debug of main_avm_address_o       : signal is "true";
attribute mark_debug of main_avm_writedata_o     : signal is "true";
attribute mark_debug of main_avm_byteenable_o    : signal is "true";
attribute mark_debug of main_avm_burstcount_o    : signal is "true";
attribute mark_debug of main_avm_waitrequest_i   : signal is "true";
attribute mark_debug of main_avm_readdata_i      : signal is "true";
attribute mark_debug of main_avm_readdatavalid_i : signal is "true";

begin

   -- MMCME2_ADV clock generators
   --   C64 PAL: 31.528 MHz (main) and 63.056 MHz (video)
   --            HDMI: Flicker-free: 0.25% slower
   clk_gen : entity work.clk
      port map (
         sys_clk_i         => CLK,             -- expects 100 MHz
         sys_rstn_i        => RESET_M2M_N,     -- Asynchronous, asserted low
         qnice_clk_i       => qnice_clk_i,

         core_speed_i      => core_speed,      -- 0=PAL/original C64, 1=PAL/HDMI flicker-free, 2=NTSC

         main_clk_o        => main_clk,        -- core's clock
         main_rst_o        => main_rst         -- core's reset, synchronized
      ); -- clk_gen

   -- share core's clock with the framework
   main_clk_o <= main_clk;
   main_rst_o <= main_rst;

   ---------------------------------------------------------------------------------------------
   -- Global switches for the core
   ---------------------------------------------------------------------------------------------

   c64_ntsc          <= '0'; -- @TODO: For now, we hardcode PAL mode

   -- needs to be in qnice clock domain
   core_speed        <= "01" when qnice_osm_control_i(C_MENU_HDMI_FF) else "00";

   -- needs to be in main clock domain
   c64_clock_speed   <= CORE_CLK_SPEED;

   -- Mode selection for Expansion Port (aka Cartridge Port):
   -- 0: Use the MEGA65's actual hardware slot
   -- 1: Simulate a 1750 REU with 512KB
   -- 2: Simulate a cartridge by using a cartridge from from the SD card (.crt file)
   c64_exp_port_mode <= 1 when main_osm_control_i(C_MENU_EXP_PORT_REU)  else
                        2 when main_osm_control_i(C_MENU_EXP_PORT_CRT)  else
                        0;

   ---------------------------------------------------------------------------------------------
   -- main_clk (C64 MiSTer Core clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual MiSTer core
   i_main : entity work.main
      generic map (
         G_VDNUM                => C_VDNUM
      )
      port map (
         clk_main_i             => main_clk,
         reset_soft_i           => main_reset_core_i,
         reset_hard_i           => main_reset_m2m_i,
         pause_i                => main_pause_core_i,

         ---------------------------
         -- Configuration options
         ---------------------------

         -- Video mode selection:
         -- c64_ntsc_i: PAL/NTSC switch
         -- clk_main_speed_i: The core's clock speed depends on mode and needs to be very exact for avoiding clock drift
         -- video_retro15kHz_i: Analog video output configuration: Horizontal sync frequency: '0'  =30 kHz ("normal" on "modern" analog monitors), '1'=retro 15 kHz
         c64_ntsc_i             => c64_ntsc,
         clk_main_speed_i       => c64_clock_speed,
         video_retro15kHz_i     => main_osm_control_i(C_MENU_VGA_RETRO),

         -- SID and CIA versions
         c64_sid_ver_i          => main_osm_control_i(C_MENU_8580) & main_osm_control_i(C_MENU_8580),
         c64_cia_ver_i          => main_osm_control_i(C_MENU_8521),

         -- Mode selection for Expansion Port (aka Cartridge Port):
         -- 0: Use the MEGA65's actual hardware slot
         -- 1: Simulate a 1750 REU with 512KB
         -- 2: Simulate a cartridge by using a cartridge from from the SD card (.crt file)
         c64_exp_port_mode_i    => c64_exp_port_mode,

         ---------------------------
         -- Commodore 64 I/O ports
         ---------------------------

         -- M2M Keyboard interface
         kb_key_num_i           => main_kb_key_num_i,
         kb_key_pressed_n_i     => main_kb_key_pressed_n_i,

         -- MEGA65 joysticks and paddles
         joy_1_up_n_i           => main_joy_1_up_n_i ,
         joy_1_down_n_i         => main_joy_1_down_n_i,
         joy_1_left_n_i         => main_joy_1_left_n_i,
         joy_1_right_n_i        => main_joy_1_right_n_i,
         joy_1_fire_n_i         => main_joy_1_fire_n_i,
         joy_2_up_n_i           => main_joy_2_up_n_i,
         joy_2_down_n_i         => main_joy_2_down_n_i,
         joy_2_left_n_i         => main_joy_2_left_n_i,
         joy_2_right_n_i        => main_joy_2_right_n_i,
         joy_2_fire_n_i         => main_joy_2_fire_n_i,
         pot1_x_i               => main_pot1_x_i,
         pot1_y_i               => main_pot1_y_i,
         pot2_x_i               => main_pot2_x_i,
         pot2_y_i               => main_pot2_y_i,

         -- Video output
         -- This is PAL 720x576 @ 50 Hz (pixel clock 27 MHz), but synchronized to main_clk (54 MHz).
         video_ce_o             => main_video_ce_o,
         video_ce_ovl_o         => main_video_ce_ovl_o,
         video_retro15kHz_o     => main_video_retro15kHz_o,
         video_red_o            => main_video_red_o,
         video_green_o          => main_video_green_o,
         video_blue_o           => main_video_blue_o,
         video_vs_o             => main_video_vs_o,
         video_hs_o             => main_video_hs_o,
         video_hblank_o         => main_video_hblank_o,
         video_vblank_o         => main_video_vblank_o,

         -- Audio output (PCM format, signed values)
         audio_left_o           => main_audio_left_o,
         audio_right_o          => main_audio_right_o,

         -- C64 drive led
         drive_led_o            => main_drive_led_o,
         drive_led_col_o        => main_drive_led_col_o,

         -- C64 RAM
         c64_ram_addr_o         => main_ram_addr,
         c64_ram_data_o         => main_ram_data_from_c64,
         c64_ram_we_o           => main_ram_we,
         c64_ram_data_i         => unsigned(main_ram_data_to_c64),

         -- C64 IEC handled by QNICE
         c64_clk_sd_i           => qnice_clk_i,   -- "sd card write clock" for floppy drive internal dual clock RAM buffer
         c64_qnice_addr_i       => qnice_dev_addr_i,
         c64_qnice_data_i       => qnice_dev_data_i,
         c64_qnice_data_o       => qnice_c64_qnice_data,
         c64_qnice_ce_i         => qnice_c64_qnice_ce,
         c64_qnice_we_i         => qnice_c64_qnice_we,

         -- C64 Expansion Port (aka Cartridge Port) control lines
         -- *_dir=1 means FPGA->Port, =0 means Port->FPGA
         cart_ctrl_en_o         => cart_ctrl_en_o,
         cart_ctrl_dir_o        => cart_ctrl_dir_o,
         cart_addr_en_o         => cart_addr_en_o,
         cart_haddr_dir_o       => cart_haddr_dir_o,
         cart_laddr_dir_o       => cart_laddr_dir_o,
         cart_data_en_o         => cart_data_en_o,
         cart_data_dir_o        => cart_data_dir_o,

         -- C64 Expansion Port (aka Cartridge Port)
         cart_reset_o           => cart_reset_o,
         cart_phi2_o            => cart_phi2_o,
         cart_dotclock_o        => cart_dotclock_o,
         cart_nmi_i             => cart_nmi_i,
         cart_irq_i             => cart_irq_i,
         cart_dma_i             => cart_dma_i,
         cart_exrom_i           => cart_exrom_i,
         cart_game_i            => cart_game_i,
         cart_ba_io             => cart_ba_io,
         cart_rw_io             => cart_rw_io,
         cart_roml_io           => cart_roml_io,
         cart_romh_io           => cart_romh_io,
         cart_io1_io            => cart_io1_io,
         cart_io2_io            => cart_io2_io,
         cart_d_io              => cart_d_io,
         cart_a_io              => cart_a_io,

         -- RAM Expansion Unit (REU)
         ext_cycle_o            => main_ext_cycle,
         reu_cycle_i            => main_reu_cycle,
         reu_addr_o             => main_reu_addr,
         reu_dout_o             => main_reu_dout,
         reu_din_i              => main_reu_din,
         reu_we_o               => main_reu_we,
         reu_cs_o               => main_reu_cs,

         -- Support for software based cartridges (aka ".CRT" files)
         cartridge_loading_i    => main_cartridge_loading,
         cartridge_id_i         => main_cartridge_id,
         cartridge_exrom_i      => main_cartridge_exrom,
         cartridge_game_i       => main_cartridge_game,
         cartridge_bank_laddr_i => main_cartridge_bank_laddr,
         cartridge_bank_size_i  => main_cartridge_bank_size,
         cartridge_bank_num_i   => main_cartridge_bank_num,
         cartridge_bank_type_i  => main_cartridge_bank_type,
         cartridge_bank_raddr_i => main_cartridge_bank_raddr,
         cartridge_bank_wr_i    => main_cartridge_bank_wr,
         crt_bank_lo_o          => main_crt_bank_lo,
         crt_bank_hi_o          => main_crt_bank_hi

      ); -- i_main

   ---------------------------------------------------------------------------------------------
   -- Audio and video settings (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   -- Due to a discussion on the MEGA65 discord (https://discord.com/channels/719326990221574164/794775503818588200/1039457688020586507)
   -- we decided to choose a naming convention for the PAL modes that might be more intuitive for the end users than it is
   -- for the programmers: "4:3" means "meant to be run on a 4:3 monitor", "5:4 on a 5:4 monitor".
   -- The technical reality is though, that in our "5:4" mode we are actually doing a 4/3 aspect ratio adjustment
   -- while in the 4:3 mode we are outputting a 5:4 image. This is kind of odd, but it seemed that our 4/3 aspect ratio
   -- adjusted image looks best on a 5:4 monitor and the other way round.
   -- Not sure if this will stay forever or if we will come up with a better naming convention.
   qnice_video_mode_o <= 3 when qnice_osm_control_i(C_MENU_HDMI_5_4_50)  = '1' else
                         2 when qnice_osm_control_i(C_MENU_HDMI_4_3_50)  = '1' else
                         1 when qnice_osm_control_i(C_MENU_HDMI_16_9_60) = '1' else
                         0;

   -- Use On-Screen-Menu selections to configure several audio and video settings
   -- Video and audio mode control
   qnice_dvi_o                <= qnice_osm_control_i(C_MENU_HDMI_DVI);        -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_scandoubler_o        <= not qnice_osm_control_i(C_MENU_VGA_RETRO);   -- no scandoubler when using the retro 15 kHz RGB mode
   qnice_audio_mute_o         <= '0';                                         -- audio is not muted
   qnice_audio_filter_o       <= qnice_osm_control_i(C_MENU_IMPROVE_AUDIO);   -- 0 = raw audio, 1 = use filters from globals.vhd
   qnice_zoom_crop_o          <= qnice_osm_control_i(C_MENU_HDMI_ZOOM);       -- 0 = no zoom/crop

   -- ascal filters that are applied while processing the input
   -- 00 : Nearest Neighbour
   -- 01 : Bilinear
   -- 10 : Sharp Bilinear
   -- 11 : Bicubic
   qnice_ascal_mode_o         <= "00";

   -- If polyphase is '1' then the ascal filter mode is ignored and polyphase filters are used instead
   -- @TODO: Right now, the filters are hardcoded in the M2M framework, we need to make them changeable inside m2m-rom.asm
   qnice_ascal_polyphase_o    <= qnice_osm_control_i(C_MENU_CRT_EMULATION);

   -- ascal triple-buffering
   -- @TODO: Right now, the M2M framework only supports OFF, so do not touch until the framework is upgraded
   qnice_ascal_triplebuf_o    <= '0';

   -- Flip joystick ports (i.e. the joystick in port 2 is used as joystick 1 and vice versa)
   qnice_flip_joyports_o      <= qnice_osm_control_i(C_MENU_FLIP_JOYS);

   ---------------------------------------------------------------------------------------------
   -- Core specific device handling (QNICE clock domain, device IDs in globals.vhd)
   ---------------------------------------------------------------------------------------------

   core_specific_devices : process(all)
   begin
      -- avoid latches
      qnice_dev_data_o           <= x"EEEE";
      qnice_c64_ram_we           <= '0';
      qnice_c64_qnice_ce         <= '0';
      qnice_c64_qnice_we         <= '0';
      qnice_c64_mount_buf_ram_we <= '0';

      case qnice_dev_id_i is
         -- C64 RAM
         when C_DEV_C64_RAM =>
            qnice_c64_ram_we           <= qnice_dev_we_i;
            qnice_dev_data_o           <= x"00" & qnice_c64_ram_data;

         -- C64 IEC drives
         when C_VD_DEVICE =>
            qnice_c64_qnice_ce         <= qnice_dev_ce_i;
            qnice_c64_qnice_we         <= qnice_dev_we_i;
            qnice_dev_data_o           <= qnice_c64_qnice_data;

         -- Disk mount buffer RAM
         when C_DEV_C64_MOUNT =>
            qnice_c64_mount_buf_ram_we <= qnice_dev_we_i;
            qnice_dev_data_o           <= x"00" & qnice_c64_mount_buf_ram_data;

           when others => null;
      end case;
   end process core_specific_devices;

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   -- C64's RAM modelled as dual clock & dual port RAM so that the Commodore 64 core
   -- as well as QNICE can access it
   c64_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH        => 16,
         DATA_WIDTH        => 8,
         FALLING_A         => false,      -- C64 expects read/write to happen at the rising clock edge
         FALLING_B         => true        -- QNICE expects read/write to happen at the falling clock edge
      )
      port map (
         -- C64 MiSTer core
         clock_a           => main_clk,
         address_a         => std_logic_vector(main_ram_addr),
         data_a            => std_logic_vector(main_ram_data_from_c64),
         wren_a            => main_ram_we,
         q_a               => main_ram_data,

         -- QNICE
         clock_b           => qnice_clk_i,
         address_b         => qnice_dev_addr_i(15 downto 0),
         data_b            => qnice_dev_data_i(7 downto 0),
         wren_b            => qnice_c64_ram_we,
         q_b               => qnice_c64_ram_data
      ); -- c64_ram

   -- For now: Let's use a simple BRAM (using only 1 port will make a BRAM) for buffering
   -- the disks that we are mounting. This will work for D64 only.
   -- @TODO: Switch to HyperRAM at a later stage
   mount_buf_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH        => 18,
         DATA_WIDTH        => 8,
         MAXIMUM_SIZE      => 197376,        -- maximum size of any D64 image: non-standard 40-track incl. 768 error bytes
         FALLING_A         => true
      )
      port map (
         -- QNICE only
         clock_a           => qnice_clk_i,
         address_a         => qnice_dev_addr_i(17 downto 0),
         data_a            => qnice_dev_data_i(7 downto 0),
         wren_a            => qnice_c64_mount_buf_ram_we,
         q_a               => qnice_c64_mount_buf_ram_data
      ); -- mount_buf_ram

   -- Software cartridge (CRT) RAM modelled as dual clock & dual port RAM so that the Commodore 64 core
   -- as well as QNICE can access it
   crt_lo_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH        => 13,         -- 8 kB
         DATA_WIDTH        => 8,
         FALLING_A         => false,      -- C64 expects read/write to happen at the rising clock edge
         FALLING_B         => false
      )
      port map (
         -- C64 MiSTer core
         clock_a           => main_clk,
         address_a         => std_logic_vector(main_ram_addr(12 downto 0)),
         data_a            => (others => '0'),
         wren_a            => '0',
         q_a               => main_crt_lo_ram_data,

         -- Not used
         clock_b           => main_clk,
         address_b         => main_bram_lo_address,
         data_b            => main_bram_lo_data,
         wren_b            => main_bram_lo_wren,
         q_b               => open
      ); -- crt_lo_ram

   -- Software cartridge (CRT) RAM modelled as dual clock & dual port RAM so that the Commodore 64 core
   -- as well as QNICE can access it
   crt_hi_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH        => 13,         -- 8 kB
         DATA_WIDTH        => 8,
         FALLING_A         => false,      -- C64 expects read/write to happen at the rising clock edge
         FALLING_B         => false
      )
      port map (
         -- C64 MiSTer core
         clock_a           => main_clk,
         address_a         => std_logic_vector(main_ram_addr(12 downto 0)),
         data_a            => (others => '0'),
         wren_a            => '0',
         q_a               => main_crt_hi_ram_data,

         -- Not used
         clock_b           => main_clk,
         address_b         => main_bram_hi_address,
         data_b            => main_bram_hi_data,
         wren_b            => main_bram_hi_wren,
         q_b               => open
      ); -- crt_lo_ram

   process (main_clk)
   begin
      if rising_edge(main_clk) then
         main_crt_bank_lo_d <= main_crt_bank_lo;
         main_crt_bank_hi_d <= main_crt_bank_hi;
         main_crt_lo_load   <= '0';
         main_crt_hi_load   <= '0';
         main_crt_lo_address <= X"00200000";
         main_crt_hi_address <= X"00200000";

         if main_crt_bank_lo_d /= main_crt_bank_lo then
            main_crt_lo_load <= '1';
         end if;
         if main_crt_bank_hi_d /= main_crt_bank_hi then
            main_crt_hi_load <= '1';
         end if;

         if main_reset_core_i = '1' then
            main_crt_lo_load <= '1';
            main_crt_hi_load <= '1';
         end if;
      end if;
   end process;

   i_crt2hyperram : entity work.crt2hyperram
      port map (
         clk_i               => main_clk,
         rst_i               => main_reset_core_i,
         crt_busy_o          => main_crt_busy,
         crt_hi_load_i       => main_crt_hi_load,
         crt_hi_address_i    => main_crt_hi_address,
         crt_lo_load_i       => main_crt_lo_load,
         crt_lo_address_i    => main_crt_lo_address,
         avm_write_o         => main_avm_crt_write,
         avm_read_o          => main_avm_crt_read,
         avm_address_o       => main_avm_crt_address,
         avm_writedata_o     => main_avm_crt_writedata,
         avm_byteenable_o    => main_avm_crt_byteenable,
         avm_burstcount_o    => main_avm_crt_burstcount,
         avm_readdata_i      => main_avm_crt_readdata,
         avm_readdatavalid_i => main_avm_crt_readdatavalid,
         avm_waitrequest_i   => main_avm_crt_waitrequest,
         bram_lo_address_o   => main_bram_lo_address,
         bram_lo_data_o      => main_bram_lo_data,
         bram_lo_wren_o      => main_bram_lo_wren,
         bram_lo_q_i         => (others => '0'),
         bram_hi_address_o   => main_bram_hi_address,
         bram_hi_data_o      => main_bram_hi_data,
         bram_hi_wren_o      => main_bram_hi_wren,
         bram_hi_q_i         => (others => '0')
      ); -- i_crt2hyperram

   main_ram_data_to_c64 <= main_crt_lo_ram_data when cart_roml_io = '0' else
                           main_crt_hi_ram_data when cart_romh_io = '0' else
                           main_ram_data;

   -- RAM used by the REU inside i_main:
   -- Consists of a three-stage pipeline:
   -- 1) i_avm_fifo does the CDC using a FIFO (as the name suggests) by utilizing Xilinx the specific "xpm_fifo_axis":
   --    It connects to the raw HyperRAM Avalon Memory Mapped interface that M2M's arbiter offers and converts the
   --    signals into the core's clock domain
   -- 2) i_avm_cache optimizes latency, particularly for longer, subsequent RAM accesses
   -- 3) i_reu_mapper: Converts the Avalon interface into the interface that the REU expects PLUS
   --    it includes an optimization ("hack") that ensures that the REU is cycle accurate
   -- The result of stage (3) is then passed to i_main which uses these signals directly with MiSTer's i_reu
   i_reu_mapper : entity work.reu_mapper
      generic map (
         G_BASE_ADDRESS => X"0020_0000"  -- 2MW
      )
      port map (
         clk_i               => main_clk,
         rst_i               => main_reset_core_i,
         reu_ext_cycle_i     => main_ext_cycle,
         reu_ext_cycle_o     => main_reu_cycle,
         reu_addr_i          => main_reu_addr,
         reu_dout_i          => main_reu_dout,
         reu_din_o           => main_reu_din,
         reu_we_i            => main_reu_we,
         reu_cs_i            => main_reu_cs,
         avm_write_o         => main_map_write,
         avm_read_o          => main_map_read,
         avm_address_o       => main_map_address,
         avm_writedata_o     => main_map_writedata,
         avm_byteenable_o    => main_map_byteenable,
         avm_burstcount_o    => main_map_burstcount,
         avm_readdata_i      => main_map_readdata,
         avm_readdatavalid_i => main_map_readdatavalid,
         avm_waitrequest_i   => main_map_waitrequest
      ); -- i_reu_mapper

   i_avm_cache : entity work.avm_cache
      generic map (
         G_CACHE_SIZE   => 8,
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         clk_i                 => main_clk,
         rst_i                 => main_reset_core_i,
         s_avm_waitrequest_o   => main_map_waitrequest,
         s_avm_write_i         => main_map_write,
         s_avm_read_i          => main_map_read,
         s_avm_address_i       => main_map_address,
         s_avm_writedata_i     => main_map_writedata,
         s_avm_byteenable_i    => main_map_byteenable,
         s_avm_burstcount_i    => main_map_burstcount,
         s_avm_readdata_o      => main_map_readdata,
         s_avm_readdatavalid_o => main_map_readdatavalid,
         m_avm_waitrequest_i   => main_avm_reu_waitrequest,
         m_avm_write_o         => main_avm_reu_write,
         m_avm_read_o          => main_avm_reu_read,
         m_avm_address_o       => main_avm_reu_address,
         m_avm_writedata_o     => main_avm_reu_writedata,
         m_avm_byteenable_o    => main_avm_reu_byteenable,
         m_avm_burstcount_o    => main_avm_reu_burstcount,
         m_avm_readdata_i      => main_avm_reu_readdata,
         m_avm_readdatavalid_i => main_avm_reu_readdatavalid
      ); -- i_avm_cache

   -- Multiplex the HyperRAM access between the REU and the Software Cartridge (CRT)
   hyperram_mux_proc : process (all)
   begin
      -- Default values to avoid latches
      main_avm_reu_waitrequest   <= '0';
      main_avm_reu_readdata      <= (others => '0');
      main_avm_reu_readdatavalid <= '0';

      main_avm_crt_waitrequest   <= '0';
      main_avm_crt_readdata      <= (others => '0');
      main_avm_crt_readdatavalid <= '0';

      main_avm_write_o           <= '0';
      main_avm_read_o            <= '0';
      main_avm_address_o         <= (others => '0');
      main_avm_writedata_o       <= (others => '0');
      main_avm_byteenable_o      <= (others => '0');
      main_avm_burstcount_o      <= (others => '0');

      case c64_exp_port_mode is
         when 0 =>
            -- Use the MEGA65's actual hardware slot
            null;

         when 1 =>
            -- Simulate a 1750 REU with 512KB
            main_avm_write_o           <= main_avm_reu_write;
            main_avm_read_o            <= main_avm_reu_read;
            main_avm_address_o         <= main_avm_reu_address;
            main_avm_writedata_o       <= main_avm_reu_writedata;
            main_avm_byteenable_o      <= main_avm_reu_byteenable;
            main_avm_burstcount_o      <= main_avm_reu_burstcount;
            main_avm_reu_waitrequest   <= main_avm_waitrequest_i;
            main_avm_reu_readdata      <= main_avm_readdata_i;
            main_avm_reu_readdatavalid <= main_avm_readdatavalid_i;

         when 2 =>
            -- Simulate a cartridge by using a cartridge from from the SD card (.crt file)
            main_avm_write_o           <= main_avm_crt_write;
            main_avm_read_o            <= main_avm_crt_read;
            main_avm_address_o         <= main_avm_crt_address;
            main_avm_writedata_o       <= main_avm_crt_writedata;
            main_avm_byteenable_o      <= main_avm_crt_byteenable;
            main_avm_burstcount_o      <= main_avm_crt_burstcount;
            main_avm_crt_waitrequest   <= main_avm_waitrequest_i;
            main_avm_crt_readdata      <= main_avm_readdata_i;
            main_avm_crt_readdatavalid <= main_avm_readdatavalid_i;

         when others =>
            null;
      end case;
   end process hyperram_mux_proc;

end architecture synthesis;

