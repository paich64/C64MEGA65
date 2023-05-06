library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module loads and caches the active banks into BRAM.

-- This module runs entirely in the HyperRAM clock domain, and therefore the BRAM
-- is placed outside this module.

-- It acts as a master towards both the HyperRAM and the BRAM.
-- The maximum amount of addressable HyperRAM is 22 address bits @ 16 data bits, i.e. 8 MB of memory.
-- Not all this memory will be available to the CRT file, though.
-- The CRT file is stored in little-endian format, i.e. even address bytes are in bits 7-0 and
-- odd address bytes are in bits 15-8.

-- bank_lo_i and bank_hi_i are in units of 8kB.

entity crt_cacher is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;

      -- Control interface (PARSER)
      cart_valid_i        : in  std_logic;
      cart_bank_laddr_i   : in  std_logic_vector(15 downto 0);
      cart_bank_size_i    : in  std_logic_vector(15 downto 0);
      cart_bank_num_i     : in  std_logic_vector(15 downto 0);
      cart_bank_raddr_i   : in  std_logic_vector(24 downto 0);     -- Byte address
      cart_bank_wr_i      : in  std_logic;

      -- Control interface (CORE)
      bank_lo_i           : in  std_logic_vector( 6 downto 0);     -- Current location in HyperRAM of bank LO
      bank_hi_i           : in  std_logic_vector( 6 downto 0);     -- Current location in HyperRAM of bank HI
      bank_wait_o         : out std_logic;                         -- Asserted when cache is being updated

      -- Connect to HyperRAM
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(21 downto 0);
      avm_writedata_o     : out std_logic_vector(15 downto 0);
      avm_byteenable_o    : out std_logic_vector( 1 downto 0);
      avm_burstcount_o    : out std_logic_vector( 7 downto 0);
      avm_readdata_i      : in  std_logic_vector(15 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;

      -- Connect to BRAM (2*8kB)
      bram_address_o      : out std_logic_vector(11 downto 0);
      bram_data_o         : out std_logic_vector(15 downto 0);
      bram_lo_wren_o      : out std_logic;
      bram_lo_q_i         : in  std_logic_vector(15 downto 0);
      bram_hi_wren_o      : out std_logic;
      bram_hi_q_i         : in  std_logic_vector(15 downto 0)
   );
end entity crt_cacher;

architecture synthesis of crt_cacher is

   type t_state is (IDLE_ST,
                    READ_HI_ST,
                    READ_LO_ST);
   signal state         : t_state := IDLE_ST;

   type mem_t is array (natural range <>) of std_logic_vector(22 downto 0);
   -- Contains byte-address in HyperRAM of each bank location.
   signal lobanks : mem_t(0 to 63) := (others => (others => '0'));
   signal hibanks : mem_t(0 to 63) := (others => (others => '0'));

   signal cart_valid_d  : std_logic;
   signal bank_lo_d     : std_logic_vector(6 downto 0);
   signal bank_hi_d     : std_logic_vector(6 downto 0);
   signal hi_load       : std_logic;
   signal hi_load_done  : std_logic;
   signal lo_load       : std_logic;
   signal lo_load_done  : std_logic;
   signal restart       : std_logic;

   attribute mark_debug : string;
   attribute mark_debug of cart_valid_i        : signal is "true";
   attribute mark_debug of cart_bank_laddr_i   : signal is "true";
   attribute mark_debug of cart_bank_size_i    : signal is "true";
   attribute mark_debug of cart_bank_num_i     : signal is "true";
   attribute mark_debug of cart_bank_raddr_i   : signal is "true";
   attribute mark_debug of cart_bank_wr_i      : signal is "true";
   attribute mark_debug of bank_lo_i           : signal is "true";
   attribute mark_debug of bank_hi_i           : signal is "true";
   attribute mark_debug of avm_write_o         : signal is "true";
   attribute mark_debug of avm_read_o          : signal is "true";
   attribute mark_debug of avm_address_o       : signal is "true";
   attribute mark_debug of avm_writedata_o     : signal is "true";
   attribute mark_debug of avm_byteenable_o    : signal is "true";
   attribute mark_debug of avm_burstcount_o    : signal is "true";
   attribute mark_debug of avm_readdata_i      : signal is "true";
   attribute mark_debug of avm_readdatavalid_i : signal is "true";
   attribute mark_debug of avm_waitrequest_i   : signal is "true";
   attribute mark_debug of bram_address_o      : signal is "true";
   attribute mark_debug of bram_data_o         : signal is "true";
   attribute mark_debug of bram_lo_wren_o      : signal is "true";
   attribute mark_debug of bram_hi_wren_o      : signal is "true";
   attribute mark_debug of state               : signal is "true";
   attribute mark_debug of hi_load             : signal is "true";
   attribute mark_debug of hi_load_done        : signal is "true";
   attribute mark_debug of lo_load             : signal is "true";
   attribute mark_debug of lo_load_done        : signal is "true";
   attribute mark_debug of restart             : signal is "true";

