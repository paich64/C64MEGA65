----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2023 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library work;
use work.vdrives_pkg.all;

entity main is
   generic (
      G_VDNUM                : natural                     -- amount of virtual drives
   );
   port (
      clk_main_i             : in  std_logic;
      reset_soft_i           : in  std_logic;              -- Pulse once for a soft reset
      reset_hard_i           : in  std_logic;              -- Pulse once for a hard reset
      pause_i                : in  std_logic;              -- Pull high to pause the core

      -- Trigger the sequence RUN<Return> to autostart PRG files
      trigger_run_i          : in  std_logic;

      ---------------------------
      -- Configuration options
      ---------------------------

      -- Video mode selection:
      -- c64_ntsc_i: PAL/NTSC switch
      -- clk_main_speed_i: The core's clock speed depends on mode and needs to be very exact for avoiding clock drift
      -- video_retro15kHz_i: Analog video output configuration: Horizontal sync frequency: '0'=30 kHz ("normal" on "modern" analog monitors), '1'=retro 15 kHz
      c64_ntsc_i             : in  std_logic;               -- 0 = PAL mode, 1 = NTSC mode, clocks need to be correctly set, too
      clk_main_speed_i       : in  natural;
      video_retro15kHz_i     : in  std_logic;

      -- SID and CIA versions
      c64_sid_ver_i          : in  std_logic_vector(1 downto 0); -- SID version, 0=6581, 1=8580, low bit = left SID
      c64_sid_port_i         : in  unsigned(2 downto 0);    -- Right SID Port: 0=same as left, 1=DE00, 2=D420, 3=D500, 4=DF00
      c64_cia_ver_i          : in  std_logic;               -- CIA version: 0=6526 "old", 1=8521 "new"

      -- Mode selection for Expansion Port (aka Cartridge Port):
      -- 0: Use the MEGA65's actual hardware slot
      -- 1: Simulate a 1750 REU with 512KB
      -- 2: Simulate a cartridge by using a cartridge from from the SD card (.crt file)
      c64_exp_port_mode_i    : in  natural range 0 to 2;

      ---------------------------
      -- Commodore 64 I/O ports
      ---------------------------

      -- M2M Keyboard interface
      kb_key_num_i           : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i     : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?

      -- MEGA65 joysticks and paddles
      joy_1_up_n_i           : in  std_logic;
      joy_1_down_n_i         : in  std_logic;
      joy_1_left_n_i         : in  std_logic;
      joy_1_right_n_i        : in  std_logic;
      joy_1_fire_n_i         : in  std_logic;
      joy_2_up_n_i           : in  std_logic;
      joy_2_down_n_i         : in  std_logic;
      joy_2_left_n_i         : in  std_logic;
      joy_2_right_n_i        : in  std_logic;
      joy_2_fire_n_i         : in  std_logic;
      pot1_x_i               : in  std_logic_vector(7 downto 0);
      pot1_y_i               : in  std_logic_vector(7 downto 0);
      pot2_x_i               : in  std_logic_vector(7 downto 0);
      pot2_y_i               : in  std_logic_vector(7 downto 0);

      -- Video output
      video_ce_o             : out std_logic;
      video_ce_ovl_o         : out std_logic;
      video_retro15kHz_o     : out std_logic;
      video_red_o            : out std_logic_vector(7 downto 0);
      video_green_o          : out std_logic_vector(7 downto 0);
      video_blue_o           : out std_logic_vector(7 downto 0);
      video_vs_o             : out std_logic;
      video_hs_o             : out std_logic;
      video_hblank_o         : out std_logic;
      video_vblank_o         : out std_logic;

      -- Audio output (Signed PCM)
      audio_left_o           : out signed(15 downto 0);
      audio_right_o          : out signed(15 downto 0);

      -- C64 drive led (color is RGB)
      drive_led_o            : out std_logic;
      drive_led_col_o        : out std_logic_vector(23 downto 0);

      -- C64 RAM: No address latching necessary and the chip can always be enabled
      c64_ram_addr_o         : out unsigned(15 downto 0);    -- C64 address bus
      c64_ram_data_o         : out unsigned( 7 downto 0);     -- C64 RAM data out
      c64_ram_we_o           : out std_logic;                -- C64 RAM write enable
      c64_ram_data_i         : in  unsigned( 7 downto 0);     -- C64 RAM data in

      -- C64 IEC handled by QNICE
      c64_clk_sd_i           : in  std_logic;                -- "sd card write clock" for floppy drive internal dual clock RAM buffer
      c64_qnice_addr_i       : in  std_logic_vector(27 downto 0);
      c64_qnice_data_i       : in  std_logic_vector(15 downto 0);
      c64_qnice_data_o       : out std_logic_vector(15 downto 0);
      c64_qnice_ce_i         : in  std_logic;
      c64_qnice_we_i         : in  std_logic;
      
      -- CBM-488/IEC serial (hardware) port
      iec_hardware_port_en   : in  std_logic;
      iec_reset_n_o          : out std_logic;
      iec_atn_n_o            : out std_logic;
      iec_clk_en_o           : out std_logic;
      iec_clk_n_i            : in  std_logic;
      iec_clk_n_o            : out std_logic;
      iec_data_en_o          : out std_logic;
      iec_data_n_i           : in  std_logic;
      iec_data_n_o           : out std_logic;
      iec_srq_en_o           : out std_logic;
      iec_srq_n_i            : in  std_logic;
      iec_srq_n_o            : out std_logic;    
   
      -- C64 Expansion Port (aka Cartridge Port) control lines
      -- *_dir=1 means FPGA->Port, =0 means Port->FPGA
      cart_ctrl_en_o         : out std_logic;
      cart_ctrl_dir_o        : out std_logic;
      cart_addr_en_o         : out std_logic;
      cart_haddr_dir_o       : out std_logic;
      cart_laddr_dir_o       : out std_logic;
      cart_data_en_o         : out std_logic;
      cart_data_dir_o        : out std_logic;

      -- C64 Expansion Port (aka Cartridge Port)
      cart_reset_o           : out   std_logic;
      cart_phi2_o            : out   std_logic;
      cart_dotclock_o        : out   std_logic;
      cart_nmi_i             : in    std_logic;
      cart_irq_i             : in    std_logic;
      cart_dma_i             : in    std_logic;
      cart_exrom_i           : in    std_logic;
      cart_game_i            : in    std_logic;
      cart_ba_io             : inout std_logic;
      cart_rw_io             : inout std_logic;
      cart_roml_io           : inout std_logic;
      cart_romh_io           : inout std_logic;
      cart_io1_io            : inout std_logic;
      cart_io2_io            : inout std_logic;
      cart_d_io              : inout unsigned( 7 downto 0);
      cart_a_io              : inout unsigned(15 downto 0);

      -- RAM Expansion Unit
      ext_cycle_o            : out std_logic;
      reu_cycle_i            : in  std_logic;
      reu_addr_o             : out std_logic_vector(24 downto 0);
      reu_dout_o             : out std_logic_vector( 7 downto 0);
      reu_din_i              : in  std_logic_vector( 7 downto 0);
      reu_we_o               : out std_logic;
      reu_cs_o               : out std_logic;

      -- Support for software based cartridges (aka ".CRT" files)
      cartridge_loading_i    : in  std_logic;
      cartridge_id_i         : in  std_logic_vector(15 downto 0);
      cartridge_exrom_i      : in  std_logic_vector( 7 downto 0);
      cartridge_game_i       : in  std_logic_vector( 7 downto 0);
      cartridge_bank_laddr_i : in  std_logic_vector(15 downto 0);
      cartridge_bank_size_i  : in  std_logic_vector(15 downto 0);
      cartridge_bank_num_i   : in  std_logic_vector(15 downto 0);
      cartridge_bank_type_i  : in  std_logic_vector( 7 downto 0);
      cartridge_bank_raddr_i : in  std_logic_vector(24 downto 0);
      cartridge_bank_wr_i    : in  std_logic;
      crt_bank_wait_i        : in  std_logic;
      crt_lo_ram_data_i      : in  std_logic_vector(15 downto 0);
      crt_hi_ram_data_i      : in  std_logic_vector(15 downto 0);
      crt_ioe_ram_data_i     : in  std_logic_vector( 7 downto 0);
      crt_iof_ram_data_i     : in  std_logic_vector( 7 downto 0);
      crt_addr_bus_o         : out unsigned(15 downto 0);
      crt_ioe_we_o           : out std_logic;
      crt_iof_we_o           : out std_logic;
      crt_bank_lo_o          : out std_logic_vector( 6 downto 0);
      crt_bank_hi_o          : out std_logic_vector( 6 downto 0)
   );
