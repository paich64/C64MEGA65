library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module acts as a bridge connection between the RAM Expansion Unit of the C64
-- and the HyperRAM device of the MEGA65.
-- Since the two operate at different clock frequencies, this module uses
-- asynchronuous FIFO's to handle the Clock Domain Crossing.

entity reu_mapper is
   generic (
      -- Configure base address within the HyperRAM device
      G_BASE_ADDRESS : std_logic_vector(31 downto 0)
   );
   port (
      -- Main clock @ 32 MHz
      reu_clk_i          : in  std_logic;
      reu_rst_i          : in  std_logic;
      reu_ext_cycle_i    : in  std_logic; -- From C64
      reu_ext_cycle_o    : out std_logic; -- To REU
      reu_addr_i         : in  std_logic_vector(24 downto 0);  -- 32 MB
      reu_dout_i         : in  std_logic_vector(7 downto 0);
      reu_din_o          : out std_logic_vector(7 downto 0);
      reu_we_i           : in  std_logic;
      reu_cs_i           : in  std_logic;

      -- HyperRAM clock @ 100 MHz
      hr_clk_i           : in  std_logic;
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

   subtype R_FIFO_DOUT is natural range 7 downto 0;
   subtype R_FIFO_ADDR is natural range 32 downto 8;
   subtype R_FIFO_WE   is natural range 33 downto 33;
   constant C_FIFO_SIZE : natural := 40;

   signal reu_ext_cycle_d   : std_logic;

   signal reu_wr_fifo_ready : std_logic;
   signal reu_wr_fifo_valid : std_logic;
   signal reu_wr_fifo_data  : std_logic_vector(C_FIFO_SIZE-1 downto 0);

   signal hr_addr           : std_logic_vector(24 downto 0);
   signal hr_dout           : std_logic_vector(7 downto 0);
   signal hr_we             : std_logic;

   signal hr_wr_fifo_ready  : std_logic;
   signal hr_wr_fifo_valid  : std_logic;
   signal hr_wr_fifo_data   : std_logic_vector(C_FIFO_SIZE-1 downto 0);

   signal reu_rd_fifo_valid : std_logic;

begin

   p_ext_cycle_d : process (reu_clk_i)
   begin
      if rising_edge(reu_clk_i) then
         reu_ext_cycle_d <= reu_ext_cycle_i;
      end if;
   end process p_ext_cycle_d;

   -- TBD: Should there be edge detection on reu_wr_fifo_ready ?
   --      E.g. will this still work if reu_wr_fifo_ready is asserted only
   --      on the last clock cycle of reu_ext_cycle_i ?
   -- TBD: Should this depend on reu_rd_fifo_valid as well ?
   reu_ext_cycle_o <= reu_wr_fifo_ready and reu_ext_cycle_i;

   reu_wr_fifo_valid <= reu_cs_i and reu_ext_cycle_i and not reu_ext_cycle_d;  -- Pulse on rising edge

   i_axi_fifo_wr : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => C_FIFO_SIZE,
         G_USER_SIZE => 8
      )
      port map (
         s_aclk_i        => reu_clk_i,
         s_aresetn_i     => not reu_rst_i,
         s_axis_tready_o => reu_wr_fifo_ready,
         s_axis_tvalid_i => reu_wr_fifo_valid,
         s_axis_tdata_i  => reu_wr_fifo_data,
         s_axis_tkeep_i  => (others => '1'),
         s_axis_tlast_i  => '1',
         s_axis_tuser_i  => (others => '0'),
         m_aclk_i        => hr_clk_i,
         m_axis_tready_i => hr_wr_fifo_ready,
         m_axis_tvalid_o => hr_wr_fifo_valid,
         m_axis_tdata_o  => hr_wr_fifo_data,
         m_axis_tkeep_o  => open,
         m_axis_tlast_o  => open,
         m_axis_tuser_o  => open
      ); -- i_axi_fifo_wr

   reu_wr_fifo_data(R_FIFO_DOUT) <= reu_dout_i;
   reu_wr_fifo_data(R_FIFO_ADDR) <= reu_addr_i;
   reu_wr_fifo_data(R_FIFO_WE)   <= "" & reu_we_i;
   hr_dout <= hr_wr_fifo_data(R_FIFO_DOUT);
   hr_addr <= hr_wr_fifo_data(R_FIFO_ADDR);
   hr_we   <= hr_wr_fifo_data(R_FIFO_WE)(0);

   hr_wr_fifo_ready <= not hr_waitrequest_i;
   hr_write_o       <= hr_wr_fifo_valid and hr_we;
   hr_read_o        <= hr_wr_fifo_valid and (not hr_we);
   hr_address_o     <= (("0000000" & hr_addr) + G_BASE_ADDRESS) and X"003FFFFF";
   hr_writedata_o   <= X"00" & hr_dout;
   hr_byteenable_o  <= "01";
   hr_burstcount_o  <= X"01";


   i_axi_fifo_rd : entity work.axi_fifo
      generic map (
         G_DEPTH     => 16,
         G_DATA_SIZE => 8,
         G_USER_SIZE => 8
      )
      port map (
         s_aclk_i        => hr_clk_i,
         s_aresetn_i     => not hr_rst_i,
         s_axis_tready_o => open,               -- This should always be asserted.
         s_axis_tvalid_i => hr_readdatavalid_i,
         s_axis_tdata_i  => hr_readdata_i(7 downto 0),
         s_axis_tkeep_i  => (others => '1'),
         s_axis_tlast_i  => '1',
         s_axis_tuser_i  => (others => '0'),
         m_aclk_i        => reu_clk_i,
         m_axis_tready_i => '1',                -- TBD ???
         m_axis_tvalid_o => reu_rd_fifo_valid,  -- TBD ???
         m_axis_tdata_o  => reu_din_o,
         m_axis_tkeep_o  => open,
         m_axis_tlast_o  => open,
         m_axis_tuser_o  => open
      ); -- i_axi_fifo_rd

end architecture synthesis;

