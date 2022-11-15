----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- MEGA65 main file that contains the whole machine
--
-- based on C64_MiSTer by the MiSTer development team
-- powered by MiSTer2MEGA65 done by sy2002 and MJoergen in 2022
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.qnice_tools.all;

library work;
use work.types_pkg.all;
use work.video_modes_pkg.all;

library xpm;
use xpm.vcomponents.all;

entity MEGA65_Core is
port (
   CLK            : in std_logic;                  -- 100 MHz clock

   -- M2M's reset manager provides 2 signals:
   --    RESET_M2M_N:   Reset the whole machine: Core and Framework
   --    RESET_CORE_N:  Only reset the core
   RESET_M2M_N    : in std_logic;
   RESET_CORE_N   : in std_logic;

   -- Serial communication (rxd, txd only; rts/cts are not available)
   -- 115.200 baud, 8-N-1
   UART_RXD       : in std_logic;                  -- receive data
   UART_TXD       : out std_logic;                 -- send data

   -- VGA
   VGA_RED        : out std_logic_vector(7 downto 0);
   VGA_GREEN      : out std_logic_vector(7 downto 0);
   VGA_BLUE       : out std_logic_vector(7 downto 0);
   VGA_HS         : out std_logic;
   VGA_VS         : out std_logic;

   -- VDAC
   vdac_clk       : out std_logic;
   vdac_sync_n    : out std_logic;
   vdac_blank_n   : out std_logic;

   -- Digital Video (HDMI)
   tmds_data_p    : out std_logic_vector(2 downto 0);
   tmds_data_n    : out std_logic_vector(2 downto 0);
   tmds_clk_p     : out std_logic;
   tmds_clk_n     : out std_logic;

   -- MEGA65 smart keyboard controller
   kb_io0         : out std_logic;                 -- clock to keyboard
   kb_io1         : out std_logic;                 -- data output to keyboard
   kb_io2         : in std_logic;                  -- data input from keyboard

   -- SD Card (internal on bottom)
   SD_RESET       : out std_logic;
   SD_CLK         : out std_logic;
   SD_MOSI        : out std_logic;
   SD_MISO        : in std_logic;
   SD_CD          : in std_logic;

   -- SD Card (external on back)
   SD2_RESET      : out std_logic;
   SD2_CLK        : out std_logic;
   SD2_MOSI       : out std_logic;
   SD2_MISO       : in std_logic;
   SD2_CD         : in std_logic;

   -- 3.5mm analog audio jack
   pwm_l          : out std_logic;
   pwm_r          : out std_logic;

   -- Joysticks and Paddles
   joy_1_up_n     : in std_logic;
   joy_1_down_n   : in std_logic;
   joy_1_left_n   : in std_logic;
   joy_1_right_n  : in std_logic;
   joy_1_fire_n   : in std_logic;

   joy_2_up_n     : in std_logic;
   joy_2_down_n   : in std_logic;
   joy_2_left_n   : in std_logic;
   joy_2_right_n  : in std_logic;
   joy_2_fire_n   : in std_logic;

   paddle         : in std_logic_vector(3 downto 0);
   paddle_drain   : out std_logic;

   -- Built-in HyperRAM
   hr_d           : inout std_logic_vector(7 downto 0);    -- Data/Address
   hr_rwds        : inout std_logic;               -- RW Data strobe
   hr_reset       : out std_logic;                 -- Active low RESET line to HyperRAM
   hr_clk_p       : out std_logic;
   hr_cs0         : out std_logic
);
end entity MEGA65_Core;

architecture beh of MEGA65_Core is

-- QNICE Firmware: Use the regular QNICE "operating system" called "Monitor" while developing
-- and debugging and use the MiSTer2MEGA65 firmware in the release version
--constant QNICE_FIRMWARE       : string  := "../../QNICE/monitor/monitor.rom";  -- debug/development
constant QNICE_FIRMWARE       : string  := "../../MEGA65/m2m-rom/m2m-rom.rom";   -- release

-- HDMI 1280x720 @ 50 Hz resolution = mode 0, 1280x720 @ 60 Hz resolution = mode 1, PAL 576p in 4:3 and 5:4 are modes 2 and 3
constant VIDEO_MODE_VECTOR    : video_modes_vector(0 to 3) := (C_HDMI_720p_50, C_HDMI_720p_60, C_HDMI_576p_50, C_HDMI_576p_50);

-- C64 core clock speeds
-- Make sure that you specify very exact values here, because these values will be used in counters
-- in main.vhd and in fpga64_sid_iec.vhd to avoid clock drift at derived clocks
constant CORE_CLK_SPEED_PAL      : natural := 31_527_778;   -- Will lead to a C64 clock of 985,243 Hz
constant CORE_CLK_SPEED_NTSC     : natural := 32_727_264;   -- @TODO: This is MiSTer's value; we will need to adjust it to ours

-- Rendering constants (in pixels)
--    VGA_*   size of the final output on the screen
--    FONT_*  size of one OSM character
constant VGA_DX               : natural := 720;
constant VGA_DY               : natural := 540;
constant FONT_FILE            : string  := "../font/Anikki-16x16-m2m.rom";
constant FONT_DX              : natural := 16;
constant FONT_DY              : natural := 16;

-- Constants for the OSM screen memory
constant CHARS_DX             : natural := VGA_DX / FONT_DX;
constant CHARS_DY             : natural := VGA_DY / FONT_DY;
constant CHAR_MEM_SIZE        : natural := CHARS_DX * CHARS_DY;
constant VRAM_ADDR_WIDTH      : natural := f_log2(CHAR_MEM_SIZE);

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal qnice_clk              : std_logic;               -- QNICE main clock @ 50 MHz
signal hr_clk_x1              : std_logic;               -- HyperRAM @ 100 MHz
signal hr_clk_x2              : std_logic;               -- HyperRAM @ 200 MHz
signal hr_clk_x2_del          : std_logic;               -- HyperRAM @ 200 MHz phase delayed
signal audio_clk              : std_logic;               -- Audio clock @ 60 MHz
signal tmds_clk               : std_logic;               -- HDMI pixel clock at 5x speed for TMDS @ 371.25 MHz
signal hdmi_clk               : std_logic;               -- HDMI pixel clock at normal speed @ 74.25 MHz

signal main_clk               : std_logic;
signal video_clk              : std_logic;

signal qnice_rst              : std_logic;
signal hr_rst                 : std_logic;
signal audio_rst              : std_logic;
signal hdmi_rst               : std_logic;
signal main_rst               : std_logic;
signal video_rst              : std_logic;

signal core_only_rst          : std_logic;               -- reset only the core, not the framework

