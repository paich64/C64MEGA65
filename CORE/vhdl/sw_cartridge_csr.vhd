library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module acts as a complete wrapper around the SW cartridge emulation.
-- It contains interfaces to the QNICE, to the C64 core, and to the HyperRAM.

entity sw_cartridge_csr is
generic (
   G_BASE_ADDRESS : std_logic_vector(21 downto 0)
);
port (
   qnice_clk_i               : in  std_logic;
   qnice_rst_i               : in  std_logic;
   qnice_addr_i              : in  std_logic_vector(27 downto 0);
   qnice_data_i              : in  std_logic_vector(15 downto 0);
   qnice_ce_i                : in  std_logic;
   qnice_we_i                : in  std_logic;
   qnice_data_o              : out std_logic_vector(15 downto 0);
   qnice_wait_o              : out std_logic;

   qnice_req_status_o        : out std_logic_vector(15 downto 0);
   qnice_req_length_o        : out std_logic_vector(22 downto 0);
   qnice_req_valid_o         : out std_logic;
   qnice_resp_status_i       : in  std_logic_vector( 3 downto 0);
   qnice_resp_error_i        : in  std_logic_vector( 3 downto 0);
   qnice_resp_address_i      : in  std_logic_vector(22 downto 0);

   qnice_avm_write_o         : out std_logic;
   qnice_avm_read_o          : out std_logic;
   qnice_avm_address_o       : out std_logic_vector(31 downto 0);
   qnice_avm_writedata_o     : out std_logic_vector(15 downto 0);
   qnice_avm_byteenable_o    : out std_logic_vector( 1 downto 0);
   qnice_avm_burstcount_o    : out std_logic_vector( 7 downto 0);
   qnice_avm_readdata_i      : in  std_logic_vector(15 downto 0);
   qnice_avm_readdatavalid_i : in  std_logic;
   qnice_avm_waitrequest_i   : in  std_logic
);
end entity sw_cartridge_csr;

architecture synthesis of sw_cartridge_csr is

   constant C_ERROR_STRING_LENGTH : integer := 21;
   type string_vector is array (natural range <>) of string(1 to C_ERROR_STRING_LENGTH);
   constant C_ERROR_STRINGS : string_vector(0 to 7) := (
     "OK                 \n",
     "Missing CRT header \n",
     "Missing CHIP header\n",
     "Wrong CRT header   \n",
     "Wrong CHIP header  \n",
     "Truncated CHIP     \n",
     "OK                 \n",
     "OK                 \n");


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

   signal qnice_stat_data         : std_logic_vector( 7 downto 0);
   signal qnice_hr_ce             : std_logic;
   signal qnice_hr_addr           : std_logic_vector(31 downto 0);
   signal qnice_hr_wait           : std_logic;
   signal qnice_hr_data           : std_logic_vector(15 downto 0);
   signal qnice_hr_byteenable     : std_logic_vector( 1 downto 0);

begin

   ----------------------------------------
   -- Decode information from and to QNICE
   ----------------------------------------

   qnice_req_valid_o <= '1' when qnice_req_status_o = C_CRT_ST_OK else '0';

   process (qnice_clk_i)
   begin
      if falling_edge(qnice_clk_i) then
         if qnice_ce_i = '1' and
            qnice_we_i = '1' and
            unsigned(qnice_addr_i(27 downto 12)) = C_CRT_CASREG
         then
            case unsigned(qnice_addr_i(11 downto 0)) is
               when C_CRT_STATUS => qnice_req_status_o                <= qnice_data_i;
               when C_CRT_FS_LO  => qnice_req_length_o(15 downto  0)  <= qnice_data_i;
               when C_CRT_FS_HI  => qnice_req_length_o(22 downto 16)  <= qnice_data_i(6 downto 0);
               when others => null;
            end case;
         end if;

         if qnice_rst_i = '1' then
            qnice_req_status_o <= (others => '0');
            qnice_req_length_o <= (others => '0');
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
      error_index_v := to_integer(unsigned(qnice_resp_error_i(2 downto 0)));
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
            when to_integer(C_CRT_STATUS)  => qnice_data_o <= qnice_req_status_o;
            when to_integer(C_CRT_FS_LO)   => qnice_data_o <= qnice_req_length_o(15 downto  0);
            when to_integer(C_CRT_FS_HI)   => qnice_data_o(6 downto 0) <= qnice_req_length_o(22 downto 16);
            when to_integer(C_CRT_PARSEST) => qnice_data_o <= X"000" & qnice_resp_status_i;
            when to_integer(C_CRT_PARSEE1) => qnice_data_o <= X"000" & qnice_resp_error_i;
            when to_integer(C_CRT_ADDR_LO) => qnice_data_o <= qnice_resp_address_i(15 downto 0);
            when to_integer(C_CRT_ADDR_HI) => qnice_data_o <= "000000000" & qnice_resp_address_i(22 downto 16);
            when to_integer(C_CRT_ERR_START)
              to to_integer(C_CRT_ERR_END) => qnice_data_o <= X"00" & qnice_stat_data;
            when others => null;
         end case;
      end if;

      if qnice_ce_i = '1' and unsigned(qnice_addr_i(27 downto 12)) /= C_CRT_CASREG then
         qnice_wait_o <= qnice_hr_wait;
         if qnice_addr_i(0) = '1' then
            qnice_data_o <= X"00" & qnice_hr_data(15 downto 8);
         else
            qnice_data_o <= X"00" & qnice_hr_data(7 downto 0);
         end if;
      end if;
   end process;

   qnice_hr_ce <= qnice_ce_i when unsigned(qnice_addr_i(27 downto 12)) /= C_CRT_CASREG
             else '0';
   qnice_hr_addr <= std_logic_vector(("00000" & unsigned(qnice_addr_i(27 downto 1))) +
                                     ("0000000000" & unsigned(G_BASE_ADDRESS)));
   qnice_hr_byteenable <= "10" when qnice_addr_i(0) = '1'
                     else "01";

   i_qnice2hyperram : entity work.qnice2hyperram
      port map (
         clk_i                 => qnice_clk_i,
         rst_i                 => qnice_rst_i,
         s_qnice_wait_o        => qnice_hr_wait,
         s_qnice_address_i     => qnice_hr_addr,
         s_qnice_cs_i          => qnice_hr_ce,
         s_qnice_write_i       => qnice_we_i,
         s_qnice_writedata_i   => qnice_data_i(7 downto 0) & qnice_data_i(7 downto 0),
         s_qnice_byteenable_i  => qnice_hr_byteenable,
         s_qnice_readdata_o    => qnice_hr_data,
         m_avm_write_o         => qnice_avm_write_o,
         m_avm_read_o          => qnice_avm_read_o,
         m_avm_address_o       => qnice_avm_address_o,
         m_avm_writedata_o     => qnice_avm_writedata_o,
         m_avm_byteenable_o    => qnice_avm_byteenable_o,
         m_avm_burstcount_o    => qnice_avm_burstcount_o,
         m_avm_readdata_i      => qnice_avm_readdata_i,
         m_avm_readdatavalid_i => qnice_avm_readdatavalid_i,
         m_avm_waitrequest_i   => qnice_avm_waitrequest_i
      ); -- i_qnice2hyperram

end architecture synthesis;

