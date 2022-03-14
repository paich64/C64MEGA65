----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- MEGA65 main file that contains the whole machine
--
-- based on C64_MiSTer by the MiSTer development team
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
   RESET_N        : in std_logic;                  -- CPU reset button

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

   -- SD Card
   SD_RESET       : out std_logic;
   SD_CLK         : out std_logic;
   SD_MOSI        : out std_logic;
   SD_MISO        : in std_logic;

   -- 3.5mm analog audio jack
   pwm_l          : out std_logic;
   pwm_r          : out std_logic;

   -- Joysticks
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
constant QNICE_FIRMWARE       : string  := "../../QNICE/monitor/monitor.rom";
--constant QNICE_FIRMWARE       : string  := "../../MEGA65/m2m-rom/m2m-rom.rom";

-- HDMI 1280x720 @ 50 Hz resolution
constant VIDEO_MODE           : video_modes_t := C_HDMI_720p_50;

-- C64 core clock speeds
-- Make sure that you specify very exact values here, because these values will be used in counters
-- in main.vhd and in fpga64_sid_iec.vhd to avoid clock drift at derived clocks
constant CORE_CLK_SPEED_PAL   : natural := 31_527_778;   -- C64 main clock in PAL mode @ 31,527,778 MHz
constant CORE_CLK_SPEED_NTSC  : natural := 32_727_264;   -- @TODO: This is MiSTer's value; we will need to adjust it to ours

-- QNICE clock speed
constant QNICE_CLK_SPEED      : natural := 50_000_000;   -- QNICE main clock @ 50 MHz

-- Rendering constants (in pixels)
--    VGA_*   size of the final output on the screen
--    FONT_*  size of one OSM character
constant VGA_DX               : natural := 658;
constant VGA_DY               : natural := 540;
constant FONT_DX              : natural := 16;
constant FONT_DY              : natural := 16;

-- Constants for the OSM screen memory
constant CHARS_DX             : natural := VGA_DX / FONT_DX;
constant CHARS_DY             : natural := VGA_DY / FONT_DY;
constant CHAR_MEM_SIZE        : natural := CHARS_DX * CHARS_DY;
constant VRAM_ADDR_WIDTH      : natural := f_log2(CHAR_MEM_SIZE);

-- Shell rendering constants (in characters)
-- The Shell uses the OSM mechanism to display itself
-- SHELL_M_* full screen menu and file browser
constant SHELL_M_X            : integer := 0;
constant SHELL_M_Y            : integer := 0;
constant SHELL_M_DX           : integer := CHARS_DX;
constant SHELL_M_DY           : integer := CHARS_DY;
-- SHELL_O_* (smaller) on-screen menu, overlayed on top of the cores video.
constant SHELL_O_X            : integer := CHARS_DX - 20;
constant SHELL_O_Y            : integer := 0;
constant SHELL_O_DX           : integer := 20;
constant SHELL_O_DY           : integer := 15;

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal qnice_clk              : std_logic;               -- QNICE main clock @ 50 MHz
signal hr_clk_x1              : std_logic;               -- HyperRAM @ 100 MHz
signal hr_clk_x2              : std_logic;               -- HyperRAM @ 200 MHz
signal hr_clk_x2_del          : std_logic;               -- HyperRAM @ 200 MHz phase delayed
signal tmds_clk               : std_logic;               -- HDMI pixel clock at 5x speed for TMDS @ 371.25 MHz
signal hdmi_clk               : std_logic;               -- HDMI pixel clock at normal speed @ 74.25 MHz
signal main_clk               : std_logic;               -- C64 main clock @ 31.528 MHz
signal video_clk              : std_logic;               -- Video clock @ 63.056 MHz

signal qnice_rst              : std_logic;
signal hr_rst                 : std_logic;
signal hdmi_rst               : std_logic;
signal main_rst               : std_logic;
signal video_rst              : std_logic;
signal reset_na               : std_logic;

