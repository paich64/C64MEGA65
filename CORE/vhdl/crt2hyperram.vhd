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
      address_i           : in  std_logic_vector(31 downto 0);     -- Address in HyperRAM of start of CRT file

      -- Connect to HyperRAM
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(31 downto 0) := (others => '0'); -- Force upper bits to zero (outside HyperRAM area)
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

   -- Use a wider data bus locally
   -- This is just to simplify the following state machine
   signal wide_write         : std_logic;
   signal wide_read          : std_logic;
   signal wide_address       : std_logic_vector(18 downto 0);
   signal wide_writedata     : std_logic_vector(127 downto 0);
   signal wide_byteenable    : std_logic_vector(15 downto 0);
   signal wide_burstcount    : std_logic_vector(7 downto 0);
   signal wide_readdata      : std_logic_vector(127 downto 0);
   signal wide_readdatavalid : std_logic;
   signal wide_waitrequest   : std_logic;

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
                    READ_CHIP_DATA_ST,
                    ERROR_ST);
   signal state : t_state := IDLE_ST;
   signal base_address : std_logic_vector(31 downto 0);
   signal image_size   : std_logic_vector(15 downto 0);

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

--   attribute mark_debug : string;
--   attribute mark_debug of wide_read          : signal is "true";
--   attribute mark_debug of wide_address       : signal is "true";
--   attribute mark_debug of wide_burstcount    : signal is "true";
--   attribute mark_debug of wide_writedata     : signal is "true";
--   attribute mark_debug of wide_readdata      : signal is "true";
--   attribute mark_debug of wide_readdatavalid : signal is "true";
--   attribute mark_debug of wide_waitrequest   : signal is "true";
--   attribute mark_debug of state              : signal is "true";
--   attribute mark_debug of base_address       : signal is "true";
--   attribute mark_debug of image_size         : signal is "true";
--   attribute mark_debug of cart_id_o          : signal is "true";
--   attribute mark_debug of cart_exrom_o       : signal is "true";
--   attribute mark_debug of cart_game_o        : signal is "true";

begin

   p_fsm : process (clk_i)
      variable file_header_length_v : std_logic_vector(31 downto 0);
   begin
      if rising_edge(clk_i) then
         if wide_waitrequest = '0' then
            wide_write <= '0';
            wide_read  <= '0';
         end if;

         case state is
            when IDLE_ST =>
               if start_i = '1' then
                  base_address    <= address_i; -- Address supplied by framework (in units of 16-bit words)

                  -- Read first 0x20 bytes of CRT header
                  wide_address    <= address_i(21 downto 3); -- Divide address by 8 to get in units of 128-bit words
                  wide_read       <= '1';
                  wide_burstcount <= X"02";
                  state           <= WAIT_FOR_CRT_HEADER_00_ST;
               end if;

            when WAIT_FOR_CRT_HEADER_00_ST =>
               if wide_readdatavalid = '1' then
                  state <= ERROR_ST; -- Assume error

                  if wide_readdata = str2slv("C64 CARTRIDGE   ") then
                     state <= WAIT_FOR_CRT_HEADER_10_ST;
                  end if;
               end if;

            when WAIT_FOR_CRT_HEADER_10_ST =>
               if wide_readdatavalid = '1' then
                  cart_id_o    <= bswap(wide_readdata(R_CRT_CARTRIDGE_TYPE));
                  cart_exrom_o <= wide_readdata(R_CRT_EXROM);
                  cart_game_o  <= wide_readdata(R_CRT_GAME);

                  -- Read 0x10 bytes from CHIP header
                  file_header_length_v := bswap(wide_readdata(R_CRT_FILE_HEADER_LENGTH));
                  wide_address    <= base_address(21 downto 3) + file_header_length_v(22 downto 4);
                  wide_read       <= '1';
                  wide_burstcount <= X"01";
                  state <= WAIT_FOR_CHIP_HEADER_ST;
               end if;

            when WAIT_FOR_CHIP_HEADER_ST =>
               if wide_readdatavalid = '1' then
                  state <= ERROR_ST; -- Assume error

                  if wide_readdata(R_CHIP_SIGNATURE) = str2slv("CHIP") then
                     image_size <= bswap(wide_readdata(R_CHIP_IMAGE_SIZE));
                     state <= READ_CHIP_DATA_ST;
                  end if;
               end if;

            when READ_CHIP_DATA_ST =>
               null;

            when ERROR_ST =>
               null;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            wide_write      <= '0';
            wide_read       <= '0';
            wide_address    <= (others => '0');
            wide_writedata  <= (others => '0');
            wide_byteenable <= (others => '0');
            wide_burstcount <= (others => '0');
            state           <= IDLE_ST;
         end if;

      end if;
   end process p_fsm;


   i_avm_decrease : entity work.avm_decrease
     generic map (
       G_SLAVE_ADDRESS_SIZE  => 19,
       G_SLAVE_DATA_SIZE     => 128,
       G_MASTER_ADDRESS_SIZE => 22,
       G_MASTER_DATA_SIZE    => 16
     )
     port map (
       clk_i                 => clk_i,
       rst_i                 => rst_i,
       s_avm_write_i         => wide_write,
       s_avm_read_i          => wide_read,
       s_avm_address_i       => wide_address,
       s_avm_writedata_i     => wide_writedata,
       s_avm_byteenable_i    => wide_byteenable,
       s_avm_burstcount_i    => wide_burstcount,
       s_avm_readdata_o      => wide_readdata,
       s_avm_readdatavalid_o => wide_readdatavalid,
       s_avm_waitrequest_o   => wide_waitrequest,
       m_avm_write_o         => avm_write_o,
       m_avm_read_o          => avm_read_o,
       m_avm_address_o       => avm_address_o(21 downto 0),
       m_avm_writedata_o     => avm_writedata_o,
       m_avm_byteenable_o    => avm_byteenable_o,
       m_avm_burstcount_o    => avm_burstcount_o,
       m_avm_readdata_i      => avm_readdata_i,
       m_avm_readdatavalid_i => avm_readdatavalid_i,
       m_avm_waitrequest_i   => avm_waitrequest_i
     ); -- i_avm_decrease

end architecture synthesis;

