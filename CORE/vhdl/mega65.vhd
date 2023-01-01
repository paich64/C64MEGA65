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
use work.globals.all;
use work.types_pkg.all;


library xpm;
use xpm.vcomponents.all;

entity MEGA65_Core is
port (
   CLK                     : in std_logic;         -- 100 MHz clock
   RESET_M2M_N             : in std_logic;         -- Debounced system reset in system clock domain

   -- Share clock and reset with the framework
   main_clk_o              : out std_logic;        -- CORE's 54 MHz clock
   main_rst_o              : out std_logic;        -- CORE's reset, synchronized

   --------------------------------------------------------------------------------------------------------
   -- QNICE Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- Get QNICE clock from the framework: for the vdrives as well as for RAMs and ROMs
   qnice_clk_i             : in std_logic;

   -- Video and audio mode control
   qnice_dvi_o             : out std_logic;              -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_video_mode_o      : out natural range 0 to 3;   -- HDMI 1280x720 @ 50 Hz resolution = mode 0, 1280x720 @ 60 Hz resolution = mode 1, PAL 576p in 4:3 and 5:4 are modes 2 and 3
   qnice_scandoubler_o     : out std_logic;              -- 0 = no scandoubler, 1 = scandoubler
   qnice_audio_mute_o      : out std_logic;
   qnice_audio_filter_o    : out std_logic;
   qnice_zoom_crop_o       : out std_logic;
   qnice_ascal_mode_o      : out std_logic_vector(1 downto 0);
   qnice_ascal_polyphase_o : out std_logic;
   qnice_ascal_triplebuf_o : out std_logic;

   -- Flip joystick ports
   qnice_flip_joyports_o   : out std_logic;

   -- On-Screen-Menu selections
   qnice_osm_control_i     : in std_logic_vector(255 downto 0);

   -- QNICE general purpose register
   qnice_gp_reg_i          : in std_logic_vector(255 downto 0);

   -- Core-specific devices
   qnice_dev_id_i          : in std_logic_vector(15 downto 0);
   qnice_dev_addr_i        : in std_logic_vector(27 downto 0);
   qnice_dev_data_i        : in std_logic_vector(15 downto 0);
   qnice_dev_data_o        : out std_logic_vector(15 downto 0);
   qnice_dev_ce_i          : in std_logic;
   qnice_dev_we_i          : in std_logic;

   --------------------------------------------------------------------------------------------------------
   -- Core Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- M2M's reset manager provides 2 signals:
   --    m2m:   Reset the whole machine: Core and Framework
   --    core:  Only reset the core
   main_reset_m2m_i        : in std_logic;
   main_reset_core_i       : in std_logic;

   main_pause_core_i       : in std_logic;

   -- Video output
   main_video_ce_o         : out std_logic;
   main_video_ce_2x_o      : out std_logic;
   main_video_red_o        : out std_logic_vector(7 downto 0);
   main_video_green_o      : out std_logic_vector(7 downto 0);
   main_video_blue_o       : out std_logic_vector(7 downto 0);
   main_video_vs_o         : out std_logic;
   main_video_hs_o         : out std_logic;
   main_video_hblank_o     : out std_logic;
   main_video_vblank_o     : out std_logic;

   -- Audio output (Signed PCM)
   main_audio_left_o       : out signed(15 downto 0);
   main_audio_right_o      : out signed(15 downto 0);

   -- M2M Keyboard interface (incl. drive led)
   main_kb_key_num_i       : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
   main_kb_key_pressed_n_i : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
   main_drive_led_o        : out std_logic;
   main_drive_led_col_o    : out std_logic_vector(23 downto 0);

   -- Joysticks input
   main_joy_1_up_n_i       : in std_logic;
   main_joy_1_down_n_i     : in std_logic;
   main_joy_1_left_n_i     : in std_logic;
   main_joy_1_right_n_i    : in std_logic;
   main_joy_1_fire_n_i     : in std_logic;

   main_joy_2_up_n_i       : in std_logic;
   main_joy_2_down_n_i     : in std_logic;
   main_joy_2_left_n_i     : in std_logic;
   main_joy_2_right_n_i    : in std_logic;
   main_joy_2_fire_n_i     : in std_logic;

   -- On-Screen-Menu selections
   main_osm_control_i     : in std_logic_vector(255 downto 0);
   
   -- QNICE general purpose register converted to main clock domain
   main_qnice_gp_reg_i    : in std_logic_vector(255 downto 0)
);
end entity MEGA65_Core;

architecture synthesis of MEGA65_Core is

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal main_clk               : std_logic;               -- Core main clock
signal main_rst               : std_logic;

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

-- RAMs for the C64
signal qnice_c64_ram_data           : std_logic_vector(7 downto 0);  -- C64's actual 64kB of RAM
signal qnice_c64_ram_we             : std_logic;
signal qnice_c64_mount_buf_ram_data : std_logic_vector(7 downto 0);  -- Disk mount buffer
signal qnice_c64_mount_buf_ram_we   : std_logic;

-- QNICE signals passed down to main.vhd to handle IEC drives using vdrives.vhd
signal qnice_c64_qnice_ce     : std_logic;
signal qnice_c64_qnice_we     : std_logic;
signal qnice_c64_qnice_data   : std_logic_vector(15 downto 0);

