library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module reads and parses the CRT file that is loaded into the HyperRAM device.
-- It stores header information and chip contents into various tables and BRAM.

-- This module runs in the HyperRAM clock domain, and therefore the BRAM
-- is placed outside this module.

-- It acts as a master towards both the HyperRAM and the BRAM.

entity crt2hyperram is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;

      -- Control interface
      start_i             : in  std_logic;
      address_i           : in  std_logic_vector(21 downto 0);     -- Address in HyperRAM of start of CRT file
      length_i            : in  std_logic_vector(21 downto 0);     -- Length of CRT file in HyperRAM
      crt_bank_lo_i       : in  std_logic_vector( 6 downto 0);     -- Current location in HyperRAM of bank LO
      crt_bank_hi_i       : in  std_logic_vector( 6 downto 0);     -- Current location in HyperRAM of bank HI
      status_o            : out std_logic_vector( 3 downto 0);

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

      -- Connect to cartridge.v
      cart_bank_laddr_o   : out std_logic_vector(15 downto 0);     -- bank loading address
      cart_bank_size_o    : out std_logic_vector(15 downto 0);     -- length of each bank
      cart_bank_num_o     : out std_logic_vector(15 downto 0);
      cart_bank_raddr_o   : out std_logic_vector(24 downto 0);     -- chip packet address
      cart_bank_wr_o      : out std_logic;
      cart_loading_o      : out std_logic;
      cart_id_o           : out std_logic_vector(15 downto 0);     -- cart ID or cart type
      cart_exrom_o        : out std_logic_vector( 7 downto 0);     -- CRT file EXROM status
      cart_game_o         : out std_logic_vector( 7 downto 0);     -- CRT file GAME status

      -- Connect to BRAM (2*8kB)
      bram_address_o      : out std_logic_vector(11 downto 0);
      bram_data_o         : out std_logic_vector(15 downto 0);
      bram_lo_wren_o      : out std_logic;
      bram_lo_q_i         : in  std_logic_vector(15 downto 0);
      bram_hi_wren_o      : out std_logic;
      bram_hi_q_i         : in  std_logic_vector(15 downto 0)
   );
end entity crt2hyperram;

