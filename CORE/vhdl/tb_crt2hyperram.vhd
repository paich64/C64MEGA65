library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module reads and parses the CRT file that is loaded into the HyperRAM device.
-- It stores header information and chip contents into various tables and BRAM.

-- This module runs in the HyperRAM clock domain, and therefore the BRAM
-- is placed outside this module.

-- It acts as a master towards both the HyperRAM and the BRAM.

entity tb_crt2hyperram is
   generic (
      G_INIT_FILE : string := "../../../../../../test.crt"
   );
end entity tb_crt2hyperram;

architecture simulation of tb_crt2hyperram is

   type bank_t is array (natural range 0 to 255) of std_logic_vector(6 downto 0);
   signal lobank : bank_t := (others => (others => '0'));
   signal hibank : bank_t := (others => (others => '0'));

   signal clk               : std_logic := '0';
   signal rst               : std_logic := '1';
   signal start             : std_logic;
   signal address           : std_logic_vector(21 downto 0);
   signal length            : std_logic_vector(21 downto 0);
   signal crt_bank_lo       : std_logic_vector( 6 downto 0);
   signal crt_bank_hi       : std_logic_vector( 6 downto 0);
   signal status            : std_logic_vector( 3 downto 0);
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

begin

   clk <= not clk after 5 ns;
   rst <= '1', '0' after 100 ns;

   i_crt2hyperram : entity work.crt2hyperram
      port map (
         clk_i               => clk,
         rst_i               => rst,
         start_i             => start,
         length_i            => length,
         address_i           => address,
         crt_bank_lo_i       => crt_bank_lo,
         crt_bank_hi_i       => crt_bank_hi,
         status_o            => status,
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
      ); -- i_crt2hyperram


   i_avm_rom : entity work.avm_rom
      generic map (
         G_INIT_FILE    => G_INIT_FILE,
         G_ADDRESS_SIZE => 16,
         G_DATA_SIZE    => 16
      )
      port map (
         clk_i               => clk,
         rst_i               => rst,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address(15 downto 0),
         avm_writedata_i     => avm_writedata,
         avm_byteenable_i    => avm_byteenable,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_o      => avm_readdata,
         avm_readdatavalid_o => avm_readdatavalid,
         avm_waitrequest_o   => avm_waitrequest
      );

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

   crt_bank_lo <= lobank(0);
   crt_bank_hi <= hibank(0);

   process
   begin
      start   <= '0';
      wait until rst = '0';
      wait until rising_edge(clk);
      address <= (others => '0');
      length  <= "00" & X"08060";
      start   <= '1';
      wait until rising_edge(clk);
      start   <= '0';
      wait;
   end process;

end architecture simulation;