end entity main;

architecture synthesis of main is

   -- Generic MiSTer C64 signals
   signal c64_pause            : std_logic;
   signal c64_drive_led        : std_logic;

   -- directly connect the C64's CIA1 to the emulated keyboard matrix within keyboard.vhd
   signal cia1_pa_i            : std_logic_vector(7 downto 0);
   signal cia1_pa_o            : std_logic_vector(7 downto 0);
   signal cia1_pb_i            : std_logic_vector(7 downto 0);
   signal cia1_pb_o            : std_logic_vector(7 downto 0);

   -- the Restore key is special : it creates a non maskable interrupt (NMI)
   signal restore_key_n        : std_logic;

   -- signals for RAM
   signal c64_ram_ce           : std_logic;
   signal c64_ram_we           : std_logic;
   signal c64_ram_data         : unsigned(7 downto 0);

   -- 18-bit SID from C64 : Needs to go through audio processing ported from Verilog to VHDL from MiSTer's c64.sv
   signal c64_sid_l            : std_logic_vector(17 downto 0);
   signal c64_sid_r            : std_logic_vector(17 downto 0);
   signal alo                  : std_logic_vector(15 downto 0);
   signal aro                  : std_logic_vector(15 downto 0);

   -- C64's IEC signals
   signal c64_iec_clk_o        : std_logic;
   signal c64_iec_clk_i        : std_logic;
   signal c64_iec_atn_o        : std_logic;
   signal c64_iec_data_o       : std_logic;
   signal c64_iec_data_i       : std_logic;

   -- Hardware IEC port
   signal hw_iec_clk_n_i       : std_logic;
   signal hw_iec_data_n_i      : std_logic;

   -- Simulated IEC drives   
   signal iec_drive_ce         : std_logic;      -- chip enable for iec_drive (clock divider, see generate_drive_ce below)
   signal iec_dce_sum          : integer := 0;   -- caution: we expect 32-bit integers here and we expect the initialization to 0

   signal iec_img_mounted_i    : std_logic_vector(G_VDNUM - 1 downto 0);
   signal iec_img_readonly_i   : std_logic;
   signal iec_img_size_i       : std_logic_vector(31 downto 0);
   signal iec_img_type_i       : std_logic_vector( 1 downto 0);

   signal iec_drives_reset     : std_logic_vector(G_VDNUM - 1 downto 0);
   signal vdrives_mounted      : std_logic_vector(G_VDNUM - 1 downto 0);
   signal cache_dirty          : std_logic_vector(G_VDNUM - 1 downto 0);
   signal prevent_reset        : std_logic;
  
   signal iec_sd_lba_o         : vd_vec_array(G_VDNUM - 1 downto 0)(31 downto 0);
   signal iec_sd_blk_cnt_o     : vd_vec_array(G_VDNUM - 1 downto 0)( 5 downto 0);
   signal iec_sd_rd_o          : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_wr_o          : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_ack_i         : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_buf_addr_i    : std_logic_vector(13 downto 0);
   signal iec_sd_buf_data_i    : std_logic_vector( 7 downto 0);
   signal iec_sd_buf_data_o    : vd_vec_array(G_VDNUM - 1 downto 0)(7 downto 0);
   signal iec_sd_buf_wr_i      : std_logic;
   signal iec_par_stb_i        : std_logic;
   signal iec_par_stb_o        : std_logic;
   signal iec_par_data_i       : std_logic_vector(7 downto 0);
   signal iec_par_data_o       : std_logic_vector(7 downto 0);
   signal iec_rom_std_i        : std_logic;
   signal iec_rom_addr_i       : std_logic_vector(15 downto 0);
   signal iec_rom_data_i       : std_logic_vector( 7 downto 0);
   signal iec_rom_wr_i         : std_logic;

   -- unprocessed video output of the C64 core
   signal vga_hs               : std_logic;
   signal vga_vs               : std_logic;
   signal vga_red              : unsigned(7 downto 0);
   signal vga_green            : unsigned(7 downto 0);
   signal vga_blue             : unsigned(7 downto 0);

   -- clock enable to derive the C64's pixel clock from the core's main clock : divide by 4
   signal video_ce             : std_logic_vector(1 downto 0);

   -- Hard reset handling
   constant C_HARD_RST_DELAY   : natural := 100_000; -- roundabout 1/30 of a second
   signal reset_core_n         : std_logic;
   signal hard_reset_n         : std_logic;
   signal hard_rst_counter     : natural := 0;
   signal system_cold_start    : natural range 0 to 4 := 4;

   -- Core's simulated expansion port
   signal core_roml            : std_logic;
   signal core_romh            : std_logic;
   signal core_ioe             : std_logic;
   signal core_iof             : std_logic;
   signal core_nmi_n           : std_logic;
   signal core_nmi_ack         : std_logic;
   signal core_irq_n           : std_logic;
   signal core_dma             : std_logic;
   signal core_exrom_n         : std_logic;
   signal core_game_n          : std_logic;
   signal core_umax_romh       : std_logic;
   signal core_io_rom          : std_logic;
   signal core_io_ext          : std_logic;
   signal core_io_data         : unsigned(7 downto 0);
   signal core_dotclk          : std_logic;
   signal core_phi0            : std_logic;
   signal core_phi2            : std_logic;
   signal core_phi2_d          : std_logic;
   signal cartridge_bank_raddr : std_logic_vector(24 downto 0);

   -- Hardware Expansion Port (aka Cartridge Port)
   signal cart_roml_n          : std_logic;
   signal cart_romh_n          : std_logic;
   signal cart_io1_n           : std_logic;
   signal cart_io2_n           : std_logic;
   signal cart_nmi_n           : std_logic;
   signal cart_irq_n           : std_logic;
   signal cart_dma_n           : std_logic;
   signal cart_exrom_n         : std_logic;
   signal cart_game_n          : std_logic;
   signal data_from_cart       : unsigned(7 downto 0);
   
   constant C_CART_RESET_LEN   : natural := 32;
   signal cart_reset_counter   : natural range 0 to C_CART_RESET_LEN;
   signal cart_res_flckr_ign   : natural range 0 to 2;   -- avoid a short cart_reset_o after cart_reset_counter reached zero
   signal cart_is_an_EF3       : std_logic;

   -- RAM Expansion Unit (REU)
   signal reu_cfg              : std_logic_vector(1 downto 0);
   signal reu_dma_req          : std_logic;
   signal reu_dma_cycle        : std_logic;
   signal reu_dma_addr         : std_logic_vector(15 downto 0);
   signal reu_dma_dout         : std_logic_vector( 7 downto 0);
   signal reu_dma_din          : unsigned(7 downto 0);
   signal reu_dma_we           : std_logic;
   signal reu_irq              : std_logic;
   signal reu_iof              : std_logic;
   signal reu_oe               : std_logic;
   signal reu_dout             : unsigned(7 downto 0);

   -- Signals from the cartridge.v module (software defined cartridges)
   signal crt_addr             : std_logic_vector(24 downto 0);
   signal crt_dout             : std_logic_vector( 7 downto 0);
   signal crt_we               : std_logic;
   signal crt_cs               : std_logic;
   signal crt_io_rom           : std_logic;
   signal crt_oe               : std_logic;
   signal crt_io_ext           : std_logic;
   signal crt_io_data          : std_logic_vector(7 downto 0);
   signal crt_nmi              : std_logic;
   signal crt_exrom            : std_logic;
   signal crt_game             : std_logic;


   signal dbg_joybtn           : std_logic;
   signal dbg_cart_dir         : std_logic;

   -- Verilog file from MiSTer core
   component reu
      port (
         clk         : in  std_logic;
         reset       : in  std_logic;
         cfg         : in  std_logic_vector(1 downto 0);
         -- Connect to the DMA controller of the C64
         dma_req     : out std_logic;
         dma_cycle   : in  std_logic;
         dma_addr    : out std_logic_vector(15 downto 0);
         dma_dout    : out std_logic_vector( 7 downto 0);
         dma_din     : in  std_logic_vector( 7 downto 0);
         dma_we      : out std_logic;
         -- Connect to the HyperRAM
         ram_cycle   : in  std_logic;
         ram_addr    : out std_logic_vector(24 downto 0);
         ram_dout    : out std_logic_vector( 7 downto 0);
         ram_din     : in  std_logic_vector( 7 downto 0);
         ram_we      : out std_logic;
         ram_cs      : out std_logic;
         -- CPU register interface to the REU controller
         cpu_addr    : in  unsigned(15 downto 0);
         cpu_dout    : in  unsigned( 7 downto 0);
         cpu_din     : out unsigned( 7 downto 0);
         cpu_we      : in  std_logic;
         cpu_cs      : in  std_logic;
         irq         : out std_logic
      );
   end component reu;

   -- Verilog file from MiSTer core
   component cartridge
      port (
         clk32           : in  std_logic;
         reset_n         : in  std_logic;
         cart_loading    : in  std_logic;
         cart_id         : in  std_logic_vector(15 downto 0);
         cart_exrom      : in  std_logic_vector( 7 downto 0);
         cart_game       : in  std_logic_vector( 7 downto 0);
         cart_bank_laddr : in  std_logic_vector(15 downto 0);
         cart_bank_size  : in  std_logic_vector(15 downto 0);
         cart_bank_num   : in  std_logic_vector(15 downto 0);
         cart_bank_type  : in  std_logic_vector( 7 downto 0);
         cart_bank_raddr : in  std_logic_vector(24 downto 0);
         cart_bank_wr    : in  std_logic;
         exrom           : out std_logic;
         game            : out std_logic;
         romL            : in  std_logic;
         romH            : in  std_logic;
         UMAXromH        : in  std_logic;
         IOE             : in  std_logic;
         IOF             : in  std_logic;
         mem_write       : in  std_logic;
         mem_ce          : in  std_logic;
         mem_ce_out      : out std_logic;
         mem_write_out   : out std_logic;
         IO_rom          : out std_logic;
         IO_rd           : out std_logic;
         IO_data         : out std_logic_vector( 7 downto 0);
         addr_in         : in  std_logic_vector(15 downto 0);
         data_in         : in  std_logic_vector( 7 downto 0);
         addr_out        : out std_logic_vector(24 downto 0);
         bank_lo         : out std_logic_vector( 6 downto 0);
         bank_hi         : out std_logic_vector( 6 downto 0);
         freeze_key      : in  std_logic;
         mod_key         : in  std_logic;
         nmi             : out std_logic;
         nmi_ack         : in  std_logic
      );
   end component cartridge;

   attribute mark_debug : string;
   attribute mark_debug of c64_ram_addr_o         : signal is "true";
   attribute mark_debug of c64_ram_ce             : signal is "true";
   attribute mark_debug of c64_ram_data_i         : signal is "true";
   attribute mark_debug of c64_ram_data_o         : signal is "true";
   attribute mark_debug of c64_ram_data           : signal is "true";
   attribute mark_debug of c64_ram_we             : signal is "true";
   attribute mark_debug of core_exrom_n           : signal is "true";
   attribute mark_debug of core_game_n            : signal is "true";
   attribute mark_debug of core_ioe               : signal is "true";
   attribute mark_debug of core_iof               : signal is "true";
   attribute mark_debug of core_nmi_ack           : signal is "true";
   attribute mark_debug of core_romh              : signal is "true";
   attribute mark_debug of core_roml              : signal is "true";
   attribute mark_debug of core_umax_romh         : signal is "true";
   attribute mark_debug of ext_cycle_o            : signal is "true";
   attribute mark_debug of cart_reset_o           : signal is "true";
   attribute mark_debug of cart_phi2_o            : signal is "true";
   attribute mark_debug of cart_dotclock_o        : signal is "true";
   attribute mark_debug of cart_nmi_n             : signal is "true";
   attribute mark_debug of cart_irq_n             : signal is "true";
   attribute mark_debug of cart_dma_n             : signal is "true";
   attribute mark_debug of cart_exrom_n           : signal is "true";
   attribute mark_debug of cart_game_n            : signal is "true";
   attribute mark_debug of cart_ba_io             : signal is "true";
   attribute mark_debug of cart_rw_io             : signal is "true";
   attribute mark_debug of cart_roml_n            : signal is "true";
   attribute mark_debug of cart_romh_n            : signal is "true";
   attribute mark_debug of cart_io1_n             : signal is "true";
   attribute mark_debug of cart_io2_n             : signal is "true";
   attribute mark_debug of data_from_cart         : signal is "true";
   attribute mark_debug of c64_exp_port_mode_i    : signal is "true";
   attribute mark_debug of reset_core_n           : signal is "true";
   attribute mark_debug of reset_hard_i           : signal is "true";
   attribute mark_debug of reset_soft_i           : signal is "true";
   attribute mark_debug of restore_key_n          : signal is "true";
   attribute mark_debug of cart_reset_counter     : signal is "true";

