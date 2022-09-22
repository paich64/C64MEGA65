library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library xpm;
use xpm.vcomponents.all;

entity reu_mapper is
   generic (
      G_BASE_ADDRESS : std_logic_vector(31 downto 0)
   );
   port (
      clk_i              : in  std_logic; -- 32 MHz
      rst_i              : in  std_logic;
      ext_cycle_i        : in  std_logic; -- From C64
      reu_cycle_o        : out std_logic; -- To REU
      reu_addr_i         : in  std_logic_vector(24 downto 0);  -- 32 MB
      reu_dout_i         : in  std_logic_vector(7 downto 0);
      reu_din_o          : out std_logic_vector(7 downto 0);
      reu_we_i           : in  std_logic;

      hr_clk_i           : in  std_logic; -- 100 MHz
      hr_rst_i           : in  std_logic;
      hr_write_o         : out std_logic;
      hr_read_o          : out std_logic;
      hr_address_o       : out std_logic_vector(31 downto 0);
      hr_writedata_o     : out std_logic_vector(15 downto 0);
      hr_byteenable_o    : out std_logic_vector(1 downto 0);
      hr_burstcount_o    : out std_logic_vector(7 downto 0);
      hr_readdata_i      : in  std_logic_vector(15 downto 0);
      hr_readdatavalid_i : in  std_logic;
      hr_waitrequest_i   : in  std_logic
   );
end entity reu_mapper;

architecture synthesis of reu_mapper is

   signal hr_address : std_logic_vector(24 downto 0);

begin

   i_xpm_cdc_array_single_addr : xpm_cdc_array_single
      generic map (
         SRC_INPUT_REG => 0,
         DEST_SYNC_FF  => 2,
         WIDTH         => 25
      )
      port map (
         src_clk  => clk_i,
         src_in   => reu_addr_i,
         dest_clk => hr_clk_i,
         dest_out => hr_address

      ); -- i_xpm_cdc_array_single_addr
   hr_address_o <= ("0000000" & hr_address) + G_BASE_ADDRESS;

   i_xpm_cdc_array_single_dout : xpm_cdc_array_single
      generic map (
         SRC_INPUT_REG => 0,
         DEST_SYNC_FF  => 2,
         WIDTH         => 8
      )
      port map (
         src_clk  => clk_i,
         src_in   => reu_dout_i,
         dest_clk => hr_clk_i,
         dest_out => hr_writedata_o(7 downto 0)

      ); -- i_xpm_cdc_array_single_dout
   hr_writedata_o(15 downto 8) <= (others => '0');

   i_xpm_cdc_array_single_din : xpm_cdc_array_single
      generic map (
         SRC_INPUT_REG => 0,
         DEST_SYNC_FF  => 2,
         WIDTH         => 8
      )
      port map (
         src_clk  => hr_clk_i,
         src_in   => hr_readdata_i(7 downto 0),
         dest_clk => clk_i,
         dest_out => reu_din_o
      ); -- i_xpm_cdc_array_single_din


   hr_byteenable_o <= "01";
   hr_burstcount_o <= X"01";

   i_xpm_cdc_pulse : xpm_cdc_pulse
      generic map (
         DEST_SYNC_FF => 2,
         REG_OUTPUT   => 0,
         RST_USED     => 1
      )
      port map (
         src_clk    => clk_i,
         src_rst    => rst_i,
         src_pulse  => reu_we_i,
         dest_clk   => hr_clk_i,
         dest_rst   => hr_rst_i,
         dest_pulse => hr_write_o
      ); -- i_xpm_cdc_pulse

   reu_cycle_o <= ext_cycle_i;

end architecture synthesis;

