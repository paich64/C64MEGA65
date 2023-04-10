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
   qnice_rst_i              : in  std_logic;

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
   -- These signals run in the HyperRAM clock domain (i.e. 100 MHz)
   --------------------------------------------------------------------------------------------------------

   hr_clk_i                 : in  std_logic;
   hr_rst_i                 : in  std_logic;
   hr_core_write_o          : out std_logic;
   hr_core_read_o           : out std_logic;
   hr_core_address_o        : out std_logic_vector(31 downto 0);
   hr_core_writedata_o      : out std_logic_vector(15 downto 0);
   hr_core_byteenable_o     : out std_logic_vector( 1 downto 0);
   hr_core_burstcount_o     : out std_logic_vector( 7 downto 0);
   hr_core_readdata_i       : in  std_logic_vector(15 downto 0);
   hr_core_readdatavalid_i  : in  std_logic;
   hr_core_waitrequest_i    : in  std_logic;

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
signal c64_exp_port_mode          : natural range 0 to 2;    -- Expansion Port:
                                                             -- 0: Use hardware
                                                             -- 1: Simulate REU
                                                             -- 2: Simulate cartridge (.CRT file)

-- C64 config settings
signal sid_setup                  : std_logic_vector(1 downto 0);
signal sid_port                   : natural range 0 to 4;

-- C64 RAM
signal main_ram_addr              : unsigned(15 downto 0);         -- C64 address bus
signal main_ram_data_from_c64     : unsigned(7 downto 0);          -- C64 RAM data out
signal main_ram_we                : std_logic;                     -- C64 RAM write enable
signal main_ram_data_to_c64       : std_logic_vector( 7 downto 0); -- C64 RAM data in
signal main_ram_data              : std_logic_vector( 7 downto 0);
signal main_crt_lo_ram_data       : std_logic_vector(15 downto 0);
signal main_crt_hi_ram_data       : std_logic_vector(15 downto 0);

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

signal main_crt_loading           : std_logic;
signal main_crt_id                : std_logic_vector(15 downto 0);
signal main_crt_exrom             : std_logic_vector( 7 downto 0);
signal main_crt_game              : std_logic_vector( 7 downto 0);
signal main_crt_bank_laddr        : std_logic_vector(15 downto 0);
signal main_crt_bank_size         : std_logic_vector(15 downto 0);
signal main_crt_bank_num          : std_logic_vector(15 downto 0);
signal main_crt_bank_type         : std_logic_vector( 7 downto 0);
signal main_crt_bank_raddr        : std_logic_vector(24 downto 0);
signal main_crt_bank_wr           : std_logic;

signal main_crt_bank_lo           : std_logic_vector( 6 downto 0);
signal main_crt_bank_hi           : std_logic_vector( 6 downto 0);
signal main_crt_roml_n            : std_logic;
signal main_crt_romh_n            : std_logic;

---------------------------------------------------------------------------------------------
-- hr_clk
---------------------------------------------------------------------------------------------

signal hr_reu_write               : std_logic;
signal hr_reu_read                : std_logic;
signal hr_reu_address             : std_logic_vector(31 downto 0);
signal hr_reu_writedata           : std_logic_vector(15 downto 0);
signal hr_reu_byteenable          : std_logic_vector( 1 downto 0);
signal hr_reu_burstcount          : std_logic_vector( 7 downto 0);
signal hr_reu_readdata            : std_logic_vector(15 downto 0);
signal hr_reu_readdatavalid       : std_logic;
signal hr_reu_waitrequest         : std_logic;

signal hr_c64_exp_port_mode       : std_logic_vector( 1 downto 0);

signal hr_crt_write               : std_logic;
signal hr_crt_read                : std_logic;
signal hr_crt_address             : std_logic_vector(31 downto 0);
signal hr_crt_writedata           : std_logic_vector(15 downto 0);
signal hr_crt_byteenable          : std_logic_vector( 1 downto 0);
signal hr_crt_burstcount          : std_logic_vector( 7 downto 0);
signal hr_crt_readdata            : std_logic_vector(15 downto 0);
signal hr_crt_readdatavalid       : std_logic;
signal hr_crt_waitrequest         : std_logic;


