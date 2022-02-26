----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65  
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
   generic (
      G_CORE_CLK_SPEED        : natural;      
      G_OUTPUT_DX             : natural;
      G_OUTPUT_DY             : natural     
   );
   port (
      clk_main_i              : in std_logic;    -- 31.528 MHz
      clk_video_i             : in std_logic;    -- 63.056 MHz
      reset_i                 : in std_logic;
      pause_i                 : in std_logic;

      -- MEGA65 video
      VGA_R                   : out std_logic_vector(7 downto 0);
      VGA_G                   : out std_logic_vector(7 downto 0);
      VGA_B                   : out std_logic_vector(7 downto 0);
      VGA_VS                  : out std_logic;
      VGA_HS                  : out std_logic;
      VGA_DE                  : out std_logic;
      
      -- M2M Keyboard interface
      kb_key_num_i            : in integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
      
      -- C64 RAM: No address latching necessary and the chip can always be enabled
      c64_ram_addr_o          : out unsigned(15 downto 0);   -- C64 address bus
      c64_ram_data_o          : out unsigned(7 downto 0);    -- C64 RAM data out
      c64_ram_we_o            : out std_logic;               -- C64 RAM write enable      
      c64_ram_data_i          : in unsigned(7 downto 0)      -- C64 RAM data in

      -- MEGA65 audio
--      pwm_l                  : out std_logic;
--      pwm_r                  : out std_logic;

      -- MEGA65 joysticks
      joy_1_up_n             : in std_logic;
      joy_1_down_n           : in std_logic;
      joy_1_left_n           : in std_logic;
      joy_1_right_n          : in std_logic;
      joy_1_fire_n           : in std_logic;

      joy_2_up_n             : in std_logic;
      joy_2_down_n           : in std_logic;
      joy_2_left_n           : in std_logic;
      joy_2_right_n          : in std_logic;
      joy_2_fire_n           : in std_logic
   );
end main;

architecture synthesis of main is

   component video_mixer is
      port (
         CLK_VIDEO   : in  std_logic;
         CE_PIXEL    : out std_logic;
         ce_pix      : in  std_logic;
         scandoubler : in  std_logic;
         hq2x        : in  std_logic;
         gamma_bus   : inout std_logic_vector(21 downto 0);
         R           : in  unsigned(7 downto 0);
         G           : in  unsigned(7 downto 0);
         B           : in  unsigned(7 downto 0);
         HSync       : in  std_logic;
         VSync       : in  std_logic;
         HBlank      : in  std_logic;
         VBlank      : in  std_logic;
         HDMI_FREEZE : in  std_logic;
         freeze_sync : out std_logic;
         VGA_R       : out std_logic_vector(7 downto 0);
         VGA_G       : out std_logic_vector(7 downto 0);
         VGA_B       : out std_logic_vector(7 downto 0);
         VGA_VS      : out std_logic;
         VGA_HS      : out std_logic;
         VGA_DE      : out std_logic
      );
   end component video_mixer;

-- MiSTer C64 signals
signal c64_pause     : std_logic;
signal ce_pix        : std_logic;
signal c64_hsync     : std_logic;
signal c64_vsync     : std_logic;
signal c64_r         : unsigned(7 downto 0);
signal c64_g         : unsigned(7 downto 0);
signal c64_b         : unsigned(7 downto 0);

-- MiSTer video pipeline signals
signal vs_hsync      : std_logic;
signal vs_vsync      : std_logic;
signal vs_hblank     : std_logic;
signal vs_vblank     : std_logic;
signal div           : integer range 0 to 7;
signal mix_r         : std_logic_vector(7 downto 0);
signal mix_g         : std_logic_vector(7 downto 0);
signal mix_b         : std_logic_vector(7 downto 0);
signal mix_vga_de    : std_logic;

-- directly connect the C64's CIA1 to the emulated keyboard matrix within keyboard.vhd
signal cia1_pa_i     : std_logic_vector(7 downto 0);
signal cia1_pa_o     : std_logic_vector(7 downto 0);
signal cia1_pb_i     : std_logic_vector(7 downto 0);
signal cia1_pb_o     : std_logic_vector(7 downto 0);

-- the Restore key is special: it creates a non maskable interrupt (NMI)
signal restore_key_n : std_logic;

-- signales for RAM
signal c64_ram_ce    : std_logic;
signal c64_ram_we    : std_logic;

