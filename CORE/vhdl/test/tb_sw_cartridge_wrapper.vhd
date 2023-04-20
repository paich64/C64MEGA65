library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sw_cartridge_wrapper is
   generic (
      G_FILE_NAME : string := ""
   );
end entity tb_sw_cartridge_wrapper;

architecture simulation of tb_sw_cartridge_wrapper is

   -- Clock and reset
   signal qnice_clk            : std_logic := '0';
   signal qnice_rst            : std_logic := '1';
   signal main_clk             : std_logic := '0';
   signal main_rst             : std_logic := '1';
   signal hr_clk               : std_logic := '0';
   signal hr_rst               : std_logic := '1';

   -- Signals driven by tester_sim
   signal qnice_addr           : std_logic_vector(27 downto 0);
   signal qnice_writedata      : std_logic_vector(15 downto 0);
   signal qnice_ce             : std_logic;
   signal qnice_we             : std_logic;
   signal qnice_readdata       : std_logic_vector(15 downto 0);
   signal qnice_wait           : std_logic;
   signal qnice_length         : natural;

   -- Signals driven by sw_cartridge_wrapper
   signal main_loading         : std_logic;
   signal main_id              : std_logic_vector(15 downto 0);
   signal main_exrom           : std_logic_vector( 7 downto 0);
   signal main_game            : std_logic_vector( 7 downto 0);
   signal main_bank_laddr      : std_logic_vector(15 downto 0);
   signal main_bank_size       : std_logic_vector(15 downto 0);
   signal main_bank_num        : std_logic_vector(15 downto 0);
   signal main_bank_type       : std_logic_vector( 7 downto 0);
   signal main_bank_raddr      : std_logic_vector(24 downto 0);
   signal main_bank_wr         : std_logic;
   signal main_lo_ram_data     : std_logic_vector(15 downto 0);
   signal main_hi_ram_data     : std_logic_vector(15 downto 0);
   signal main_ram_data_to_c64 : std_logic_vector( 7 downto 0);
   signal main_bank_wait       : std_logic;

   -- Signals driven by sw_cartridge_wrapper
   signal hr_write             : std_logic;
   signal hr_read              : std_logic;
   signal hr_address           : std_logic_vector(31 downto 0);
   signal hr_writedata         : std_logic_vector(15 downto 0);
   signal hr_byteenable        : std_logic_vector( 1 downto 0);
   signal hr_burstcount        : std_logic_vector( 7 downto 0);
   signal hr_readdata          : std_logic_vector(15 downto 0);
   signal hr_readdatavalid     : std_logic;
   signal hr_waitrequest       : std_logic;

   -- Signals driven by tester_sim.vhd
   signal tb_roml              : std_logic;
   signal tb_romh              : std_logic;
   signal tb_umaxromh          : std_logic;
   signal tb_ioe               : std_logic;
   signal tb_iof               : std_logic;
   signal tb_mem_write         : std_logic;
   signal tb_mem_ce            : std_logic;
   signal tb_addr              : std_logic_vector(15 downto 0);
   signal tb_data              : std_logic_vector( 7 downto 0);
   signal tb_ram_addr          : std_logic_vector(15 downto 0);
   signal tb_freeze_key        : std_logic;
   signal tb_mod_key           : std_logic;
   signal tb_nmi_ack           : std_logic;
   signal tb_running           : std_logic := '1';

   -- Signals driven by cartridge.v
   signal cart_exrom           : std_logic;
   signal cart_game            : std_logic;
   signal cart_mem_ce_out      : std_logic;
   signal cart_mem_write_out   : std_logic;
   signal cart_io_rom          : std_logic;
   signal cart_io_rd           : std_logic;
   signal cart_io_data         : std_logic_vector( 7 downto 0);
   signal cart_addr_out        : std_logic_vector(24 downto 0);
   signal cart_bank_lo         : std_logic_vector( 6 downto 0);
   signal cart_bank_hi         : std_logic_vector( 6 downto 0);
   signal cart_nmi             : std_logic;


   -- Verilog file from MiSTer core
   component cartridge
      port (
         clk32           : in  std_logic;
         reset_n         : in  std_logic;
         cart_loading    : in  std_logic;
         cart_id         : in  std_logic_vector(15 downto 0);
         cart_exrom      : in  std_logic_vector( 7 downto 0);
         cart_game       : in  std_logic_vector( 7 downto 0);
         cart_bank_laddr : in  std_logic_vector(15 downto 0);
         cart_bank_size  : in  std_logic_vector(15 downto 0);
         cart_bank_num   : in  std_logic_vector(15 downto 0);
         cart_bank_type  : in  std_logic_vector( 7 downto 0);
         cart_bank_raddr : in  std_logic_vector(24 downto 0);
         cart_bank_wr    : in  std_logic;
         exrom           : out std_logic;
         game            : out std_logic;
         romL            : in  std_logic;
         romH            : in  std_logic;
         UMAXromH        : in  std_logic;
         IOE             : in  std_logic;
         IOF             : in  std_logic;
         mem_write       : in  std_logic;
         mem_ce          : in  std_logic;
         mem_ce_out      : out std_logic;
         mem_write_out   : out std_logic;
         IO_rom          : out std_logic;
         IO_rd           : out std_logic;
         IO_data         : out std_logic_vector( 7 downto 0);
         addr_in         : in  std_logic_vector(15 downto 0);
         data_in         : in  std_logic_vector( 7 downto 0);
         addr_out        : out std_logic_vector(24 downto 0);
         bank_lo         : out std_logic_vector(6 downto 0);
         bank_hi         : out std_logic_vector(6 downto 0);
         freeze_key      : in  std_logic;
         mod_key         : in  std_logic;
         nmi             : out std_logic;
         nmi_ack         : in  std_logic
      );
   end component cartridge;