---------------------------------------------------------------------------------------------
-- main_clk (MiSTer core's clock)
---------------------------------------------------------------------------------------------

signal c64_ntsc               : std_logic;                     -- global switch: 0 = PAL mode, 1 = NTSC mode
signal c64_clock_speed        : natural;                       -- clock speed depending on PAL/NTSC     

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

-- C64 RAM
signal main_ram_addr          : unsigned(15 downto 0);         -- C64 address bus
signal main_ram_data_from_c64 : unsigned(7 downto 0);          -- C64 RAM data out
signal main_ram_we            : std_logic;                     -- C64 RAM write enable
signal main_ram_data_to_c64   : std_logic_vector(7 downto 0);  -- C64 RAM data in

-- SID Audio
signal main_sid_l             : signed(15 downto 0);
signal main_sid_r             : signed(15 downto 0);

-- C64 Video output
signal video_vga_ce           : std_logic_vector(6 downto 0) := "1010100"; -- Clock divider 3/7
signal video_vga_red          : std_logic_vector(7 downto 0);
signal video_vga_green        : std_logic_vector(7 downto 0);
signal video_vga_blue         : std_logic_vector(7 downto 0);
signal video_vga_hs           : std_logic;
signal video_vga_vs           : std_logic;
signal video_vga_de           : std_logic;

-- On-Screen-Menu (OSM)
signal video_osm_cfg_enable   : std_logic;
signal video_osm_cfg_xy       : std_logic_vector(15 downto 0);
signal video_osm_cfg_dxdy     : std_logic_vector(15 downto 0);
signal video_osm_vram_addr    : std_logic_vector(15 downto 0);
signal video_osm_vram_data    : std_logic_vector(7 downto 0);
signal video_osm_vram_attr    : std_logic_vector(7 downto 0);
signal video_osm_red          : std_logic_vector(7 downto 0);
signal video_osm_green        : std_logic_vector(7 downto 0);
signal video_osm_blue         : std_logic_vector(7 downto 0);
signal video_osm_hs           : std_logic;
signal video_osm_vs           : std_logic;

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

-- m2m_keyb output for the firmware and the Shell; see also sysdef.asm
signal qnice_qnice_keys_n     : std_logic_vector(15 downto 0);

-- QNICE MMIO 4k-segmented access to RAMs, ROMs and similarily behaving devices
-- ramrom_dev_o: 0 = VRAM data, 1 = VRAM attributes, > 256 = free to be used for any "RAM like" device
-- ramrom_addr_o is 28-bit because we have a 16-bit window selector and a 4k window: 65536*4096 = 268.435.456 = 2^28
signal qnice_ramrom_dev       : std_logic_vector(15 downto 0);
signal qnice_ramrom_addr      : std_logic_vector(27 downto 0);
signal qnice_ramrom_data_o    : std_logic_vector(15 downto 0);
signal qnice_ramrom_data_i    : std_logic_vector(15 downto 0);
signal qnice_ramrom_ce        : std_logic;
signal qnice_ramrom_we        : std_logic;

-- VRAM
signal qnice_vram_we          : std_logic;
signal qnice_vram_data_o      : std_logic_vector(7 downto 0);
signal qnice_vram_attr_we     : std_logic;
signal qnice_vram_attr_data_o : std_logic_vector(7 downto 0);

-- Shell configuration (config.vhd)
signal qnice_config_data      : std_logic_vector(15 downto 0);

-- RAMs for the C64
signal qnice_c64_ram_data_o            : std_logic_vector(7 downto 0);  -- C64's actual 64kB of RAM
signal qnice_c64_ram_we                : std_logic;
signal qnice_c64_mount_buf_ram_data_o  : std_logic_vector(7 downto 0);  -- Disk mount buffer
signal qnice_c64_mount_buf_ram_we      : std_logic;

-- QNICE signals passed down to main.vhd to handle IEC drives using vdrives.vhd
signal qnice_c64_qnice_ce     : std_logic;
signal qnice_c64_qnice_we     : std_logic;
signal qnice_c64_qnice_data_o : std_logic_vector(15 downto 0);

---------------------------------------------------------------------------------------------
-- hdmi_clk (VGA pixelclock)
---------------------------------------------------------------------------------------------

signal hdmi_tmds              : slv_9_0_t(0 to 2);    -- parallel TMDS symbol stream x 3 channels

-- After video_rescaler
signal hdmi_scaled_red        : std_logic_vector(7 downto 0);
signal hdmi_scaled_green      : std_logic_vector(7 downto 0);
signal hdmi_scaled_blue       : std_logic_vector(7 downto 0);
signal hdmi_scaled_hs         : std_logic;
signal hdmi_scaled_vs         : std_logic;
signal hdmi_scaled_de         : std_logic;

begin

   -- MMCME2_ADV clock generators:
   --   QNICE:                50 MHz
   --   HyperRAM:             100 MHz
   --   HDMI 720p 50 Hz:      74.25 MHz (HDMI) and 371.25 MHz (TMDS)
   --   C64:                  31.528 MHz
   clk_gen : entity work.clk
      port map (
         sys_clk_i       => CLK,             -- expects 100 MHz
         sys_rstn_i      => RESET_N,         -- Asynchronous, asserted low

         qnice_clk_o     => qnice_clk,       -- QNICE's 50 MHz main clock
         qnice_rst_o     => qnice_rst,       -- QNICE's reset, synchronized

         hr_clk_x1_o     => hr_clk_x1,
         hr_clk_x2_o     => hr_clk_x2,
         hr_clk_x2_del_o => hr_clk_x2_del,
         hr_rst_o        => hr_rst,

         tmds_clk_o      => tmds_clk,        -- HDMI's 371.25 MHz pixelclock (74.25 MHz x 5) for TMDS
         hdmi_clk_o      => hdmi_clk,        -- HDMI's 74.25 MHz pixelclock for 720p @ 50 Hz
         hdmi_rst_o      => hdmi_rst,        -- HDMI's reset, synchronized

         main_clk_o      => main_clk,        -- main's 31.528 MHz clock
         main_rst_o      => main_rst,        -- main's reset, synchronized

         video_clk_o     => video_clk,       -- video's 63.056 MHz clock
         video_rst_o     => video_rst        -- video's reset, synchronized
      ); -- clk_gen

   ---------------------------------------------------------------------------------------------
   -- Global switch between PAL and NTSC
   ---------------------------------------------------------------------------------------------

   -- @TODO: For now, we hardcode PAL mode
   -- CAUTION: As soon as we change this to a dynamic behavior, we need to make sure
   -- that we are adding False Paths or something like that for keyscan_delay,
   -- repeat_start_timer and repeat_again_timer in matrix_to_keynum.vhdl and we also
   -- need to port these False Paths upstream into the XDC of the MiSTer2MEGA65 framework
   -- itself. Right now, Vivado is optimizing everything away, because we have a hard coded
   -- PAL mode: The frequencies are constantsand so the math can be done during synthesis.
   -- But as soon as this becomes dynamic, the calculations done for the
   -- above-mentioned signals will put a strain on our timing closure. Due to the fact
   -- that switching between PAL and NTSC does not happen very often, it is OK to accept
   -- that the calculations might take multiple cycles and therefore use a False Path or
   -- another measure in the XDC. 

   c64_ntsc <= '0'; -- @TODO: For now, we hardcode PAL mode
   c64_clock_speed <= CORE_CLK_SPEED_PAL when c64_ntsc = '0' else CORE_CLK_SPEED_NTSC;

   ---------------------------------------------------------------------------------------------
   -- main_clk (C64 MiSTer Core clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual Commodore 64 MiSTer core
   i_main : entity work.main
      port map (
         clk_main_i           => main_clk,
         clk_video_i          => video_clk,
         reset_i              => main_rst or main_qnice_reset,
         pause_i              => main_qnice_pause,
 
         -- global PAL/NTSC switch; c64_clock_speed depends on mode and needs to be very exact for avoiding clock drift
         c64_ntsc_i           => c64_ntsc,
         clk_main_speed_i     => c64_clock_speed,

         -- M2M Keyboard interface
         kb_key_num_i         => main_key_num,
         kb_key_pressed_n_i   => main_key_pressed_n,

         -- MEGA65 joysticks
         joy_1_up_n_i         => joy_1_up_n,
         joy_1_down_n_i       => joy_1_down_n,
         joy_1_left_n_i       => joy_1_left_n,
         joy_1_right_n_i      => joy_1_right_n,
         joy_1_fire_n_i       => joy_1_fire_n,

         joy_2_up_n_i         => joy_2_up_n,
         joy_2_down_n_i       => joy_2_down_n,
         joy_2_left_n_i       => joy_2_left_n,
         joy_2_right_n_i      => joy_2_right_n,
         joy_2_fire_n_i       => joy_2_fire_n,

         -- C64 video out (after scandoubler)
         -- This is PAL 720x576 @ 50 Hz (pixel clock 27 MHz), but synchronized to video_clk (63 MHz).
         vga_red_o            => video_vga_red,
         vga_green_o          => video_vga_green,
         vga_blue_o           => video_vga_blue,
         vga_vs_o             => video_vga_vs,
         vga_hs_o             => video_vga_hs,
         vga_de_o             => video_vga_de,

         -- C64 SID audio out: signed, see MiSTer's c64.sv
         sid_l                => main_sid_l,
         sid_r                => main_sid_r,

         -- C64 RAM
         c64_ram_addr_o       => main_ram_addr,
         c64_ram_data_o       => main_ram_data_from_c64,
         c64_ram_we_o         => main_ram_we,
         c64_ram_data_i       => unsigned(main_ram_data_to_c64),

         -- C64 IEC handled by QNICE
         c64_clk_sd_i         => qnice_clk,           -- "sd card write clock" for floppy drive internal dual clock RAM buffer
         c64_qnice_addr_i     => qnice_ramrom_addr,
         c64_qnice_data_i     => qnice_ramrom_data_o,
         c64_qnice_data_o     => qnice_c64_qnice_data_o,
         c64_qnice_ce_i       => qnice_c64_qnice_ce,
         c64_qnice_we_i       => qnice_c64_qnice_we
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

         -- interface to QNICE: used by the firmware and the Shell
         qnice_keys_n_o       => main_qnice_keys_n
      ); -- i_m2m_keyb

   -- Convert the C64's PCM output to pulse density modulation
   i_pcm2pdm : entity work.pcm_to_pdm
      port map
      (
         cpuclock                => main_clk,

         pcm_left                => main_sid_l,
         pcm_right               => main_sid_r,

         -- Pulse Density Modulation (PDM is supposed to sound better than PWM on MEGA65)
         pdm_left                => pwm_l,
         pdm_right               => pwm_r,
         audio_mode              => '0'         -- 0=PDM, 1=PWM
      ); -- i_pcm2pdm

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
         G_FONT_DY               => FONT_DY,
         G_SHELL_M_X             => SHELL_M_X,
         G_SHELL_M_Y             => SHELL_M_Y,
         G_SHELL_M_DX            => SHELL_M_DX,
         G_SHELL_M_DY            => SHELL_M_DY,
         G_SHELL_O_X             => SHELL_O_X,
         G_SHELL_O_Y             => SHELL_O_Y,
         G_SHELL_O_DX            => SHELL_O_DX,
         G_SHELL_O_DY            => SHELL_O_DY
      )
      port map (
         clk50_i                 => qnice_clk,
         reset_n_i               => not qnice_rst,

         -- serial communication (rxd, txd only; rts/cts are not available)
         -- 115.200 baud, 8-N-1
         uart_rxd_i              => UART_RXD,
         uart_txd_o              => UART_TXD,

         -- SD Card
         sd_reset_o              => SD_RESET,
         sd_clk_o                => SD_CLK,
         sd_mosi_o               => SD_MOSI,
         sd_miso_i               => SD_MISO,

         -- QNICE public registers
         csr_reset_o             => qnice_csr_reset,
         csr_pause_o             => qnice_csr_pause,
         csr_osm_o               => qnice_osm_cfg_enable,
         csr_keyboard_o          => qnice_csr_keyboard_on,
         csr_joy1_o              => qnice_csr_joy1_on,
         csr_joy2_o              => qnice_csr_joy2_on,
         osm_xy_o                => qnice_osm_cfg_xy,
         osm_dxdy_o              => qnice_osm_cfg_dxdy,

         -- Keyboard input for the firmware and Shell (see sysdef.asm)
         keys_n_i                => qnice_qnice_keys_n,

         -- 256-bit General purpose control flags
         -- "d" = directly controled by the firmware
         -- "m" = indirectly controled by the menu system
         control_d_o             => open,
         control_m_o             => open,

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
         -- bits 27 .. 12:    select configuration data block; called "Selector" hereafter
         -- bits 11 downto 0: address the up to 4k the configuration data
         address_i               => qnice_ramrom_addr,

         -- config data
         data_o                  => qnice_config_data
      ); -- shell_cfg

   -- The device selector qnice_ramrom_dev decides, which RAM/ROM-like device QNICE is writing to.
   -- Device numbers < 256 are reserved for QNICE; everything else can be used by your MiSTer core.
   qnice_ramrom_devices : process(all)
   variable strpos : integer;
   begin
      -- MiSTer2MEGA65 reserved
      qnice_vram_we        <= '0';
      qnice_vram_attr_we   <= '0';
      qnice_ramrom_data_i  <= x"EEEE";
      -- C64 specific
      qnice_c64_ram_we           <= '0';
      qnice_c64_qnice_ce         <= '0';
      qnice_c64_qnice_we         <= '0';
      qnice_c64_mount_buf_ram_we <= '0';

      case qnice_ramrom_dev is
         ----------------------------------------------------------------------------
         -- MiSTer2MEGA65 reserved devices
         -- OSM VRAM data and attributes with device numbers < 0x0100
         -- (refer to M2M/rom/sysdef.asm for a memory map and more details)
         ----------------------------------------------------------------------------
         when x"0000" =>
            qnice_vram_we              <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_vram_data_o;
         when x"0001" =>
            qnice_vram_attr_we         <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_vram_attr_data_o;

         -- Shell configuration data (config.vhd)
         when x"0002" =>
            qnice_ramrom_data_i        <= qnice_config_data;

         ----------------------------------------------------------------------------
         -- Commodore 64 specific devices
         ----------------------------------------------------------------------------

         -- C64 RAM
         when x"0100" =>
            qnice_c64_ram_we           <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_c64_ram_data_o;

         -- C64 IEC drives
         when x"0101" =>
            qnice_c64_qnice_ce         <= qnice_ramrom_ce;
            qnice_c64_qnice_we         <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= qnice_c64_qnice_data_o;

         -- Disk mount buffer RAM
         when x"0102" =>
            qnice_c64_mount_buf_ram_we <= qnice_ramrom_we;
            qnice_ramrom_data_i        <= x"00" & qnice_c64_mount_buf_ram_data_o;

         when others => null;
      end case;
   end process qnice_ramrom_devices;

   ---------------------------------------------------------------------------------------------
   -- video_clk (VGA output)
   ---------------------------------------------------------------------------------------------

   p_video_vga_ce : process (video_clk)
   begin
      if rising_edge(video_clk) then
         video_vga_ce <= video_vga_ce(0) & video_vga_ce(video_vga_ce'left downto 1);
      end if;
   end process p_video_vga_ce;

   i_video_overlay : entity work.video_overlay
      generic  map (
         G_VGA_DX         => VGA_DX,
         G_VGA_DY         => VGA_DY,
         G_FONT_DX        => FONT_DX,
         G_FONT_DY        => FONT_DY
      )
      port map (
         vga_clk_i        => video_clk,
         vga_ce_i         => video_vga_ce(0),
         vga_red_i        => video_vga_red,
         vga_green_i      => video_vga_green,
         vga_blue_i       => video_vga_blue,
         vga_hs_i         => video_vga_hs,
         vga_vs_i         => video_vga_vs,
         vga_de_i         => video_vga_de,
         vga_cfg_enable_i => video_osm_cfg_enable,
         vga_cfg_xy_i     => video_osm_cfg_xy,
         vga_cfg_dxdy_i   => video_osm_cfg_dxdy,
         vga_vram_addr_o  => video_osm_vram_addr,
         vga_vram_data_i  => video_osm_vram_data,
         vga_vram_attr_i  => video_osm_vram_attr,
         vga_ce_o         => open,
         vga_red_o        => video_osm_red,
         vga_green_o      => video_osm_green,
         vga_blue_o       => video_osm_blue,
         vga_hs_o         => video_osm_hs,
         vga_vs_o         => video_osm_vs,
         vga_de_o         => open
      ); -- i_video_overlay

   vga_red   <= video_osm_red;
   vga_green <= video_osm_green;
   vga_blue  <= video_osm_blue;
   vga_hs    <= video_osm_hs;
   vga_vs    <= video_osm_vs;

   -- Make the VDAC output the image
   vdac_sync_n  <= '0';
   vdac_blank_n <= '1';
   vdac_clk     <= not video_clk;

   ---------------------------------------------------------------------------------------------
   -- hdmi_clk
   ---------------------------------------------------------------------------------------------

   reset_na <= not (video_rst or hdmi_rst or hr_rst);

   i_video_rescaler : entity work.video_rescaler
      generic map (
         G_VIDEO_MODE => VIDEO_MODE
      )
      port map (
         reset_na_i      => reset_na,
         core_clk_i      => video_clk,
         core_ce_i       => video_vga_ce(0),
         core_r_i        => video_vga_red,
         core_g_i        => video_vga_green,
         core_b_i        => video_vga_blue,
         core_hs_i       => video_vga_hs,
         core_vs_i       => video_vga_vs,
         core_de_i       => video_vga_de,

         vga_clk_i       => hdmi_clk,
         vga_ce_i        => '1',
         vga_r_o         => hdmi_scaled_red,
         vga_g_o         => hdmi_scaled_green,
         vga_b_o         => hdmi_scaled_blue,
         vga_hs_o        => hdmi_scaled_hs,
         vga_vs_o        => hdmi_scaled_vs,
         vga_de_o        => hdmi_scaled_de,

         hr_clk_x1_i     => hr_clk_x1,
         hr_clk_x2_i     => hr_clk_x2,
         hr_clk_x2_del_i => hr_clk_x2_del,
         hr_rst_i        => hr_rst,
         hr_resetn       => hr_reset,
         hr_csn          => hr_cs0,
         hr_ck           => hr_clk_p,
         hr_rwds         => hr_rwds,
         hr_dq           => hr_d
      ); -- i_video_rescaler


   i_vga_to_hdmi : entity work.vga_to_hdmi
      port map (
         select_44100 => '0',
         dvi          => '0',                         -- DVI mode: if activated, HDMI extensions like sound are deactivated
         vic          => std_logic_vector(to_unsigned(VIDEO_MODE.CEA_CTA_VIC, 8)),  -- CEA/CTA VIC 17=PAL @ 50 Hz 4:3
         aspect       => VIDEO_MODE.ASPECT,           -- "01" which means 4:3 which fits for PAL
         pix_rep      => VIDEO_MODE.PIXEL_REP,        -- no pixel repetition for PAL
         vs_pol       => VIDEO_MODE.V_POL,            -- horizontal polarity: negative
         hs_pol       => VIDEO_MODE.H_POL,            -- vertaical polarity: negative

         vga_rst      => hdmi_rst,                    -- active high reset
         vga_clk      => hdmi_clk,                    -- VGA pixel clock
         vga_vs       => hdmi_scaled_vs,
         vga_hs       => hdmi_scaled_hs,
         vga_de       => hdmi_scaled_de,
         vga_r        => hdmi_scaled_red,
         vga_g        => hdmi_scaled_green,
         vga_b        => hdmi_scaled_blue,

         -- PCM audio
         pcm_rst      => main_rst,
         pcm_clk      => main_clk,
         pcm_clken    => '0',
         pcm_l        => (others => '0'),
         pcm_r        => (others => '0'),
         pcm_acr      => '0',
         pcm_n        => (others => '0'),
         pcm_cts      => (others => '0'),

         -- TMDS output (parallel)
         tmds         => hdmi_tmds
      ); -- i_vga_to_hdmi

   ---------------------------------------------------------------------------------------------
   -- tmds_clk (HDMI)
   ---------------------------------------------------------------------------------------------

   -- serialiser: in this design we use TMDS SelectIO outputs
   GEN_HDMI_DATA: for i in 0 to 2 generate
   begin
      I_HDMI_DATA: entity work.serialiser_10to1_selectio
      port map (
         rst     => hdmi_rst,
         clk     => hdmi_clk,
         clk_x5  => tmds_clk,
         d       => hdmi_tmds(i),
         out_p   => TMDS_data_p(i),
         out_n   => TMDS_data_n(i)
      ); -- I_HDMI_DATA: entity work.serialiser_10to1_selectio
   end generate GEN_HDMI_DATA;

   GEN_HDMI_CLK: entity work.serialiser_10to1_selectio
   port map (
         rst     => hdmi_rst,
         clk     => hdmi_clk,
         clk_x5  => tmds_clk,
         d       => "0000011111",
         out_p   => TMDS_clk_p,
         out_n   => TMDS_clk_n
      ); -- GEN_HDMI_CLK

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   -- IMPORTANT THING TO PONDER AROUND DUAL-CLOCK / DUAL-PORT DEVICES SUCH AS BRAMs:
   --
   -- We might want to make sure, that all dual port dual clock RAMs here that are interacting
   -- with QNICE are rising-edge only, so that we have 20ns time versus the 10ns that are
   -- available due to the "mixed mode" of QNICE needing falling-edge and other parts of
   -- M2M need rising-edge.
   --
   -- Example: gbc4mega65 Cartridge RAM, where we ran into timing closure problems due to this.
   -- Back then, this was solved by adjusting the FPGA speed grade to the right value (-2) and
   -- "luck" due to Vivado picking the right routing optimization strategy.
   --
   -- Possible solution that does not need QNICE changes: In the MMIO-MUX part, introduce
   -- a delay for QNICE when accessing anything via the "0x7000 device system" using the
   -- WAIT_FOR_DATA mechanism. Something like this untested/unproven sketech of code:
   --     process delay_cart_rom : process (clk50)
   --     begin
   --        if rising_edge(clk50) then
   --          if WAIT = '1' then
   --              WAIT <= '0';
   --         elsif gbc_cart_en = '1' then
   --              WAIT <= '1';
   --         end if;
   --     end process;
   -- When doing this, one needs to check QNICE's internal address bus timing to see, if
   -- gbc_cart_en is asserted long enough to still work after this delay. And if not,
   -- some mechanism to compensate for this needs to be found. And of course it might be
   -- that the above-mentioned code is "too slow" (setting WAIT one cycle too late). The
   -- whole thing needs some serious brain-power-investment to be solved.
   --
   -- Advantage: Will make the whole design more robust and less prone to timing closure problems.
   --
   -- Disadvantage: Slower QNICE access to "0x7000 devices"; but as it can be seen at the time
   -- of writing this, this should not be a problem because most of the tasks QNICE does outside
   -- SD card access for mounted floppies and other devices is not realtime and therefore not
   -- timing critical. If this changed, we might introduce "high-speed" devices that are using
   -- the falling-edge and that work without WAIT_FOR_DATA.

   -- Clock domain crossing: QNICE to C64
   i_qnice2main: xpm_cdc_array_single
      generic map (
         WIDTH => 5
      )
      port map (
         src_clk                => qnice_clk,
         src_in(0)              => qnice_csr_reset,
         src_in(1)              => qnice_csr_pause,
         src_in(2)              => qnice_csr_keyboard_on,
         src_in(3)              => qnice_csr_joy1_on,
         src_in(4)              => qnice_csr_joy2_on,
         dest_clk               => main_clk,
         dest_out(0)            => main_qnice_reset,
         dest_out(1)            => main_qnice_pause,
         dest_out(2)            => main_csr_keyboard_on,
         dest_out(3)            => main_csr_joy1_on,
         dest_out(4)            => main_csr_joy2_on
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

   -- Clock domain crossing: QNICE to QNICE-On-Screen-Display
   i_qnice2vga: xpm_cdc_array_single
      generic map (
         WIDTH => 33
      )
      port map (
         src_clk                => qnice_clk,
         src_in(15 downto 0)    => qnice_osm_cfg_xy,
         src_in(31 downto 16)   => qnice_osm_cfg_dxdy,
         src_in(32)             => qnice_osm_cfg_enable,
         dest_clk               => video_clk,
         dest_out(15 downto 0)  => video_osm_cfg_xy,
         dest_out(31 downto 16) => video_osm_cfg_dxdy,
         dest_out(32)           => video_osm_cfg_enable
      ); -- i_qnice2vga

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
         q_b               => qnice_c64_ram_data_o
      );

   -- For now: Let's use a simple BRAM (using only 1 port will make a BRAM) for buffering
   -- the disks that we are mounting. This will work for D64 only.
   -- @TODO: Switch to HyperRAM at a later stage
   mount_buf_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH        => 18,
         DATA_WIDTH        => 8,
         MAXIMUM_SIZE      => 174848,        -- size of standard D64
         FALLING_A         => true
      )
      port map (
         -- QNICE only
         clock_a           => qnice_clk,
         address_a         => qnice_ramrom_addr(17 downto 0),
         data_a            => qnice_ramrom_data_o(7 downto 0),
         wren_a            => qnice_c64_mount_buf_ram_we,
         q_a               => qnice_c64_mount_buf_ram_data_o
      );

   -- Dual port & dual clock screen RAM / video RAM: contains the "ASCII" codes of the characters
   osm_vram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH   => VRAM_ADDR_WIDTH,
         DATA_WIDTH   => 8,
         FALLING_A    => true              -- QNICE expects read/write to happen at the falling clock edge
      )
      port map (
         clock_a      => qnice_clk,
         address_a    => qnice_ramrom_addr(VRAM_ADDR_WIDTH-1 downto 0),
         data_a       => qnice_ramrom_data_o(7 downto 0),
         wren_a       => qnice_vram_we,
         q_a          => qnice_vram_data_o,

         clock_b      => video_clk,
         address_b    => video_osm_vram_addr(VRAM_ADDR_WIDTH-1 downto 0),
         q_b          => video_osm_vram_data
      ); -- osm_vram

   -- Dual port & dual clock attribute RAM: contains inverse attribute, light/dark attrib. and colors of the chars
   -- bit 7: 1=inverse
   -- bit 6: 1=dark, 0=bright
   -- bit 5: background red
   -- bit 4: background green
   -- bit 3: background blue
   -- bit 2: foreground red
   -- bit 1: foreground green
   -- bit 0: foreground blue
   osm_vram_attr : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH   => VRAM_ADDR_WIDTH,
         DATA_WIDTH   => 8,
         FALLING_A    => true
      )
      port map (
         clock_a      => qnice_clk,
         address_a    => qnice_ramrom_addr(VRAM_ADDR_WIDTH-1 downto 0),
         data_a       => qnice_ramrom_data_o(7 downto 0),
         wren_a       => qnice_vram_attr_we,
         q_a          => qnice_vram_attr_data_o,

         clock_b      => video_clk,
         address_b    => video_osm_vram_addr(VRAM_ADDR_WIDTH-1 downto 0),       -- same address as VRAM
         q_b          => video_osm_vram_attr
      ); -- osm_vram_attr

end architecture beh;