---------------------------------------------------------------------------------------------
-- qnice_clk
---------------------------------------------------------------------------------------------

-- OSM selections within qnice_osm_control_i
constant C_MENU_EXP_PORT_HW   : natural := 6;
constant C_MENU_EXP_PORT_REU  : natural := 7;
constant C_MENU_EXP_PORT_CRT  : natural := 8;
constant C_MENU_FLIP_JOYS     : natural := 13;
constant C_MENU_MONO_6581     : natural := 19;
constant C_MENU_MONO_8580     : natural := 20;
constant C_MENU_STEREO_L6R6   : natural := 24;
constant C_MENU_STEREO_L6R8   : natural := 25;
constant C_MENU_STEREO_L8R6   : natural := 26;
constant C_MENU_STEREO_L8R8   : natural := 27;
constant C_MENU_STEREO_R_D420 : natural := 31;
constant C_MENU_STEREO_R_D500 : natural := 32;
constant C_MENU_STEREO_R_DE00 : natural := 33;
constant C_MENU_STEREO_R_DF00 : natural := 34;
constant C_MENU_IMPROVE_AUDIO : natural := 37;
constant C_MENU_8521          : natural := 40;
constant C_MENU_HDMI_16_9_50  : natural := 47;
constant C_MENU_HDMI_16_9_60  : natural := 48;
constant C_MENU_HDMI_4_3_50   : natural := 49;
constant C_MENU_HDMI_5_4_50   : natural := 50;
constant C_MENU_CRT_EMULATION : natural := 53;
constant C_MENU_HDMI_ZOOM     : natural := 54;
constant C_MENU_HDMI_FF       : natural := 55;
constant C_MENU_HDMI_DVI      : natural := 56;
constant C_MENU_VGA_RETRO     : natural := 57;


-- RAMs for the C64
signal qnice_c64_ram_data           : std_logic_vector(7 downto 0);  -- C64's actual 64kB of RAM
signal qnice_c64_ram_we             : std_logic;
signal qnice_c64_mount_buf_ram_data : std_logic_vector(7 downto 0);  -- Disk mount buffer
signal qnice_c64_mount_buf_ram_we   : std_logic;

-- QNICE signals passed down to main.vhd to handle IEC drives using vdrives.vhd
signal qnice_c64_qnice_ce     : std_logic;
signal qnice_c64_qnice_we     : std_logic;
signal qnice_c64_qnice_data   : std_logic_vector(15 downto 0);

