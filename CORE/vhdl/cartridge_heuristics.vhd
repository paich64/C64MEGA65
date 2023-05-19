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

entity cartridge_heuristics is
   port (
      clk_main_i           : in  std_logic;
      reset_core_n_i       : in  std_logic;   -- Active low

      cart_exrom_n_i       : in  std_logic;
      cart_game_n_i        : in  std_logic;
      cart_io1_i           : in  std_logic;
      cart_io2_i           : in  std_logic;
      c64_ram_we_i         : in  std_logic;
      c64_ram_addr_i       : in  std_logic_vector(15 downto 0);
      phi2_i               : in  std_logic;

      is_an_EF3_standard_o : out std_logic
   );
end entity cartridge_heuristics;

architecture synthesis of cartridge_heuristics is

   type state_t is (IDLE_ST, STAGE1_ST, STAGE2_ST, STAGE3_ST, STAGE4_ST, STAGE5_ST, DONE_ST);
   signal state : state_t := IDLE_ST;

   -- These are for edge detection
   signal cart_io1_d : std_logic;
   signal cart_io2_d : std_logic;
   signal phi2_d     : std_logic;

   -- This is a gereric down-counter to handle timeouts while waiting for some event.
   signal counter : natural range 0 to 200*32; -- Multiply by 32, because the main clock is 32 MHz.

begin

   p_fsm : process (clk_main_i)
   begin
      if rising_edge(clk_main_i) then
         -- This is for edge detection
         cart_io1_d <= cart_io1_i;
         cart_io2_d <= cart_io2_i;
         phi2_d     <= phi2_i;

         if counter > 0 then
            counter <= counter - 1;
         end if;

         case state is
            when IDLE_ST =>
               -- Reset all heuristics
               is_an_EF3_standard_o <= '0';

               -- Falling edge of cart_io1
               -- Detect writing to DE00
               if cart_io1_d = '1' and cart_io1_i = '0' and c64_ram_we_i = '1' and c64_ram_addr_i = X"DE00" then
                  counter <= 200*32; -- Maximum 200 CPU clock cycle waiting time in next stage
                  state   <= STAGE1_ST;
               end if;

            when STAGE1_ST =>
               -- Falling edge of cart_io1
               -- Detect writing to DE0E
               if cart_io1_d = '1' and cart_io1_i = '0' and c64_ram_we_i = '1' and c64_ram_addr_i = X"DE0E" then
                  state <= STAGE2_ST;
               end if;

               if counter = 0 then
                  state <= IDLE_ST;
               end if;

            when STAGE2_ST =>
               -- Detect rising edge of cart_io1
               if cart_io1_d = '0' and cart_io1_i = '1' then
                  state <= STAGE3_ST;
               end if;

            when STAGE3_ST =>
               if phi2_d = '1' and phi2_i = '0' then
                  if c64_ram_addr_i = X"0108" then
                     state <= STAGE4_ST;
                  else
                     state <= IDLE_ST;
                  end if;
               end if;

            when STAGE4_ST =>
               if phi2_d = '1' and phi2_i = '0' then
                  if c64_ram_addr_i = X"0109" then
                     state <= STAGE5_ST;
                  else
                     state <= IDLE_ST;
                  end if;
               end if;

            when STAGE5_ST =>
               if phi2_d = '1' and phi2_i = '0' then
                  if c64_ram_addr_i = X"0013" then
                     state                <= DONE_ST;
                     is_an_EF3_standard_o <= '1';
                  else
                     state <= IDLE_ST;
                  end if;
               end if;

            when DONE_ST =>
               -- Stay here forever until next reset
               null;

            when others =>

         end case;

         if reset_core_n_i = '0' or cart_exrom_n_i = '1' or cart_game_n_i = '1' then
            state                <= IDLE_ST;
            is_an_EF3_standard_o <= '0';
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

