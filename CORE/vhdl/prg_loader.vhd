----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- QNICE streaming device for loading PRG files into the C64's RAM
--
-- done by sy2002 in 2023 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library work;        
use work.globals.all;

entity prg_loader is
port (
   qnice_clk_i       : in  std_logic;
   qnice_rst_i       : in  std_logic;
   qnice_addr_i      : in  std_logic_vector(27 downto 0);
   qnice_data_i      : in  std_logic_vector(15 downto 0);
   qnice_ce_i        : in  std_logic;
   qnice_we_i        : in  std_logic;
   qnice_data_o      : out std_logic_vector(15 downto 0);
   qnice_wait_o      : out std_logic;

   c64ram_we_o       : out std_logic;
   c64ram_addr_o     : out std_logic_vector(15 downto 0);
   c64ram_data_i     : in std_logic_vector(7 downto 0);
   c64ram_data_o     : out std_logic_vector(7 downto 0);
   
   core_reset_o      : out std_logic;  -- reset the core when the PRG loading starts
   core_triggerrun_o : out std_logic   -- trigger program auto starts after loading finished
);
end prg_loader;

architecture beh of prg_loader is

   -- Status reporting from QNICE
   constant C_CRT_ST_IDLE         : std_logic_vector(15 downto 0) := X"0000";
   constant C_CRT_ST_LDNG         : std_logic_vector(15 downto 0) := X"0001";
   constant C_CRT_ST_ERR          : std_logic_vector(15 downto 0) := X"0002";
   constant C_CRT_ST_OK           : std_logic_vector(15 downto 0) := X"0003";

   -- Status reporting to QNICE   
   constant C_STAT_IDLE         : std_logic_vector(3 downto 0) := "0000";
   constant C_STAT_PARSING      : std_logic_vector(3 downto 0) := "0001";
   constant C_STAT_READY        : std_logic_vector(3 downto 0) := "0010"; -- Successfully parsed CRT file
   constant C_STAT_ERROR        : std_logic_vector(3 downto 0) := "0011"; -- Error parsing CRT file
   
   -- Control & status register
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
   signal qnice_req_length        : std_logic_vector(31 downto 0);
   signal qnice_req_valid         : std_logic;
   signal qnice_resp_status       : std_logic_vector( 3 downto 0);
   signal qnice_resp_error        : std_logic_vector( 3 downto 0);
   
   -- PRG load address
   signal prg_start               : unsigned(15 downto 0);
   
   -- Communication and reset state machine (see comment directly at the state machine below)
   constant C_COMM_DELAY          : natural := 50;
   constant C_RESET_DELAY         : natural := 4 * CORE_CLK_SPEED;  -- 3 seconds
        
   type t_comm_state is (IDLE_ST,
                         RESET_ST,
                         RESET_POST_ST,
                         TRIGGER_RUN_ST);

   signal state : t_comm_state := IDLE_ST;                         
   signal delay : natural range 0 to C_RESET_DELAY;

begin

   -- Write to registers
   process (qnice_clk_i)
   begin
      if falling_edge(qnice_clk_i) then    
         if qnice_ce_i = '1' and qnice_we_i = '1' then
            -- control and status register
            if unsigned(qnice_addr_i(27 downto 12)) = C_CRT_CASREG then
               case unsigned(qnice_addr_i(11 downto 0)) is
                  when C_CRT_STATUS =>
                     qnice_req_status <= qnice_data_i;
                     if qnice_data_i = C_CRT_ST_LDNG then
                        state <= RESET_ST;
                     elsif qnice_data_i = C_CRT_ST_OK then
                        state <= TRIGGER_RUN_ST;
                     end if;
                  when C_CRT_FS_LO  => qnice_req_length(15 downto  0)  <= qnice_data_i;
                  when C_CRT_FS_HI  => qnice_req_length(31 downto 16)  <= qnice_data_i;
                  when others => null;
               end case;
            
            -- extract low byte of program start
            elsif qnice_addr_i(27 downto 0) = x"000" & "0000" then
               prg_start(7 downto 0) <= unsigned(qnice_data_i(7 downto 0));
            elsif qnice_addr_i(27 downto 0) = x"000" & "0001" then
               prg_start(15 downto 8) <= unsigned(qnice_data_i(7 downto 0));
            end if;
         end if;

         -- Due to the falling_edge nature of QNICE, one QNICE cycle is not enough to ensure that the core
         -- which runs in another clock domain registers core_reset_o or core_triggerrun_o. Therefore we
         -- hold the signal C_COMM_DELAY QNICE cycles high.
         --
         -- While the C64 resets, it clears some status memory locations so that QNICE needs to wait before
         -- loading the PRG until the reset is done (C_RESET_DELAY), otherwise we have a race condition.  
         case state is
            when IDLE_ST =>
               qnice_wait_o       <= '0';
               core_reset_o       <= '0';
               core_triggerrun_o  <= '0';
               delay              <= C_COMM_DELAY;
               
            when RESET_ST =>
               qnice_wait_o <= '1';
               core_reset_o <= '1';
               if delay = 0 then
                  state <= RESET_POST_ST;
                  delay <= C_RESET_DELAY;
                  core_reset_o <= '0';
               else
                  delay <= delay - 1;
               end if;

            when RESET_POST_ST =>
               if delay = 0 then
                  state <= IDLE_ST;
               else
                  delay <= delay - 1;
               end if;
               
            when TRIGGER_RUN_ST =>
               core_triggerrun_o <= '1';
               if delay = 0 then
                  state <= IDLE_ST;
               else
                  delay <= delay - 1;
               end if;

            when others =>
               null;
         end case;

         if qnice_rst_i = '1' then
            qnice_req_status  <= C_CRT_ST_IDLE;           
            qnice_req_length  <= (others => '0');
            prg_start         <= (others => '0');
            core_reset_o      <= '0';
            core_triggerrun_o <= '0';
            qnice_wait_o      <= '0';
            state             <= IDLE_ST;
         end if;
      end if;
   end process;
   
   -- Read from registers and handle the C64 RAM signals
   process(all)
   begin
      qnice_data_o <= x"0000"; -- By default read back zeros
      
      c64ram_addr_o  <= std_logic_vector(prg_start + unsigned(qnice_addr_i(15 downto 0) - 2));
      c64ram_data_o  <= (others => '0');         
      c64ram_we_o    <= '0';  
      
      -- for now: hardcoded as we do not really parse anything
      qnice_resp_status <= C_STAT_READY;
      qnice_resp_error <= (others => '0');
           
      -- Control and status registers
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
            when others => null;
         end case;
      end if;
      
      -- Handle C64 RAM signals
      if qnice_ce_i = '1' and unsigned(qnice_addr_i(27 downto 0)) > 1 and unsigned(qnice_addr_i(27 downto 12)) /= C_CRT_CASREG then
         if qnice_we_i = '0' then
            qnice_data_o <= x"00" & c64ram_data_i;
         else
            c64ram_we_o <= '1';
            c64ram_data_o <= qnice_data_i(7 downto 0);
         end if;
      end if;
   end process;

end architecture beh;