begin

   -------------------
   -- Clock and reset
   -------------------

   hr_clk    <= tb_running and not hr_clk    after  5 ns;
   qnice_clk <= tb_running and not qnice_clk after 10 ns;
   main_clk  <= tb_running and not main_clk  after 15 ns;

   hr_rst    <= '1', '0' after 100 ns;
   qnice_rst <= '1', '0' after 100 ns;


   main_ram_data_to_c64 <= main_lo_ram_data(15 downto 8) when tb_roml = '1' and tb_ram_addr(0) = '1' else
                           main_lo_ram_data( 7 downto 0) when tb_roml = '1' and tb_ram_addr(0) = '0' else
                           main_hi_ram_data(15 downto 8) when tb_romh = '1' and tb_ram_addr(0) = '1' else
                           main_hi_ram_data( 7 downto 0) when tb_romh = '1' and tb_ram_addr(0) = '0' else
                           X"00";

   -----------------------------------
   -- Instantiate main test procedure
   -----------------------------------

   i_tester_sim : entity work.tester_sim
      port map (
         qnice_clk_i       => qnice_clk,
         qnice_rst_i       => qnice_rst,
         qnice_addr_o      => qnice_addr,
         qnice_writedata_o => qnice_writedata,
         qnice_ce_o        => qnice_ce,
         qnice_we_o        => qnice_we,
         qnice_readdata_i  => qnice_readdata,
         qnice_wait_i      => qnice_wait,
         qnice_length_i    => qnice_length,
         main_clk_i        => main_clk,
         main_rst_o        => main_rst,
         tb_loading_i      => main_loading,
         tb_bank_wait_i    => main_bank_wait,
         tb_ram_addr_o     => tb_ram_addr,
         tb_ram_data_i     => main_ram_data_to_c64,
         tb_roml_o         => tb_roml,
         tb_romh_o         => tb_romh,
         tb_umaxromh_o     => tb_umaxromh,
         tb_ioe_o          => tb_ioe,
         tb_iof_o          => tb_iof,
         tb_mem_write_o    => tb_mem_write,
         tb_mem_ce_o       => tb_mem_ce,
         tb_addr_o         => tb_addr,
         tb_data_o         => tb_data,
         tb_freeze_key_o   => tb_freeze_key,
         tb_mod_key_o      => tb_mod_key,
         tb_nmi_ack_o      => tb_nmi_ack,
         tb_running_o      => tb_running
      ); -- i_tester_sim


   -------------------
   -- Instantiate DUT
   -------------------

   i_sw_cartridge_wrapper : entity work.sw_cartridge_wrapper
      generic map (
         G_BASE_ADDRESS => (others => '0')
      )
      port map (
         qnice_clk_i        => qnice_clk,
         qnice_rst_i        => qnice_rst,
         qnice_addr_i       => qnice_addr,
         qnice_data_i       => qnice_writedata,
         qnice_ce_i         => qnice_ce,
         qnice_we_i         => qnice_we,
         qnice_data_o       => qnice_readdata,
         qnice_wait_o       => qnice_wait,
         main_clk_i         => main_clk,
         main_rst_i         => main_rst,
         main_loading_o     => main_loading,
         main_id_o          => main_id,
         main_exrom_o       => main_exrom,
         main_game_o        => main_game,
         main_bank_laddr_o  => main_bank_laddr,
         main_bank_size_o   => main_bank_size,
         main_bank_num_o    => main_bank_num,
         main_bank_type_o   => main_bank_type,
         main_bank_raddr_o  => main_bank_raddr,
         main_bank_wr_o     => main_bank_wr,
         main_bank_lo_i     => cart_bank_lo,
         main_bank_hi_i     => cart_bank_hi,
         main_bank_wait_o   => main_bank_wait,
         main_ram_addr_i    => tb_ram_addr,
         main_lo_ram_data_o => main_lo_ram_data,
         main_hi_ram_data_o => main_hi_ram_data,
         hr_clk_i           => hr_clk,
         hr_rst_i           => hr_rst,
         hr_write_o         => hr_write,
         hr_read_o          => hr_read,
         hr_address_o       => hr_address,
         hr_writedata_o     => hr_writedata,
         hr_byteenable_o    => hr_byteenable,
         hr_burstcount_o    => hr_burstcount,
         hr_readdata_i      => hr_readdata,
         hr_readdatavalid_i => hr_readdatavalid,
         hr_waitrequest_i   => hr_waitrequest
      ); -- i_sw_cartridge_wrapper

   i_cartridge : component cartridge
      port map (
         clk32           => main_clk,                          -- input
         reset_n         => not main_rst,                      -- input
         cart_loading    => main_loading,                      -- input
         cart_id         => main_id,                           -- input
         cart_exrom      => main_exrom,                        -- input
         cart_game       => main_game,                         -- input
         cart_bank_laddr => main_bank_laddr,                   -- input
         cart_bank_size  => main_bank_size,                    -- input
         cart_bank_num   => main_bank_num,                     -- input
         cart_bank_type  => main_bank_type,                    -- input
         cart_bank_raddr => "000000" & main_bank_num(5 downto 0) & X"000" & "0", -- input
         cart_bank_wr    => main_bank_wr,                      -- input
         exrom           => cart_exrom,                        -- output
         game            => cart_game,                         -- output
         romL            => tb_roml,                           -- input
         romH            => tb_romh,                           -- input
         UMAXromH        => tb_umaxromh,                       -- input
         IOE             => tb_ioe,                            -- input
         IOF             => tb_iof,                            -- input
         mem_write       => tb_mem_write,                      -- input
         mem_ce          => tb_mem_ce,                         -- input
         mem_ce_out      => cart_mem_ce_out,                   -- output
         mem_write_out   => cart_mem_write_out,                -- output
         IO_rom          => cart_io_rom,                       -- output
         IO_rd           => cart_io_rd,                        -- output
         IO_data         => cart_io_data,                      -- output
         addr_in         => tb_addr,                           -- input
         data_in         => tb_data,                           -- input
         addr_out        => cart_addr_out,                     -- output
         bank_lo         => cart_bank_lo,                      -- output
         bank_hi         => cart_bank_hi,                      -- output
         freeze_key      => tb_freeze_key,                     -- input
         mod_key         => tb_mod_key,                        -- input
         nmi             => cart_nmi,                          -- output
         nmi_ack         => tb_nmi_ack                         -- input
      ); -- i_cartridge

   i_avm_rom : entity work.avm_rom
      generic map (
         G_INIT_FILE    => G_FILE_NAME,
         G_ADDRESS_SIZE => 20,
         G_DATA_SIZE    => 16
      )
      port map (
         clk_i               => hr_clk,
         rst_i               => hr_rst,
         avm_write_i         => hr_write,
         avm_read_i          => hr_read,
         avm_address_i       => hr_address(19 downto 0),
         avm_writedata_i     => hr_writedata,
         avm_byteenable_i    => hr_byteenable,
         avm_burstcount_i    => hr_burstcount,
         avm_readdata_o      => hr_readdata,
         avm_readdatavalid_o => hr_readdatavalid,
         avm_waitrequest_o   => hr_waitrequest,
         length_o            => qnice_length
      ); -- i_avm_rom

end architecture simulation;

