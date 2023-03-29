library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module acts as a complete wrapper around the SW cartridge emulation.
-- It contains interfaces to the QNICE, to the C64 core, and to the HyperRAM.

entity sw_cartridge_wrapper is
port (
   qnice_clk_i            : in  std_logic;
   qnice_rst_i            : in  std_logic;
   qnice_crt_status_i     : in  std_logic_vector(15 downto 0);
   qnice_crt_fs_lo_i      : in  std_logic_vector(15 downto 0);
   qnice_crt_fs_hi_i      : in  std_logic_vector(15 downto 0);
   qnice_crt_hrs_lo_i     : in  std_logic_vector(15 downto 0);
   qnice_crt_hrs_hi_i     : in  std_logic_vector(15 downto 0);
   qnice_crt_parsest_o    : out std_logic_vector(15 downto 0);
   qnice_crt_parsee1_o    : out std_logic_vector(15 downto 0);
   qnice_crt_parsee2_o    : out std_logic_vector(15 downto 0);

   main_clk_i             : in  std_logic;
   main_rst_i             : in  std_logic;
   main_crt_loading_o     : out std_logic;
   main_crt_id_o          : out std_logic_vector(15 downto 0);
   main_crt_exrom_o       : out std_logic_vector( 7 downto 0);
   main_crt_game_o        : out std_logic_vector( 7 downto 0);
   main_crt_bank_laddr_o  : out std_logic_vector(15 downto 0);
   main_crt_bank_size_o   : out std_logic_vector(15 downto 0);
   main_crt_bank_num_o    : out std_logic_vector(15 downto 0);
   main_crt_bank_type_o   : out std_logic_vector( 7 downto 0);
   main_crt_bank_raddr_o  : out std_logic_vector(24 downto 0);
   main_crt_bank_wr_o     : out std_logic;
   main_crt_bank_lo_i     : in  std_logic_vector( 6 downto 0);
   main_crt_bank_hi_i     : in  std_logic_vector( 6 downto 0);
   main_ram_addr_i        : in  std_logic_vector(15 downto 0);
   main_crt_lo_ram_data_o : out std_logic_vector(15 downto 0);
   main_crt_hi_ram_data_o : out std_logic_vector(15 downto 0);

   hr_clk_i               : in  std_logic;
   hr_rst_i               : in  std_logic;
   hr_crt_write_o         : out std_logic;
   hr_crt_read_o          : out std_logic;
   hr_crt_address_o       : out std_logic_vector(31 downto 0) := (others => '0');
   hr_crt_writedata_o     : out std_logic_vector(15 downto 0);
   hr_crt_byteenable_o    : out std_logic_vector( 1 downto 0);
   hr_crt_burstcount_o    : out std_logic_vector( 7 downto 0);
   hr_crt_readdata_i      : in  std_logic_vector(15 downto 0);
   hr_crt_readdatavalid_i : in  std_logic;
   hr_crt_waitrequest_i   : in  std_logic
);
end entity sw_cartridge_wrapper;

architecture synthesis of sw_cartridge_wrapper is

   constant C_CRT_ST_IDLE : std_logic_vector(15 downto 0) := X"0000";
   constant C_CRT_ST_LDNG : std_logic_vector(15 downto 0) := X"0001";
   constant C_CRT_ST_ERR  : std_logic_vector(15 downto 0) := X"0002";
   constant C_CRT_ST_OK   : std_logic_vector(15 downto 0) := X"0003";

   signal qnice_cartridge_address    : std_logic_vector(21 downto 0);
   signal qnice_cartridge_length     : std_logic_vector(21 downto 0);
   signal qnice_cartridge_crt_loaded : std_logic;
   signal qnice_crt_status           : std_logic_vector( 3 downto 0);

   signal hr_cartridge_address       : std_logic_vector(21 downto 0);
   signal hr_cartridge_length        : std_logic_vector(21 downto 0);
   signal hr_cartridge_crt_loaded    : std_logic;
   signal hr_crt_bank_lo             : std_logic_vector( 6 downto 0);
   signal hr_crt_bank_hi             : std_logic_vector( 6 downto 0);
   signal hr_crt_status              : std_logic_vector( 3 downto 0);

   signal hr_bram_address            : std_logic_vector(11 downto 0);
   signal hr_bram_data               : std_logic_vector(15 downto 0);
   signal hr_bram_lo_wren            : std_logic;
   signal hr_bram_hi_wren            : std_logic;

   signal hr_crt_loading             : std_logic;
   signal hr_crt_id                  : std_logic_vector(15 downto 0);
   signal hr_crt_exrom               : std_logic_vector( 7 downto 0);
   signal hr_crt_game                : std_logic_vector( 7 downto 0);
   signal hr_crt_bank_laddr          : std_logic_vector(15 downto 0);
   signal hr_crt_bank_size           : std_logic_vector(15 downto 0);
   signal hr_crt_bank_num            : std_logic_vector(15 downto 0);
   signal hr_crt_bank_type           : std_logic_vector( 7 downto 0);
   signal hr_crt_bank_raddr          : std_logic_vector(24 downto 0);
   signal hr_crt_bank_wr             : std_logic;

