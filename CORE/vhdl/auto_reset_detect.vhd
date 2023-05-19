----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- It would be great, if you could make a kind of generic heuristics module that would
-- have multiple outputs like "is_an_EF3_standard" (Easy Flash 3 standard cartridge) and
-- "is_an_EF3_kernal" (Easy Flash 3 mapping a new Kernal into the C64) and "is_a_KFF" (Kung
-- Fu Flash) and others. The "is_an_xyz" signals should stay high as soon as they were
-- triggered once and only go back to zero, if the heuristics module receives a reset.

-- The clock is the 32 MHz main clock, the module is meant to be run inside main.vhd. Have
-- a look at the branch dev-morehwcrts:
-- https://github.com/MJoergen/C64MEGA65/blob/dev-morehwcrts/CORE/vhdl/main.vhd#L837
--
-- This is where the "is_an_EF3_standard" signal would be used if it would be available, so the line would read:
--
-- elsif cart_reset_counter = 0 and is_an_EF3_standard = '1' and c64_ram_we = '1' and
-- cart_io1_n = '0' and c64_ram_addr_o = x"DE0F" and c64_ram_data_o = x"00" then
-- The heuristics to detect an EasyFlash 3 (EF3) that is just about to start a cartridge
-- is (all clock cycles relative to the 32 MHz main clock):
--
-- While:
-- cart_exrom_n = 0
-- cart_game_n = 0
--
-- Detect falling edge of (cart_io1) and then check if c64_ram_we=1 and c64_ram_addr_o=x"DE00" (i.e. writing to DE00)
-- AND less than 200 cycles later (otherwise, if it comes later than 200 cycles, then it is not "is_an_EF3_standard")
-- Detect falling edge of (cart_io1) and then check if c64_ram_we=1 and c64_ram_addr_o=x"DE0E" (i.e. writing to DE0E)
-- Detect rising edge of cart_io1 and AFTER that:
-- Detect next falling edge of phi2: System Address needs to be x"0108"
-- Detect next falling edge of phi2: System Address needs to be x"0109"
-- Detect next falling edge of phi2: System Address needs to be x"0013"
-- Now set is_an_EF3_standard to 1 until the next incoming reset

-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2023 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity auto_reset_detect is
   port (
      clk_main_i           : in  std_logic;
      reset_soft_i         : in  std_logic;
      reset_hard_i         : in  std_logic;

      cart_exrom_n_i       : in  std_logic;
      cart_game_n_i        : in  std_logic;
      cart_io1_i           : in  std_logic;
      cart_io2_i           : in  std_logic;
      c64_ram_we_i         : in  std_logic;
      c64_ram_addr_i       : in  std_logic;
      phi2_i               : in  std_logic;

      is_an_EF3_standard_o : out std_logic
   );
end entity auto_reset_detect;

architecture synthesis of auto_reset_detect is

   type state_t is (IDLE_ST, STAGE1_ST, STAGE2_ST, STAGE3_ST, STAGE4_ST, STAGE5_ST);
   signal state : state_t := IDLE_ST;

   signal cart_io1_d : std_logic;
   signal cart_io2_d : std_logic;

begin

   p_fsm : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         cart_io1_d <= cart_io1_i;
         cart_io2_d <= cart_io2_i;

         case state is
            when IDLE_ST =>
               if cart_io1_d = '1' and cart_io1_i = '0' then
                  -- Falling edge of cart_io1
               end if;

            when others =>

         end case;

         if reset_soft_i = '1' or reset_hard_i = '1' then
            state                <= IDLE_ST;
            is_an_EF3_standard_o <= '0';
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

