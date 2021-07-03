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

