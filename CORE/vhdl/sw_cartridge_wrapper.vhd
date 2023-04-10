library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module acts as a complete wrapper around the SW cartridge emulation.
-- It contains interfaces to the QNICE, to the C64 core, and to the HyperRAM.

entity sw_cartridge_wrapper is
generic (
   G_BASE_ADDRESS : std_logic_vector(21 downto 0)
);
port (
   qnice_clk_i          : in  std_logic;
   qnice_rst_i          : in  std_logic;
   qnice_addr_i         : in  std_logic_vector(27 downto 0);
   qnice_data_i         : in  std_logic_vector(15 downto 0);
   qnice_ce_i           : in  std_logic;
   qnice_we_i           : in  std_logic;
   qnice_data_o         : out std_logic_vector(15 downto 0);
   qnice_wait_o         : out std_logic;

   main_clk_i           : in  std_logic;
   main_rst_i           : in  std_logic;
   main_loading_o       : out std_logic;
   main_id_o            : out std_logic_vector(15 downto 0);
   main_exrom_o         : out std_logic_vector( 7 downto 0);
   main_game_o          : out std_logic_vector( 7 downto 0);
   main_bank_laddr_o    : out std_logic_vector(15 downto 0);
   main_bank_size_o     : out std_logic_vector(15 downto 0);
   main_bank_num_o      : out std_logic_vector(15 downto 0);
   main_bank_type_o     : out std_logic_vector( 7 downto 0);
   main_bank_raddr_o    : out std_logic_vector(24 downto 0);
   main_bank_wr_o       : out std_logic;
   main_bank_lo_i       : in  std_logic_vector( 6 downto 0);
   main_bank_hi_i       : in  std_logic_vector( 6 downto 0);
   main_ram_addr_i      : in  std_logic_vector(15 downto 0);
   main_lo_ram_data_o   : out std_logic_vector(15 downto 0);
   main_hi_ram_data_o   : out std_logic_vector(15 downto 0);

   hr_clk_i             : in  std_logic;
   hr_rst_i             : in  std_logic;
   hr_write_o           : out std_logic;
   hr_read_o            : out std_logic;
   hr_address_o         : out std_logic_vector(31 downto 0) := (others => '0');
   hr_writedata_o       : out std_logic_vector(15 downto 0);
   hr_byteenable_o      : out std_logic_vector( 1 downto 0);
   hr_burstcount_o      : out std_logic_vector( 7 downto 0);
   hr_readdata_i        : in  std_logic_vector(15 downto 0);
   hr_readdatavalid_i   : in  std_logic;
   hr_waitrequest_i     : in  std_logic
);
end entity sw_cartridge_wrapper;