begin

   bank_wait_o <= '1' when state = READ_HI_ST
                        or state = READ_LO_ST
                        or hi_load = '1'
                        or lo_load = '1'
             else '0';

   -- Even though MiSTer implements a similar mapping in the file cartridge.v, MiSTer's
   -- implementation only stores the upper bits of the HyperRAM address, which is not
   -- enough for us. Therefore we replicate the mapping here, but retain the complete
   -- HyperRAM address.
   p_banks : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cart_bank_wr_i = '1' then
            if cart_bank_laddr_i <= X"8000" then
               lobanks(to_integer(cart_bank_num_i(5 downto 0))) <= cart_bank_raddr_i(22 downto 0);
               if cart_bank_size_i > X"2000" then
                  hibanks(to_integer(cart_bank_num_i(5 downto 0))) <= cart_bank_raddr_i(22 downto 0)+ ("000" & X"02000");
               end if;
            else
               hibanks(to_integer(cart_bank_num_i(5 downto 0))) <= cart_bank_raddr_i(22 downto 0);
            end if;
         end if;
      end if;
   end process p_banks;


   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         bram_lo_wren_o <= '0';
         bram_hi_wren_o <= '0';
         hi_load_done   <= '0';
         lo_load_done   <= '0';

         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         case state is
            when IDLE_ST =>
               if hi_load = '1' and hi_load_done = '0' then
                  -- Starting load to HI bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  -- Convert byte address to word address used by HyperRAM
                  avm_address_o      <= hibanks(to_integer(bank_hi_i))(22 downto 1);
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_address_o     <= (others => '1');
                  state              <= READ_HI_ST;
               elsif lo_load = '1' and lo_load_done = '0' then
                  -- Starting load to LO bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  -- Convert byte address to word address used by HyperRAM
                  avm_address_o      <= lobanks(to_integer(bank_lo_i))(22 downto 1);
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_address_o     <= (others => '1');
                  state              <= READ_LO_ST;
               end if;

            when READ_HI_ST =>
               if avm_readdatavalid_i = '1' then
                  bram_data_o    <= avm_readdata_i;
                  bram_hi_wren_o <= '1';
                  bram_address_o <= bram_address_o + 1;
                  if bram_address_o = X"FFE" then
                     hi_load_done <= '1';
                     state        <= IDLE_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     if restart = '1' then
                        state <= IDLE_ST;
                     else
                        avm_write_o      <= '0';
                        avm_read_o       <= '1';
                        avm_address_o    <= avm_address_o + X"80";
                        avm_burstcount_o <= X"80"; -- Read 256 bytes
                     end if;
                  end if;
               end if;

            when READ_LO_ST =>
               if avm_readdatavalid_i = '1' then
                  bram_data_o    <= avm_readdata_i;
                  bram_lo_wren_o <= '1';
                  bram_address_o <= bram_address_o + 1;
                  if bram_address_o = X"FFE" then
                     lo_load_done <= '1';
                     state        <= IDLE_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     if restart = '1' then
                        state <= IDLE_ST;
                     else
                        avm_write_o      <= '0';
                        avm_read_o       <= '1';
                        avm_address_o    <= avm_address_o + X"80";
                        avm_burstcount_o <= X"80"; -- Read 256 bytes
                     end if;
                  end if;
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
            bram_address_o   <= (others => '0');
            bram_data_o      <= (others => '0');
            bram_lo_wren_o   <= '0';
            bram_hi_wren_o   <= '0';
            state            <= IDLE_ST;
         end if;

      end if;
   end process p_fsm;

   p_crt_load : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cart_valid_d <= cart_valid_i;
         bank_lo_d    <= bank_lo_i;
         bank_hi_d    <= bank_hi_i;

         if lo_load_done = '1' then
            lo_load <= '0';
         end if;
         if hi_load_done = '1' then
            hi_load <= '0';
         end if;

         if cart_valid_i = '1' then
            -- Detect change in bank addresses
            if bank_lo_d /= bank_lo_i then
               lo_load <= '1';
               restart <= '1';
            end if;
            if bank_hi_d /= bank_hi_i then
               hi_load <= '1';
               restart <= '1';
            end if;
         end if;

         if cart_valid_d = '0' and cart_valid_i = '1' then
            lo_load <= '1';
            hi_load <= '1';
         end if;

         if state = IDLE_ST then
            restart <= '0';
         end if;

         if rst_i = '1' then
            lo_load <= '0';
            hi_load <= '0';
            restart <= '0';
         end if;
      end if;
   end process p_crt_load;

end architecture synthesis;