---------------------------------------------------------------------------------------------
-- main_clk (MiSTer core's clock)
---------------------------------------------------------------------------------------------

signal core_speed             : unsigned(1 downto 0);    -- see clock.vhd for details
signal c64_ntsc               : std_logic;               -- global switch: 0 = PAL mode, 1 = NTSC mode
signal c64_clock_speed        : natural;                 -- clock speed depending on PAL/NTSC

-- QNICE control and status register
signal main_qnice_reset       : std_logic;
signal main_qnice_pause       : std_logic;
signal main_csr_keyboard_on   : std_logic;
signal main_csr_joy1_on       : std_logic;
signal main_csr_joy2_on       : std_logic;

-- keyboard handling
signal main_key_num           : integer range 0 to 79;
signal main_key_pressed_n     : std_logic;
signal main_qnice_keys_n      : std_logic_vector(15 downto 0);
signal main_drive_led         : std_logic;
signal main_drive_led_col     : std_logic_vector(23 downto 0);

-- C64 RAM
signal main_ram_addr          : unsigned(15 downto 0);         -- C64 address bus
signal main_ram_data_from_c64 : unsigned(7 downto 0);          -- C64 RAM data out
signal main_ram_we            : std_logic;                     -- C64 RAM write enable
signal main_ram_data_to_c64   : std_logic_vector(7 downto 0);  -- C64 RAM data in

-- RAM Expansion Unit
signal main_ext_cycle         : std_logic;
signal main_reu_cycle         : std_logic;
signal main_reu_addr          : std_logic_vector(24 downto 0);
signal main_reu_dout          : std_logic_vector(7 downto 0);
signal main_reu_din           : std_logic_vector(7 downto 0);
signal main_reu_we            : std_logic;
signal main_reu_cs            : std_logic;

signal main_avm_write         : std_logic;
signal main_avm_read          : std_logic;
signal main_avm_address       : std_logic_vector(31 downto 0) := (others => '0');
signal main_avm_writedata     : std_logic_vector(15 downto 0);
signal main_avm_byteenable    : std_logic_vector(1 downto 0);
signal main_avm_burstcount    : std_logic_vector(7 downto 0);
signal main_avm_readdata      : std_logic_vector(15 downto 0);
signal main_avm_readdatavalid : std_logic;
signal main_avm_waitrequest   : std_logic;

signal main_cache_write         : std_logic;
signal main_cache_read          : std_logic;
signal main_cache_address       : std_logic_vector(31 downto 0) := (others => '0');
signal main_cache_writedata     : std_logic_vector(15 downto 0);
signal main_cache_byteenable    : std_logic_vector(1 downto 0);
signal main_cache_burstcount    : std_logic_vector(7 downto 0);
signal main_cache_readdata      : std_logic_vector(15 downto 0);
signal main_cache_readdatavalid : std_logic;
signal main_cache_waitrequest   : std_logic;

-- QNICE On Screen Menu selections
signal main_osm_control_m     : std_logic_vector(255 downto 0);

-- SID Audio
signal main_sid_l             : signed(15 downto 0);
signal main_sid_r             : signed(15 downto 0);
signal filt_audio_l           : std_logic_vector(15 downto 0);
signal filt_audio_r           : std_logic_vector(15 downto 0);
signal audio_l                : std_logic_vector(15 downto 0);
signal audio_r                : std_logic_vector(15 downto 0);

-- C64 Video output
signal main_red               : std_logic_vector(7 downto 0);
signal main_green             : std_logic_vector(7 downto 0);
signal main_blue              : std_logic_vector(7 downto 0);
signal main_hs                : std_logic;
signal main_vs                : std_logic;
signal main_hblank            : std_logic;
signal main_vblank            : std_logic;
signal main_ce                : std_logic;

signal main_crop_ce           : std_logic;
signal main_crop_red          : std_logic_vector(7 downto 0);
signal main_crop_green        : std_logic_vector(7 downto 0);
signal main_crop_blue         : std_logic_vector(7 downto 0);
signal main_crop_hs           : std_logic;
signal main_crop_vs           : std_logic;
signal main_crop_hblank       : std_logic;
signal main_crop_vblank       : std_logic;

-- Joysticks
signal j1_up_n                : std_logic;
signal j1_down_n              : std_logic;
signal j1_left_n              : std_logic;
signal j1_right_n             : std_logic;
signal j1_fire_n              : std_logic;
signal j2_up_n                : std_logic;
signal j2_down_n              : std_logic;
signal j2_left_n              : std_logic;
signal j2_right_n             : std_logic;
signal j2_fire_n              : std_logic;

-- Paddles in 50 MHz clock domain which happens to be QNICE's
signal qnice_pot1_x           : unsigned(7 downto 0);
signal qnice_pot1_y           : unsigned(7 downto 0);
signal qnice_pot2_x           : unsigned(7 downto 0);
signal qnice_pot2_y           : unsigned(7 downto 0);

signal qnice_pot1_x_n         : unsigned(7 downto 0);
signal qnice_pot1_y_n         : unsigned(7 downto 0);
signal qnice_pot2_x_n         : unsigned(7 downto 0);
signal qnice_pot2_y_n         : unsigned(7 downto 0);

-- Paddles after CDC to C64's clock domain
signal main_pot1_x            : std_logic_vector(7 downto 0);
signal main_pot1_y            : std_logic_vector(7 downto 0);
signal main_pot2_x            : std_logic_vector(7 downto 0);
signal main_pot2_y            : std_logic_vector(7 downto 0);

-- On-Screen-Menu (OSM) for VGA
signal video_osm_cfg_enable   : std_logic;
signal video_osm_cfg_xy       : std_logic_vector(15 downto 0);
signal video_osm_cfg_dxdy     : std_logic_vector(15 downto 0);
signal video_osm_vram_addr    : std_logic_vector(15 downto 0);
signal video_osm_vram_data    : std_logic_vector(15 downto 0);

-- On-Screen-Menu (OSM) for HDMI
signal hdmi_osm_cfg_enable    : std_logic;
signal hdmi_osm_cfg_xy        : std_logic_vector(15 downto 0);
signal hdmi_osm_cfg_dxdy      : std_logic_vector(15 downto 0);
signal hdmi_osm_vram_addr     : std_logic_vector(15 downto 0);
signal hdmi_osm_vram_data     : std_logic_vector(15 downto 0);

-- QNICE On Screen Menu selections
signal hdmi_osm_control_m     : std_logic_vector(255 downto 0);

signal hdmi_video_mode        : natural range 0 to 3;

---------------------------------------------------------------------------------------------
-- qnice_clk
---------------------------------------------------------------------------------------------

-- Control and status register that QNICE uses to control the C64
signal qnice_csr_reset        : std_logic;
signal qnice_csr_pause        : std_logic;
signal qnice_csr_keyboard_on  : std_logic;
signal qnice_csr_joy1_on      : std_logic;
signal qnice_csr_joy2_on      : std_logic;

-- On-Screen-Menu (OSM)
signal qnice_osm_cfg_enable   : std_logic;
signal qnice_osm_cfg_xy       : std_logic_vector(15 downto 0);
signal qnice_osm_cfg_dxdy     : std_logic_vector(15 downto 0);

-- ascal.vhd mode register and polyphase filter handling
signal qnice_ascal_mode       : std_logic_vector(4 downto 0);
signal qnice_poly_wr          : std_logic;

-- m2m_keyb output for the firmware and the Shell; see also sysdef.asm
signal qnice_qnice_keys_n     : std_logic_vector(15 downto 0);

-- QNICE MMIO 4k-segmented access to RAMs, ROMs and similarily behaving devices
-- ramrom_addr is 28-bit because we have a 16-bit window selector and a 4k window: 65536*4096 = 268.435.456 = 2^28
signal qnice_ramrom_dev       : std_logic_vector(15 downto 0);
signal qnice_ramrom_addr      : std_logic_vector(27 downto 0);
signal qnice_ramrom_data_o    : std_logic_vector(15 downto 0);
signal qnice_ramrom_data_i    : std_logic_vector(15 downto 0);
signal qnice_ramrom_ce        : std_logic;
signal qnice_ramrom_we        : std_logic;

-- Devices: MiSTer2MEGA framework
constant C_DEV_VRAM_DATA      : std_logic_vector(15 downto 0) := x"0000";
constant C_DEV_VRAM_ATTR      : std_logic_vector(15 downto 0) := x"0001";
constant C_DEV_OSM_CONFIG     : std_logic_vector(15 downto 0) := x"0002";
constant C_DEV_ASCAL_PPHASE   : std_logic_vector(15 downto 0) := x"0003";
constant C_DEV_SYS_INFO       : std_logic_vector(15 downto 0) := x"00FF";
constant C_SYS_VGA            : std_logic_vector(15 downto 0) := x"0010";
constant C_SYS_HDMI           : std_logic_vector(15 downto 0) := x"0011";

-- Commodore 64 specific devices
constant C_DEV_C64_RAM        : std_logic_vector(15 downto 0) := x"0100";     -- C64's main RAM
constant C_DEV_C64_MOUNT      : std_logic_vector(15 downto 0) := x"0102";     -- RAM to buffer disk images

-- Virtual drive management system (handled by vdrives.vhd and the firmware)
-- If you are not using virtual drives, make sure that:
--    C_VDNUM        is 0
--    C_VD_DEVICE    is x"EEEE"
--    C_VD_BUFFER    is (x"EEEE", x"EEEE")
-- Otherwise make sure that you wire C_VD_DEVICE in the qnice_ramrom_devices process and that you
-- have as many appropriately sized RAM buffers for disk images as you have drives
type vd_buf_array is array(natural range <>) of std_logic_vector;
constant C_VDNUM              : natural := 1;                                 -- amount of virtual drives; if more than 5: also adjust VDRIVES_MAX in M2M/rom/shell_vars.asm, maximum is 15
constant C_VD_DEVICE          : std_logic_vector(15 downto 0) := x"0101";     -- device number of vdrives.vhd device
constant C_VD_BUFFER          : vd_buf_array := (C_DEV_C64_MOUNT, x"EEEE");   -- Finish the array using x"EEEE"

-- Sysinfo device for the two graphics adaptors that the firmware uses for the on-screen-display
signal sys_info_vga           : std_logic_vector(47 downto 0);
signal sys_info_hdmi          : std_logic_vector(47 downto 0);

-- VRAM
signal qnice_vram_data        : std_logic_vector(15 downto 0);
signal qnice_vram_we          : std_logic;   -- Writing to bits 7-0
signal qnice_vram_attr_we     : std_logic;   -- Writing to bits 15-8

-- Shell configuration (config.vhd)
signal qnice_config_data      : std_logic_vector(15 downto 0);

-- RAMs for the C64
signal qnice_c64_ram_data           : std_logic_vector(7 downto 0);  -- C64's actual 64kB of RAM
signal qnice_c64_ram_we             : std_logic;
signal qnice_c64_mount_buf_ram_data : std_logic_vector(7 downto 0);  -- Disk mount buffer
signal qnice_c64_mount_buf_ram_we   : std_logic;

-- QNICE signals passed down to main.vhd to handle IEC drives using vdrives.vhd
signal qnice_c64_qnice_ce     : std_logic;
signal qnice_c64_qnice_we     : std_logic;
signal qnice_c64_qnice_data   : std_logic_vector(15 downto 0);

-- QNICE On Screen Menu selections
signal qnice_osm_control_m    : std_logic_vector(255 downto 0);

constant C_MENU_FLIP_JOYS     : natural := 4;
constant C_MENU_8580          : natural := 9;
constant C_MENU_REU           : natural := 13;
constant C_MENU_CRT_EMULATION : natural := 14;
constant C_MENU_HDMI_ZOOM     : natural := 15;
constant C_MENU_HDMI_16_9_50  : natural := 16;
constant C_MENU_HDMI_16_9_60  : natural := 17;
constant C_MENU_HDMI_4_3_50   : natural := 18;  -- Caution: This naming convention is not self-explanatory,
constant C_MENU_HDMI_5_4_50   : natural := 19;  --          scroll down and search for "hdmi_video_mode <= " to learn more 
constant C_MENU_HDMI_FF       : natural := 20;
constant C_MENU_HDMI_DVI      : natural := 21;
constant C_MENU_VGA_RETRO     : natural := 22;
constant C_MENU_8521          : natural := 23;
constant C_MENU_IMPROVE_AUDIO : natural := 24;

-- HyperRAM
signal hr_dig_write         : std_logic;
signal hr_dig_read          : std_logic;
signal hr_dig_address       : std_logic_vector(31 downto 0) := (others => '0');
signal hr_dig_writedata     : std_logic_vector(15 downto 0);
signal hr_dig_byteenable    : std_logic_vector(1 downto 0);
signal hr_dig_burstcount    : std_logic_vector(7 downto 0);
signal hr_dig_readdata      : std_logic_vector(15 downto 0);
signal hr_dig_readdatavalid : std_logic;
signal hr_dig_waitrequest   : std_logic;

signal hr_reu_write         : std_logic;
signal hr_reu_read          : std_logic;
signal hr_reu_address       : std_logic_vector(31 downto 0) := (others => '0');
signal hr_reu_writedata     : std_logic_vector(15 downto 0);
signal hr_reu_byteenable    : std_logic_vector(1 downto 0);
signal hr_reu_burstcount    : std_logic_vector(7 downto 0);
signal hr_reu_readdata      : std_logic_vector(15 downto 0);
signal hr_reu_readdatavalid : std_logic;
signal hr_reu_waitrequest   : std_logic;

signal hr_write             : std_logic;
signal hr_read              : std_logic;
signal hr_address           : std_logic_vector(31 downto 0) := (others => '0');
signal hr_writedata         : std_logic_vector(15 downto 0);
signal hr_byteenable        : std_logic_vector(1 downto 0);
signal hr_burstcount        : std_logic_vector(7 downto 0);
signal hr_readdata          : std_logic_vector(15 downto 0);
signal hr_readdatavalid     : std_logic;
signal hr_waitrequest       : std_logic;

signal hr_rwds_in           : std_logic;
signal hr_rwds_out          : std_logic;
signal hr_rwds_oe           : std_logic;   -- Output enable for RWDS
signal hr_dq_in             : std_logic_vector(7 downto 0);
signal hr_dq_out            : std_logic_vector(7 downto 0);
signal hr_dq_oe             : std_logic;   -- Output enable for DQ

-- These values are copied from C64_MiSTerMEGA65/sys/sys_top.v
constant audio_flt_rate : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(7056000, 32));
constant audio_cx       : std_logic_vector(39 downto 0) := std_logic_vector(to_signed(4258969, 40));
constant audio_cx0      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(3, 8));
constant audio_cx1      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(2, 8));
constant audio_cx2      : std_logic_vector( 7 downto 0) := std_logic_vector(to_signed(1, 8));
constant audio_cy0      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed(-6216759, 24));
constant audio_cy1      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed( 6143386, 24));
constant audio_cy2      : std_logic_vector(23 downto 0) := std_logic_vector(to_signed(-2023767, 24));
constant audio_att      : std_logic_vector( 4 downto 0) := "00000";
constant audio_mix      : std_logic_vector( 1 downto 0) := "00"; -- 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