begin   
   -- MiSTer Commodore 64 core / main machine
   i_fpga64_sid_iec : entity work.fpga64_sid_iec
      port map (
         clk32       => clk_main_i,      
         reset_n     => not reset_i,
         bios        => "01",             -- standard C64, internal ROM
         
         pause       => pause_i,
         pause_out   => c64_pause,
      
         -- keyboard interface: directly connect the CIA1
         cia1_pa_i   => cia1_pa_i,
         cia1_pa_o   => cia1_pa_o,
         cia1_pb_i   => cia1_pb_i,
         cia1_pb_o   => cia1_pb_o,
               
         -- external memory
         ramAddr     => c64_ram_addr_o,
         ramDin      => c64_ram_data_i,
         ramDout     => c64_ram_data_o,
         ramCE       => c64_ram_ce,
         ramWE       => c64_ram_we,
      
         io_cycle    => open,
         ext_cycle   => open,
         refresh     => open,
      
         cia_mode    => '0',              -- 0 - 6526 "old", 1 - 8521 "new"
         turbo_mode  => "00",
         turbo_speed => "00",
      
         -- VGA/SCART interface
         ntscMode    => '0',
         hsync       => c64_hsync,
         vsync       => c64_vsync,
         r           => c64_r,
         g           => c64_g,
         b           => c64_b,
      
         -- cartridge port
         game        => '1',              -- low active, 1 is default so that KERNAL ROM can be read
         exrom       => '1',              -- ditto
         io_rom      => '0',
         io_ext      => '0',
         io_data     => x"00",
         irq_n       => '1',
         nmi_n       => restore_key_n,    -- TODO: "freeze_key" handling also regarding the cartrige (see MiSTer)
         nmi_ack     => open,
         romL        => open,
         romH        => open,
         UMAXromH 	=> open,
         IOE			=> open,
         IOF			=> open,
         freeze_key  => open,
         mod_key     => open,
         tape_play   => open,
      
         -- dma access
         dma_req     => '0',
         dma_cycle   => open,
         dma_addr    => x"0000",
         dma_dout    => x"00",
         dma_din     => open,
         dma_we      => '0',
         irq_ext_n   => '1',
      
         -- joystick interface
         joyA        => "0000000",
         joyB        => "0000000",
         pot1        => x"00",
         pot2        => x"00",
         pot3        => x"00",
         pot4        => x"00",
      
         -- SID
         audio_l     => open,
         audio_r     => open,
         sid_filter  => "00",
         sid_ver     => "00",
         sid_mode    => "000",
         sid_cfg     => "0000",
         sid_ld_clk  => '0',
         sid_ld_addr => "000000000000",
         sid_ld_data => x"0000",
         sid_ld_wr   => '0',
         
         -- USER
         pb_i        => x"00",
         pb_o        => open,
         pa2_i       => '0',
         pa2_o       => open,
         pc2_n_o     => open,
         flag2_n_i   => '1',
         sp2_i       => '0',
         sp2_o       => open,
         sp1_i       => '0',
         sp1_o       => open,
         cnt2_i      => '0',
         cnt2_o      => open,
         cnt1_i      => '0',
         cnt1_o      => open,
      
         -- IEC
         iec_data_o	=> open,
         iec_data_i	=> '0',
         iec_clk_o	=> open,
         iec_clk_i	=> '0',
         iec_atn_o	=> open,
         
         c64rom_addr => "00000000000000",
         c64rom_data => x"00",
         c64rom_wr   => '0',
      
         cass_motor  => open,
         cass_write  => open,
         cass_sense  => '0',
         cass_read   => '0'            
      ); -- i_fpga64_sid_iec
      
   -- RAM write enable also needs to check for chip enable
   c64_ram_we_o <= c64_ram_ce and c64_ram_we; 
                      
   -- Convert MEGA65 keystrokes to the C64 keyboard matrix that the CIA1 can scan
   i_m65_to_c64 : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
            
         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

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


   i_video_sync : entity work.video_sync
      port map (
         clk32     => clk_main_i,
         pause     => c64_pause,
         hsync     => c64_hsync,
         vsync     => c64_vsync,
         ntsc      => '0',
         wide      => '0',
         hsync_out => vs_hsync,
         vsync_out => vs_vsync,
         hblank    => vs_hblank,
         vblank    => vs_vblank
      ); -- i_video_sync

   p_div : process (clk_video_i)
   begin
      if rising_edge(clk_video_i) then
         div <= div + 1;
      end if;
   end process p_div;
   ce_pix <= '1' when div = 0 else '0';

   i_video_mixer : video_mixer
      port map (
         CLK_VIDEO   => clk_video_i,      -- 63.056 MHz
         CE_PIXEL    => open,
         ce_pix      => ce_pix,
         scandoubler => '1',
         hq2x        => '0',
         gamma_bus   => open,
         R           => c64_r,
         G           => c64_g,
         B           => c64_b,
         HSync       => vs_hsync,
         VSync       => vs_vsync,
         HBlank      => vs_hblank,
         VBlank      => vs_vblank,
         HDMI_FREEZE => '0',
         freeze_sync => open,
         VGA_R       => mix_r,
         VGA_G       => mix_g,
         VGA_B       => mix_b,
         VGA_VS      => VGA_VS,
         VGA_HS      => VGA_HS,
         VGA_DE      => mix_vga_de
      ); -- i_video_mixer
      
   VGA_DE <= mix_vga_de;
   vga_data_enable : process(mix_r, mix_g, mix_b, mix_vga_de)
   begin
      if mix_vga_de = '1' then
         VGA_R <= mix_r;
         VGA_G <= mix_g;
         VGA_B <= mix_b;
      else
         VGA_R <= (others => '0');
         VGA_G <= (others => '0');
         VGA_B <= (others => '0');
      end if;
   end process;
      
end synthesis;