begin

   ---------------------------------
   -- Decode information from QNICE
   ---------------------------------

   process (qnice_clk_i)
   begin
      if rising_edge(qnice_clk_i) then
         if qnice_crt_status_i = C_CRT_ST_OK then
            qnice_cartridge_address    <= qnice_crt_hrs_hi_i(5 downto 0) & qnice_crt_hrs_lo_i;
            qnice_cartridge_length     <= qnice_crt_fs_hi_i (5 downto 0) & qnice_crt_fs_lo_i;
            qnice_cartridge_crt_loaded <= '1';
         else
            qnice_cartridge_crt_loaded <= '0';
         end if;
      end if;
   end process;

   process (qnice_clk_i)
   begin
      if rising_edge(qnice_clk_i) then
         qnice_crt_parsest_o <= (others => '0');
         qnice_crt_parsee1_o <= (others => '0');
         qnice_crt_parsee2_o <= (others => '0');
         qnice_crt_parsest_o(3 downto 0) <= qnice_crt_status;
      end if;
   end process;


   --------------------------------------------
   -- Clock Domain Crossing: QNICE -> HyperRAM
   --------------------------------------------

   i_cdc_qnice2hr : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 45
      )
      port map (
         src_clk_i                => qnice_clk_i,
         src_data_i(21 downto  0) => qnice_cartridge_address,
         src_data_i(43 downto 22) => qnice_cartridge_length,
         src_data_i(44)           => qnice_cartridge_crt_loaded,
         dst_clk_i                => hr_clk_i,
         dst_data_o(21 downto  0) => hr_cartridge_address,
         dst_data_o(43 downto 22) => hr_cartridge_length,
         dst_data_o(44)           => hr_cartridge_crt_loaded
      ); -- i_cdc_qnice2hr


   --------------------------------------------
   -- Clock Domain Crossing: HyperRAM -> QNICE
   --------------------------------------------
   i_cdc_hr2qnice : entity work.cdc_stable
      generic map (
         G_DATA_SIZE => 4
      )
      port map (
         src_clk_i              => hr_clk_i,
         src_data_i(3 downto 0) => hr_crt_status,
         dst_clk_i              => qnice_clk_i,
         dst_data_o(3 downto 0) => qnice_crt_status
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
         src_data_i( 6 downto  0) => main_crt_bank_lo_i,
         src_data_i(13 downto  7) => main_crt_bank_hi_i,
         dst_clk_i                => hr_clk_i,
         dst_data_o( 6 downto  0) => hr_crt_bank_lo,
         dst_data_o(13 downto  7) => hr_crt_bank_hi
      ); -- i_cdc_main2hr


   -------------------------------------------------------------
   -- Instantiate SW cartridge emulation.
   -- This module runs entire within the HyperRAM clock domain.
   -------------------------------------------------------------

   i_crt2hyperram : entity work.crt2hyperram
      port map (
         clk_i               => hr_clk_i,
         rst_i               => hr_rst_i,
         address_i           => hr_cartridge_address,
         length_i            => hr_cartridge_length,
         start_i             => hr_cartridge_crt_loaded,
         crt_bank_lo_i       => hr_crt_bank_lo,
         crt_bank_hi_i       => hr_crt_bank_hi,
         status_o            => hr_crt_status,
         avm_write_o         => hr_crt_write_o,
         avm_read_o          => hr_crt_read_o,
         avm_address_o       => hr_crt_address_o(21 downto 0),
         avm_writedata_o     => hr_crt_writedata_o,
         avm_byteenable_o    => hr_crt_byteenable_o,
         avm_burstcount_o    => hr_crt_burstcount_o,
         avm_readdata_i      => hr_crt_readdata_i,
         avm_readdatavalid_i => hr_crt_readdatavalid_i,
         avm_waitrequest_i   => hr_crt_waitrequest_i,
         cart_bank_laddr_o   => hr_crt_bank_laddr,
         cart_bank_size_o    => hr_crt_bank_size,
         cart_bank_num_o     => hr_crt_bank_num,
         cart_bank_raddr_o   => hr_crt_bank_raddr,
         cart_bank_wr_o      => hr_crt_bank_wr,
         cart_loading_o      => hr_crt_loading,
         cart_id_o           => hr_crt_id,
         cart_exrom_o        => hr_crt_exrom,
         cart_game_o         => hr_crt_game,
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
       src_valid_i              => hr_crt_bank_wr,
       src_data_i(15 downto  0) => hr_crt_bank_laddr,
       src_data_i(31 downto 16) => hr_crt_bank_size,
       src_data_i(47 downto 32) => hr_crt_bank_num,
       src_data_i(55 downto 48) => hr_crt_bank_type,
       src_data_i(80 downto 56) => hr_crt_bank_raddr,
       dst_clk_i                => main_clk_i,
       dst_valid_o              => main_crt_bank_wr_o,
       dst_data_o(15 downto  0) => main_crt_bank_laddr_o,
       dst_data_o(31 downto 16) => main_crt_bank_size_o,
       dst_data_o(47 downto 32) => main_crt_bank_num_o,
       dst_data_o(55 downto 48) => main_crt_bank_type_o,
       dst_data_o(80 downto 56) => main_crt_bank_raddr_o
     ); -- i_cdc_slow

   i_cdc_stable : entity work.cdc_stable
     generic map (
       G_DATA_SIZE    => 33,
       G_REGISTER_SRC => false
     )
     port map (
       src_clk_i                => hr_clk_i,
       src_data_i(15 downto  0) => hr_crt_id,
       src_data_i(23 downto 16) => hr_crt_exrom,
       src_data_i(31 downto 24) => hr_crt_game,
       src_data_i(32)           => hr_crt_loading,
       dst_clk_i                => main_clk_i,
       dst_data_o(15 downto  0) => main_crt_id_o,
       dst_data_o(23 downto 16) => main_crt_exrom_o,
       dst_data_o(31 downto 24) => main_crt_game_o,
       dst_data_o(32)           => main_crt_loading_o
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
         q_a        => main_crt_lo_ram_data_o,

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
         q_a        => main_crt_hi_ram_data_o,

         clock_b    => hr_clk_i,
         address_b  => hr_bram_address,
         data_b     => hr_bram_data,
         wren_b     => hr_bram_hi_wren,
         q_b        => open
      ); -- crt_lo_ram

end architecture synthesis;

