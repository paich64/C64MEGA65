----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65  
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2021 and licensed under GPL v3
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
      clk_main_i              : in std_logic;
      clk_audio_i             : in std_logic;
      reset_i                 : in std_logic;

      -- M2M Keyboard interface
      kb_key_num_i           : in integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i     : in std_logic                 -- low active: debounced feedback: is kb_key_num_i pressed right now?   

      -- MEGA65 audio
--      pwm_l                  : out std_logic;
--      pwm_r                  : out std_logic;

      -- MEGA65 joysticks
--      joy_1_up_n             : in std_logic;
--      joy_1_down_n           : in std_logic;
--      joy_1_left_n           : in std_logic;
--      joy_1_right_n          : in std_logic;
--      joy_1_fire_n           : in std_logic;

--      joy_2_up_n             : in std_logic;
--      joy_2_down_n           : in std_logic;
--      joy_2_left_n           : in std_logic;
--      joy_2_right_n          : in std_logic;
--      joy_2_fire_n           : in std_logic
   );
end main;

architecture synthesis of main is

signal kb_ps2 : std_logic_vector(10 downto 0);

begin

   -- MiSTer Commodore 64 core / main machine
   i_c64 : entity work.fpga64_sid_iec
      port map (
         clk32       => clk_main_i,      
         reset_n     => not reset_i,
         bios        => "01",             -- standard C64, internal ROM
         
         pause       => '0',
         pause_out   => open,
      
         -- keyboard interface (use any ordinairy PS2 keyboard)
         ps2_key     => kb_ps2,
         kbd_reset   => reset_i,
      
         -- external memory
         ramAddr     => open,
         ramDin      => x"00",
         ramDout     => open,
         ramCE       => open,
         ramWE       => open,
      
         io_cycle    => open,
         ext_cycle   => open,
         refresh     => open,
      
         cia_mode    => '0',              -- 0 - 6526 "old", 1 - 8521 "new"
         turbo_mode  => "00",
         turbo_speed => "00",
      
         -- VGA/SCART interface
         ntscMode    => '0',
         hsync       => open,
         vsync       => open,
         r           => open,
         g           => open,
         b           => open,
      
         -- cartridge port
         game        => '0',
         exrom       => '0',
         io_rom      => '0',
         io_ext      => '0',
         io_data     => x"00",
         irq_n       => '1',
         nmi_n       => '1',
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
      
         --SID
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
      );
      
   -- The C64 core expects an own variant of PS/2 scancodes including make/break codes
   i_m65_to_ps2 : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
            
         -- interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

         -- PS/2 interface to the MiSTer C64 core         
         ps2_o                => kb_ps2
      );
      
end synthesis;