component audio_out
   generic (
      CLK_RATE : natural := 24576000
   );
   port (
      reset       : in  std_logic;
      clk         : in  std_logic;

      -- 0 - 48KHz, 1 - 96KHz
      sample_rate : in  std_logic;

      flt_rate    : in  std_logic_vector(31 downto 0);
      cx          : in  std_logic_vector(39 downto 0);
      cx0         : in  std_logic_vector( 7 downto 0);
      cx1         : in  std_logic_vector( 7 downto 0);
      cx2         : in  std_logic_vector( 7 downto 0);
      cy0         : in  std_logic_vector(23 downto 0);
      cy1         : in  std_logic_vector(23 downto 0);
      cy2         : in  std_logic_vector(23 downto 0);

      att         : in  std_logic_vector( 4 downto 0);
      mix         : in  std_logic_vector( 1 downto 0);

      is_signed   : in  std_logic;
      core_l      : in  std_logic_vector(15 downto 0);
      core_r      : in  std_logic_vector(15 downto 0);

      alsa_l      : in  std_logic_vector(15 downto 0);
      alsa_r      : in  std_logic_vector(15 downto 0);

      -- Signed output
      al          : out std_logic_vector(15 downto 0);
      ar          : out std_logic_vector(15 downto 0)
   );
end component audio_out;

