library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

-- This module connects the HyperRAM device to the internal BRAM cache
-- It acts as a master towards both the HyperRAM and the BRAM.
-- It runs in the HyperRAM clock domain

entity crt2hyperram is
   port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;

      -- Control interface
      crt_busy_o          : out std_logic;
      crt_bank_lo_i       : in  std_logic_vector(6 downto 0);
      crt_bank_hi_i       : in  std_logic_vector(6 downto 0);

      -- Connect to HyperRAM
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(31 downto 0);
      avm_writedata_o     : out std_logic_vector(15 downto 0);
      avm_byteenable_o    : out std_logic_vector(1 downto 0);
      avm_burstcount_o    : out std_logic_vector(7 downto 0);
      avm_readdata_i      : in  std_logic_vector(15 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic;

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

   constant C_CRT_LO_BASE_ADDRESS : std_logic_vector(31 downto 0) := X"00200000";
   constant C_CRT_HI_BASE_ADDRESS : std_logic_vector(31 downto 0) := X"00200000";

   signal crt_bank_lo_d    : std_logic_vector(6 downto 0);
   signal crt_bank_hi_d    : std_logic_vector(6 downto 0);
   signal crt_hi_load      : std_logic;
   signal crt_hi_load_done : std_logic;
   signal crt_hi_address   : std_logic_vector(31 downto 0);
   signal crt_lo_load      : std_logic;
   signal crt_lo_load_done : std_logic;
   signal crt_lo_address   : std_logic_vector(31 downto 0);

   type t_state is (IDLE_ST, READ_HI_ST, READ_LO_ST);

   signal state : t_state := IDLE_ST;

begin

   crt_busy_o <= '0' when state = IDLE_ST and crt_lo_load = '0' and crt_hi_load = '0'  else '1';

   p_crt_load : process (clk_i)
   begin
      if rising_edge(clk_i) then
         crt_bank_lo_d  <= crt_bank_lo_i;
         crt_bank_hi_d  <= crt_bank_hi_i;
         if crt_lo_load_done = '1' then
            crt_lo_load <= '0';
         end if;
         if crt_hi_load_done = '1' then
            crt_hi_load <= '0';
         end if;
         crt_lo_address <= C_CRT_LO_BASE_ADDRESS + (X"000" & "0" & crt_bank_lo_i & X"000");
         crt_hi_address <= C_CRT_HI_BASE_ADDRESS + (X"000" & "0" & crt_bank_hi_i & X"000");

         -- Detect change in bank numbers
         if crt_bank_lo_d /= crt_bank_lo_i then
            crt_lo_load <= '1';
         end if;
         if crt_bank_hi_d /= crt_bank_hi_i then
            crt_hi_load <= '1';
         end if;

         if rst_i = '1' then
            crt_lo_load <= '1';
            crt_hi_load <= '1';
         end if;
      end if;
   end process p_crt_load;


   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         crt_lo_load_done <= '0';
         crt_hi_load_done <= '0';
         bram_hi_wren_o <= '0';
         bram_lo_wren_o <= '0';

         case state is
            when IDLE_ST =>
               if crt_hi_load = '1' and crt_hi_load_done = '0' then
                  -- Starting load to HI bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  avm_address_o      <= crt_hi_address;
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_address_o     <= (others => '1');
                  state              <= READ_HI_ST;
               elsif crt_lo_load = '1' and crt_lo_load_done = '0' then
                  -- Starting load to LO bank
                  avm_write_o        <= '0';
                  avm_read_o         <= '1';
                  avm_address_o      <= crt_lo_address;
                  avm_burstcount_o   <= X"80"; -- Read 256 bytes
                  bram_address_o     <= (others => '1');
                  state              <= READ_LO_ST;
               end if;

            when READ_HI_ST =>
               if avm_readdatavalid_i = '1' then
                  bram_data_o    <= avm_readdata_i;
                  bram_hi_wren_o <= '1';
                  bram_address_o <= bram_address_o + 1;
                  if bram_address_o = X"FFE" then
                     crt_hi_load_done <= '1';
                     state            <= IDLE_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     avm_write_o      <= '0';
                     avm_read_o       <= '1';
                     avm_address_o    <= avm_address_o + X"80";
                     avm_burstcount_o <= X"80"; -- Read 256 bytes
                  end if;
               end if;

            when READ_LO_ST =>
               if avm_readdatavalid_i = '1' then
                  bram_data_o    <= avm_readdata_i;
                  bram_lo_wren_o <= '1';
                  bram_address_o <= bram_address_o + 1;
                  if bram_address_o = X"FFE" then
                     crt_lo_load_done <= '1';
                     state            <= IDLE_ST;
                  elsif bram_address_o(6 downto 0) = X"7E" then
                     avm_write_o      <= '0';
                     avm_read_o       <= '1';
                     avm_address_o    <= avm_address_o + X"80";
                     avm_burstcount_o <= X"80"; -- Read 256 bytes
                  end if;
               end if;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            avm_write_o      <= '0';
            avm_read_o       <= '0';
            avm_address_o    <= (others => '0');
            avm_writedata_o  <= (others => '0');
            avm_byteenable_o <= (others => '0');
            avm_burstcount_o <= (others => '0');
            bram_hi_wren_o   <= '0';
            bram_lo_wren_o   <= '0';
            crt_lo_load_done <= '0';
            crt_hi_load_done <= '0';
            state            <= IDLE_ST;
         end if;

      end if;
   end process p_fsm;

end architecture synthesis;

