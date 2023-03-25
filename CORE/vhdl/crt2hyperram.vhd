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
      crt_bank_lo_i       : in  std_logic_vector(6 downto 0);
      crt_bank_hi_i       : in  std_logic_vector(6 downto 0);

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
                    ERROR_ST);
   signal state         : t_state := IDLE_ST;
   signal read_pos      : integer range 0 to 7;
   signal wide_readdata : std_logic_vector(127 downto 0);

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

   attribute mark_debug : string;
   attribute mark_debug of state         : signal is "true";
   attribute mark_debug of wide_readdata : signal is "true";
   attribute mark_debug of read_pos      : signal is "true";
   attribute mark_debug of cart_id_o     : signal is "true";
   attribute mark_debug of cart_exrom_o  : signal is "true";
   attribute mark_debug of cart_game_o   : signal is "true";

begin

   p_fsm : process (clk_i)
      variable file_header_length_v : std_logic_vector(31 downto 0);
      variable image_size_v         : std_logic_vector(15 downto 0);
      variable wide_readdata_v      : std_logic_vector(127 downto 0);
      variable read_addr_v          : std_logic_vector(21 downto 0);
   begin
      if rising_edge(clk_i) then
         cart_bank_wr_o <= '0';

         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

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
                  cart_loading_o   <= '1';
                  -- Read first 0x20 bytes of CRT header
                  avm_address_o    <= address_i;
                  avm_read_o       <= '1';
                  avm_burstcount_o <= X"10";
                  state            <= WAIT_FOR_CRT_HEADER_00_ST;
               end if;

            when WAIT_FOR_CRT_HEADER_00_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  state <= ERROR_ST; -- Assume error

                  if wide_readdata_v = str2slv("C64 CARTRIDGE   ") then
                     state <= WAIT_FOR_CRT_HEADER_10_ST;
                  end if;
               end if;

            when WAIT_FOR_CRT_HEADER_10_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  cart_id_o    <= bswap(wide_readdata_v(R_CRT_CARTRIDGE_TYPE));
                  cart_exrom_o <= wide_readdata_v(R_CRT_EXROM);
                  cart_game_o  <= wide_readdata_v(R_CRT_GAME);

                  -- Read 0x10 bytes from CHIP header
                  file_header_length_v := bswap(wide_readdata_v(R_CRT_FILE_HEADER_LENGTH));
                  avm_address_o    <= avm_address_o + file_header_length_v(22 downto 1);
                  avm_read_o       <= '1';
                  avm_burstcount_o <= X"08";
                  state <= WAIT_FOR_CHIP_HEADER_ST;
               end if;

            when WAIT_FOR_CHIP_HEADER_ST =>
               if avm_readdatavalid_i = '1' and read_pos = 7 then
                  if wide_readdata_v(R_CHIP_SIGNATURE) = str2slv("CHIP") then
                     cart_bank_laddr_o <= bswap(wide_readdata_v(R_CHIP_LOAD_ADDRESS));
                     cart_bank_size_o  <= bswap(wide_readdata_v(R_CHIP_IMAGE_SIZE));
                     cart_bank_num_o   <= bswap(wide_readdata_v(R_CHIP_BANK_NUMBER));
                     read_addr_v := avm_address_o + X"08";
                     cart_bank_raddr_o <= "00" & read_addr_v & "0";
                     cart_bank_wr_o    <= '1';

                     image_size_v := bswap(wide_readdata_v(R_CHIP_IMAGE_SIZE));
                     avm_address_o    <= avm_address_o + X"08" + image_size_v(15 downto 1);
                     avm_read_o       <= '1';
                     avm_burstcount_o <= X"08";
                  else
                     state <= IDLE_ST;
                     cart_loading_o <= '0';
                  end if;
               end if;

            when ERROR_ST =>
               cart_loading_o <= '0';

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
            state             <= IDLE_ST;
            cart_loading_o    <= '0';
            cart_bank_raddr_o <= (others => '0');
            cart_bank_wr_o    <= '0';
            cart_loading_o    <= '0';
            cart_id_o         <= (others => '0');
            cart_exrom_o      <= (others => '0');
            cart_game_o       <= (others => '0');
            read_pos          <= 0;
         end if;

      end if;
   end process p_fsm;

end architecture synthesis;