architecture synthesis of sw_cartridge_wrapper is

   constant C_ERROR_STRING_LENGTH : integer := 21;
   type string_vector is array (natural range <>) of string(1 to C_ERROR_STRING_LENGTH);
   constant C_ERROR_STRINGS : string_vector(0 to 7) := (
     "OK\n                 ",
     "Missing CRT header\n ",
     "Missing CHIP header\n",
     "Wrong CRT header\n   ",
     "Wrong CHIP header\n  ",
     "Truncated CHIP\n     ",
     "OK\n                 ",
     "OK\n                 ");


   -- Status reporting from the QNICE
   constant C_CRT_ST_IDLE         : std_logic_vector(15 downto 0) := X"0000";
   constant C_CRT_ST_LDNG         : std_logic_vector(15 downto 0) := X"0001";
   constant C_CRT_ST_ERR          : std_logic_vector(15 downto 0) := X"0002";
   constant C_CRT_ST_OK           : std_logic_vector(15 downto 0) := X"0003";

   constant C_CRT_CASREG          : unsigned(15 downto 0) := X"FFFF";
   constant C_CRT_STATUS          : unsigned(11 downto 0) := X"000";
   constant C_CRT_FS_LO           : unsigned(11 downto 0) := X"001";
   constant C_CRT_FS_HI           : unsigned(11 downto 0) := X"002";
   constant C_CRT_PARSEST         : unsigned(11 downto 0) := X"010";
   constant C_CRT_PARSEE1         : unsigned(11 downto 0) := X"011";
   constant C_CRT_ADDR_LO         : unsigned(11 downto 0) := X"012";
   constant C_CRT_ADDR_HI         : unsigned(11 downto 0) := X"013";
   constant C_CRT_ERR_START       : unsigned(11 downto 0) := X"100";
   constant C_CRT_ERR_END         : unsigned(11 downto 0) := X"1FF";


   -- Request and response
   signal qnice_req_status        : std_logic_vector(15 downto 0);
   signal qnice_req_length        : std_logic_vector(22 downto 0);
   signal qnice_req_valid         : std_logic;
   signal qnice_resp_status       : std_logic_vector( 3 downto 0);
   signal qnice_resp_error        : std_logic_vector( 3 downto 0);
   signal qnice_resp_address      : std_logic_vector(22 downto 0);
   signal qnice_stat_data         : std_logic_vector( 7 downto 0);

   signal qnice_hr_ce             : std_logic;
   signal qnice_hr_addr           : std_logic_vector(31 downto 0);
   signal qnice_hr_wait           : std_logic;
   signal qnice_hr_data           : std_logic_vector(15 downto 0);

   signal qnice_avm_write         : std_logic;
   signal qnice_avm_read          : std_logic;
   signal qnice_avm_address       : std_logic_vector(31 downto 0);
   signal qnice_avm_writedata     : std_logic_vector(15 downto 0);
   signal qnice_avm_byteenable    : std_logic_vector(1 downto 0);
   signal qnice_avm_burstcount    : std_logic_vector(7 downto 0);
   signal qnice_avm_readdata      : std_logic_vector(15 downto 0);
   signal qnice_avm_readdatavalid : std_logic;
   signal qnice_avm_waitrequest   : std_logic;

   -- Request and response
   signal hr_req_length           : std_logic_vector(22 downto 0);
   signal hr_req_valid            : std_logic;
   signal hr_resp_status          : std_logic_vector( 3 downto 0);
   signal hr_resp_error           : std_logic_vector( 3 downto 0);
   signal hr_resp_address         : std_logic_vector(22 downto 0);

   signal hr_qnice_write          : std_logic;
   signal hr_qnice_read           : std_logic;
   signal hr_qnice_address        : std_logic_vector(31 downto 0);
   signal hr_qnice_writedata      : std_logic_vector(15 downto 0);
   signal hr_qnice_byteenable     : std_logic_vector(1 downto 0);
   signal hr_qnice_burstcount     : std_logic_vector(7 downto 0);
   signal hr_qnice_readdata       : std_logic_vector(15 downto 0);
   signal hr_qnice_readdatavalid  : std_logic;
   signal hr_qnice_waitrequest    : std_logic;

   signal hr_crt_write            : std_logic;
   signal hr_crt_read             : std_logic;
   signal hr_crt_address          : std_logic_vector(31 downto 0) := (others => '0');
   signal hr_crt_writedata        : std_logic_vector(15 downto 0);
   signal hr_crt_byteenable       : std_logic_vector(1 downto 0);
   signal hr_crt_burstcount       : std_logic_vector(7 downto 0);
   signal hr_crt_readdata         : std_logic_vector(15 downto 0);
   signal hr_crt_readdatavalid    : std_logic;
   signal hr_crt_waitrequest      : std_logic;

   -- Writing to BRAM
   signal hr_bram_address         : std_logic_vector(11 downto 0);
   signal hr_bram_data            : std_logic_vector(15 downto 0);
   signal hr_bram_lo_wren         : std_logic;
   signal hr_bram_hi_wren         : std_logic;

   -- Connect to CORE
   signal hr_bank_lo              : std_logic_vector( 6 downto 0);
   signal hr_bank_hi              : std_logic_vector( 6 downto 0);
   signal hr_loading              : std_logic;
   signal hr_id                   : std_logic_vector(15 downto 0);
   signal hr_exrom                : std_logic_vector( 7 downto 0);
   signal hr_game                 : std_logic_vector( 7 downto 0);
   signal hr_bank_laddr           : std_logic_vector(15 downto 0);
   signal hr_bank_size            : std_logic_vector(15 downto 0);
   signal hr_bank_num             : std_logic_vector(15 downto 0);
   signal hr_bank_type            : std_logic_vector( 7 downto 0);
   signal hr_bank_raddr           : std_logic_vector(24 downto 0);
   signal hr_bank_wr              : std_logic;

