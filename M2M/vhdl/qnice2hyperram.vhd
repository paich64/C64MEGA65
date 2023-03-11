library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module allows the QNICE CPU to access an Avalon Memory Mapped
-- device (normally the HyperRAM device of the MEGA65).
--
-- This module runs in the QNICE clock domain.

entity qnice2hyperram is
   generic (
      G_ADDRESS_SIZE : integer                       := 21;  -- 2 MB
      G_BASE_ADDRESS : std_logic_vector(31 downto 0) := X"00000000"
   );
   port (
      -- This is the QNICE clock
      clk_i                 : in  std_logic;
      rst_i                 : in  std_logic;

      -- Connect to QNICE CPU
      -- This is a slave interface
      s_qnice_wait_o        : out std_logic;
      s_qnice_address_i     : in  std_logic_vector(G_ADDRESS_SIZE-1 downto 0);
      s_qnice_cs_i          : in  std_logic;
      s_qnice_write_i       : in  std_logic;
      s_qnice_writedata_i   : in  std_logic_vector(7 downto 0);
      s_qnice_readdata_o    : out std_logic_vector(7 downto 0);

      -- Connect to HyperRAM (via avm_fifo)
      -- This is a master interface
      m_avm_write_o         : out std_logic;
      m_avm_read_o          : out std_logic;
      m_avm_address_o       : out std_logic_vector(31 downto 0);
      m_avm_writedata_o     : out std_logic_vector(15 downto 0);
      m_avm_byteenable_o    : out std_logic_vector(1 downto 0);
      m_avm_burstcount_o    : out std_logic_vector(7 downto 0);
      m_avm_readdata_i      : in  std_logic_vector(15 downto 0);
      m_avm_readdatavalid_i : in  std_logic;
      m_avm_waitrequest_i   : in  std_logic
   );
end entity qnice2hyperram;

architecture synthesis of qnice2hyperram is

   signal reading : std_logic;
   signal msb     : std_logic;

begin

   s_qnice_wait_o <= m_avm_write_o or m_avm_read_o or reading;

   convert_proc : process (clk_i)
   begin
      if falling_edge(clk_i) then
         if m_avm_waitrequest_i = '1' then
            m_avm_write_o <= '0';
            m_avm_read_o  <= '0';
         end if;

         if s_qnice_cs_i = '1' then
            m_avm_write_o      <= s_qnice_write_i;
            m_avm_read_o       <= not s_qnice_write_i;
            m_avm_address_o    <= to_stdlogicvector(to_integer(s_qnice_address_i)/2 + to_integer(G_BASE_ADDRESS), 32);
            m_avm_writedata_o  <= s_qnice_writedata_i & s_qnice_writedata_i;
            if s_qnice_address_i(0) = '0' then
               m_avm_byteenable_o <= "01";
            else
               m_avm_byteenable_o <= "10";
            end if;
            m_avm_burstcount_o <= X"01";

            reading <= not s_qnice_write_i;
            msb <= s_qnice_address_i(0);
         end if;

         if m_avm_readdatavalid_i = '1' then
            if msb = '0' then
               s_qnice_readdata_o <= m_avm_readdata_i(7 downto 0);
            else
               s_qnice_readdata_o <= m_avm_readdata_i(15 downto 8);
            end if;
            reading            <= '0';
         end if;

         if rst_i = '1' then
            m_avm_write_o <= '0';
            m_avm_read_o  <= '0';
            reading       <= '0';
         end if;
      end if;
   end process convert_proc;

end architecture synthesis;

