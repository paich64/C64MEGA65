library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module connects the HyperRAM device to the internal BRAM cache
-- It acts as a master towards both the HyperRAM and the BRAM.

entity crt2hyperram is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;

      -- Control interface
      crt_busy_o          : out std_logic;
      crt_hi_load_i       : in  std_logic;
      crt_hi_address_i    : in  std_logic_vector(31 downto 0);
      crt_lo_load_i       : in  std_logic;
      crt_lo_address_i    : in  std_logic_vector(31 downto 0);

      -- Connect to HyperRAM
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(31 downto 0);
      avm_writedata_o     : out std_logic_vector(15 downto 0);
      avm_byteenable_o    : out std_logic_vector(1 downto 0);
      avm_burstcount_o    : out std_logic_vector(7 downto 0);
      avm_readdata_i      : in  std_logic_vector(15 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;

      -- Connect to BRAM (8kB)
      bram_lo_address_o   : out std_logic_vector(12 downto 0);
      bram_lo_data_o      : out std_logic_vector(7 downto 0);
      bram_lo_wren_o      : out std_logic;
      bram_lo_q_i         : in  std_logic_vector(7 downto 0);

      -- Connect to BRAM (8kB)
      bram_hi_address_o   : out std_logic_vector(12 downto 0);
      bram_hi_data_o      : out std_logic_vector(7 downto 0);
      bram_hi_wren_o      : out std_logic;
      bram_hi_q_i         : in  std_logic_vector(7 downto 0)
   );
end entity crt2hyperram;

architecture synthesis of crt2hyperram is

   type t_state is (IDLE_ST, READ_LSB_ST, READ_MSB_ST);

   signal state       : t_state := IDLE_ST;
   signal fifo_ready  : std_logic;
   signal fifo_valid  : std_logic;
   signal fifo_data   : std_logic_vector(15 downto 0);

   attribute mark_debug : string;
   attribute mark_debug of crt_busy_o          : signal is "true";
   attribute mark_debug of crt_hi_load_i       : signal is "true";
   attribute mark_debug of crt_hi_address_i    : signal is "true";
   attribute mark_debug of crt_lo_load_i       : signal is "true";
   attribute mark_debug of crt_lo_address_i    : signal is "true";
   attribute mark_debug of avm_write_o         : signal is "true";
   attribute mark_debug of avm_read_o          : signal is "true";
   attribute mark_debug of avm_address_o       : signal is "true";
   attribute mark_debug of avm_writedata_o     : signal is "true";
   attribute mark_debug of avm_byteenable_o    : signal is "true";
   attribute mark_debug of avm_burstcount_o    : signal is "true";
   attribute mark_debug of avm_readdata_i      : signal is "true";
   attribute mark_debug of avm_readdatavalid_i : signal is "true";
   attribute mark_debug of avm_waitrequest_i   : signal is "true";
   attribute mark_debug of bram_lo_address_o   : signal is "true";
   attribute mark_debug of bram_lo_data_o      : signal is "true";
   attribute mark_debug of bram_lo_wren_o      : signal is "true";
   attribute mark_debug of bram_lo_q_i         : signal is "true";
   attribute mark_debug of bram_hi_address_o   : signal is "true";
   attribute mark_debug of bram_hi_data_o      : signal is "true";
   attribute mark_debug of bram_hi_wren_o      : signal is "true";
   attribute mark_debug of bram_hi_q_i         : signal is "true";
   attribute mark_debug of state               : signal is "true";
   attribute mark_debug of fifo_ready          : signal is "true";
   attribute mark_debug of fifo_valid          : signal is "true";
   attribute mark_debug of fifo_data           : signal is "true";

begin

   crt_busy_o <= '0' when state = IDLE_ST else '1';
   fifo_ready <= '1' when state = READ_MSB_ST else '0';

   p_master : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         bram_hi_wren_o <= '0';

         case state is
            when IDLE_ST =>
               if crt_hi_load_i = '1' then
                  report "Starting load to Hi BRAM from address " & to_hstring(crt_hi_address_i);
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  avm_address_o      <= crt_hi_address_i;
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_lo_address_o  <= (others => '1');
                  state              <= READ_LSB_ST;
               end if;

            when READ_LSB_ST =>
               if fifo_valid = '1' then
                  bram_hi_data_o    <= fifo_data(7 downto 0);
                  bram_hi_wren_o    <= '1';
                  bram_lo_address_o <= bram_lo_address_o + 1;
                  state             <= READ_MSB_ST;
               end if;

            when READ_MSB_ST =>
               assert fifo_valid = '1';
               bram_hi_data_o    <= fifo_data(15 downto 8);
               bram_hi_wren_o    <= '1';
               bram_lo_address_o <= bram_lo_address_o + 1;
               state             <= READ_LSB_ST;

               if "000" & bram_lo_address_o = X"1FFE" then
                  state          <= IDLE_ST;
               elsif bram_lo_address_o(7 downto 0) = X"FE" then
                  avm_write_o      <= '0';
                  avm_read_o       <= '1';
                  avm_address_o    <= avm_address_o + X"80";
                  avm_burstcount_o <= X"80"; -- Read 256 bytes
               end if;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            avm_write_o      <= '0';
            avm_read_o       <= '0';
            avm_address_o    <= (others => '0');
            avm_writedata_o  <= (others => '0');
            avm_byteenable_o <= (others => '0');
            avm_burstcount_o <= (others => '0');
            state            <= IDLE_ST;
         end if;

      end if;
   end process p_master;

   -- We store the read data from the HyperRAM
   -- in a FIFO, because we receive 2 bytes at a time,
   -- but can only write 1 byte at a time.
   i_axi_fifo_small : entity work.axi_fifo_small
      generic map (
         G_RAM_WIDTH => 16,
         G_RAM_DEPTH => 128
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_ready_o => open,
         s_valid_i => avm_readdatavalid_i,
         s_data_i  => avm_readdata_i,
         m_ready_i => fifo_ready,
         m_valid_o => fifo_valid,
         m_data_o  => fifo_data
      ); -- i_axi_fifo_small

end architecture synthesis;

