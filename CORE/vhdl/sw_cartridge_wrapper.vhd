library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module acts as a complete wrapper around the SW cartridge emulation.
-- It contains interfaces to the QNICE, to the C64 core, and to the HyperRAM.

entity sw_cartridge_wrapper is
port (
   qnice_clk_i          : in  std_logic;
   qnice_rst_i          : in  std_logic;
   qnice_req_status_i   : in  std_logic_vector(15 downto 0);
   qnice_req_fs_lo_i    : in  std_logic_vector(15 downto 0);
   qnice_req_fs_hi_i    : in  std_logic_vector(15 downto 0);
   qnice_req_hrs_lo_i   : in  std_logic_vector(15 downto 0);
   qnice_req_hrs_hi_i   : in  std_logic_vector(15 downto 0);
   qnice_resp_parsest_o : out std_logic_vector(15 downto 0);
   qnice_resp_parsee1_o : out std_logic_vector(15 downto 0);
   qnice_resp_addr_lo_o : out std_logic_vector(15 downto 0);
   qnice_resp_addr_hi_o : out std_logic_vector(15 downto 0);
   qnice_stat_addr_i    : in  std_logic_vector( 7 downto 0);
   qnice_stat_data_o    : out std_logic_vector( 7 downto 0);

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
   constant C_CRT_ST_IDLE      : std_logic_vector(15 downto 0) := X"0000";
   constant C_CRT_ST_LDNG      : std_logic_vector(15 downto 0) := X"0001";
   constant C_CRT_ST_ERR       : std_logic_vector(15 downto 0) := X"0002";
   constant C_CRT_ST_OK        : std_logic_vector(15 downto 0) := X"0003";

   -- Request and response
   signal qnice_req_address    : std_logic_vector(21 downto 0);
   signal qnice_req_length     : std_logic_vector(22 downto 0);
   signal qnice_req_valid      : std_logic;
   signal qnice_resp_status    : std_logic_vector( 3 downto 0);
   signal qnice_resp_error     : std_logic_vector( 3 downto 0);
   signal qnice_resp_address   : std_logic_vector(22 downto 0);

   -- Request and response
   signal hr_req_address       : std_logic_vector(21 downto 0);
   signal hr_req_length        : std_logic_vector(22 downto 0);
   signal hr_req_valid         : std_logic;
   signal hr_resp_status       : std_logic_vector( 3 downto 0);
   signal hr_resp_error        : std_logic_vector( 3 downto 0);
   signal hr_resp_address      : std_logic_vector(22 downto 0);

   -- Writing to BRAM
   signal hr_bram_address      : std_logic_vector(11 downto 0);
   signal hr_bram_data         : std_logic_vector(15 downto 0);
   signal hr_bram_lo_wren      : std_logic;
   signal hr_bram_hi_wren      : std_logic;

   -- Connect to CORE
   signal hr_bank_lo           : std_logic_vector( 6 downto 0);
   signal hr_bank_hi           : std_logic_vector( 6 downto 0);
   signal hr_loading           : std_logic;
   signal hr_id                : std_logic_vector(15 downto 0);
   signal hr_exrom             : std_logic_vector( 7 downto 0);
   signal hr_game              : std_logic_vector( 7 downto 0);
   signal hr_bank_laddr        : std_logic_vector(15 downto 0);
   signal hr_bank_size         : std_logic_vector(15 downto 0);
   signal hr_bank_num          : std_logic_vector(15 downto 0);
   signal hr_bank_type         : std_logic_vector( 7 downto 0);
   signal hr_bank_raddr        : std_logic_vector(24 downto 0);
   signal hr_bank_wr           : std_logic;

   attribute mark_debug : string;
   attribute mark_debug of qnice_rst_i          : signal is "true";
   attribute mark_debug of qnice_req_status_i   : signal is "true";
   attribute mark_debug of qnice_req_fs_lo_i    : signal is "true";
   attribute mark_debug of qnice_req_fs_hi_i    : signal is "true";
   attribute mark_debug of qnice_req_hrs_lo_i   : signal is "true";
   attribute mark_debug of qnice_req_hrs_hi_i   : signal is "true";
   attribute mark_debug of qnice_resp_parsest_o : signal is "true";
   attribute mark_debug of qnice_resp_parsee1_o : signal is "true";
   attribute mark_debug of qnice_resp_addr_lo_o : signal is "true";
   attribute mark_debug of qnice_resp_addr_hi_o : signal is "true";
   attribute mark_debug of qnice_stat_addr_i    : signal is "true";
   attribute mark_debug of qnice_stat_data_o    : signal is "true";
   attribute mark_debug of main_rst_i           : signal is "true";
   attribute mark_debug of main_loading_o       : signal is "true";
   attribute mark_debug of main_id_o            : signal is "true";
   attribute mark_debug of main_exrom_o         : signal is "true";
   attribute mark_debug of main_game_o          : signal is "true";
   attribute mark_debug of main_bank_laddr_o    : signal is "true";
   attribute mark_debug of main_bank_size_o     : signal is "true";
   attribute mark_debug of main_bank_num_o      : signal is "true";
   attribute mark_debug of main_bank_type_o     : signal is "true";
   attribute mark_debug of main_bank_raddr_o    : signal is "true";
   attribute mark_debug of main_bank_wr_o       : signal is "true";
   attribute mark_debug of main_bank_lo_i       : signal is "true";
   attribute mark_debug of main_bank_hi_i       : signal is "true";
   attribute mark_debug of main_ram_addr_i      : signal is "true";
   attribute mark_debug of main_lo_ram_data_o   : signal is "true";
   attribute mark_debug of main_hi_ram_data_o   : signal is "true";
   attribute mark_debug of hr_rst_i             : signal is "true";
   attribute mark_debug of hr_write_o           : signal is "true";
   attribute mark_debug of hr_read_o            : signal is "true";
   attribute mark_debug of hr_address_o         : signal is "true";
   attribute mark_debug of hr_writedata_o       : signal is "true";
   attribute mark_debug of hr_byteenable_o      : signal is "true";
   attribute mark_debug of hr_burstcount_o      : signal is "true";
   attribute mark_debug of hr_readdata_i        : signal is "true";
   attribute mark_debug of hr_readdatavalid_i   : signal is "true";
   attribute mark_debug of hr_waitrequest_i     : signal is "true";
   attribute mark_debug of hr_bram_address      : signal is "true";
   attribute mark_debug of hr_bram_data         : signal is "true";
   attribute mark_debug of hr_bram_lo_wren      : signal is "true";
   attribute mark_debug of hr_bram_hi_wren      : signal is "true";
   attribute mark_debug of hr_req_address       : signal is "true";
   attribute mark_debug of hr_req_length        : signal is "true";
   attribute mark_debug of hr_req_valid         : signal is "true";
   attribute mark_debug of hr_resp_status       : signal is "true";
   attribute mark_debug of hr_resp_error        : signal is "true";
   attribute mark_debug of hr_resp_address      : signal is "true";
   attribute mark_debug of hr_bank_lo           : signal is "true";
   attribute mark_debug of hr_bank_hi           : signal is "true";

begin

   -----------------------------------------
   -- Generate error status string to QNICE
   -----------------------------------------

   process (all)
      variable error_index_v : natural range 0 to 7;
      variable char_index_v  : natural range 1 to 32;
      variable char_v        : character;
   begin
      error_index_v := to_integer(unsigned(qnice_resp_error(2 downto 0)));
      char_index_v  := to_integer(unsigned(qnice_stat_addr_i(4 downto 0))) + 1;
      if char_index_v <= C_ERROR_STRING_LENGTH then
         char_v := C_ERROR_STRINGS(error_index_v)(char_index_v);
         qnice_stat_data_o <= std_logic_vector(to_unsigned(character'pos(char_v), 8));
      else
         qnice_stat_data_o <= X"00"; -- zero-terminated strings
      end if;
   end process;


   ----------------------------------------
   -- Decode information from and to QNICE
   ----------------------------------------

   process (qnice_clk_i)
   begin
      if falling_edge(qnice_clk_i) then
         if qnice_req_status_i = C_CRT_ST_OK then
            -- Address is in units of 16-bit words.
            qnice_req_address <= qnice_req_hrs_hi_i(5 downto 0) & qnice_req_hrs_lo_i;
            -- Length is in units of bytes.
            qnice_req_length  <= qnice_req_fs_hi_i (6 downto 0) & qnice_req_fs_lo_i;
            qnice_req_valid   <= '1';
         else
            qnice_req_valid   <= '0';
         end if;
      end if;
   end process;

   process (qnice_clk_i)
   begin
      if falling_edge(qnice_clk_i) then
         qnice_resp_parsest_o <= X"000" & qnice_resp_status;
         qnice_resp_parsee1_o <= X"000" & qnice_resp_error;
         qnice_resp_addr_lo_o <= qnice_resp_address(15 downto 0);
         qnice_resp_addr_hi_o <= "000000000" & qnice_resp_address(22 downto 16);
      end if;
   end process;


   --------------------------------------------
   -- Clock Domain Crossing: QNICE -> HyperRAM
   --------------------------------------------

   i_cdc_qnice2hr : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 46
      )
      port map (
         src_clk_i                => qnice_clk_i,
         src_data_i(21 downto  0) => qnice_req_address,
         src_data_i(44 downto 22) => qnice_req_length,
         src_data_i(45)           => qnice_req_valid,
         dst_clk_i                => hr_clk_i,
         dst_data_o(21 downto  0) => hr_req_address,
         dst_data_o(44 downto 22) => hr_req_length,
         dst_data_o(45)           => hr_req_valid
      ); -- i_cdc_qnice2hr


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
         req_address_i       => hr_req_address,
         req_length_i        => hr_req_length,
         req_start_i         => hr_req_valid,
         resp_status_o       => hr_resp_status,
         resp_error_o        => hr_resp_error,
         resp_address_o      => hr_resp_address,
         bank_lo_i           => hr_bank_lo,
         bank_hi_i           => hr_bank_hi,
         avm_write_o         => hr_write_o,
         avm_read_o          => hr_read_o,
         avm_address_o       => hr_address_o(21 downto 0),
         avm_writedata_o     => hr_writedata_o,
         avm_byteenable_o    => hr_byteenable_o,
         avm_burstcount_o    => hr_burstcount_o,
         avm_readdata_i      => hr_readdata_i,
         avm_readdatavalid_i => hr_readdatavalid_i,
         avm_waitrequest_i   => hr_waitrequest_i,
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