begin

   -- @TODO DEBUG/DELIT
   dbg_joybtn     <= joy_2_fire_n_i;
   dbg_cart_dir   <= cart_data_dir_o;

   -- prevent data corruption by not allowing a soft reset to happen while the cache is still dirty
   prevent_reset <= '0' when unsigned(cache_dirty) = 0 else '1';

   -- the color of the drive led is green normally, but it turns yellow
   -- when the cache is dirty and/or currently being flushed
   drive_led_col_o <= x"00FF00" when unsigned(cache_dirty) = 0 else x"FFFF00";

   -- the drive led is on if either the C64 is writing to the virtual disk (cached in RAM)
   -- or if the dirty cache is dirty and/orcurrently being flushed to the SD card
   drive_led_o <= c64_drive_led when unsigned(cache_dirty) = 0 else '1';

   --------------------------------------------------------------------------------------------------
   -- Hard reset
   --------------------------------------------------------------------------------------------------

   hard_reset : process(clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         if reset_soft_i = '1' or reset_hard_i = '1' or cart_reset_counter /= 0 then
            hard_rst_counter  <= C_HARD_RST_DELAY;

            -- reset_core_n is low-active, so prevent_reset = 0 means execute reset
            -- but a hard reset can override
            reset_core_n      <= prevent_reset and (not reset_hard_i);

            hard_reset_n      <= not reset_hard_i;  -- "not" converts to low-active
         else
            reset_core_n      <= '1';
            if hard_rst_counter = 0 then
               hard_reset_n   <= '1';
            else
               hard_rst_counter <= hard_rst_counter - 1;
            end if;
         end if;
      end if;
   end process;

   -- Ensure that the cpu_data_in process provides a potential cartridge's ROM to the CPU so that we can
   -- start a cartridge directly upon power on (aka "cold start"). The complex reset mechanisms in the
   -- system create two hard_reset_n signals directly after power on, so we need to compensate for that.
   handle_cold_start : process(clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         if hard_reset_n = '0' and hard_rst_counter = C_HARD_RST_DELAY and (system_cold_start = 4 or system_cold_start = 2) then
            system_cold_start <= system_cold_start - 1;
         elsif hard_reset_n = '1' and hard_rst_counter = 0 and (system_cold_start = 3  or system_cold_start = 1) then
            system_cold_start <= system_cold_start - 1;
         end if;
      end if;
   end process;

   --------------------------------------------------------------------------------------------------
   -- Access to C64's RAM and hardware/simulated cartridge ROM
   --------------------------------------------------------------------------------------------------

   cpu_data_in : process(all)
   begin
      c64_ram_data <= x"00";

      -- We are emulating what is written here: https://www.c64-wiki.com/wiki/Reset_Button
      -- and avoid that the KERNAL ever sees the CBM80 signature during hard reset reset.
      -- But we cannot do it like on real hardware using the exrom signal because the
      -- MiSTer core is not supporting this.
      if hard_reset_n = '0' and c64_ram_addr_o(15 downto 12) = x"8" and system_cold_start = 0 then
         c64_ram_data <= x"00";

      -- Access the hardware cartridge
      elsif c64_exp_port_mode_i = 0 and (cart_roml_n = '0' or cart_romh_n = '0') then
         c64_ram_data <= data_from_cart;

      -- Access the simulated cartridge
      elsif c64_exp_port_mode_i = 2 and (cart_roml_n = '0' or cart_romh_n = '0' or core_ioe = '1' or core_iof = '1') then
         c64_ram_data <= unsigned(crt_lo_ram_data_i(15 downto 8)) when cart_roml_n = '0' and crt_addr_bus_o(0) = '1' else
                         unsigned(crt_lo_ram_data_i( 7 downto 0)) when cart_roml_n = '0' and crt_addr_bus_o(0) = '0' else
                         unsigned(crt_hi_ram_data_i(15 downto 8)) when cart_romh_n = '0' and crt_addr_bus_o(0) = '1' else
                         unsigned(crt_hi_ram_data_i( 7 downto 0)) when cart_romh_n = '0' and crt_addr_bus_o(0) = '0' else
                         unsigned(crt_ioe_ram_data_i)             when core_ioe = '1'                                else
                         unsigned(crt_iof_ram_data_i);

      -- Standard access to the C64's RAM
      else
         c64_ram_data <= c64_ram_data_i;

      end if;
   end process;

   -- RAM write enable also needs to check for chip enable
   c64_ram_we_o <= c64_ram_ce and c64_ram_we;

   --------------------------------------------------------------------------------------------------
   -- MiSTer Commodore 64 core / main machine
   --------------------------------------------------------------------------------------------------

   i_fpga64_sid_iec : entity work.fpga64_sid_iec
      port map (
         clk32       => clk_main_i,
         clk32_speed => clk_main_speed_i,
         reset_n     => reset_core_n,
         bios        => "01",             -- standard C64, internal ROM

         pause       => pause_i,
         pause_out   => c64_pause,        -- unused

         -- keyboard interface: directly connect the CIA1
         cia1_pa_i   => cia1_pa_i,
         cia1_pa_o   => cia1_pa_o,
         cia1_pb_i   => cia1_pb_i,
         cia1_pb_o   => cia1_pb_o,

         -- external memory
         ramAddr     => c64_ram_addr_o,
         ramDin      => c64_ram_data,
         ramDout     => c64_ram_data_o,
         ramCE       => c64_ram_ce,
         ramWE       => c64_ram_we,

         io_cycle    => open,
         ext_cycle   => ext_cycle_o,
         refresh     => open,

         cia_mode    => c64_cia_ver_i, -- 0 - 6526 "old", 1 - 8521 "new"
         turbo_mode  => "00",
         turbo_speed => "00",

         -- VGA/SCART interface
         -- The hsync frequency is 15.64 kHz (period 63.94 us).
         -- The hsync pulse width is 12.69 us.
         ntscMode    => c64_ntsc_i,
         hsync       => vga_hs,
         vsync       => vga_vs,
         r           => vga_red,
         g           => vga_green,
         b           => vga_blue,

         -- cartridge port
         game        => core_game_n,      -- input: low active
         exrom       => core_exrom_n,     -- input: low active
         io_rom      => core_io_rom,      -- input
         io_ext      => core_io_ext,      -- input
         io_data     => core_io_data,     -- input
         irq_n       => core_irq_n,       -- input: low active
         nmi_n       => core_nmi_n,       -- input
         nmi_ack     => core_nmi_ack,     -- output
         romL        => core_roml,        -- output. CPU access to 0x8000-0x9FFF
         romH        => core_romh,        -- output. CPU access to 0xA000-0xBFFF or 0xE000-0xFFFF (ultimax)
         UMAXromH    => core_umax_romh,   -- output
         IOE         => core_ioe,         -- output. aka IO1. CPU access to 0xDExx
         IOF         => core_iof,         -- output. aka IO2. CPU access to 0xDFxx
         dotclk      => core_dotclk,      -- output
         phi0        => core_phi0,        -- output
         phi2        => core_phi2,        -- output
--         freeze_key  => open,
--         mod_key     => open,
--         tape_play   => open,

         -- dma access
         dma_req     => core_dma,
         dma_cycle   => reu_dma_cycle,
         dma_addr    => unsigned(reu_dma_addr),
         dma_dout    => unsigned(reu_dma_dout),
         dma_din     => reu_dma_din,
         dma_we      => reu_dma_we,
         irq_ext_n   => not reu_irq,

         -- paddle interface
         pot1        => pot1_x_i,
         pot2        => pot1_y_i,
         pot3        => pot2_x_i,
         pot4        => pot2_y_i,

         -- SID
         audio_l     => c64_sid_l,
         audio_r     => c64_sid_r,
         sid_filter  => "11",             -- filter enable = true for both SIDs, low bit = left SID
         sid_ver     => c64_sid_ver_i,    -- SID version, 0=6581, 1=8580, low bit = left SID
         sid_mode    => c64_sid_port_i,   -- Right SID Port: 0=same as left, 1=DE00, 2=D420, 3=D500, 4=DF00
         sid_cfg     => "0000",           -- filter type: 0=Default, 1=Custom 1, 2=Custom 2, 3=Custom 3, lower two bits = left SID

         -- mechanism for loading custom SID filters: not supported, yet
         sid_ld_clk  => '0',
         sid_ld_addr => "000000000000",
         sid_ld_data => x"0000",
         sid_ld_wr   => '0',

         -- User Port: Unused inputs need to be high
         pb_i        => x"FF",
         pb_o        => open,
         pa2_i       => '1',
         pa2_o       => open,
         pc2_n_o     => open,
         flag2_n_i   => '1',
         sp2_i       => '1',
         sp2_o       => open,
         sp1_i       => '1',
         sp1_o       => open,
         cnt2_i      => '1',
         cnt2_o      => open,
         cnt1_i      => '1',
         cnt1_o      => open,

         -- IEC
         iec_clk_i   => c64_iec_clk_i and hw_iec_clk_n_i,
         iec_clk_o   => c64_iec_clk_o,
         iec_atn_o   => c64_iec_atn_o,
         iec_data_i  => c64_iec_data_i and hw_iec_data_n_i,
         iec_data_o  => c64_iec_data_o,

         c64rom_addr => "00000000000000",
         c64rom_data => x"00",
         c64rom_wr   => '0',

         cass_motor  => open,
         cass_write  => open,
         cass_sense  => '1',              -- low active
         cass_read   => '1'               -- default is '1' according to MiSTer's c1530.vhd
      ); -- i_fpga64_sid_iec

   --------------------------------------------------------------------------------------------------
   -- Expansion Port (aka Cartridge Port) handling:
   --    * MEGA65's hardware expansion port
   --    * Simulated 1750 REU 512KB
   --    * Simulateed cartridge using data from .crt file
   --------------------------------------------------------------------------------------------------

   delay_phi2 : process(clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         if c64_exp_port_mode_i = 0 then
            core_phi2_d       <= core_phi2;
            cart_phi2_o       <= core_phi2_d;
         else
            cart_phi2_o       <= '0';
         end if;
      end if;
   end process;

   handle_hardware_expansion_port : process(all)
   begin
      -- C64 Expansion Port (aka Cartridge Port) control lines
      -- *_en is low active else tri-state high impedance
      -- *_dir=1 means FPGA->Port, =0 means Port->FPGA

      -- Tristate all expansion port drivers that we can directly control
      cart_ctrl_en_o       <= '1';
      cart_addr_en_o       <= '1';
      cart_data_en_o       <= '1';

      -- Fixed direction signals: from FPGA to HW port
      -- @TODO: As soon as we support modules that can act as busmaster, we need to become more flexible here
      cart_ctrl_dir_o      <= '1';     -- control signals
      cart_haddr_dir_o     <= '1';     -- CPU address bus: higher 8 bit
      cart_laddr_dir_o     <= '1';     -- CPU address bus: lower 8 bit

      -- Default values for all signals
      cart_a_io            <= (others => 'Z');
      cart_d_io            <= (others => 'Z');
      cart_roml_io         <= 'Z';
      cart_romh_io         <= 'Z';
      cart_io1_io          <= 'Z';
      cart_io2_io          <= 'Z';
      cart_ba_io           <= 'Z';
      cart_rw_io           <= 'Z';
      cart_reset_o         <= '1';
      cart_dotclock_o      <= '0';
      cart_nmi_n           <= '1';
      cart_irq_n           <= '1';
      cart_dma_n           <= '1';
      cart_exrom_n         <= '1';
      cart_game_n          <= '1';
      cart_data_dir_o      <= '0';     -- changes dynamically (see below)
      data_from_cart       <= x"00";

      -- memory access flags
      cart_roml_n          <= not core_roml;
      cart_romh_n          <= (not core_romh) and (not core_umax_romh); -- normal ROMH and Ultimax VIC access ROMH
      cart_io1_n           <= not core_ioe;
      cart_io2_n           <= not core_iof;

      -- Mode = Use hardware slot
      if c64_exp_port_mode_i = 0 then

         -- Expansion Port control signals
         cart_ctrl_en_o    <= '0';
         cart_roml_io      <= cart_roml_n;
         cart_romh_io      <= cart_romh_n;
         cart_io1_io       <= cart_io1_n;
         cart_io2_io       <= cart_io2_n;
         cart_ba_io        <= '1';              -- @TODO
         cart_rw_io        <= not c64_ram_we;

         cart_reset_o      <= reset_core_n when cart_reset_counter = 0 and cart_res_flckr_ign = 0 else '1';
         cart_dotclock_o   <= core_dotclk;

         cart_nmi_n        <= cart_nmi_i;
         cart_irq_n        <= cart_irq_i;
         cart_dma_n        <= cart_dma_i;
         cart_exrom_n      <= cart_exrom_i;
         cart_game_n       <= cart_game_i;

         -- @TODO: As soon as we want to support DMA-enabled cartridges,
         -- we need to treat the address bus as a bi-directional port
         cart_addr_en_o    <= '0';
         if core_umax_romh = '0' then
            cart_a_io         <= c64_ram_addr_o;
         -- Ultimax mode and VIC accesses the bus
         else
            -- According to "The PLA Dissected", the address lines A12 to A15 of the C64 address bus are pulled up by
            -- RP4 whenever the VIC-II has the bus, so they are %1111 usually.
            cart_a_io         <= "11" & c64_ram_addr_o(13 downto 0);
         end if;

         -- Switch the data lines bi-directionally so that the CPU can also
         -- write to the cartridge, e.g. for bank switching
         cart_data_en_o       <= '0';
         if c64_ram_we = '0' and (cart_roml_n = '0' or cart_romh_n = '0' or cart_io1_n = '0' or cart_io2_n = '0') then
            cart_data_dir_o   <= '0';
            data_from_cart    <= cart_d_io;
         else
            cart_data_dir_o   <= '1';
            if c64_ram_we = '0' then
               cart_d_io         <= c64_ram_data_i;
            else
               cart_d_io         <= c64_ram_data_o;
            end if;
         end if;
      end if;
   end process;

   handle_cores_expansion_port_signals : process(all)
   begin
      core_game_n          <= '1';
      core_exrom_n         <= '1';
      core_io_rom          <= '0';
      core_io_ext          <= '0';
      core_io_data         <= x"FF";
      core_irq_n           <= '1';
      core_nmi_n           <= restore_key_n;
      core_dma             <= '0';  -- @TODO: Currently we ignore the HW cartridge's DMA request
      reu_iof              <= '0';
      crt_addr_bus_o       <= c64_ram_addr_o;

      case c64_exp_port_mode_i is

         -- Use hardware slot
         when 0 =>
            core_game_n    <= cart_game_n;
            core_exrom_n   <= cart_exrom_n;
            core_irq_n     <= cart_irq_n;
            core_nmi_n     <= cart_nmi_n and restore_key_n;
            core_io_ext    <= core_ioe or core_iof;
            core_io_data   <= data_from_cart;

         -- Simulate 1750 REU 512KB
         when 1 =>
            core_io_ext    <= reu_oe;
            core_io_data   <= reu_dout;
            core_dma       <= reu_dma_req;
            reu_iof        <= core_iof;

         -- Simulated cartridge using data from .crt file
         when 2 =>
            core_io_rom    <= crt_io_rom;
            core_io_ext    <= crt_io_ext;
            core_io_data   <= unsigned(crt_io_data);
            core_game_n    <= crt_game;
            core_exrom_n   <= crt_exrom;
            core_dma       <= cartridge_loading_i or crt_bank_wait_i;
            if core_umax_romh = '1' then
               -- Ultimax mode and VIC accesses the bus: we need to translate the address, see comment about "The PLA Dissected" above
               crt_addr_bus_o <= "11" & c64_ram_addr_o(13 downto 0);
            end if;

         when others =>
            null;
      end case;
   end process;

   i_cartridge_heuristics : entity work.cartridge_heuristics
      port map (
         clk_main_i           => clk_main_i,
         reset_core_n_i       => reset_core_n,
         cart_exrom_n_i       => cart_exrom_n,
         cart_game_n_i        => cart_game_n,
         cart_io1_n_i         => cart_io1_n,
         cart_io2_n_i         => cart_io2_n,
         c64_ram_we_i         => c64_ram_we,
         c64_ram_addr_i       => std_logic_vector(c64_ram_addr_o),
         phi2_i               => core_phi2,
         is_an_EF3_o          => cart_is_an_EF3
      ); -- i_cartridge_heuristics
   
   -- Cartridge-specific workaround due to the fact, that R3 and R3A board do not allow cartridges to pull the reset line to low (i.e. trigger a reset)
   handle_cartridge_triggered_resets : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         -- we cannot use reset_core_n here because as soon as cart_reset_counter 
         if reset_soft_i or reset_hard_i then
            cart_reset_counter <= 0;
            cart_res_flckr_ign <= 0;
            
         -------------------------------------------------------------------------------------------------
         -- EasyFlash 3
         -------------------------------------------------------------------------------------------------
         
         -- The EF3 needs to send a reset signal to the C64 core
         -- Learn more about the exact mechanics here: https://github.com/MJoergen/C64MEGA65/issues/60
         -- And/or look at the EF3 source code:
         --   What happens when "start-entry" key is pressed in the main menu: https://gitlab.com/easyflash/easyflash3-bootimage/-/blob/master/efmenu/src/efmenu.c#L361
         --   Set the EF ROM bank and change to the given cartridge mode: https://gitlab.com/easyflash/easyflash3-bootimage/-/blob/master/efmenu/src/efmenu_asm.s#L96
         elsif cart_reset_counter = 0 and cart_is_an_EF3 = '1' and c64_ram_we = '1' and cart_io1_n = '0' and c64_ram_addr_o = x"DE0F" then
            -- Modes that lead to a reset: https://gitlab.com/easyflash/easyflash3-core/-/blob/master/src/ef3.vhdl#L695
            -- We are deliberately not supporting the Kernal mode x"02" of the EF3, because in Kernal mode, the EF3 manipulates the address line A14.
            -- While we could emulate the behavior on our side of the transciever, the problem is, that the transciever and the EF3 would fight" against
            -- each other: There might be situations where the core sets A14 to zero while the EF3 sets it to one and this "fight" would lead to quite
            -- some current flowing which might damage either the MEGA65's transciever or the EF3's CPLD or other logic parts.
            if c64_ram_data_o = x"00" or c64_ram_data_o = x"04" or c64_ram_data_o <= x"05" or c64_ram_data_o = x"07" then
               cart_reset_counter <= C_CART_RESET_LEN;
               cart_res_flckr_ign <= 2; -- avoid a short cart_reset_o after cart_reset_counter reached zero
            end if;

         elsif cart_reset_counter > 0 then
            cart_reset_counter <= cart_reset_counter - 1;
         end if;
         
         if reset_core_n = '0' and cart_reset_counter = 0 and cart_res_flckr_ign /= 0 then
            cart_res_flckr_ign <= cart_res_flckr_ign - 1;
         end if;
      end if;
   end process;

   --------------------------------------------------------------------------------------------------
   -- Simulated REU
   --------------------------------------------------------------------------------------------------

   -- REU configuration: "00":None, "01":512k, "10":2M, "11":16M
   reu_cfg <= "01" when c64_exp_port_mode_i = 1 else "00";

   i_reu : reu
      port map (
         clk       => clk_main_i,
         reset     => not reset_core_n,
         cfg       => reu_cfg,
         dma_req   => reu_dma_req,
         dma_cycle => reu_dma_cycle,
         dma_addr  => reu_dma_addr,
         dma_dout  => reu_dma_dout,
         dma_din   => std_logic_vector(reu_dma_din),
         dma_we    => reu_dma_we,
         ram_cycle => reu_cycle_i,
         ram_addr  => reu_addr_o,
         ram_dout  => reu_dout_o,
         ram_din   => reu_din_i,
         ram_we    => reu_we_o,
         ram_cs    => reu_cs_o,
         cpu_addr  => c64_ram_addr_o,
         cpu_dout  => c64_ram_data_o,
         cpu_din   => reu_dout,
         cpu_we    => c64_ram_we,
         cpu_cs    => reu_iof,
         irq       => reu_irq
      ); -- i_reu

   reu_oe <= reu_iof;

   --------------------------------------------------------------------------------------------------
   -- Simulated Cartridge
   --------------------------------------------------------------------------------------------------

   -- This component is part of the MiSTer core, and provides
   -- support for software emulated cartridges (aka *.CRT files).
   -- This module does 3 things:
   -- 1: It stores the decoded CRT file header information in a local RAM.
   -- 2: It handles the CPU writes to $DExx and $DFxx for the bank switching.
   -- 3: It does real-time address translation.
   -- In our implementation we are not using part 3 above, but we are
   -- relying on part 1 and 2 above.

   -- This is a hack, but it works! This MiSTer component already does
   -- a lookup from bank number of HyperRAM address.
   -- In other words, bank_lo and bank_hi contain the upper bits of the
   -- cartridge_bank_raddr input. In this implementation we use our own lookup
   -- (located in crt_cacher.vhd), so we want to "disable" the mapping
   -- done by MiSTer. We do this by ensuring that the mapping is essentially
   -- the identity transformation. In other words, even though the MiSTer is
   -- performing a mapping, the output result of this mapping (in bank_lo
   -- and bank_hi) is precisely the bank number we want.
   cartridge_bank_raddr <= "000000" & cartridge_bank_num_i(5 downto 0) & X"000" & "0";

   i_cartridge : component cartridge
      port map (
         clk32           => clk_main_i,                        -- input
         reset_n         => hard_reset_n,                      -- input
         cart_loading    => cartridge_loading_i,               -- input
         cart_id         => cartridge_id_i,                    -- input
         cart_exrom      => cartridge_exrom_i,                 -- input
         cart_game       => cartridge_game_i,                  -- input
         cart_bank_laddr => cartridge_bank_laddr_i,            -- input
         cart_bank_size  => cartridge_bank_size_i,             -- input
         cart_bank_num   => cartridge_bank_num_i,              -- input
         cart_bank_type  => cartridge_bank_type_i,             -- input
         cart_bank_raddr => cartridge_bank_raddr,              -- input
         cart_bank_wr    => cartridge_bank_wr_i,               -- input
         exrom           => crt_exrom,                         -- output
         game            => crt_game,                          -- output
         romL            => core_roml,                         -- input
         romH            => core_romh,                         -- input
         UMAXromH        => core_umax_romh,                    -- input
         IOE             => core_ioe,                          -- input
         IOF             => core_iof,                          -- input
         mem_write       => c64_ram_we,                        -- input
         mem_ce          => c64_ram_ce,                        -- input
         mem_ce_out      => crt_cs,                            -- output
         mem_write_out   => crt_we,                            -- output
         IO_rom          => crt_io_rom,                        -- output
         IO_rd           => crt_oe,                            -- output
         IO_data         => crt_io_data,                       -- output
         addr_in         => std_logic_vector(c64_ram_addr_o),  -- input
         data_in         => std_logic_vector(c64_ram_data_o),  -- input
         addr_out        => crt_addr,                          -- output
         bank_lo         => crt_bank_lo_o,                     -- output
         bank_hi         => crt_bank_hi_o,                     -- output
         freeze_key      => not restore_key_n,                 -- input
         mod_key         => '0',                               -- input  (TBD)
         nmi             => crt_nmi,                           -- output (TBD: inverted of cart_nmi_n)
         nmi_ack         => core_nmi_ack                       -- input
      ); -- i_cartridge

   crt_ioe_we_o <= core_ioe and crt_we;
   crt_iof_we_o <= core_iof and crt_we;

   --------------------------------------------------------------------------------------------------
   -- Generate video output for the M2M framework
   --------------------------------------------------------------------------------------------------

   -- The M2M framework needs the signals vga_hblank_o, vga_vblank_o, and vga_ce_o.
   -- This shortens the hsync pulse width to 4.82 us, still with a period of 63.94 us.
   -- This also crops the signal to 384x270 via the vs_hblank and vs_vblank signals.
   i_video_sync : entity work.video_sync
      port map (
         clk32     => clk_main_i,
         pause     => '0',
         hsync     => vga_hs,
         vsync     => vga_vs,
         ntsc      => '0',
         wide      => '0',
         hsync_out => video_hs_o,
         vsync_out => video_vs_o,
         hblank    => video_hblank_o,
         vblank    => video_vblank_o
      ); -- i_video_sync

   video_red_o        <= std_logic_vector(vga_red);
   video_green_o      <= std_logic_vector(vga_green);
   video_blue_o       <= std_logic_vector(vga_blue);
   video_retro15kHz_o <= video_retro15kHz_i;
   video_ce_o         <= '1' when video_ce = 0 else '0';
   video_ce_ovl_o     <= '1' when video_retro15kHz_i = '0' else not video_ce(0);

   -- Clock divider: The core's pixel clock is 1/4 of the main clock
   generate_video_ce : process(clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         video_ce <= video_ce + 1;
      end if;
   end process;

   --------------------------------------------------------------------------------------------------
   -- Keyboard- and joystick controller
   --------------------------------------------------------------------------------------------------

   -- Convert MEGA65 keystrokes to the C64 keyboard matrix that the CIA1 can scan
   -- and convert the MEGA65 joystick signals to CIA1 signals as well
   i_m65_to_c64 : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
         reset_i              => not reset_core_n,

         -- Trigger the sequence RUN<Return> to autostart PRG files
         trigger_run_i        => trigger_run_i,

         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

         -- Interface to the MEGA65 joysticks
         joy_1_up_n           => joy_1_up_n_i,
         joy_1_down_n         => joy_1_down_n_i,
         joy_1_left_n         => joy_1_left_n_i,
         joy_1_right_n        => joy_1_right_n_i,
         joy_1_fire_n         => joy_1_fire_n_i,

         joy_2_up_n           => joy_2_up_n_i,
         joy_2_down_n         => joy_2_down_n_i,
         joy_2_left_n         => joy_2_left_n_i,
         joy_2_right_n        => joy_2_right_n_i,
         joy_2_fire_n         => joy_2_fire_n_i,

         -- Interface to the MiSTer C64 core that directly connects to the C64's CIA1 instead of
         -- going the detour of converting the MEGA65 keystrokes into PS/2 keystrokes first.
         -- This means, that the "fpga64_keyboard" entity of the original core is not used. Instead,
         -- we are modifying the "fpga64_sid_iec" entity so that we can route the CIA1's ports
         -- A and B into this keyboard driver which then emulates the behavior of the physical
         -- C64 keyboard including the possibility to "scan" via the row, i.e. pull one or more bits of
         -- port A to zero (one by one) and read via the "column" (i.e. from port B) or vice versa.
         cia1_pai_o           => cia1_pa_i,
         cia1_pao_i           => cia1_pa_o,
         cia1_pbi_o           => cia1_pb_i,
         cia1_pbo_i           => cia1_pb_o,

         -- Restore key = NMI
         restore_n            => restore_key_n
      ); -- i_m65_to_c64

   --------------------------------------------------------------------------------------------------
   -- MiSTer audio signal processing: Convert the core's 18-bit signal to a signed 16-bit signal
   --------------------------------------------------------------------------------------------------

   audio_processing : process(all)
      variable alm, arm : std_logic_vector(16 downto 0);
   begin
      -- "alm" and "alr" are used to mix various audio sources
      -- Additional to SID, MiSTer supports OPL, DAC and the noise of the tape drive. All these sound
      -- inputs are meant to be added here (see c64.sv in the MiSTER source) as soon as we support it.
      alm(16)           := c64_sid_l(17);
      alm(15 downto 0)  := c64_sid_l(17 downto 2);
      arm(16)           := c64_sid_r(17);
      arm(15 downto 0)  := c64_sid_r(17 downto 2);

      -- Anti-overflow mechanism for alm and arm. Right now this is not yet needed, because we are
      -- not adding multiple audio sources, but as soon as we will do that in future, we are prepared
      if alm(16) /= alm(15) then
         alo(15)           <= alm(16);
         alo(14 downto 0)  <= (others => alm(15));
      else
         alo               <= alm(15 downto 0);
      end if;

      if arm(16) /= arm(15) then
         aro(15)           <= arm(16);
         aro(14 downto 0)  <= (others => arm(15));
      else
         aro               <= arm(15 downto 0);
      end if;
   end process;

   audio_left_o  <= signed(alo);
   audio_right_o <= signed(aro);
   
   --------------------------------------------------------------------------------------------------
   -- Hardware IEC port
   --------------------------------------------------------------------------------------------------
   
   handle_hardware_iec_port : process(all)
   begin      
      iec_reset_n_o     <= '1';
      iec_atn_n_o       <= '1';
      iec_clk_en_o      <= '0';
      iec_clk_n_o       <= '1';
      iec_data_en_o     <= '0';
      iec_data_n_o      <= '1';

      -- Since IEC is a bus, we need to connect the input lines coming from the hardware port
      -- to all participants of the bus. At this time these are:
      --    C64: i_fpga64_sid_iec using the iec_ signals
      --    Simulated disk drives: i_iec_drive using the iec_ signals
      -- All signals are LOW active, so we need to AND them.
      -- As soon as we have more participants than just i_fpga64_sid_iec and i_iec_drive we will
      -- need to have some more signals for the bus instead of directly connecting them as we do today.
      hw_iec_clk_n_i    <= '1';
      hw_iec_data_n_i   <= '1';
      
      -- According to https://www.c64-wiki.com/wiki/Serial_Port, the C64 does not use the SRQ line and therefore
      -- we are at this time also not using it. The wiki article states, hat even though it is not used, it is
      -- still connected with the read line of the cassette port (although this can only detect signal edges,
      -- but not signal levels).
      -- @TODO: Investigate, if there are some edge-case use-cases that are using this "feature" and
      -- in this case enhance our simulation
      iec_srq_en_o      <= '0';   
      iec_srq_n_o       <= '1';
        
      if iec_hardware_port_en = '1' then
         -- The IEC bus is low active. By default, we let the hardware bus lines float by setting the NC7SZ126P5X
         -- output driver's OE to zero. We hardcode all output lines to zero and as soon as we need to pull a line
         -- to zero, we activate the NC7SZ126P5X OE by setting it to one. This means that the actual signalling is
         -- done by changing the NC7SZ126P5X OE instead of changing the output lines to high/low. This ensures
         -- that the lines keep floating when we have "nothing to say" to the bus.
         iec_clk_n_o       <= '0';
         iec_data_n_o      <= '0';
         
         -- These lines are not connected to a NC7SZ126P5X since the C64 is supposed to be the only
         -- party in the bus who is allowed to pull this line to zero
         iec_reset_n_o     <= reset_core_n;
         iec_atn_n_o       <= c64_iec_atn_o;

         -- Read from the hardware IEC port (see comment above: We need to connect this to i_fpga64_sid_iec and i_iec_drive)
         hw_iec_clk_n_i    <= iec_clk_n_i; 
         hw_iec_data_n_i   <= iec_data_n_i;
                           
         -- Write to the IEC port by pulling the signals low and otherwise let them float (using the NC7SZ126P5X chip)
         -- We need to invert the logic, because if the C64 wants to pull something to LOW we need to ENABLE the NC7SZ126P5X's OE
         iec_clk_en_o      <= not c64_iec_clk_o;
         iec_data_en_o     <= not c64_iec_data_o;
      end if;
   end process;

   --------------------------------------------------------------------------------------------------
   -- MiSTer IEC drives
   --------------------------------------------------------------------------------------------------

   -- Parallel C1541 port: not implemented, yet
   iec_par_stb_i        <= '0';
   iec_par_data_i       <= (others => '0');

   -- Custom ROM load facility: not implemented, yet
   iec_rom_std_i        <= '1';     -- use the factory default ROM
   iec_rom_addr_i       <= (others => '0');
   iec_rom_data_i       <= (others => '0');
   iec_rom_wr_i         <= '0';

   -- Drive is held to reset if the core is held to reset or if the drive is not mounted, yet
   -- @TODO: MiSTer also allows these options when it comes to drive-enable:
   --        "P2oPQ,Enable Drive #8,If Mounted,Always,Never;"
   --        "P2oNO,Enable Drive #9,If Mounted,Always,Never;"
   --        This code currently only implements the "If Mounted" option
   g_iec_drv_reset : for i in 0 to G_VDNUM - 1 generate
      iec_drives_reset(i) <= (not reset_core_n) or (not vdrives_mounted(i));
   end generate g_iec_drv_reset;

   i_iec_drive : entity work.iec_drive
      generic map (
         PARPORT        => 0,                -- Parallel C1541 port for faster (~20x) loading time using DolphinDOS
         DUALROM        => 0,
         DRIVES         => G_VDNUM
      )
      port map (
         clk            => clk_main_i,
         ce             => iec_drive_ce,
         reset          => iec_drives_reset,
         pause          => pause_i,

         -- interface to the C64 core
         iec_clk_i      => c64_iec_clk_o and hw_iec_clk_n_i,
         iec_clk_o      => c64_iec_clk_i,
         iec_atn_i      => c64_iec_atn_o,
         iec_data_i     => c64_iec_data_o and hw_iec_data_n_i,
         iec_data_o     => c64_iec_data_i,

         -- disk image status
         img_mounted    => iec_img_mounted_i,
         img_readonly   => iec_img_readonly_i,
         img_size       => iec_img_size_i,
         img_type       => iec_img_type_i,         -- 00=1541 emulated GCR(D64), 01=1541 real GCR mode (G64,D64), 10=1581 (D81)

         -- QNICE SD-Card/FAT32 interface
         clk_sys        => c64_clk_sd_i,           -- "SD card" clock for writing to the drives' internal data buffers

         sd_lba         => iec_sd_lba_o,
         sd_blk_cnt     => iec_sd_blk_cnt_o,
         sd_rd          => iec_sd_rd_o,
         sd_wr          => iec_sd_wr_o,
         sd_ack         => iec_sd_ack_i,
         sd_buff_addr   => iec_sd_buf_addr_i,
         sd_buff_dout   => iec_sd_buf_data_i,   -- data from SD card to the buffer RAM within the drive ("dout" is a strange name)
         sd_buff_din    => iec_sd_buf_data_o,   -- read the buffer RAM within the drive
         sd_buff_wr     => iec_sd_buf_wr_i,

         -- drive led
         led            => c64_drive_led,

         -- Parallel C1541 port
         par_stb_i      => iec_par_stb_i,
         par_stb_o      => iec_par_stb_o,
         par_data_i     => iec_par_data_i,
         par_data_o     => iec_par_data_o,

         -- Facility to load custom rom (currently not used)
         -- Important: If we want to use it, we need to replace "iecdrv_mem" in c1581_multi.sv
         -- by "dualport_2clk_ram" due to QNICE's falling-edge reading and writing
         rom_std        => iec_rom_std_i,       -- hardcoded to '1', use the factory default ROM
         rom_addr       => iec_rom_addr_i,
         rom_data       => iec_rom_data_i,
         rom_wr         => iec_rom_wr_i
      ); -- i_iec_drive

   -- 16 MHz chip enable for the IEC drives, so that ph2_r and ph2_f can be 1 MHz (C1541's CPU runs with 1 MHz)
   -- Uses a counter to compensate for clock drift, because the input clock is not exactly at 32 MHz
   --
   -- It is important that also in the HDMI-Flicker-Free-mode we are using the vanilla clock speed given by
   -- CORE_CLK_SPEED_PAL (or CORE_CLK_SPEED_NTSC) and not a speed-adjusted version of this speed. Reason:
   -- Otherwise the drift-compensation in generate_drive_ce will compensate for the slower clock speed and
   -- ensure an exact 32 MHz frequency even though the system has been slowed down by the HDMI-Flicker-Free.
   -- This leads to a different frequency ratio C64 vs 1541 and therefore to incompatibilities such as the
   -- one described in this GitHub issue:
   -- https://github.com/MJoergen/C64MEGA65/issues/2
   generate_drive_ce : process(all)
      variable msum, nextsum: integer;
   begin
      msum    := clk_main_speed_i;
      nextsum := iec_dce_sum + 16000000;

      if rising_edge(clk_main_i) then
         iec_drive_ce <= '0';
         if reset_core_n = '0' then
            iec_dce_sum <= 0;
         else
            iec_dce_sum <= nextsum;
            if nextsum >= msum then
               iec_dce_sum <= nextsum - msum;
               iec_drive_ce <= '1';
            end if;
         end if;
      end if;
   end process;

   i_vdrives : entity work.vdrives
      generic map (
         VDNUM                => G_VDNUM,             -- amount of virtual drives
         BLKSZ                => 1                    -- 1 = 256 bytes block size
      )
      port map (
         clk_qnice_i          => c64_clk_sd_i,
         clk_core_i           => clk_main_i,
         reset_core_i         => not reset_core_n,

         -- MiSTer's "SD config" interface, which runs in the core's clock domain
         img_mounted_o        => iec_img_mounted_i,
         img_readonly_o       => iec_img_readonly_i,
         img_size_o           => iec_img_size_i,
         img_type_o           => iec_img_type_i,      -- 00=1541 emulated GCR(D64), 01=1541 real GCR mode (G64,D64), 10=1581 (D81)

         -- While "img_mounted_o" needs to be strobed, "drive_mounted" latches the strobe in the core's clock domain,
         -- so that it can be used for resetting (and unresetting) the drive.
         drive_mounted_o      => vdrives_mounted,

         -- Cache output signals: The dirty flags is used to enforce data consistency
         -- (for example by ignoring/delaying a reset or delaying a drive unmount/mount, etc.)
         -- and to signal via "the yellow led" to the user that the cache is not yet
         -- written to the SD card, i.e. that writing is in progress
         cache_dirty_o        => cache_dirty,
         cache_flushing_o     => open,

         -- MiSTer's "SD block level access" interface, which runs in QNICE's clock domain
         -- using dedicated signal on Mister's side such as "clk_sys"
         sd_lba_i             => iec_sd_lba_o,
         sd_blk_cnt_i         => iec_sd_blk_cnt_o,    -- number of blocks-1
         sd_rd_i              => iec_sd_rd_o,
         sd_wr_i              => iec_sd_wr_o,
         sd_ack_o             => iec_sd_ack_i,

         -- MiSTer's "SD byte level access": the MiSTer components use a combination of the drive-specific sd_ack and the sd_buff_wr
         -- to determine, which RAM buffer actually needs to be written to (using the clk_qnice_i clock domain)
         sd_buff_addr_o       => iec_sd_buf_addr_i,
         sd_buff_dout_o       => iec_sd_buf_data_i,
         sd_buff_din_i        => iec_sd_buf_data_o,
         sd_buff_wr_o         => iec_sd_buf_wr_i,

         -- QNICE interface (MMIO, 4k-segmented)
         -- qnice_addr is 28-bit because we have a 16-bit window selector and a 4k window: 65536*4096 = 268.435.456 = 2^28
         qnice_addr_i         => c64_qnice_addr_i,
         qnice_data_i         => c64_qnice_data_i,
         qnice_data_o         => c64_qnice_data_o,
         qnice_ce_i           => c64_qnice_ce_i,
         qnice_we_i           => c64_qnice_we_i
      ); -- i_vdrives

end architecture synthesis;