-- QNICE signals passed down to sw_cartridge_wrapper.vhd to handle CRT files
signal qnice_crt_qnice_ce     : std_logic;
signal qnice_crt_qnice_we     : std_logic;
signal qnice_crt_qnice_data   : std_logic_vector(15 downto 0);

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

   -- SID version, 0=6581, 1=8580, low bit = left SID                        
   sid_setup <= "00" when main_osm_control_i(C_MENU_MONO_6581)    else
                "11" when main_osm_control_i(C_MENU_MONO_8580)    else
                "00" when main_osm_control_i(C_MENU_STEREO_L6R6)  else
                "10" when main_osm_control_i(C_MENU_STEREO_L6R8)  else
                "01" when main_osm_control_i(C_MENU_STEREO_L8R6)  else
                "11" when main_osm_control_i(C_MENU_STEREO_L8R8)  else
                "00";

   -- Right SID Port: 0=same as left, 1=DE00, 2=D420, 3=D500, 4=DF00
   sid_port  <= 0 when main_osm_control_i(C_MENU_MONO_6581) or main_osm_control_i(C_MENU_MONO_8580) else
                1 when main_osm_control_i(C_MENU_STEREO_R_DE00) else
                2 when main_osm_control_i(C_MENU_STEREO_R_D420) else
                3 when main_osm_control_i(C_MENU_STEREO_R_D500) else
                4 when main_osm_control_i(C_MENU_STEREO_R_DF00) else
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
         c64_sid_ver_i          => sid_setup,
         c64_sid_port_i         => to_unsigned(sid_port, 3),
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
         cartridge_loading_i    => main_crt_loading,
         cartridge_id_i         => main_crt_id,
         cartridge_exrom_i      => main_crt_exrom,
         cartridge_game_i       => main_crt_game,
         cartridge_bank_laddr_i => main_crt_bank_laddr,
         cartridge_bank_size_i  => main_crt_bank_size,
         cartridge_bank_num_i   => main_crt_bank_num,
         cartridge_bank_type_i  => main_crt_bank_type,
         cartridge_bank_raddr_i => main_crt_bank_raddr,
         cartridge_bank_wr_i    => main_crt_bank_wr,
         crt_bank_lo_o          => main_crt_bank_lo,
         crt_bank_hi_o          => main_crt_bank_hi,
         crt_roml_n_o           => main_crt_roml_n,
         crt_romh_n_o           => main_crt_romh_n
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

         -- SW cartridges (*.CRT)
         when C_DEV_C64_CRT =>
            qnice_crt_qnice_ce         <= qnice_dev_ce_i;
            qnice_crt_qnice_we         <= qnice_dev_we_i;
            qnice_dev_data_o           <= qnice_crt_qnice_data;

         when others => null;
      end case;
   end process core_specific_devices;

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   --------------------------------------------
   -- Clock Domain Crossing: CORE -> HyperRAM
   --------------------------------------------

   i_cdc_main2hr : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 2
      )
      port map (
         src_clk_i              => main_clk,
         src_data_i(1 downto 0) => std_logic_vector(to_unsigned(c64_exp_port_mode, 2)),
         dst_clk_i              => hr_clk_i,
         dst_data_o(1 downto 0) => hr_c64_exp_port_mode
      ); -- i_cdc_main2hr

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

   -- Handle SW based cartridges, aka *.CRT files
   i_sw_cartridge_wrapper : entity work.sw_cartridge_wrapper
   generic map (
      G_BASE_ADDRESS => C_HMAP_CRT(9 downto 0) & X"000"
   )
   port map (
      qnice_clk_i          => qnice_clk_i,
      qnice_rst_i          => qnice_rst_i,
      qnice_addr_i         => qnice_dev_addr_i,
      qnice_data_i         => qnice_dev_data_i,
      qnice_ce_i           => qnice_crt_qnice_ce,
      qnice_we_i           => qnice_crt_qnice_we,
      qnice_data_o         => qnice_crt_qnice_data,
      main_clk_i           => main_clk,
      main_rst_i           => main_rst,
      main_loading_o       => main_crt_loading,
      main_id_o            => main_crt_id,
      main_exrom_o         => main_crt_exrom,
      main_game_o          => main_crt_game,
      main_bank_laddr_o    => main_crt_bank_laddr,
      main_bank_size_o     => main_crt_bank_size,
      main_bank_num_o      => main_crt_bank_num,
      main_bank_type_o     => main_crt_bank_type,
      main_bank_raddr_o    => main_crt_bank_raddr,
      main_bank_wr_o       => main_crt_bank_wr,
      main_bank_lo_i       => main_crt_bank_lo,
      main_bank_hi_i       => main_crt_bank_hi,
      main_ram_addr_i      => std_logic_vector(main_ram_addr),
      main_lo_ram_data_o   => main_crt_lo_ram_data,
      main_hi_ram_data_o   => main_crt_hi_ram_data,
      hr_clk_i             => hr_clk_i,
      hr_rst_i             => hr_rst_i,
      hr_write_o           => hr_crt_write,
      hr_read_o            => hr_crt_read,
      hr_address_o         => hr_crt_address,
      hr_writedata_o       => hr_crt_writedata,
      hr_byteenable_o      => hr_crt_byteenable,
      hr_burstcount_o      => hr_crt_burstcount,
      hr_readdata_i        => hr_crt_readdata,
      hr_readdatavalid_i   => hr_crt_readdatavalid,
      hr_waitrequest_i     => hr_crt_waitrequest
   ); -- i_sw_cartridge_wrapper

   main_ram_data_to_c64 <= main_crt_lo_ram_data(15 downto 8) when main_crt_roml_n = '0' and main_ram_addr(0) = '1' else
                           main_crt_lo_ram_data( 7 downto 0) when main_crt_roml_n = '0' and main_ram_addr(0) = '0' else
                           main_crt_hi_ram_data(15 downto 8) when main_crt_romh_n = '0' and main_ram_addr(0) = '1' else
                           main_crt_hi_ram_data( 7 downto 0) when main_crt_romh_n = '0' and main_ram_addr(0) = '0' else
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

   avm_fifo : entity work.avm_fifo
      generic map (
         G_WR_DEPTH     => 16,
         G_RD_DEPTH     => 16,
         G_FILL_SIZE    => 1,
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         s_clk_i               => main_clk,
         s_rst_i               => main_rst,
         s_avm_waitrequest_o   => main_avm_reu_waitrequest,
         s_avm_write_i         => main_avm_reu_write,
         s_avm_read_i          => main_avm_reu_read,
         s_avm_address_i       => main_avm_reu_address,
         s_avm_writedata_i     => main_avm_reu_writedata,
         s_avm_byteenable_i    => main_avm_reu_byteenable,
         s_avm_burstcount_i    => main_avm_reu_burstcount,
         s_avm_readdata_o      => main_avm_reu_readdata,
         s_avm_readdatavalid_o => main_avm_reu_readdatavalid,
         m_clk_i               => hr_clk_i,
         m_rst_i               => hr_rst_i,
         m_avm_waitrequest_i   => hr_reu_waitrequest,
         m_avm_write_o         => hr_reu_write,
         m_avm_read_o          => hr_reu_read,
         m_avm_address_o       => hr_reu_address,
         m_avm_writedata_o     => hr_reu_writedata,
         m_avm_byteenable_o    => hr_reu_byteenable,
         m_avm_burstcount_o    => hr_reu_burstcount,
         m_avm_readdata_i      => hr_reu_readdata,
         m_avm_readdatavalid_i => hr_reu_readdatavalid
      ); -- avm_fifo


   -- Multiplex the HyperRAM access between the REU and the Software Cartridge (CRT)
   hyperram_mux_proc : process (all)
   begin
      -- Default values to avoid latches
      hr_reu_waitrequest   <= '0';
      hr_reu_readdata      <= (others => '0');
      hr_reu_readdatavalid <= '0';

      hr_crt_waitrequest   <= '0';
      hr_crt_readdata      <= (others => '0');
      hr_crt_readdatavalid <= '0';

      hr_core_write_o      <= '0';
      hr_core_read_o       <= '0';
      hr_core_address_o    <= (others => '0');
      hr_core_writedata_o  <= (others => '0');
      hr_core_byteenable_o <= (others => '0');
      hr_core_burstcount_o <= (others => '0');

      case to_integer(unsigned(hr_c64_exp_port_mode)) is
         when 1 =>
            -- Simulate a 1750 REU with 512KB
            hr_core_write_o      <= hr_reu_write;
            hr_core_read_o       <= hr_reu_read;
            hr_core_address_o    <= hr_reu_address;
            hr_core_writedata_o  <= hr_reu_writedata;
            hr_core_byteenable_o <= hr_reu_byteenable;
            hr_core_burstcount_o <= hr_reu_burstcount;
            hr_reu_waitrequest   <= hr_core_waitrequest_i;
            hr_reu_readdata      <= hr_core_readdata_i;
            hr_reu_readdatavalid <= hr_core_readdatavalid_i;

         when others =>
            -- Simulate a cartridge by using a cartridge from the SD card (.CRT file)
            hr_core_write_o      <= hr_crt_write;
            hr_core_read_o       <= hr_crt_read;
            hr_core_address_o    <= hr_crt_address;
            hr_core_writedata_o  <= hr_crt_writedata;
            hr_core_byteenable_o <= hr_crt_byteenable;
            hr_core_burstcount_o <= hr_crt_burstcount;
            hr_crt_waitrequest   <= hr_core_waitrequest_i;
            hr_crt_readdata      <= hr_core_readdata_i;
            hr_crt_readdatavalid <= hr_core_readdatavalid_i;
      end case;
   end process hyperram_mux_proc;

end architecture synthesis;

