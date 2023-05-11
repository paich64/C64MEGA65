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

entity tester_sim is
   port (
      qnice_clk_i       : in  std_logic;
      qnice_rst_i       : in  std_logic;
      qnice_addr_o      : out std_logic_vector(27 downto 0);
      qnice_writedata_o : out std_logic_vector(15 downto 0);
      qnice_ce_o        : out std_logic;
      qnice_we_o        : out std_logic;
      qnice_readdata_i  : in  std_logic_vector(15 downto 0);
      qnice_wait_i      : in  std_logic;
      qnice_length_i    : in  natural;

      main_clk_i        : in  std_logic;
      main_rst_o        : out std_logic;
      tb_addr_o         : out std_logic_vector(15 downto 0);
      tb_data_o         : out std_logic_vector( 7 downto 0);
      tb_ioe_o          : out std_logic;
      tb_iof_o          : out std_logic;
      tb_loading_i      : in  std_logic;
      tb_bank_wait_i    : in  std_logic;
      tb_mem_write_o    : out std_logic;
      tb_ram_addr_o     : out std_logic_vector(15 downto 0);
      tb_ram_data_i     : in  std_logic_vector( 7 downto 0);
      tb_romh_o         : out std_logic;
      tb_roml_o         : out std_logic;
      tb_running_o      : out std_logic := '1'
   );
end entity tester_sim;

architecture simulation of tester_sim is

   signal tb_length : std_logic_vector(31 downto 0);

begin

   tb_addr_o       <= (others => '0');
   tb_data_o       <= (others => '0');
   tb_ioe_o        <= '0';
   tb_iof_o        <= '0';
   tb_mem_write_o  <= '0';

   -- Simplified PLA
   tb_roml_o <= '1' when tb_ram_addr_o(15 downto 13) = "100"      -- 0x8000 - 0x9FFF
           else '0';
   tb_romh_o <= '1' when tb_ram_addr_o(15 downto 13) = "101"      -- 0xA000 - 0xBFFF
                      or tb_ram_addr_o(15 downto 13) = "111"      -- 0xE000 - 0xFFFF
           else '0';

   tb_length <= std_logic_vector(to_unsigned(2*qnice_length_i, 32));

   p_test : process

      procedure qnice_cpu_write(addr : std_logic_vector(27 downto 0);
                                data : std_logic_vector(15 downto 0)) is
      begin
         qnice_addr_o      <= addr;
         qnice_writedata_o <= data;
         qnice_we_o        <= '1';
         qnice_ce_o        <= '1';
         wait until falling_edge(qnice_clk_i);
         while qnice_wait_i = '1' loop
            wait until falling_edge(qnice_clk_i);
         end loop;
         qnice_ce_o        <= '0';
      end procedure qnice_cpu_write;

      procedure qnice_cpu_verify(addr : std_logic_vector(27 downto 0);
                                 data : std_logic_vector(15 downto 0)) is
      begin
         qnice_addr_o      <= addr;
         qnice_we_o        <= '0';
         qnice_ce_o        <= '1';
         wait until falling_edge(qnice_clk_i);
         while qnice_wait_i = '1' loop
            wait until falling_edge(qnice_clk_i);
         end loop;
         assert qnice_readdata_i = data
            report "ERROR: QNICE Reading from address " & to_hstring(addr) &
               " returned " & to_hstring(qnice_readdata_i) & ", but expected " &
               to_hstring(data)
            severity error;
         qnice_ce_o        <= '0';
      end procedure qnice_cpu_verify;

      procedure c64_cpu_verify(addr : std_logic_vector(15 downto 0);
                               data : std_logic_vector( 7 downto 0)) is
      begin
         tb_ram_addr_o <= addr;
         -- Wait 1 CPU cycle
         for i in 31 downto 0 loop
            wait until falling_edge(main_clk_i);
         end loop;
         assert tb_ram_data_i = data
            report "ERROR: C64 Reading from address " & to_hstring(addr) &
               " returned " & to_hstring(tb_ram_data_i) & ", but expected " &
               to_hstring(data)
            severity error;
      end procedure c64_cpu_verify;

      constant C_CRT_STATUS    : std_logic_vector(27 downto 0) := X"FFFF000";
      constant C_CRT_FS_LO     : std_logic_vector(27 downto 0) := X"FFFF001";
      constant C_CRT_FS_HI     : std_logic_vector(27 downto 0) := X"FFFF002";
      constant C_CRT_PARSEST   : std_logic_vector(27 downto 0) := X"FFFF010";
      constant C_CRT_PARSEE1   : std_logic_vector(27 downto 0) := X"FFFF011";
      constant C_CRT_ADDR_LO   : std_logic_vector(27 downto 0) := X"FFFF012";
      constant C_CRT_ADDR_HI   : std_logic_vector(27 downto 0) := X"FFFF013";
      constant C_CRT_ERR_START : std_logic_vector(27 downto 0) := X"FFFF100";
      constant C_CRT_ERR_END   : std_logic_vector(27 downto 0) := X"FFFF1FF";

      -- Values for C_CRT_STATUS
      constant C_CRT_ST_IDLE   : std_logic_vector(15 downto 0) := X"0000";
      constant C_CRT_ST_LDNG   : std_logic_vector(15 downto 0) := X"0001";
      constant C_CRT_ST_ERR    : std_logic_vector(15 downto 0) := X"0002";
      constant C_CRT_ST_OK     : std_logic_vector(15 downto 0) := X"0003";

      -- Values for C_CRT_PARSEST
      constant C_STAT_IDLE     : std_logic_vector(15 downto 0) := X"0000";
      constant C_STAT_PARSING  : std_logic_vector(15 downto 0) := X"0001";
      constant C_STAT_READY    : std_logic_vector(15 downto 0) := X"0002"; -- Successfully parsed CRT file
      constant C_STAT_ERROR    : std_logic_vector(15 downto 0) := X"0003"; -- Error parsing CRT file

   begin

      tb_ram_addr_o <= (others => '0');
      main_rst_o    <= '1';
      qnice_ce_o    <= '0';
      wait until qnice_rst_i = '0';
      wait until falling_edge(qnice_clk_i);
      qnice_cpu_verify(C_CRT_PARSEST, C_STAT_IDLE);

      qnice_cpu_write(C_CRT_STATUS, C_CRT_ST_IDLE);
      qnice_cpu_write(C_CRT_FS_LO,  tb_length(15 downto  0));
      qnice_cpu_write(C_CRT_FS_HI,  tb_length(31 downto 16));
      qnice_cpu_write(C_CRT_STATUS, C_CRT_ST_OK);
      wait for 500 ns;
      wait until falling_edge(qnice_clk_i);

      qnice_cpu_verify(C_CRT_PARSEST, C_STAT_PARSING);
      wait until tb_loading_i = '0';
      wait until tb_bank_wait_i = '0';

      qnice_cpu_verify(C_CRT_PARSEST, C_STAT_READY);
      wait for 100 ns;

      main_rst_o <= '0';
      wait for 2 us;

      c64_cpu_verify(X"FFFC", X"00");
      c64_cpu_verify(X"FFFD", X"E0");
      wait for 100 ns;

      tb_running_o <= '0';
      report "Test finished";
      wait;
   end process p_test;

end architecture simulation;