begin

   ----------------------------------------
   -- Decode information from and to QNICE
   ----------------------------------------

   qnice_req_valid <= '1' when qnice_req_status = C_CRT_ST_OK else '0';

   process (qnice_clk_i)
   begin
      if rising_edge(qnice_clk_i) then
         if qnice_ce_i = '1' and
            qnice_we_i = '1' and
            unsigned(qnice_addr_i(27 downto 12)) = C_CRT_CASREG
         then
            case unsigned(qnice_addr_i(11 downto 0)) is
               when C_CRT_STATUS => qnice_req_status                <= qnice_data_i;
               when C_CRT_FS_LO  => qnice_req_length(15 downto  0)  <= qnice_data_i;
               when C_CRT_FS_HI  => qnice_req_length(22 downto 16)  <= qnice_data_i(6 downto 0);
               when others => null;
            end case;
         end if;

         if qnice_rst_i = '1' then
            qnice_req_status  <= (others => '0');
            qnice_req_length  <= (others => '0');
         end if;
      end if;
   end process;


   -----------------------------------------
   -- Generate error status string to QNICE
   -----------------------------------------

   process (all)
      variable error_index_v : natural range 0 to 7;
      variable char_index_v  : natural range 1 to 32;
      variable char_v        : character;
   begin
      error_index_v := to_integer(unsigned(qnice_resp_error(2 downto 0)));
      char_index_v  := to_integer(unsigned(qnice_addr_i(4 downto 0))) + 1;
      if char_index_v <= C_ERROR_STRING_LENGTH then
         char_v := C_ERROR_STRINGS(error_index_v)(char_index_v);
         qnice_stat_data <= std_logic_vector(to_unsigned(character'pos(char_v), 8));
      else
         qnice_stat_data <= X"00"; -- zero-terminated strings
      end if;
   end process;

   process (all)
   begin
      qnice_data_o <= x"0000"; -- By default read back zeros.
      qnice_wait_o <= '0';

      if qnice_ce_i = '1' and
         qnice_we_i = '0' and
         unsigned(qnice_addr_i(27 downto 12)) = C_CRT_CASREG
      then
         case to_integer(unsigned(qnice_addr_i(11 downto 0))) is
            when to_integer(C_CRT_STATUS)  => qnice_data_o <= qnice_req_status;
            when to_integer(C_CRT_FS_LO)   => qnice_data_o <= qnice_req_length(15 downto  0);
            when to_integer(C_CRT_FS_HI)   => qnice_data_o(6 downto 0) <= qnice_req_length(22 downto 16);
            when to_integer(C_CRT_PARSEST) => qnice_data_o <= X"000" & qnice_resp_status;
            when to_integer(C_CRT_PARSEE1) => qnice_data_o <= X"000" & qnice_resp_error;
            when to_integer(C_CRT_ADDR_LO) => qnice_data_o <= qnice_resp_address(15 downto 0);
            when to_integer(C_CRT_ADDR_HI) => qnice_data_o <= "000000000" & qnice_resp_address(22 downto 16);
            when to_integer(C_CRT_ERR_START)
              to to_integer(C_CRT_ERR_END) => qnice_data_o <= X"00" & qnice_stat_data;
            when others => null;
         end case;
      end if;

      if qnice_ce_i = '1' and unsigned(qnice_addr_i(27 downto 12)) /= C_CRT_CASREG then
         qnice_wait_o <= qnice_hr_wait;
         qnice_data_o <= qnice_hr_data;
      end if;
   end process;

   qnice_hr_ce <= qnice_ce_i when unsigned(qnice_addr_i(27 downto 12)) /= C_CRT_CASREG
             else '0';
   qnice_hr_addr <= std_logic_vector(("0000" & unsigned(qnice_addr_i)) +
                                     ("0000000000" & unsigned(G_BASE_ADDRESS)));

   i_qnice2hyperram : entity work.qnice2hyperram
      port map (
         clk_i                 => qnice_clk_i,
         rst_i                 => qnice_rst_i,
         s_qnice_wait_o        => qnice_hr_wait,
         s_qnice_address_i     => qnice_hr_addr,
         s_qnice_cs_i          => qnice_hr_ce,
         s_qnice_write_i       => qnice_we_i,
         s_qnice_writedata_i   => qnice_data_i,
         s_qnice_readdata_o    => qnice_hr_data,
         m_avm_write_o         => qnice_avm_write,
         m_avm_read_o          => qnice_avm_read,
         m_avm_address_o       => qnice_avm_address,
         m_avm_writedata_o     => qnice_avm_writedata,
         m_avm_byteenable_o    => qnice_avm_byteenable,
         m_avm_burstcount_o    => qnice_avm_burstcount,
         m_avm_readdata_i      => qnice_avm_readdata,
         m_avm_readdatavalid_i => qnice_avm_readdatavalid,
         m_avm_waitrequest_i   => qnice_avm_waitrequest
      ); -- i_qnice2hyperram


   --------------------------------------------
   -- Clock Domain Crossing: QNICE -> HyperRAM
   --------------------------------------------

   i_cdc_qnice2hr : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 24
      )
      port map (
         src_clk_i                => qnice_clk_i,
         src_data_i(22 downto  0) => qnice_req_length,
         src_data_i(23)           => qnice_req_valid,
         dst_clk_i                => hr_clk_i,
         dst_data_o(22 downto  0) => hr_req_length,
         dst_data_o(23)           => hr_req_valid
      ); -- i_cdc_qnice2hr

   avm_fifo_qnice : entity work.avm_fifo
      generic map (
         G_WR_DEPTH     => 16,
         G_RD_DEPTH     => 16,
         G_FILL_SIZE    => 1,
         G_ADDRESS_SIZE => 32,
         G_DATA_SIZE    => 16
      )
      port map (
         s_clk_i               => qnice_clk_i,
         s_rst_i               => qnice_rst_i,
         s_avm_waitrequest_o   => qnice_avm_waitrequest,
         s_avm_write_i         => qnice_avm_write,
         s_avm_read_i          => qnice_avm_read,
         s_avm_address_i       => qnice_avm_address,
         s_avm_writedata_i     => qnice_avm_writedata,
         s_avm_byteenable_i    => qnice_avm_byteenable,
         s_avm_burstcount_i    => qnice_avm_burstcount,
         s_avm_readdata_o      => qnice_avm_readdata,
         s_avm_readdatavalid_o => qnice_avm_readdatavalid,
         m_clk_i               => hr_clk_i,
         m_rst_i               => hr_rst_i,
         m_avm_waitrequest_i   => hr_qnice_waitrequest,
         m_avm_write_o         => hr_qnice_write,
         m_avm_read_o          => hr_qnice_read,
         m_avm_address_o       => hr_qnice_address,
         m_avm_writedata_o     => hr_qnice_writedata,
         m_avm_byteenable_o    => hr_qnice_byteenable,
         m_avm_burstcount_o    => hr_qnice_burstcount,
         m_avm_readdata_i      => hr_qnice_readdata,
         m_avm_readdatavalid_i => hr_qnice_readdatavalid
      ); -- avm_fifo_qnice


   --------------------------------------------
   -- Clock Domain Crossing: HyperRAM -> QNICE
   --------------------------------------------

   i_cdc_hr2qnice : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 31
      )
      port map (
         src_clk_i               => hr_clk_i,
         src_data_i( 3 downto 0) => hr_resp_status,
         src_data_i( 7 downto 4) => hr_resp_error,
         src_data_i(30 downto 8) => hr_resp_address,
         dst_clk_i               => qnice_clk_i,
         dst_data_o( 3 downto 0) => qnice_resp_status,
         dst_data_o( 7 downto 4) => qnice_resp_error,
         dst_data_o(30 downto 8) => qnice_resp_address
      ); -- i_cdc_hr2qnice


   --------------------------------------------
   -- Clock Domain Crossing: CORE -> HyperRAM
   --------------------------------------------

   i_cdc_main2hr : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 14
      )
      port map (
         src_clk_i                => main_clk_i,
         src_data_i( 6 downto  0) => main_bank_lo_i,
         src_data_i(13 downto  7) => main_bank_hi_i,
         dst_clk_i                => hr_clk_i,
         dst_data_o( 6 downto  0) => hr_bank_lo,
         dst_data_o(13 downto  7) => hr_bank_hi
      ); -- i_cdc_main2hr


   -------------------------------------------------------------
   -- Instantiate CRT loader and parser
   -- This module runs entire within the HyperRAM clock domain.
   -------------------------------------------------------------

   i_crt_loader : entity work.crt_loader
      port map (
         clk_i               => hr_clk_i,
         rst_i               => hr_rst_i,
         req_address_i       => G_BASE_ADDRESS,
         req_length_i        => hr_req_length,
         req_start_i         => hr_req_valid,
         resp_status_o       => hr_resp_status,
         resp_error_o        => hr_resp_error,
         resp_address_o      => hr_resp_address,
         bank_lo_i           => hr_bank_lo,
         bank_hi_i           => hr_bank_hi,
         avm_write_o         => hr_crt_write,
         avm_read_o          => hr_crt_read,
         avm_address_o       => hr_crt_address(21 downto 0),
         avm_writedata_o     => hr_crt_writedata,
         avm_byteenable_o    => hr_crt_byteenable,
         avm_burstcount_o    => hr_crt_burstcount,
         avm_readdata_i      => hr_crt_readdata,
         avm_readdatavalid_i => hr_crt_readdatavalid,
         avm_waitrequest_i   => hr_crt_waitrequest,
         cart_bank_laddr_o   => hr_bank_laddr,
         cart_bank_size_o    => hr_bank_size,
         cart_bank_num_o     => hr_bank_num,
         cart_bank_raddr_o   => hr_bank_raddr,
         cart_bank_wr_o      => hr_bank_wr,
         cart_loading_o      => hr_loading,
         cart_id_o           => hr_id,
         cart_exrom_o        => hr_exrom,
         cart_game_o         => hr_game,
         bram_address_o      => hr_bram_address,
         bram_data_o         => hr_bram_data,
         bram_lo_wren_o      => hr_bram_lo_wren,
         bram_lo_q_i         => (others => '0'),
         bram_hi_wren_o      => hr_bram_hi_wren,
         bram_hi_q_i         => (others => '0')
      ); -- i_crt2hyperram

   i_avm_arbit : entity work.avm_arbit
      generic map (
         G_ADDRESS_SIZE  => 32,
         G_DATA_SIZE     => 16
      )
      port map (
         clk_i                  => hr_clk_i,
         rst_i                  => hr_rst_i,
         s0_avm_write_i         => hr_qnice_write,
         s0_avm_read_i          => hr_qnice_read,
         s0_avm_address_i       => hr_qnice_address,
         s0_avm_writedata_i     => hr_qnice_writedata,
         s0_avm_byteenable_i    => hr_qnice_byteenable,
         s0_avm_burstcount_i    => hr_qnice_burstcount,
         s0_avm_readdata_o      => hr_qnice_readdata,
         s0_avm_readdatavalid_o => hr_qnice_readdatavalid,
         s0_avm_waitrequest_o   => hr_qnice_waitrequest,
         s1_avm_write_i         => hr_crt_write,
         s1_avm_read_i          => hr_crt_read,
         s1_avm_address_i       => hr_crt_address,
         s1_avm_writedata_i     => hr_crt_writedata,
         s1_avm_byteenable_i    => hr_crt_byteenable,
         s1_avm_burstcount_i    => hr_crt_burstcount,
         s1_avm_readdata_o      => hr_crt_readdata,
         s1_avm_readdatavalid_o => hr_crt_readdatavalid,
         s1_avm_waitrequest_o   => hr_crt_waitrequest,
         m_avm_write_o          => hr_write_o,
         m_avm_read_o           => hr_read_o,
         m_avm_address_o        => hr_address_o,
         m_avm_writedata_o      => hr_writedata_o,
         m_avm_byteenable_o     => hr_byteenable_o,
         m_avm_burstcount_o     => hr_burstcount_o,
         m_avm_readdata_i       => hr_readdata_i,
         m_avm_readdatavalid_i  => hr_readdatavalid_i,
         m_avm_waitrequest_i    => hr_waitrequest_i
      ); -- i_avm_arbit


   --------------------------------------------
   -- Clock Domain Crossing: HyperRAM -> CORE
   --------------------------------------------

   i_cdc_slow : entity work.cdc_slow
     generic map (
       G_DATA_SIZE    => 81,
       G_REGISTER_SRC => false
     )
     port map (
       src_clk_i                => hr_clk_i,
       src_valid_i              => hr_bank_wr,
       src_data_i(15 downto  0) => hr_bank_laddr,
       src_data_i(31 downto 16) => hr_bank_size,
       src_data_i(47 downto 32) => hr_bank_num,
       src_data_i(55 downto 48) => hr_bank_type,
       src_data_i(80 downto 56) => hr_bank_raddr,
       dst_clk_i                => main_clk_i,
       dst_valid_o              => main_bank_wr_o,
       dst_data_o(15 downto  0) => main_bank_laddr_o,
       dst_data_o(31 downto 16) => main_bank_size_o,
       dst_data_o(47 downto 32) => main_bank_num_o,
       dst_data_o(55 downto 48) => main_bank_type_o,
       dst_data_o(80 downto 56) => main_bank_raddr_o
     ); -- i_cdc_slow

   i_cdc_stable : entity work.cdc_stable
     generic map (
       G_DATA_SIZE    => 33,
       G_REGISTER_SRC => false
     )
     port map (
       src_clk_i                => hr_clk_i,
       src_data_i(15 downto  0) => hr_id,
       src_data_i(23 downto 16) => hr_exrom,
       src_data_i(31 downto 24) => hr_game,
       src_data_i(32)           => hr_loading,
       dst_clk_i                => main_clk_i,
       dst_data_o(15 downto  0) => main_id_o,
       dst_data_o(23 downto 16) => main_exrom_o,
       dst_data_o(31 downto 24) => main_game_o,
       dst_data_o(32)           => main_loading_o
     ); -- i_cdc_stable


   -------------------------------------------------------------
   -- Instantiate bank cache memory
   -------------------------------------------------------------

   crt_lo_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH => 12,         -- 4 kW = 8 kB
         DATA_WIDTH => 16,
         FALLING_A  => false,
         FALLING_B  => false
      )
      port map (
         -- C64 MiSTer core
         clock_a    => main_clk_i,
         address_a  => main_ram_addr_i(12 downto 1),
         data_a     => (others => '0'),
         wren_a     => '0',
         q_a        => main_lo_ram_data_o,

         clock_b    => hr_clk_i,
         address_b  => hr_bram_address,
         data_b     => hr_bram_data,
         wren_b     => hr_bram_lo_wren,
         q_b        => open
      ); -- crt_lo_ram

   crt_hi_ram : entity work.dualport_2clk_ram
      generic map (
         ADDR_WIDTH => 12,         -- 4 kW = 8 kB
         DATA_WIDTH => 16,
         FALLING_A  => false,
         FALLING_B  => false
      )
      port map (
         -- C64 MiSTer core
         clock_a    => main_clk_i,
         address_a  => main_ram_addr_i(12 downto 1),
         data_a     => (others => '0'),
         wren_a     => '0',
         q_a        => main_hi_ram_data_o,

         clock_b    => hr_clk_i,
         address_b  => hr_bram_address,
         data_b     => hr_bram_data,
         wren_b     => hr_bram_hi_wren,
         q_b        => open
      ); -- crt_lo_ram

end architecture synthesis;