begin

   -- MMCME2_ADV clock generators:
   --   QNICE:                50 MHz
   --   HyperRAM:             100 MHz and 200 MHz
   --   HDMI 720p 50 Hz:      74.25 MHz (HDMI) and 371.25 MHz (TMDS)
   --   C64:                  31.528 MHz (main) and 63.056 MHz (video)
   clk_gen : entity work.clk
      port map (
         sys_clk_i         => CLK,             -- expects 100 MHz
         sys_rstn_i        => RESET_M2M_N,     -- Asynchronous, asserted low

         qnice_clk_o       => qnice_clk,       -- QNICE's 50 MHz main clock
         qnice_rst_o       => qnice_rst,       -- QNICE's reset, synchronized

         hr_clk_x1_o       => hr_clk_x1,       -- HyperRAM's 100 MHz
         hr_clk_x2_o       => hr_clk_x2,       -- HyperRAM's 200 MHz
         hr_clk_x2_del_o   => hr_clk_x2_del,   -- HyperRAM's 200 MHz phase delayed
         hr_rst_o          => hr_rst,          -- HyperRAM's reset, synchronized

         audio_clk_o       => audio_clk,       -- Audio's 30 MHz
         audio_rst_o       => audio_rst,       -- Audio's reset, synchronized

         hdmi_clk_sel_i    => hdmi_osm_control_m(C_MENU_HDMI_4_3_50) or -- 0: 720p (74.25 MHz), 1: 576p (27.00 MHz)
                              hdmi_osm_control_m(C_MENU_HDMI_5_4_50),
         tmds_clk_o        => tmds_clk,        -- TMDS's pixelclock (5 * HDMI)
         hdmi_clk_o        => hdmi_clk,        -- HDMI's pixelclock
         hdmi_rst_o        => hdmi_rst,        -- HDMI's reset, synchronized

         core_speed_i      => core_speed,      -- 0=PAL/original C64, 1=PAL/HDMI flicker-fix, 2=NTSC

         main_clk_o        => main_clk,
         main_rst_o        => main_rst,

         video_clk_o       => video_clk,
         video_rst_o       => video_rst
      ); -- clk_gen

   ---------------------------------------------------------------------------------------------
   -- Global switches for core speed and for switching between PAL and NTSC
   ---------------------------------------------------------------------------------------------

   c64_ntsc          <= '0'; -- @TODO: For now, we hardcode PAL mode

   -- needs to be in qnice clock domain
   core_speed        <= "01" when qnice_osm_control_m(C_MENU_HDMI_FF) else "00";

   -- needs to be in main clock domain
   c64_clock_speed   <= CORE_CLK_SPEED_PAL;

   ---------------------------------------------------------------------------------------------
   -- main_clk (C64 MiSTer Core clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual Commodore 64 MiSTer core
   i_main : entity work.main
      generic map (
         G_VDNUM              => C_VDNUM
      )
      port map (
         clk_main_i           => main_clk,
         reset_soft_i         => core_only_rst,
         reset_hard_i         => main_rst or main_qnice_reset,
         pause_i              => main_qnice_pause,
         flip_joys_i          => main_osm_control_m(C_MENU_FLIP_JOYS),

         -- global PAL/NTSC switch; c64_clock_speed depends on mode and needs to be very exact for avoiding clock drift
         c64_ntsc_i           => c64_ntsc,
         clk_main_speed_i     => c64_clock_speed,

         -- SID and CIA versions
         c64_sid_ver_i        => main_osm_control_m(C_MENU_8580) & main_osm_control_m(C_MENU_8580),
         c64_cia_ver_i        => main_osm_control_m(C_MENU_8521),

         -- M2M Keyboard interface
         kb_key_num_i         => main_key_num,
         kb_key_pressed_n_i   => main_key_pressed_n,

         -- MEGA65 joysticks
         joy_1_up_n_i         => j1_up_n,
         joy_1_down_n_i       => j1_down_n,
         joy_1_left_n_i       => j1_left_n,
         joy_1_right_n_i      => j1_right_n,
         joy_1_fire_n_i       => j1_fire_n,

         joy_2_up_n_i         => j2_up_n,
         joy_2_down_n_i       => j2_down_n,
         joy_2_left_n_i       => j2_left_n,
         joy_2_right_n_i      => j2_right_n,
         joy_2_fire_n_i       => j2_fire_n,

         paddle_1_x           => main_pot1_x,
         paddle_1_y           => main_pot1_y,
         paddle_2_x           => main_pot2_x,
         paddle_2_y           => main_pot2_y,

         -- C64 video out
         vga_red_o            => main_red,
         vga_green_o          => main_green,
         vga_blue_o           => main_blue,
         vga_vs_o             => main_vs,
         vga_hs_o             => main_hs,
         vga_hblank_o         => main_hblank,
         vga_vblank_o         => main_vblank,
         vga_ce_o             => main_ce,

         -- C64 SID audio out: signed, see MiSTer's c64.sv
         sid_l                => main_sid_l,
         sid_r                => main_sid_r,

         -- C64 drive led
         drive_led_o          => main_drive_led,
         drive_led_col_o      => main_drive_led_col,

         -- C64 RAM
         c64_ram_addr_o       => main_ram_addr,
         c64_ram_data_o       => main_ram_data_from_c64,
         c64_ram_we_o         => main_ram_we,
         c64_ram_data_i       => unsigned(main_ram_data_to_c64),

         -- C64 IEC handled by QNICE
         c64_clk_sd_i         => qnice_clk,           -- "sd card write clock" for floppy drive internal dual clock RAM buffer
         c64_qnice_addr_i     => qnice_ramrom_addr,
         c64_qnice_data_i     => qnice_ramrom_data_o,
         c64_qnice_data_o     => qnice_c64_qnice_data,
         c64_qnice_ce_i       => qnice_c64_qnice_ce,
         c64_qnice_we_i       => qnice_c64_qnice_we,

         reu_cfg_i            => main_osm_control_m(C_MENU_REU),
         ext_cycle_o          => main_ext_cycle,
         reu_cycle_i          => main_reu_cycle,
         reu_addr_o           => main_reu_addr,
         reu_dout_o           => main_reu_dout,
         reu_din_i            => main_reu_din,
         reu_we_o             => main_reu_we,
         reu_cs_o             => main_reu_cs
      ); -- i_main

   -- M2M keyboard driver that outputs two distinct keyboard states: key_* for being used by the core and qnice_* for the firmware/Shell
   i_m2m_keyb : entity work.m2m_keyb
      port map (
         clk_main_i           => main_clk,
         clk_main_speed_i     => c64_clock_speed,

         -- interface to the MEGA65 keyboard controller
         kio8_o               => kb_io0,
         kio9_o               => kb_io1,
         kio10_i              => kb_io2,

         -- interface to the core
         enable_core_i        => main_csr_keyboard_on,
         key_num_o            => main_key_num,
         key_pressed_n_o      => main_key_pressed_n,

         -- control the drive led on the MEGA65 keyboard
         drive_led_i          => main_drive_led,
         drive_led_col_i      => main_drive_led_col,

         -- interface to QNICE: used by the firmware and the Shell
         qnice_keys_n_o       => main_qnice_keys_n
      ); -- i_m2m_keyb

   ---------------------------------------------------------------------------------------------
   -- qnice_clk
   ---------------------------------------------------------------------------------------------

   -- QNICE Co-Processor (System-on-a-Chip) for ROM loading and On-Screen-Menu
   QNICE_SOC : entity work.QNICE
      generic map (
         G_FIRMWARE              => QNICE_FIRMWARE,
         G_VGA_DX                => VGA_DX,
         G_VGA_DY                => VGA_DY,
         G_FONT_DX               => FONT_DX,
         G_FONT_DY               => FONT_DY
      )
      port map (
         clk50_i                 => qnice_clk,
         reset_n_i               => not qnice_rst,

         -- serial communication (rxd, txd only; rts/cts are not available)
         -- 115.200 baud, 8-N-1
         uart_rxd_i              => UART_RXD,
         uart_txd_o              => UART_TXD,

         -- SD Card (internal on bottom)
         sd_reset_o              => SD_RESET,
         sd_clk_o                => SD_CLK,
         sd_mosi_o               => SD_MOSI,
         sd_miso_i               => SD_MISO,
         sd_cd_i                 => SD_CD,

         -- SD Card (external on back)
         sd2_reset_o             => SD2_RESET,
         sd2_clk_o               => SD2_CLK,
         sd2_mosi_o              => SD2_MOSI,
         sd2_miso_i              => SD2_MISO,
         sd2_cd_i                => SD2_CD,

         -- QNICE public registers
         csr_reset_o             => qnice_csr_reset,
         csr_pause_o             => qnice_csr_pause,
         csr_osm_o               => qnice_osm_cfg_enable,
         csr_keyboard_o          => qnice_csr_keyboard_on,
         csr_joy1_o              => qnice_csr_joy1_on,
         csr_joy2_o              => qnice_csr_joy2_on,
         osm_xy_o                => qnice_osm_cfg_xy,
         osm_dxdy_o              => qnice_osm_cfg_dxdy,

         ascal_mode_i            => "00" & qnice_osm_control_m(C_MENU_CRT_EMULATION) & "00",
         ascal_mode_o            => qnice_ascal_mode,

         -- Keyboard input for the firmware and Shell (see sysdef.asm)
         keys_n_i                => qnice_qnice_keys_n,

         -- 256-bit General purpose control flags
         -- "d" = directly controled by the firmware
         -- "m" = indirectly controled by the menu system
         control_d_o             => open,
         control_m_o             => qnice_osm_control_m,

         -- 16-bit special-purpose and 16-bit general-purpose input flags
         -- Special-purpose flags are having a given semantic when the "Shell" firmware is running,
         -- but right now they are reserved and not used, yet.
         special_i               => (others => '0'),
         general_i               => (others => '0'),

         -- QNICE MMIO 4k-segmented access to RAMs, ROMs and similarily behaving devices
         -- ramrom_dev_o: 0 = VRAM data, 1 = VRAM attributes, > 256 = free to be used for any "RAM like" device
         -- ramrom_addr_o is 28-bit because we have a 16-bit window selector and a 4k window: 65536*4096 = 268.435.456 = 2^28
         ramrom_dev_o            => qnice_ramrom_dev,
         ramrom_addr_o           => qnice_ramrom_addr,
         ramrom_data_o           => qnice_ramrom_data_o,
         ramrom_data_i           => qnice_ramrom_data_i,
         ramrom_ce_o             => qnice_ramrom_ce,
         ramrom_we_o             => qnice_ramrom_we
      ); -- QNICE_SOC

   shell_cfg : entity work.config
      port map (
         clk_i                   => qnice_clk,

         -- bits 27 .. 12:    select configuration data block; called "Selector" hereafter
         -- bits 11 downto 0: address the up to 4k the configuration data
         address_i               => qnice_ramrom_addr,

         -- config data
         data_o                  => qnice_config_data
      ); -- shell_cfg

   -- The device selector qnice_ramrom_dev decides, which RAM/ROM-like device QNICE is writing to.
   -- Device numbers < 256 are reserved for QNICE; everything else can be used by your MiSTer core.
   qnice_ramrom_devices : process(all)
   begin
      -- MiSTer2MEGA65 reserved
      qnice_vram_we        <= '0';
      qnice_vram_attr_we   <= '0';
      qnice_ramrom_data_i  <= x"EEEE";
      qnice_poly_wr        <= '0';
      -- C64 specific
      qnice_c64_ram_we           <= '0';
      qnice_c64_qnice_ce         <= '0';
      qnice_c64_qnice_we         <= '0';
      qnice_c64_mount_buf_ram_we <= '0';

      case qnice_ramrom_dev is
         ----------------------------------------------------------------------------
         -- MiSTer2MEGA65 reserved devices with device numbers < 0x0100
         -- (refer to M2M/rom/sysdef.asm for a memory map and more details)
         ----------------------------------------------------------------------------

         -- On-Screen-Menu (OSM) video ram data and attributes
         when C_DEV_VRAM_DATA =>
            qnice_vram_we              <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_vram_data(7 downto 0);
         when C_DEV_VRAM_ATTR =>
            qnice_vram_attr_we         <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_vram_data(15 downto 8);

         -- Shell configuration data (config.vhd)
         when C_DEV_OSM_CONFIG =>
            qnice_ramrom_data_i        <= qnice_config_data;

         -- ascal.vhd's polyphase handling
         when C_DEV_ASCAL_PPHASE =>
            qnice_ramrom_data_i        <= x"EEEE"; -- write-only
            qnice_poly_wr              <= qnice_ramrom_we;

         -- Read-only System Info (constants are defined in sysdef.asm)
         when C_DEV_SYS_INFO =>
            case qnice_ramrom_addr(27 downto 12) is
               -- Virtual drives
               when x"0000" =>
                  case qnice_ramrom_addr(11 downto 0) is
                     when x"000" => qnice_ramrom_data_i <= std_logic_vector(to_unsigned(C_VDNUM, 16));
                     when x"001" => qnice_ramrom_data_i <= C_VD_DEVICE;

                     when others =>
                        if qnice_ramrom_addr(11 downto 4) = x"10" then
                           qnice_ramrom_data_i <= C_VD_BUFFER(to_integer(unsigned(qnice_ramrom_addr(3 downto 0))));
                        end if;

                  end case;

               -- Graphics card VGA
               when X"0010" =>
                  case qnice_ramrom_addr(11 downto 0) is
                     when X"000" => qnice_ramrom_data_i <= sys_info_vga(15 downto  0);
                     when X"001" => qnice_ramrom_data_i <= sys_info_vga(31 downto 16);
                     when X"002" => qnice_ramrom_data_i <= sys_info_vga(47 downto 32);
                     when others => null;
                  end case;

               -- Graphics card HDMI
               when X"0011" =>
                  case qnice_ramrom_addr(11 downto 0) is
                     when X"000" => qnice_ramrom_data_i <= sys_info_hdmi(15 downto  0);
                     when X"001" => qnice_ramrom_data_i <= sys_info_hdmi(31 downto 16);
                     when X"002" => qnice_ramrom_data_i <= sys_info_hdmi(47 downto 32);
                     when others => null;
                  end case;

               when others => null;
            end case;

         ----------------------------------------------------------------------------
         -- Commodore 64 specific devices
         ----------------------------------------------------------------------------

         -- C64 RAM
         when C_DEV_C64_RAM =>
            qnice_c64_ram_we           <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_c64_ram_data;

         -- C64 IEC drives
         when C_VD_DEVICE =>
            qnice_c64_qnice_ce         <= qnice_ramrom_ce;
            qnice_c64_qnice_we         <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= qnice_c64_qnice_data;

         -- Disk mount buffer RAM
         when C_DEV_C64_MOUNT =>
            qnice_c64_mount_buf_ram_we <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_c64_mount_buf_ram_data;

         when others => null;
      end case;
   end process qnice_ramrom_devices;

   -- Generate the paddle readings (mouse not supported, yet)
   -- Works with 50 MHz, which happens to be the QNICE clock domain
   i_mouse_paddles: entity work.mouse_input
      port map (
         clk                     => qnice_clk,

         mouse_debug             => open,
         amiga_mouse_enable_a    => '0',
         amiga_mouse_enable_b    => '0',
         amiga_mouse_assume_a    => '0',
         amiga_mouse_assume_b    => '0',

         -- These are the 1351 mouse / C64 paddle inputs and drain control
         fa_potx                 => paddle(0),
         fa_poty                 => paddle(1),
         fb_potx                 => paddle(2),
         fb_poty                 => paddle(3),
         pot_drain               => paddle_drain,

         -- To allow auto-detection of Amiga mouses, we need to know what the
         -- rest of the joystick pins are doing
         fa_fire                 => '1',
         fa_left                 => '1',
         fa_right                => '1',
         fa_up                   => '1',
         fa_down                 => '1',
         fb_fire                 => '1',
         fb_left                 => '1',
         fb_right                => '1',
         fb_up                   => '1',
         fb_down                 => '1',

         fa_up_out               => open,
         fa_down_out             => open,
         fa_left_out             => open,
         fa_right_out            => open,

         fb_up_out               => open,
         fb_down_out             => open,
         fb_left_out             => open,
         fb_right_out            => open,

         -- We output the four sampled pot values
         pota_x                  => qnice_pot1_x,
         pota_y                  => qnice_pot1_y,
         potb_x                  => qnice_pot2_x,
         potb_y                  => qnice_pot2_y
      );

   -- C64 games seem to expect an inverted signal compared to what we receive from i_mouse_paddles
   qnice_pot1_x_n <= x"FF" - qnice_pot1_x;
   qnice_pot1_y_n <= x"FF" - qnice_pot1_y;
   qnice_pot2_x_n <= x"FF" - qnice_pot2_x;
   qnice_pot2_y_n <= x"FF" - qnice_pot2_y;

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   i_reu_mapper : entity work.reu_mapper
      generic map (
         G_BASE_ADDRESS => X"0020_0000"  -- 2MW
      )
      port map (
         clk_i               => main_clk,
         rst_i               => main_rst,
         reu_ext_cycle_i     => main_ext_cycle,
         reu_ext_cycle_o     => main_reu_cycle,
         reu_addr_i          => main_reu_addr,
         reu_dout_i          => main_reu_dout,
         reu_din_o           => main_reu_din,
         reu_we_i            => main_reu_we,
         reu_cs_i            => main_reu_cs,
         avm_write_o         => main_avm_write,
         avm_read_o          => main_avm_read,
         avm_address_o       => main_avm_address,
         avm_writedata_o     => main_avm_writedata,
         avm_byteenable_o    => main_avm_byteenable,
         avm_burstcount_o    => main_avm_burstcount,
         avm_readdata_i      => main_avm_readdata,
         avm_readdatavalid_i => main_avm_readdatavalid,
         avm_waitrequest_i   => main_avm_waitrequest
      ); -- i_reu_mapper

   i_avm_cache : entity work.avm_cache
      generic map (
         G_CACHE_SIZE   => 8,
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         clk_i                 => main_clk,
         rst_i                 => main_rst,
         s_avm_waitrequest_o   => main_avm_waitrequest,
         s_avm_write_i         => main_avm_write,
         s_avm_read_i          => main_avm_read,
         s_avm_address_i       => main_avm_address,
         s_avm_writedata_i     => main_avm_writedata,
         s_avm_byteenable_i    => main_avm_byteenable,
         s_avm_burstcount_i    => main_avm_burstcount,
         s_avm_readdata_o      => main_avm_readdata,
         s_avm_readdatavalid_o => main_avm_readdatavalid,
         m_avm_waitrequest_i   => main_cache_waitrequest,
         m_avm_write_o         => main_cache_write,
         m_avm_read_o          => main_cache_read,
         m_avm_address_o       => main_cache_address,
         m_avm_writedata_o     => main_cache_writedata,
         m_avm_byteenable_o    => main_cache_byteenable,
         m_avm_burstcount_o    => main_cache_burstcount,
         m_avm_readdata_i      => main_cache_readdata,
         m_avm_readdatavalid_i => main_cache_readdatavalid
      ); -- i_avm_cache

   i_avm_fifo : entity work.avm_fifo
      generic map (
         G_DEPTH        => 16,
         G_FILL_SIZE    => 1,
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         s_clk_i               => main_clk,
         s_rst_i               => main_rst,
         s_avm_waitrequest_o   => main_cache_waitrequest,
         s_avm_write_i         => main_cache_write,
         s_avm_read_i          => main_cache_read,
         s_avm_address_i       => main_cache_address,
         s_avm_writedata_i     => main_cache_writedata,
         s_avm_byteenable_i    => main_cache_byteenable,
         s_avm_burstcount_i    => main_cache_burstcount,
         s_avm_readdata_o      => main_cache_readdata,
         s_avm_readdatavalid_o => main_cache_readdatavalid,
         m_clk_i               => hr_clk_x1,
         m_rst_i               => hr_rst,
         m_avm_waitrequest_i   => hr_reu_waitrequest,
         m_avm_write_o         => hr_reu_write,
         m_avm_read_o          => hr_reu_read,
         m_avm_address_o       => hr_reu_address,
         m_avm_writedata_o     => hr_reu_writedata,
         m_avm_byteenable_o    => hr_reu_byteenable,
         m_avm_burstcount_o    => hr_reu_burstcount,
         m_avm_readdata_i      => hr_reu_readdata,
         m_avm_readdatavalid_i => hr_reu_readdatavalid
      ); -- i_avm_fifo


   -- Clock domain crossing: 100 MHz system main clock to core
   i_system2main: xpm_cdc_array_single
      generic map (
         WIDTH => 11
      )
      port map (
         src_clk                => CLK,
         src_in(0)              => not RESET_CORE_N,
         src_in(1)              => joy_1_up_n,
         src_in(2)              => joy_1_down_n,
         src_in(3)              => joy_1_left_n,
         src_in(4)              => joy_1_right_n,
         src_in(5)              => joy_1_fire_n,
         src_in(6)              => joy_2_up_n,
         src_in(7)              => joy_2_down_n,
         src_in(8)              => joy_2_left_n,
         src_in(9)              => joy_2_right_n,
         src_in(10)             => joy_2_fire_n,
         dest_clk               => main_clk,
         dest_out(0)            => core_only_rst,
         dest_out(1)            => j1_up_n,
         dest_out(2)            => j1_down_n,
         dest_out(3)            => j1_left_n,
         dest_out(4)            => j1_right_n,
         dest_out(5)            => j1_fire_n,
         dest_out(6)            => j2_up_n,
         dest_out(7)            => j2_down_n,
         dest_out(8)            => j2_left_n,
         dest_out(9)            => j2_right_n,
         dest_out(10)           => j2_fire_n
      );

   -- Clock domain crossing: QNICE to C64
   i_qnice2main: xpm_cdc_array_single
      generic map (
         WIDTH => 293
      )
      port map (
         src_clk                    => qnice_clk,
         src_in(0)                  => qnice_csr_reset,
         src_in(1)                  => qnice_csr_pause,
         src_in(2)                  => qnice_csr_keyboard_on,
         src_in(3)                  => qnice_csr_joy1_on,
         src_in(4)                  => qnice_csr_joy2_on,
         src_in(260 downto 5)       => qnice_osm_control_m,
         src_in(268 downto 261)     => std_logic_vector(qnice_pot1_x_n),
         src_in(276 downto 269)     => std_logic_vector(qnice_pot1_y_n),
         src_in(284 downto 277)     => std_logic_vector(qnice_pot2_x_n),
         src_in(292 downto 285)     => std_logic_vector(qnice_pot2_y_n),
         dest_clk                   => main_clk,
         dest_out(0)                => main_qnice_reset,
         dest_out(1)                => main_qnice_pause,
         dest_out(2)                => main_csr_keyboard_on,
         dest_out(3)                => main_csr_joy1_on,
         dest_out(4)                => main_csr_joy2_on,
         dest_out(260 downto 5)     => main_osm_control_m,
         dest_out(268 downto 261)   => main_pot1_x,
         dest_out(276 downto 269)   => main_pot1_y,
         dest_out(284 downto 277)   => main_pot2_x,
         dest_out(292 downto 285)   => main_pot2_y
      ); -- i_qnice2main

   -- Clock domain crossing: C64 to QNICE
   i_main2qnice: xpm_cdc_array_single
      generic map (
         WIDTH => 16
      )
      port map (
         src_clk                => main_clk,
         src_in(15 downto 0)    => main_qnice_keys_n,
         dest_clk               => qnice_clk,
         dest_out(15 downto 0)  => qnice_qnice_keys_n
      ); -- i_main2qnice

   -- Clock domain crossing: QNICE to VGA QNICE-On-Screen-Display
   i_qnice2video: xpm_cdc_array_single
      generic map (
         WIDTH => 33
      )
      port map (
         src_clk                 => qnice_clk,
         src_in(15 downto 0)     => qnice_osm_cfg_xy,
         src_in(31 downto 16)    => qnice_osm_cfg_dxdy,
         src_in(32)              => qnice_osm_cfg_enable,
         dest_clk                => video_clk,
         dest_out(15 downto 0)   => video_osm_cfg_xy,
         dest_out(31 downto 16)  => video_osm_cfg_dxdy,
         dest_out(32)            => video_osm_cfg_enable
      ); -- i_qnice2video

   -- Clock domain crossing: QNICE to HDMI QNICE-On-Screen-Display
   i_qnice2hdmi: xpm_cdc_array_single
      generic map (
         WIDTH => 289
      )
      port map (
         src_clk                 => qnice_clk,
         src_in(15 downto 0)     => qnice_osm_cfg_xy,
         src_in(31 downto 16)    => qnice_osm_cfg_dxdy,
         src_in(32)              => qnice_osm_cfg_enable,
         src_in(288 downto 33)   => qnice_osm_control_m,
         dest_clk                => hdmi_clk,
         dest_out(15 downto 0)   => hdmi_osm_cfg_xy,
         dest_out(31 downto 16)  => hdmi_osm_cfg_dxdy,
         dest_out(32)            => hdmi_osm_cfg_enable,
         dest_out(288 downto 33) => hdmi_osm_control_m
      ); -- i_qnice2hdmi

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
         q_a               => main_ram_data_to_c64,

         -- QNICE
         clock_b           => qnice_clk,
         address_b         => qnice_ramrom_addr(15 downto 0),
         data_b            => qnice_ramrom_data_o(7 downto 0),
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
         clock_a           => qnice_clk,
         address_a         => qnice_ramrom_addr(17 downto 0),
         data_a            => qnice_ramrom_data_o(7 downto 0),
         wren_a            => qnice_c64_mount_buf_ram_we,
         q_a               => qnice_c64_mount_buf_ram_data
      ); -- mount_buf_ram

   -- QNICE-On-Screen-Display Video RAM for VGA output
   i_osm_vram_vga : entity work.dualport_2clk_ram_byteenable
      generic map (
         G_ADDR_WIDTH   => VRAM_ADDR_WIDTH,
         G_DATA_WIDTH   => 16,
         G_FALLING_A    => true  -- QNICE expects read/write to happen at the falling clock edge
      )
      port map
      (
         a_clk_i        => qnice_clk,
         a_address_i    => qnice_ramrom_addr(VRAM_ADDR_WIDTH-1 downto 0),
         a_data_i       => qnice_ramrom_data_o(7 downto 0) & qnice_ramrom_data_o(7 downto 0),   -- 2 copies of the same data
         a_wren_i       => qnice_vram_we or qnice_vram_attr_we,
         a_byteenable_i => qnice_vram_attr_we & qnice_vram_we,
         a_q_o          => qnice_vram_data,

         b_clk_i        => video_clk,
         b_address_i    => video_osm_vram_addr(VRAM_ADDR_WIDTH-1 downto 0),
         b_q_o          => video_osm_vram_data
      ); -- i_osm_vram_vga

   -- QNICE-On-Screen-Display Video RAM for HDMI output
   i_osm_vram_hdmi : entity work.dualport_2clk_ram_byteenable
      generic map (
         G_ADDR_WIDTH   => VRAM_ADDR_WIDTH,
         G_DATA_WIDTH   => 16,
         G_FALLING_A    => true  -- QNICE expects read/write to happen at the falling clock edge
      )
      port map
      (
         a_clk_i        => qnice_clk,
         a_address_i    => qnice_ramrom_addr(VRAM_ADDR_WIDTH-1 downto 0),
         a_data_i       => qnice_ramrom_data_o(7 downto 0) & qnice_ramrom_data_o(7 downto 0),   -- 2 copies of the same data
         a_wren_i       => qnice_vram_we or qnice_vram_attr_we,
         a_byteenable_i => qnice_vram_attr_we & qnice_vram_we,
         a_q_o          => open, -- TBD

         b_clk_i        => hdmi_clk,
         b_address_i    => hdmi_osm_vram_addr(VRAM_ADDR_WIDTH-1 downto 0),
         b_q_o          => hdmi_osm_vram_data
      ); -- i_osm_vram_hdmi

   --------------------------------------------------------
   -- Audio and Video processing pipeline
   --------------------------------------------------------

   i_audio_out : audio_out
      generic map (
         CLK_RATE => 30_000_000
      )
      port map (
         reset       => audio_rst,
         clk         => audio_clk,

         sample_rate => '0', -- 0 - 48KHz, 1 - 96KHz

         flt_rate    => audio_flt_rate,
         cx          => audio_cx,
         cx0         => audio_cx0,
         cx1         => audio_cx1,
         cx2         => audio_cx2,
         cy0         => audio_cy0,
         cy1         => audio_cy1,
         cy2         => audio_cy2,
         att         => audio_att,
         mix         => audio_mix,

         is_signed   => '1',
         core_l      => std_logic_vector(main_sid_l),
         core_r      => std_logic_vector(main_sid_r),

         alsa_l      => (others => '0'),
         alsa_r      => (others => '0'),

         -- Signed output
         al          => filt_audio_l,
         ar          => filt_audio_r
      ); -- i_audio_out

   audio_l <= filt_audio_l when qnice_osm_control_m(C_MENU_IMPROVE_AUDIO) = '1' else std_logic_vector(main_sid_l);
   audio_r <= filt_audio_r when qnice_osm_control_m(C_MENU_IMPROVE_AUDIO) = '1' else std_logic_vector(main_sid_r);

   i_analog_pipeline : entity work.analog_pipeline
      generic map (
         G_VGA_DX            => VGA_DX,
         G_VGA_DY            => VGA_DY,
         G_FONT_FILE         => FONT_FILE,
         G_FONT_DX           => FONT_DX,
         G_FONT_DY           => FONT_DY
      )
      port map (
         -- Input from Core (video and audio)
         video_clk_i              => video_clk,
         video_rst_i              => main_rst,
         video_ce_i               => main_ce,
         video_red_i              => main_red,
         video_green_i            => main_green,
         video_blue_i             => main_blue,
         video_hs_i               => main_hs,
         video_vs_i               => main_vs,
         video_hblank_i           => main_hblank,
         video_vblank_i           => main_vblank,
         audio_clk_i              => audio_clk, -- 30 MHz
         audio_rst_i              => audio_rst,
         audio_left_i             => signed(audio_l),
         audio_right_i            => signed(audio_r),

         -- Analog output (VGA and audio jack)
         vga_red_o                => vga_red,
         vga_green_o              => vga_green,
         vga_blue_o               => vga_blue,
         vga_hs_o                 => vga_hs,
         vga_vs_o                 => vga_vs,
         vdac_clk_o               => vdac_clk,
         vdac_syncn_o             => vdac_sync_n,
         vdac_blankn_o            => vdac_blank_n,
         pwm_l_o                  => pwm_l,
         pwm_r_o                  => pwm_r,

         -- Connect to QNICE and Video RAM
         video_osm_cfg_enable_i   => video_osm_cfg_enable,
         video_osm_cfg_xy_i       => video_osm_cfg_xy,
         video_osm_cfg_dxdy_i     => video_osm_cfg_dxdy,
         video_osm_vram_addr_o    => video_osm_vram_addr,
         video_osm_vram_data_i    => video_osm_vram_data,
         scandoubler_i            => not main_osm_control_m(C_MENU_VGA_RETRO),

         -- System info device
         sys_info_vga_o           => sys_info_vga
      ); -- i_analog_pipeline

   i_crop : entity work.crop
      port map (
         video_crop_mode_i => main_osm_control_m(C_MENU_HDMI_ZOOM),
         video_clk_i       => main_clk,
         video_rst_i       => main_rst,
         video_ce_i        => main_ce,
         video_red_i       => main_red,
         video_green_i     => main_green,
         video_blue_i      => main_blue,
         video_hs_i        => main_hs,
         video_vs_i        => main_vs,
         video_hblank_i    => main_hblank,
         video_vblank_i    => main_vblank,
         video_ce_o        => main_crop_ce,
         video_red_o       => main_crop_red,
         video_green_o     => main_crop_green,
         video_blue_o      => main_crop_blue,
         video_hs_o        => main_crop_hs,
         video_vs_o        => main_crop_vs,
         video_hblank_o    => main_crop_hblank,
         video_vblank_o    => main_crop_vblank
      ); -- i_crop


   -- As of Version 4 of the core:
   -- Due to a discussion on the MEGA65 discord (https://discord.com/channels/719326990221574164/794775503818588200/1039457688020586507)
   -- we decided to choose a naming convention for the PAL modes that might be more intuitive for the end users than it is
   -- for the programmers: "4:3" means "meant to be run on a 4:3 monitor", "5:4 on a 5:4 monitor".
   -- The technical reality is though, that in our "5:4" mode we are actually doing a 4/3 aspect ratio adjustment
   -- while in the 4:3 mode we are outputting a 5:4 image. This is kind of odd, but it seemed that our 4/3 aspect ratio
   -- adjusted image looks best on a 5:4 monitor and the other way round.
   -- Not sure if this will stay forever or if we will come up with a better naming convention.
   hdmi_video_mode <= 3 when hdmi_osm_control_m(C_MENU_HDMI_5_4_50)  = '1' else
                      2 when hdmi_osm_control_m(C_MENU_HDMI_4_3_50)  = '1' else
                      1 when hdmi_osm_control_m(C_MENU_HDMI_16_9_60) = '1' else
                      0;

   i_digital_pipeline : entity work.digital_pipeline
      generic map (
         G_VIDEO_MODE_VECTOR => VIDEO_MODE_VECTOR,
         G_VGA_DX            => VGA_DX,
         G_VGA_DY            => VGA_DY,
         G_FONT_FILE         => FONT_FILE,
         G_FONT_DX           => FONT_DX,
         G_FONT_DY           => FONT_DY
      )
      port map (
         -- Input from Core (video and audio)
         video_clk_i              => main_clk,
         video_rst_i              => main_rst,
         video_ce_i               => main_crop_ce,
         video_red_i              => main_crop_red,
         video_green_i            => main_crop_green,
         video_blue_i             => main_crop_blue,
         video_hs_i               => main_crop_hs,
         video_vs_i               => main_crop_vs,
         video_hblank_i           => main_crop_hblank,
         video_vblank_i           => main_crop_vblank,
         audio_clk_i              => audio_clk, -- 30 MHz
         audio_rst_i              => audio_rst,
         audio_left_i             => signed(audio_l),
         audio_right_i            => signed(audio_r),

         -- Digital output (HDMI)
         hdmi_clk_i               => hdmi_clk,
         hdmi_rst_i               => hdmi_rst,
         tmds_clk_i               => tmds_clk,
         tmds_data_p_o            => tmds_data_p,
         tmds_data_n_o            => tmds_data_n,
         tmds_clk_p_o             => tmds_clk_p,
         tmds_clk_n_o             => tmds_clk_n,

         -- Connect to QNICE and Video RAM
         hdmi_dvi_i               => hdmi_osm_control_m(C_MENU_HDMI_DVI),
         hdmi_video_mode_i        => hdmi_video_mode,
         hdmi_crop_mode_i         => main_osm_control_m(C_MENU_HDMI_ZOOM),
         hdmi_osm_cfg_enable_i    => hdmi_osm_cfg_enable,
         hdmi_osm_cfg_xy_i        => hdmi_osm_cfg_xy,
         hdmi_osm_cfg_dxdy_i      => hdmi_osm_cfg_dxdy,
         hdmi_osm_vram_addr_o     => hdmi_osm_vram_addr,
         hdmi_osm_vram_data_i     => hdmi_osm_vram_data,

         -- System info device
         sys_info_hdmi_o          => sys_info_hdmi,

         -- QNICE connection to ascal's mode register
         qnice_ascal_mode_i       => unsigned(qnice_ascal_mode),

         -- QNICE device for interacting with the Polyphase filter coefficients
         qnice_poly_clk_i         => qnice_clk,
         qnice_poly_dw_i          => unsigned(qnice_ramrom_data_o(9 downto 0)),
         qnice_poly_a_i           => unsigned(qnice_ramrom_addr(6+3 downto 0)),
         qnice_poly_wr_i          => qnice_poly_wr,

         -- Connect to HyperRAM controller
         hr_clk_i                 => hr_clk_x1,
         hr_rst_i                 => hr_rst,
         hr_write_o               => hr_dig_write,
         hr_read_o                => hr_dig_read,
         hr_address_o             => hr_dig_address,
         hr_writedata_o           => hr_dig_writedata,
         hr_byteenable_o          => hr_dig_byteenable,
         hr_burstcount_o          => hr_dig_burstcount,
         hr_readdata_i            => hr_dig_readdata,
         hr_readdatavalid_i       => hr_dig_readdatavalid,
         hr_waitrequest_i         => hr_dig_waitrequest
      ); -- i_digital_pipeline

   --------------------------------------------------------
   -- Instantiate HyperRAM arbiter
   --------------------------------------------------------

   i_avm_arbit : entity work.avm_arbit
      generic map (
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         clk_i                  => hr_clk_x1,
         rst_i                  => hr_rst,
         s0_avm_write_i         => hr_dig_write,
         s0_avm_read_i          => hr_dig_read,
         s0_avm_address_i       => hr_dig_address,
         s0_avm_writedata_i     => hr_dig_writedata,
         s0_avm_byteenable_i    => hr_dig_byteenable,
         s0_avm_burstcount_i    => hr_dig_burstcount,
         s0_avm_readdata_o      => hr_dig_readdata,
         s0_avm_readdatavalid_o => hr_dig_readdatavalid,
         s0_avm_waitrequest_o   => hr_dig_waitrequest,
         s1_avm_write_i         => hr_reu_write,
         s1_avm_read_i          => hr_reu_read,
         s1_avm_address_i       => hr_reu_address,
         s1_avm_writedata_i     => hr_reu_writedata,
         s1_avm_byteenable_i    => hr_reu_byteenable,
         s1_avm_burstcount_i    => hr_reu_burstcount,
         s1_avm_readdata_o      => hr_reu_readdata,
         s1_avm_readdatavalid_o => hr_reu_readdatavalid,
         s1_avm_waitrequest_o   => hr_reu_waitrequest,
         m_avm_write_o          => hr_write,
         m_avm_read_o           => hr_read,
         m_avm_address_o        => hr_address,
         m_avm_writedata_o      => hr_writedata,
         m_avm_byteenable_o     => hr_byteenable,
         m_avm_burstcount_o     => hr_burstcount,
         m_avm_readdata_i       => hr_readdata,
         m_avm_readdatavalid_i  => hr_readdatavalid,
         m_avm_waitrequest_i    => hr_waitrequest
      ); -- i_avm_arbit

   --------------------------------------------------------
   -- Instantiate HyperRAM controller
   --------------------------------------------------------

   i_hyperram : entity work.hyperram
      port map (
         clk_x1_i            => hr_clk_x1,
         clk_x2_i            => hr_clk_x2,
         clk_x2_del_i        => hr_clk_x2_del,
         rst_i               => hr_rst,
         avm_write_i         => hr_write,
         avm_read_i          => hr_read,
         avm_address_i       => hr_address,
         avm_writedata_i     => hr_writedata,
         avm_byteenable_i    => hr_byteenable,
         avm_burstcount_i    => hr_burstcount,
         avm_readdata_o      => hr_readdata,
         avm_readdatavalid_o => hr_readdatavalid,
         avm_waitrequest_o   => hr_waitrequest,
         hr_resetn_o         => hr_reset,
         hr_csn_o            => hr_cs0,
         hr_ck_o             => hr_clk_p,
         hr_rwds_in_i        => hr_rwds_in,
         hr_rwds_out_o       => hr_rwds_out,
         hr_rwds_oe_o        => hr_rwds_oe,
         hr_dq_in_i          => hr_dq_in,
         hr_dq_out_o         => hr_dq_out,
         hr_dq_oe_o          => hr_dq_oe
      ); -- i_hyperram

   -- Tri-state buffers for HyperRAM
   hr_rwds    <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
   hr_d       <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');
   hr_rwds_in <= hr_rwds;
   hr_dq_in   <= hr_d;

end architecture beh;