begin

   -- MMCME2_ADV clock generators
   --   C64 PAL: 31.528 MHz (main) and 63.056 MHz (video)
   --            HDMI: Flicker-free: 0.25% slower 
   clk_gen : entity work.clk
      port map (
         sys_clk_i         => CLK,             -- expects 100 MHz
         sys_rstn_i        => RESET_M2M_N,     -- Asynchronous, asserted low
         
         core_speed_i      => core_speed,      -- 0=PAL/original C64, 1=PAL/HDMI flicker-free, 2=NTSC
         
         main_clk_o        => main_clk,        -- CORE's 54 MHz clock
         main_rst_o        => main_rst         -- CORE's reset, synchronized
      ); -- clk_gen

   ---------------------------------------------------------------------------------------------
   -- Global switches for core speed and for switching between PAL and NTSC
   ---------------------------------------------------------------------------------------------

   c64_ntsc          <= '0'; -- @TODO: For now, we hardcode PAL mode

   -- needs to be in qnice clock domain
   core_speed        <= "01" when qnice_osm_control_i(C_MENU_HDMI_FF) else "00";

   -- needs to be in main clock domain
   c64_clock_speed   <= CORE_CLK_SPEED_PAL;

   ---------------------------------------------------------------------------------------------
   -- main_clk (C64 MiSTer Core clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual MiSTer core
   i_main : entity work.main
      generic map (
         G_VDNUM              => C_VDNUM
      )
      port map (
         clk_main_i           => main_clk,
         reset_soft_i         => main_reset_core_i,
         reset_hard_i         => main_reset_m2m_i,
         pause_i              => main_pause_core_i,

         -- global PAL/NTSC switch; c64_clock_speed depends on mode and needs to be very exact for avoiding clock drift
         c64_ntsc_i           => c64_ntsc,
         clk_main_speed_i     => c64_clock_speed,

         -- SID and CIA versions
         c64_sid_ver_i        => main_osm_control_i(C_MENU_8580) & main_osm_control_m(C_MENU_8580),
         c64_cia_ver_i        => main_osm_control_i(C_MENU_8521),

         -- M2M Keyboard interface
         kb_key_num_i         => main_kb_key_num_i,
         kb_key_pressed_n_i   => main_kb_key_pressed_n_i,

         -- MEGA65 joysticks
         joy_1_up_n_i         => main_joy_1_up_n_i ,
         joy_1_down_n_i       => main_joy_1_down_n_i,
         joy_1_left_n_i       => main_joy_1_left_n_i,
         joy_1_right_n_i      => main_joy_1_right_n_i,
         joy_1_fire_n_i       => main_joy_1_fire_n_i,

         joy_2_up_n_i         => main_joy_2_up_n_i,
         joy_2_down_n_i       => main_joy_2_down_n_i,
         joy_2_left_n_i       => main_joy_2_left_n_i,
         joy_2_right_n_i      => main_joy_2_right_n_i,
         joy_2_fire_n_i       => main_joy_2_fire_n_i,
         
         paddle_1_x           => main_pot1_x,
         paddle_1_y           => main_pot1_y,
         paddle_2_x           => main_pot2_x,
         paddle_2_y           => main_pot2_y,             
         
         -- Video output
         -- This is PAL 720x576 @ 50 Hz (pixel clock 27 MHz), but synchronized to main_clk (54 MHz).
         video_ce_o           => main_video_ce_o,
         video_ce_2x_o        => main_video_ce_2x_o,
         video_red_o          => main_video_red_o,
         video_green_o        => main_video_green_o,
         video_blue_o         => main_video_blue_o,
         video_vs_o           => main_video_vs_o,
         video_hs_o           => main_video_hs_o,
         video_hblank_o       => main_video_hblank_o,
         video_vblank_o       => main_video_vblank_o,

         -- Audio output (PCM format, signed values)
         audio_left_o         => main_audio_left_o,
         audio_right_o        => main_audio_right_o,
         
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
   qnice_dvi_o                <= '0';                                         -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_scandoubler_o        <= '0';                                         -- no scandoubler
   qnice_audio_mute_o         <= '0';                                         -- audio is not muted
   qnice_audio_filter_o       <= qnice_osm_control_i(C_MENU_IMPROVE_AUDIO);   -- 0 = raw audio, 1 = use filters from globals.vhd
   qnice_zoom_crop_o          <= qnice_osm_control_i(C_MENU_HDMI_ZOOM);       -- 0 = no zoom/crop

   -- ascal filters that are applied while zooming the input to 720p
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
   qnice_flip_joyports_o      <= '0';

   ---------------------------------------------------------------------------------------------
   -- Core specific device handling (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   core_specific_devices : process(all)
   begin
      -- make sure that this is x"EEEE" by default and avoid a register here by having this default value
      qnice_dev_data_o     <= x"EEEE";

      -- Demo core specific: Delete before starting to port your core
      qnice_demo_vd_ce     <= '0';
      qnice_demo_vd_we     <= '0';

      case qnice_dev_id_i is

         -- Demo core specific stuff: delete before porting your own core
         when C_DEV_DEMO_VD =>
            qnice_demo_vd_ce     <= qnice_dev_ce_i;
            qnice_demo_vd_we     <= qnice_dev_we_i;
            qnice_dev_data_o     <= qnice_demo_vd_data_o;

         -- @TODO YOUR RAMs or ROMs (e.g. for cartridges) or other devices here
         -- Device numbers need to be >= 0x0100

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



end architecture synthesis;