architecture synthesis of crt2hyperram is

   constant C_STAT_IDLE         : std_logic_vector(3 downto 0) := "0000";
   constant C_STAT_PARSING      : std_logic_vector(3 downto 0) := "0001";
   constant C_STAT_READY        : std_logic_vector(3 downto 0) := "0010"; -- Successfully parsed CRT file
   constant C_STAT_ERR_LENGTH   : std_logic_vector(3 downto 0) := "1000"; -- Invalid file length
   constant C_STAT_ERR_CRT_HDR  : std_logic_vector(3 downto 0) := "1001"; -- Missing CRT header
   constant C_STAT_ERR_CHIP_HDR : std_logic_vector(3 downto 0) := "1010"; -- Missing CHIP header

   subtype R_CRT_FILE_HEADER_LENGTH is natural range  4*8-1 downto  0*8;
   subtype R_CRT_CARTRIDGE_VERSION  is natural range  6*8-1 downto  4*8;
   subtype R_CRT_CARTRIDGE_TYPE     is natural range  8*8-1 downto  6*8;
   subtype R_CRT_EXROM              is natural range  9*8-1 downto  8*8;
   subtype R_CRT_GAME               is natural range 10*8-1 downto  9*8;

   subtype R_CHIP_SIGNATURE         is natural range  4*8-1 downto  0*8;
   subtype R_CHIP_LENGTH            is natural range  8*8-1 downto  4*8;
   subtype R_CHIP_TYPE              is natural range 10*8-1 downto  8*8;
   subtype R_CHIP_BANK_NUMBER       is natural range 12*8-1 downto 10*8;
   subtype R_CHIP_LOAD_ADDRESS      is natural range 14*8-1 downto 12*8;
   subtype R_CHIP_IMAGE_SIZE        is natural range 16*8-1 downto 14*8;

   type t_state is (IDLE_ST,
                    WAIT_FOR_CRT_HEADER_00_ST,
                    WAIT_FOR_CRT_HEADER_10_ST,
                    WAIT_FOR_CHIP_HEADER_ST,
                    READY_ST,
                    READ_HI_ST,
                    READ_LO_ST,
                    ERROR_ST);
   signal base_address     : std_logic_vector(21 downto 0);
   signal state            : t_state := IDLE_ST;
   signal read_pos         : integer range 0 to 7;
   signal wide_readdata    : std_logic_vector(127 downto 0);
   signal crt_bank_lo_d    : std_logic_vector(6 downto 0);
   signal crt_bank_hi_d    : std_logic_vector(6 downto 0);
   signal crt_hi_load      : std_logic;
   signal crt_hi_load_done : std_logic;
   signal crt_lo_load      : std_logic;
   signal crt_lo_load_done : std_logic;
   signal remaining_size   : std_logic_vector(21 downto 0);

   -- Convert an ASCII string to std_logic_vector
   pure function str2slv(s : string) return std_logic_vector is
      variable res : std_logic_vector(s'length*8-1 downto 0);
   begin
      for i in 0 to s'length-1 loop
         res(8*i+7 downto 8*i) := to_stdlogicvector(character'pos(s(i+1)), 8);
      end loop;
      return res;
   end function str2slv;

   -- purpose: byteswap a vector
   pure function bswap (din : std_logic_vector) return std_logic_vector is
      variable swapped : std_logic_vector(din'length-1 downto 0);
      variable input   : std_logic_vector(din'length-1 downto 0);
   begin  -- function bswap
      -- normalize din to start at zero and to have downto as direction
      for i in 0 to din'length-1 loop
         input(i) := din(i+din'low);
      end loop;  -- i
      for i in 0 to din'length/8-1 loop
         swapped(swapped'high-i*8 downto swapped'high-i*8-7) := input(i*8+7 downto i*8);
      end loop;  -- i
      return swapped;
   end function bswap;

--attribute mark_debug : string;
--attribute mark_debug of start_i             : signal is "true";
--attribute mark_debug of address_i           : signal is "true";
--attribute mark_debug of crt_bank_lo_i       : signal is "true";
--attribute mark_debug of crt_bank_hi_i       : signal is "true";
--attribute mark_debug of avm_write_o         : signal is "true";
--attribute mark_debug of avm_read_o          : signal is "true";
--attribute mark_debug of avm_address_o       : signal is "true";
--attribute mark_debug of avm_writedata_o     : signal is "true";
--attribute mark_debug of avm_byteenable_o    : signal is "true";
--attribute mark_debug of avm_burstcount_o    : signal is "true";
--attribute mark_debug of avm_readdata_i      : signal is "true";
--attribute mark_debug of avm_readdatavalid_i : signal is "true";
--attribute mark_debug of avm_waitrequest_i   : signal is "true";
--attribute mark_debug of cart_bank_laddr_o   : signal is "true";
--attribute mark_debug of cart_bank_size_o    : signal is "true";
--attribute mark_debug of cart_bank_num_o     : signal is "true";
--attribute mark_debug of cart_bank_raddr_o   : signal is "true";
--attribute mark_debug of cart_bank_wr_o      : signal is "true";
--attribute mark_debug of cart_loading_o      : signal is "true";
--attribute mark_debug of cart_id_o           : signal is "true";
--attribute mark_debug of cart_exrom_o        : signal is "true";
--attribute mark_debug of cart_game_o         : signal is "true";
--attribute mark_debug of bram_address_o      : signal is "true";
--attribute mark_debug of bram_data_o         : signal is "true";
--attribute mark_debug of bram_lo_wren_o      : signal is "true";
--attribute mark_debug of bram_lo_q_i         : signal is "true";
--attribute mark_debug of bram_hi_wren_o      : signal is "true";
--attribute mark_debug of bram_hi_q_i         : signal is "true";
--attribute mark_debug of state               : signal is "true";
--attribute mark_debug of crt_hi_load         : signal is "true";
--attribute mark_debug of crt_hi_load_done    : signal is "true";
--attribute mark_debug of crt_lo_load         : signal is "true";
--attribute mark_debug of crt_lo_load_done    : signal is "true";

begin

   cart_loading_o <= '0' when state = IDLE_ST or
                              state = ERROR_ST or
                             (state = READY_ST and crt_lo_load = '0' and crt_hi_load = '0') else
                     '1';

   p_fsm : process (clk_i)
      variable file_header_length_v : std_logic_vector(31 downto 0);
      variable image_size_v         : std_logic_vector(15 downto 0);
      variable wide_readdata_v      : std_logic_vector(127 downto 0);
      variable read_addr_v          : std_logic_vector(21 downto 0);
      variable offset_v             : natural;
   begin
      if rising_edge(clk_i) then
         cart_bank_wr_o   <= '0';
         bram_lo_wren_o   <= '0';
         bram_hi_wren_o   <= '0';
         crt_hi_load_done <= '0';
         crt_lo_load_done <= '0';

         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         -- Gather together 16 bytes of data.
         -- This is just to make the following state machine simpler,
         -- i.e. we can process more data at a time.
         wide_readdata_v := wide_readdata;
         if avm_readdatavalid_i = '1' then
            wide_readdata_v(16*read_pos + 15 downto 16*read_pos) := avm_readdata_i;
            wide_readdata <= wide_readdata_v;

            if read_pos = 7 then
               read_pos <= 0;
            else
               read_pos <= read_pos + 1;
            end if;
         end if;

         case state is
            when IDLE_ST =>
               if start_i = '1' then
                  if length_i >= X"00040" then
                     -- Read first 0x20 bytes of CRT header
                     avm_address_o    <= address_i;
                     avm_read_o       <= '1';
                     avm_burstcount_o <= X"10";
                     remaining_size   <= length_i;
                     status_o         <= C_STAT_PARSING;
                     state            <= WAIT_FOR_CRT_HEADER_00_ST;
                  else
                     status_o <= C_STAT_ERR_LENGTH;
                     state    <= ERROR_ST;
                  end if;
               end if;

            when WAIT_FOR_CRT_HEADER_00_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  if wide_readdata_v = str2slv("C64 CARTRIDGE   ") then
                     state <= WAIT_FOR_CRT_HEADER_10_ST;
                  else
                     status_o <= C_STAT_ERR_CRT_HDR;
                     state    <= ERROR_ST;
                  end if;
               end if;

            when WAIT_FOR_CRT_HEADER_10_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  cart_id_o    <= bswap(wide_readdata_v(R_CRT_CARTRIDGE_TYPE));
                  cart_exrom_o <= wide_readdata_v(R_CRT_EXROM);
                  cart_game_o  <= wide_readdata_v(R_CRT_GAME);
                  file_header_length_v := bswap(wide_readdata_v(R_CRT_FILE_HEADER_LENGTH));

                  if length_i >= file_header_length_v(22 downto 1) + X"10" then
                     -- Read 0x10 bytes from CHIP header
                     avm_address_o    <= avm_address_o + file_header_length_v(22 downto 1);
                     avm_read_o       <= '1';
                     avm_burstcount_o <= X"08";
                     base_address     <= avm_address_o + file_header_length_v(22 downto 1) + X"08";
                     remaining_size   <= remaining_size - file_header_length_v(22 downto 1);
                     state <= WAIT_FOR_CHIP_HEADER_ST;
                  else
                     status_o <= C_STAT_ERR_LENGTH;
                     state    <= ERROR_ST;
                  end if;
               end if;

            when WAIT_FOR_CHIP_HEADER_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  -- For now, assume error
                  status_o <= C_STAT_ERR_CHIP_HDR;
                  state    <= ERROR_ST;

                  if wide_readdata_v(R_CHIP_SIGNATURE) = str2slv("CHIP") then
                     cart_bank_laddr_o <= bswap(wide_readdata_v(R_CHIP_LOAD_ADDRESS));
                     cart_bank_size_o  <= bswap(wide_readdata_v(R_CHIP_IMAGE_SIZE));
                     cart_bank_num_o   <= bswap(wide_readdata_v(R_CHIP_BANK_NUMBER));
                     read_addr_v := avm_address_o + X"08";
                     cart_bank_raddr_o <= (others => '0');
                     cart_bank_raddr_o(22 downto 1) <= read_addr_v - base_address;
                     cart_bank_wr_o    <= '1';

                     -- OK, assume we're done now
                     status_o         <= C_STAT_READY;
                     state            <= READY_ST;

                     image_size_v := bswap(wide_readdata_v(R_CHIP_IMAGE_SIZE));
                     if remaining_size >= X"08" + image_size_v(15 downto 1) then
                        -- Oh, there's more ...
                        avm_address_o    <= avm_address_o + X"08" + image_size_v(15 downto 1);
                        avm_read_o       <= '1';
                        avm_burstcount_o <= X"08";
                        remaining_size   <= remaining_size - (X"08" + image_size_v(15 downto 1));
                        status_o         <= C_STAT_PARSING;
                        state            <= WAIT_FOR_CHIP_HEADER_ST;
                     end if;
                  end if;
               end if;

            when READY_ST =>
               if crt_hi_load = '1' and crt_hi_load_done = '0' then
                  -- Starting load to HI bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  offset_v := 16#1008# * to_integer(crt_bank_hi_i);
                  avm_address_o      <= base_address + offset_v;
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_address_o     <= (others => '1');
                  state              <= READ_HI_ST;
               elsif crt_lo_load = '1' and crt_lo_load_done = '0' then
                  -- Starting load to LO bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  offset_v := 16#1008# * to_integer(crt_bank_lo_i);
                  avm_address_o      <= base_address + offset_v;
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
                     crt_hi_load_done <= '1';
                     state            <= READY_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     avm_write_o      <= '0';
                     avm_read_o       <= '1';
                     avm_address_o    <= avm_address_o + X"80";
                     avm_burstcount_o <= X"80"; -- Read 256 bytes
                  end if;
               end if;

            when READ_LO_ST =>
               if avm_readdatavalid_i = '1' then
                  bram_data_o    <= avm_readdata_i;
                  bram_lo_wren_o <= '1';
                  bram_address_o <= bram_address_o + 1;
                  if bram_address_o = X"FFE" then
                     crt_lo_load_done <= '1';
                     state            <= READY_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     avm_write_o      <= '0';
                     avm_read_o       <= '1';
                     avm_address_o    <= avm_address_o + X"80";
                     avm_burstcount_o <= X"80"; -- Read 256 bytes
                  end if;
               end if;

            when ERROR_ST =>
               if start_i = '0' then
                  status_o <= C_STAT_IDLE;
                  state    <= IDLE_ST;
               end if;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            avm_write_o       <= '0';
            avm_read_o        <= '0';
            avm_address_o     <= (others => '0');
            avm_writedata_o   <= (others => '0');
            avm_byteenable_o  <= (others => '0');
            avm_burstcount_o  <= (others => '0');
            bram_address_o    <= (others => '0');
            bram_data_o       <= (others => '0');
            bram_lo_wren_o    <= '0';
            bram_hi_wren_o    <= '0';
            state             <= IDLE_ST;
            cart_bank_raddr_o <= (others => '0');
            cart_bank_wr_o    <= '0';
            cart_id_o         <= (others => '0');
            cart_exrom_o      <= (others => '1');
            cart_game_o       <= (others => '1');
            read_pos          <= 0;
            status_o          <= C_STAT_IDLE;
         end if;

      end if;
   end process p_fsm;

   p_crt_load : process (clk_i)
   begin
      if rising_edge(clk_i) then
         crt_bank_lo_d  <= crt_bank_lo_i;
         crt_bank_hi_d  <= crt_bank_hi_i;
         if crt_lo_load_done = '1' then
            crt_lo_load <= '0';
         end if;
         if crt_hi_load_done = '1' then
            crt_hi_load <= '0';
         end if;

         -- Detect change in bank addresses
         if crt_bank_lo_d /= crt_bank_lo_i then
            crt_lo_load <= '1';
         end if;
         if crt_bank_hi_d /= crt_bank_hi_i then
            crt_hi_load <= '1';
         end if;

         if state = WAIT_FOR_CHIP_HEADER_ST then
            crt_lo_load <= '1';
         end if;

         if rst_i = '1' or state = IDLE_ST then
            crt_lo_load <= '0';
            crt_hi_load <= '0';
         end if;
      end if;
   end process p_crt_load;

end architecture synthesis;

