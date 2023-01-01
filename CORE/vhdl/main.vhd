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
use work.vdrives_pkg.all;

entity main is
   generic (
      G_VDNUM                 : natural                     -- amount of virtual drives     
   );
   port (
      clk_main_i              : in  std_logic;
      reset_soft_i            : in  std_logic;
      reset_hard_i            : in  std_logic;
      pause_i                 : in  std_logic;

      c64_ntsc_i              : in std_logic;               -- 0 = PAL mode, 1 = NTSC mode, clocks need to be correctly set, too

      -- MiSTer core main clock speed:
      -- Make sure you pass very exact numbers here, because they are used for avoiding clock drift at derived clocks
      clk_main_speed_i        : in natural;
      
      -- SID and CIA versions
      c64_sid_ver_i           : in std_logic_vector(1 downto 0); -- SID version, 0=6581, 1=8580, low bit = left SID
      c64_cia_ver_i           : in std_logic;               -- CIA version: 0=6526 "old", 1=8521 "new"      
      
      -- M2M Keyboard interface
      kb_key_num_i            : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
      
      -- MEGA65 joysticks and paddles
      joy_1_up_n_i            : in  std_logic;
      joy_1_down_n_i          : in  std_logic;
      joy_1_left_n_i          : in  std_logic;
      joy_1_right_n_i         : in  std_logic;
      joy_1_fire_n_i          : in  std_logic;

      joy_2_up_n_i            : in  std_logic;
      joy_2_down_n_i          : in  std_logic;
      joy_2_left_n_i          : in  std_logic;
      joy_2_right_n_i         : in  std_logic;
      joy_2_fire_n_i          : in  std_logic;

      paddle_1_x              : in std_logic_vector(7 downto 0);
      paddle_1_y              : in std_logic_vector(7 downto 0);
      paddle_2_x              : in std_logic_vector(7 downto 0);
      paddle_2_y              : in std_logic_vector(7 downto 0);

      -- Video output
      video_ce_o              : out std_logic;
      video_ce_2x_o           : out std_logic;
      video_red_o             : out std_logic_vector(7 downto 0);
      video_green_o           : out std_logic_vector(7 downto 0);
      video_blue_o            : out std_logic_vector(7 downto 0);
      video_vs_o              : out std_logic;
      video_hs_o              : out std_logic;
      video_hblank_o          : out std_logic;
      video_vblank_o          : out std_logic;

      -- Audio output (Signed PCM)
      audio_left_o            : out signed(15 downto 0);
      audio_right_o           : out signed(15 downto 0);

                             -- C64 drive led (color is RGB)
      drive_led_o             : out std_logic;
      drive_led_col_o         : out std_logic_vector(23 downto 0);

      -- C64 RAM: No address latching necessary and the chip can always be enabled
      c64_ram_addr_o          : out unsigned(15 downto 0);  -- C64 address bus
      c64_ram_data_o          : out unsigned(7 downto 0);   -- C64 RAM data out
      c64_ram_we_o            : out std_logic;              -- C64 RAM write enable
      c64_ram_data_i          : in unsigned(7 downto 0);    -- C64 RAM data in

      -- C64 IEC handled by QNICE
      c64_clk_sd_i            : in std_logic;               -- "sd card write clock" for floppy drive internal dual clock RAM buffer
      c64_qnice_addr_i        : in std_logic_vector(27 downto 0);
      c64_qnice_data_i        : in std_logic_vector(15 downto 0);
      c64_qnice_data_o        : out std_logic_vector(15 downto 0);
      c64_qnice_ce_i          : in std_logic;
      c64_qnice_we_i          : in std_logic;

      -- RAM Expansion Unit
      reu_cfg_i               : in  std_logic;
      ext_cycle_o             : out std_logic;
      reu_cycle_i             : in  std_logic;
      reu_addr_o              : out std_logic_vector(24 downto 0);
      reu_dout_o              : out std_logic_vector(7 downto 0);
      reu_din_i               : in  std_logic_vector(7 downto 0);
      reu_we_o                : out std_logic;
      reu_cs_o                : out std_logic                       
   );
