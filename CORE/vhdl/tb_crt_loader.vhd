library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module reads and parses the CRT file that is loaded into the HyperRAM device.
-- It stores header information and chip contents into various tables and BRAM.

-- This module runs in the HyperRAM clock domain, and therefore the BRAM
-- is placed outside this module.

-- It acts as a master towards both the HyperRAM and the BRAM.

entity tb_crt_loader is
end entity tb_crt_loader;

architecture simulation of tb_crt_loader is

   type word_vector is array (natural range <>) of std_logic_vector(15 downto 0);

   -- Expected result : File too short (incomplete CRT header)
   constant C_TEST0 : word_vector(0 to 255) := (
      X"3643", X"2034", X"4143", X"5452",
      X"4952", X"4744", X"2045", others => X"0000");

   -- Expected result : Invalid CRT header
   constant C_TEST1 : word_vector(0 to 255) := (
      X"3643", X"2034", X"4143", X"5452",
      X"4952", X"4744", X"2045", X"2120",
      X"0000", X"4000", X"0001", X"1300", others => X"0000");

   -- Expected result : File too short (despite complete CRT header)
   constant C_TEST2 : word_vector(0 to 255) := (
      X"3643", X"2034", X"4143", X"5452",
      X"4952", X"4744", X"2045", X"2020",
      X"0000", X"4000", X"0001", X"1300", others => X"0000");

   -- Expected result : File too short
   constant C_TEST3 : word_vector(0 to 255) := (
      X"3643", X"2034", X"4143", X"5452",
      X"4952", X"4744", X"2045", X"2020",
      X"0000", X"4000", X"0001", X"1300", others => X"0000");

   type test_type is record
      data        : word_vector;
      length      : integer;
      exp_status  : integer;
      exp_error   : integer;
      exp_address : integer;
   end record;

   type test_vector is array (natural range <>) of test_type;
   constant C_TESTS : test_vector := (
      (C_TEST0, 14, 3, 1, 0),
      (C_TEST1, 64, 3, 2, 0),
      (C_TEST2, 62, 3, 1, 0),
      (C_TEST3, 64, 3, 1, 64));

   type bank_t is array (natural range 0 to 255) of std_logic_vector(6 downto 0);
   signal lobank : bank_t := (others => (others => '0'));
   signal hibank : bank_t := (others => (others => '0'));

   signal clk               : std_logic := '0';
   signal rst               : std_logic := '1';
   signal req_start         : std_logic;
   signal req_address       : std_logic_vector(21 downto 0);
   signal req_length        : std_logic_vector(22 downto 0);
   signal resp_status       : std_logic_vector( 3 downto 0);
   signal resp_error        : std_logic_vector( 3 downto 0);
   signal resp_address      : std_logic_vector(22 downto 0);
   signal bank_lo           : std_logic_vector( 6 downto 0);
   signal bank_hi           : std_logic_vector( 6 downto 0);
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(21 downto 0);
   signal avm_writedata     : std_logic_vector(15 downto 0);
   signal avm_byteenable    : std_logic_vector( 1 downto 0);
   signal avm_burstcount    : std_logic_vector( 7 downto 0);
   signal avm_readdata      : std_logic_vector(15 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;
   signal cart_bank_laddr   : std_logic_vector(15 downto 0);
   signal cart_bank_size    : std_logic_vector(15 downto 0);
   signal cart_bank_num     : std_logic_vector(15 downto 0);
   signal cart_bank_raddr   : std_logic_vector(24 downto 0);
   signal cart_bank_wr      : std_logic;
   signal cart_loading      : std_logic;
   signal cart_id           : std_logic_vector(15 downto 0);
   signal cart_exrom        : std_logic_vector( 7 downto 0);
   signal cart_game         : std_logic_vector( 7 downto 0);
   signal bram_address      : std_logic_vector(11 downto 0);
   signal bram_data         : std_logic_vector(15 downto 0);
   signal bram_lo_wren      : std_logic;
   signal bram_lo_q         : std_logic_vector(15 downto 0);
   signal bram_hi_wren      : std_logic;
   signal bram_hi_q         : std_logic_vector(15 downto 0);
   signal test_num          : integer := 0;
   signal running           : std_logic := '1';
   signal burst             : integer;
   signal offset            : integer := 0;

begin

   clk <= running and not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   i_crt_loader : entity work.crt_loader
      port map (
         clk_i               => clk,
         rst_i               => rst,
         req_start_i         => req_start,
         req_length_i        => req_length,
         req_address_i       => req_address,
         resp_status_o       => resp_status,
         resp_error_o        => resp_error,
         resp_address_o      => resp_address,
         bank_lo_i           => bank_lo,
         bank_hi_i           => bank_hi,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_byteenable_o    => avm_byteenable,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest,
         cart_bank_laddr_o   => cart_bank_laddr,
         cart_bank_size_o    => cart_bank_size,
         cart_bank_num_o     => cart_bank_num,
         cart_bank_raddr_o   => cart_bank_raddr,
         cart_bank_wr_o      => cart_bank_wr,
         cart_loading_o      => cart_loading,
         cart_id_o           => cart_id,
         cart_exrom_o        => cart_exrom,
         cart_game_o         => cart_game,
         bram_address_o      => bram_address,
         bram_data_o         => bram_data,
         bram_lo_wren_o      => bram_lo_wren,
         bram_lo_q_i         => bram_lo_q,
         bram_hi_wren_o      => bram_hi_wren,
         bram_hi_q_i         => bram_hi_q
      ); -- i_crt_loader

   process (clk)
   begin
      if rising_edge(clk) then
         avm_waitrequest   <= '0';
         if avm_read = '1' then
            burst  <= to_integer(avm_burstcount);
            offset <= 1;
            avm_readdata   <= C_TESTS(test_num).data(to_integer(avm_address(7 downto 0)));
            avm_readdatavalid <= '1';
         elsif offset < burst then
            offset <= offset + 1;
            avm_readdata      <= C_TESTS(test_num).data(to_integer(avm_address(7 downto 0)) + offset);
            avm_readdatavalid <= '1';
         else
            avm_readdatavalid <= '0';
         end if;
      end if;
   end process;

   process (clk)
   begin
      if rising_edge(clk) then
         if cart_bank_wr = '1' then
            if cart_bank_laddr = X"8000" then
               report "Writing " & to_hstring(cart_bank_raddr) & " to LO bank";
               lobank(to_integer(cart_bank_num)) <= cart_bank_raddr(21 downto 15);
            else
               report "Writing " & to_hstring(cart_bank_raddr) & " to HI bank";
               hibank(to_integer(cart_bank_num)) <= cart_bank_raddr(21 downto 15);
            end if;
         end if;
      end if;
   end process;

   bank_lo <= lobank(0);
   bank_hi <= hibank(0);

   process
   begin
      req_start <= '0';
      wait until rst = '0';
      wait until rising_edge(clk);

      for i in 0 to C_TESTS'length-1 loop
         report "Test #" & to_string(i);
         test_num    <= i;
         req_address <= "01" & X"00000";
         req_length  <= std_logic_vector(to_unsigned(C_TESTS(i).length, 23));
         req_start   <= '1';
         wait until rising_edge(clk);
         wait until cart_loading = '0' or resp_status(1) = '1';
         if resp_status /= C_TESTS(test_num).exp_status then
            report "Status is " & to_string(resp_status) & ", but expected " & to_string(C_TESTS(test_num).exp_status);
            wait until rising_edge(clk);
            running <= '0';
         end if;

         if resp_error /= C_TESTS(test_num).exp_error then
            report "Error is " & to_string(resp_error) & ", but expected " & to_string(C_TESTS(test_num).exp_error);
            wait until rising_edge(clk);
            running <= '0';
         end if;

         if resp_address /= C_TESTS(test_num).exp_address then
            report "Address is " & to_hstring(resp_address) & ", but expected " & to_hstring(to_unsigned(C_TESTS(test_num).exp_address, 22));
            wait until rising_edge(clk);
            running <= '0';
         end if;

         req_start   <= '0';
         wait until rising_edge(clk);
         wait for 100 ns;
         wait until rising_edge(clk);
      end loop;

      running <= '0';
      report "Finished";
      wait;
   end process;

end architecture simulation;

