----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- This is part of the testbench for the sw_cartridge_wrapper module.
--
-- It provides the stimulus to run the simulation.
--
-- done by MJoergen in 2023 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity core_sim is
   port (
      main_clk_i          : in  std_logic;
      main_rst_i          : in  std_logic;
      main_reset_core_i   : in  std_logic;
      main_loading_i      : in  std_logic;
      main_id_i           : in  std_logic_vector(15 downto 0);
      main_exrom_i        : in  std_logic_vector( 7 downto 0);
      main_game_i         : in  std_logic_vector( 7 downto 0);
      main_size_i         : in  std_logic_vector(22 downto 0);
      main_bank_laddr_i   : in  std_logic_vector(15 downto 0);
      main_bank_size_i    : in  std_logic_vector(15 downto 0);
      main_bank_num_i     : in  std_logic_vector(15 downto 0);
      main_bank_raddr_i   : in  std_logic_vector(24 downto 0);
      main_bank_wr_i      : in  std_logic;
      main_bank_lo_o      : out std_logic_vector( 6 downto 0);
      main_bank_hi_o      : out std_logic_vector( 6 downto 0);
      main_bank_wait_i    : in  std_logic;
      main_ram_addr_o     : out std_logic_vector(15 downto 0);
      main_ram_data_o     : out std_logic_vector( 7 downto 0);
      main_ioe_we_o       : out std_logic;
      main_iof_we_o       : out std_logic;
      main_lo_ram_data_i  : in  std_logic_vector(15 downto 0);
      main_hi_ram_data_i  : in  std_logic_vector(15 downto 0);
      main_ioe_ram_data_i : in  std_logic_vector( 7 downto 0);
      main_iof_ram_data_i : in  std_logic_vector( 7 downto 0);
      main_running_o      : out std_logic := '1'
   );
end entity core_sim;

architecture simulation of core_sim is

   signal main_roml            : std_logic;
   signal main_romh            : std_logic;
   signal main_ioe             : std_logic;
   signal main_iof             : std_logic;
   signal main_ram_data_to_c64 : std_logic_vector(7 downto 0);
   signal main_wr_en           : std_logic;
   signal main_io_rom          : std_logic;
   signal main_exrom           : std_logic;
   signal main_game            : std_logic;

begin

   main_ram_data_to_c64 <= main_lo_ram_data_i(15 downto 8) when main_roml = '1' and main_ram_addr_o(0) = '1' else
                           main_lo_ram_data_i( 7 downto 0) when main_roml = '1' and main_ram_addr_o(0) = '0' else
                           main_hi_ram_data_i(15 downto 8) when main_romh = '1' and main_ram_addr_o(0) = '1' else
                           main_hi_ram_data_i( 7 downto 0) when main_romh = '1' and main_ram_addr_o(0) = '0' else
                           main_ioe_ram_data_i             when main_ioe  = '1'                              else
                           main_iof_ram_data_i             when main_iof  = '1'                              else
                           X"00";

   main_ioe_we_o   <= '0';
   main_iof_we_o   <= '0';
   main_ram_data_o <= X"00";
   main_wr_en      <= '0';
   main_ioe        <= '0';
   main_iof        <= '0';

   -- Simplified PLA
   main_roml <= '1' when main_ram_addr_o(15 downto 13) = "100"      -- 0x8000 - 0x9FFF
           else '0';
   main_romh <= '1' when main_ram_addr_o(15 downto 13) = "101"      -- 0xA000 - 0xBFFF
                      or main_ram_addr_o(15 downto 13) = "111"      -- 0xE000 - 0xFFFF
           else '0';


   i_cartridge : entity work.cartridge
      port map (
         clk_i          => main_clk_i,
         rst_i          => main_rst_i,
         cart_loading_i => main_loading_i,
         cart_id_i      => main_id_i,
         cart_exrom_i   => main_exrom_i,
         cart_game_i    => main_game_i,
         cart_size_i    => main_size_i,
         ioe_i          => main_ioe,
         iof_i          => main_iof,
         wr_en_i        => main_wr_en,
         wr_data_i      => main_ram_data_o,
         addr_i         => main_ram_addr_o,
         bank_lo_o      => main_bank_lo_o,
         bank_hi_o      => main_bank_hi_o,
         io_rom_o       => main_io_rom,
         exrom_o        => main_exrom,
         game_o         => main_game,
         freeze_key_i   => '0',
         mod_key_i      => '0',
         nmi_ack_i      => '0'
      ); -- i_cartridge

   p_test : process

      procedure c64_cpu_verify(addr : std_logic_vector(15 downto 0);
                               data : std_logic_vector( 7 downto 0)) is
      begin
         main_ram_addr_o <= addr;
         -- Wait 1 CPU cycle
         for i in 31 downto 0 loop
            wait until falling_edge(main_clk_i);
         end loop;
         assert main_ram_data_to_c64 = data
            report "ERROR: C64 Reading from address " & to_hstring(addr) &
               " returned " & to_hstring(main_ram_data_to_c64) & ", but expected " &
               to_hstring(data)
            severity error;
      end procedure c64_cpu_verify;

   begin

      main_ram_addr_o <= (others => '0');
      main_ram_data_o <= (others => '0');
      main_ioe_we_o   <= '0';
      main_iof_we_o   <= '0';
      wait until main_rst_i = '0';
      wait until main_reset_core_i = '0';
      report "Core out of reset.";
      wait for 2 us;

      c64_cpu_verify(X"FFFC", X"00");
      c64_cpu_verify(X"FFFD", X"E0");
      wait for 100 ns;

      main_running_o <= '0';
      report "Test finished";
      wait;
   end process p_test;

end architecture simulation;