end entity main;

architecture synthesis of main is

   -- MiSTer C64 signals
   signal c64_pause           : std_logic;
   signal c64_hsync           : std_logic;
   signal c64_vsync           : std_logic;
   signal c64_r               : unsigned(7 downto 0);
   signal c64_g               : unsigned(7 downto 0);
   signal c64_b               : unsigned(7 downto 0);
   signal c64_drive_led       : std_logic;

   -- directly connect the C64's CIA1 to the emulated keyboard matrix within keyboard.vhd
   signal cia1_pa_i           : std_logic_vector(7 downto 0);
   signal cia1_pa_o           : std_logic_vector(7 downto 0);
   signal cia1_pb_i           : std_logic_vector(7 downto 0);
   signal cia1_pb_o           : std_logic_vector(7 downto 0);

   -- the Restore key is special: it creates a non maskable interrupt (NMI)
   signal restore_key_n       : std_logic;

   -- signals for RAM
   signal c64_ram_ce          : std_logic;
   signal c64_ram_we          : std_logic;

   -- 18-bit SID from C64: Needs to go through audio processing ported from Verilog to VHDL from MiSTer's c64.sv
   signal c64_sid_l           : std_logic_vector(17 downto 0);
   signal c64_sid_r           : std_logic_vector(17 downto 0);
   signal alo                 : std_logic_vector(15 downto 0);
   signal aro                 : std_logic_vector(15 downto 0);

   -- IEC drives
   signal iec_drive_ce        : std_logic;      -- chip enable for iec_drive (clock divider, see generate_drive_ce below)
   signal iec_dce_sum         : integer := 0;   -- caution: we expect 32-bit integers here and we expect the initialization to 0

   signal iec_img_mounted_i   : std_logic_vector(G_VDNUM - 1 downto 0);
   signal iec_img_readonly_i  : std_logic;
   signal iec_img_size_i      : std_logic_vector(31 downto 0);
   signal iec_img_type_i      : std_logic_vector(1 downto 0);

   signal iec_drives_reset    : std_logic_vector(G_VDNUM - 1 downto 0);
   signal vdrives_mounted     : std_logic_vector(G_VDNUM - 1 downto 0);
   signal cache_dirty         : std_logic_vector(G_VDNUM - 1 downto 0);
   signal prevent_reset       : std_logic;

   signal c64_iec_clk_o       : std_logic;
   signal c64_iec_clk_i       : std_logic;
   signal c64_iec_atn_o       : std_logic;
   signal c64_iec_data_o      : std_logic;
   signal c64_iec_data_i      : std_logic;
   signal iec_sd_lba_o        : vd_vec_array(G_VDNUM - 1 downto 0)(31 downto 0);
   signal iec_sd_blk_cnt_o    : vd_vec_array(G_VDNUM - 1 downto 0)(5 downto 0);
   signal iec_sd_rd_o         : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_wr_o         : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_ack_i        : vd_std_array(G_VDNUM - 1 downto 0);
   signal iec_sd_buf_addr_i   : std_logic_vector(13 downto 0);
   signal iec_sd_buf_data_i   : std_logic_vector(7 downto 0);
   signal iec_sd_buf_data_o   : vd_vec_array(G_VDNUM - 1 downto 0)(7 downto 0);
   signal iec_sd_buf_wr_i     : std_logic;
   signal iec_par_stb_i       : std_logic;
   signal iec_par_stb_o       : std_logic;
   signal iec_par_data_i      : std_logic_vector(7 downto 0);
   signal iec_par_data_o      : std_logic_vector(7 downto 0);
   signal iec_rom_std_i       : std_logic;
   signal iec_rom_addr_i      : std_logic_vector(15 downto 0);
   signal iec_rom_data_i      : std_logic_vector(7 downto 0);
   signal iec_rom_wr_i        : std_logic;

   signal vga_hs              : std_logic;
   signal vga_vs              : std_logic;
   signal vga_red             : unsigned(7 downto 0);
   signal vga_green           : unsigned(7 downto 0);
   signal vga_blue            : unsigned(7 downto 0);
   signal vga_ce              : std_logic_vector(3 downto 0) := "1000"; -- Pixel clock is 1/4 of the main clock.

   -- Hard reset handling
   constant hard_rst_delay   : natural := 100000; -- roundabout 1/10th of a second
   signal reset_core_n        : std_logic;
   signal hard_reset_n        : std_logic;
   signal hard_rst_counter    : natural := 0;
   signal c64_ram_data        : unsigned(7 downto 0);
   
   -- Paddles
   signal pot1                : std_logic_vector(7 downto 0);  -- port 1, x
   signal pot2                : std_logic_vector(7 downto 0);  -- port 1, y
   signal pot3                : std_logic_vector(7 downto 0);  -- port 2, x
   signal pot4                : std_logic_vector(7 downto 0);  -- port 2, y

   signal dma_req             : std_logic;
   signal dma_cycle           : std_logic;
   signal dma_addr            : std_logic_vector(15 downto 0);
   signal dma_dout            : std_logic_vector(7 downto 0);
   signal dma_din             : unsigned(7 downto 0);
   signal dma_we              : std_logic;
   signal reu_irq             : std_logic;
   signal reu_oe              : std_logic;
   signal reu_dout            : unsigned(7 downto 0);
   signal iof                 : std_logic;

   component reu
      port (
         clk         : in  std_logic;
         reset       : in  std_logic;
         cfg         : in  std_logic_vector(1 downto 0);
         dma_req     : out std_logic;
         dma_cycle   : in  std_logic;
         dma_addr    : out std_logic_vector(15 downto 0);
         dma_dout    : out std_logic_vector(7 downto 0);
         dma_din     : in  std_logic_vector(7 downto 0);
         dma_we      : out std_logic;
         ram_cycle   : in  std_logic;
         ram_addr    : out std_logic_vector(24 downto 0);
         ram_dout    : out std_logic_vector(7 downto 0);
         ram_din     : in  std_logic_vector(7 downto 0);
         ram_we      : out std_logic;
         ram_cs      : out std_logic;
         cpu_addr    : in  unsigned(15 downto 0);
         cpu_dout    : in  unsigned(7 downto 0);
         cpu_din     : out unsigned(7 downto 0);
         cpu_we      : in  std_logic;
         cpu_cs      : in  std_logic;
         irq         : out std_logic
      );
   end component reu;

begin
   -- @TODO: video_ce_2x_o needs to be twice as fast as video_ce_o; the demo core's vga_ce_o halfs
   -- the speed of clk_main_i, so to achieve factor 2x we just need to set video_ce_2x_o to '1'.
   video_ce_2x_o <= '1';

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
         if reset_soft_i or reset_hard_i then
            hard_rst_counter  <= hard_rst_delay;
            
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
   
   -- We are emulating what is written here: https://www.c64-wiki.com/wiki/Reset_Button
   -- and avoid that the KERNAL ever sees the CBM80 signature during reset. But we cannot do it like
   -- on real hardware using the exrom signal because the MiSTer core is not supporting this.
   -- @TODO: As soon as we support cartridges, this code here needs to become smarter.
   c64_ram_data <= x"00" when hard_reset_n = '0' and c64_ram_addr_o(15 downto 12) = x"8" else c64_ram_data_i;
      
   --------------------------------------------------------------------------------------------------
   -- MiSTer Commodore 64 core / main machine
   --------------------------------------------------------------------------------------------------

   i_fpga64_sid_iec : entity work.fpga64_sid_iec
      port map (
         clk32       => clk_main_i,
         clk32_speed => clk_main_speed_i,
         reset_n     => reset_core_n,
         bios        => "01",          -- standard C64, internal ROM

         pause       => pause_i,
         pause_out   => c64_pause,

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
         game        => '1',           -- low active, 1 is default so that KERNAL ROM can be read
         exrom       => '1',           -- ditto
         io_rom      => '0',
         io_ext      => reu_oe,        -- input
         io_data     => reu_dout,      -- input
         irq_n       => '1',
         nmi_n       => restore_key_n, -- TODO: "freeze_key" handling also regarding the cartrige (see MiSTer)
         nmi_ack     => open,
         romL        => open,
         romH        => open,
         UMAXromH    => open,
         IOE         => open,
         IOF         => iof,           -- output
--         freeze_key  => open,
--         mod_key     => open,
--         tape_play   => open,

         -- dma access
         dma_req     => dma_req,
         dma_cycle   => dma_cycle,
         dma_addr    => unsigned(dma_addr),
         dma_dout    => unsigned(dma_dout),
         dma_din     => dma_din,
         dma_we      => dma_we,
         irq_ext_n   => not reu_irq,

         -- paddle interface
         pot1        => pot1,
         pot2        => pot2,
         pot3        => pot3,
         pot4        => pot4,

         -- SID
         audio_l     => c64_sid_l,
         audio_r     => c64_sid_r,
         sid_filter  => "11",          -- filter enable = true for both SIDs, low bit = left SID
         sid_ver     => c64_sid_ver_i, -- SID version, 0=6581, 1=8580, low bit = left SID
         sid_mode    => "000",         -- Right SID Port: 0=same as left, 1=DE00, 2=D420, 3=D500, 4=DF00
         sid_cfg     => "0000",        -- filter type: 0=Default, 1=Custom 1, 2=Custom 2, 3=Custom 3, lower two bits = left SID

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
         iec_clk_i   => c64_iec_clk_i,
         iec_clk_o   => c64_iec_clk_o,
         iec_atn_o   => c64_iec_atn_o,
         iec_data_i  => c64_iec_data_i,
         iec_data_o  => c64_iec_data_o,

         c64rom_addr => "00000000000000",
         c64rom_data => x"00",
         c64rom_wr   => '0',

         cass_motor  => open,
         cass_write  => open,
         cass_sense  => '1',           -- low active
         cass_read   => '1'            -- default is '1' according to MiSTer's c1530.vhd
      ); -- i_fpga64_sid_iec


   i_reu : reu
      port map (
         clk       => clk_main_i,
         reset     => not reset_core_n,
         cfg       => "0" & reu_cfg_i, -- "00":None, "01":512k, "10":2M, "11":16M
         dma_req   => dma_req,
         dma_cycle => dma_cycle,
         dma_addr  => dma_addr,
         dma_dout  => dma_dout,
         dma_din   => std_logic_vector(dma_din),
         dma_we    => dma_we,
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
         cpu_cs    => iof,
         irq       => reu_irq
      ); -- i_reu

   reu_oe <= iof;

   pot1 <= paddle_2_x when flip_joys_i else paddle_1_x;
   pot2 <= paddle_2_y when flip_joys_i else paddle_1_y;
   pot3 <= paddle_1_x when flip_joys_i else paddle_2_x;
   pot4 <= paddle_1_y when flip_joys_i else paddle_2_y;

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
         hsync_out => vga_hs_o,
         vsync_out => vga_vs_o,
         hblank    => vga_hblank_o,
         vblank    => vga_vblank_o
      ); -- i_video_sync

   vga_red_o   <= std_logic_vector(vga_red);
   vga_green_o <= std_logic_vector(vga_green);
   vga_blue_o  <= std_logic_vector(vga_blue);
   vga_ce_o    <= vga_ce(0);

   p_vga_ce : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         vga_ce <= vga_ce(0) & vga_ce(vga_ce'left downto 1);
      end if;
   end process p_vga_ce;

   -- RAM write enable also needs to check for chip enable
   c64_ram_we_o <= c64_ram_ce and c64_ram_we;

   -- Convert MEGA65 keystrokes to the C64 keyboard matrix that the CIA1 can scan
   -- and convert the MEGA65 joystick signals to CIA1 signals as well
   i_m65_to_c64 : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
         flip_joys_i          => flip_joys_i,

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

   sid_l <= signed(alo);
   sid_r <= signed(aro);

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
         iec_clk_i      => c64_iec_clk_o,
         iec_clk_o      => c64_iec_clk_i,
         iec_atn_i      => c64_iec_atn_o,
         iec_data_i     => c64_iec_data_o,
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

