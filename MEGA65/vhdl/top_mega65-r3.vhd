----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65  
--
-- MEGA65 R3 main file that contains the whole machine
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity mega65_r3 is
port (
   CLK            : in  std_logic;                  -- 100 MHz clock
   
   -- MAX10 FPGA (delivers reset)
   max10_tx          : in std_logic;
   max10_rx          : out std_logic;
   max10_clkandsync  : inout std_logic;
   
   -- serial communication (rxd, txd only; rts/cts are not available)
   -- 115.200 baud, 8-N-1
   UART_RXD       : in  std_logic;                  -- receive data
   UART_TXD       : out std_logic;                  -- send data

   -- VGA and VDAC
   VGA_RED        : out std_logic_vector(7 downto 0);
   VGA_GREEN      : out std_logic_vector(7 downto 0);
   VGA_BLUE       : out std_logic_vector(7 downto 0);
   VGA_HS         : out std_logic;
   VGA_VS         : out std_logic;

   vdac_clk       : out std_logic;
   vdac_sync_n    : out std_logic;
   vdac_blank_n   : out std_logic;

   -- Digital Video (HDMI)
   tmds_data_p    : out std_logic_vector(2 downto 0);
   tmds_data_n    : out std_logic_vector(2 downto 0);
   tmds_clk_p     : out std_logic;
   tmds_clk_n     : out std_logic;

   -- MEGA65 smart keyboard controller
   kb_io0         : out std_logic;                 -- clock to keyboard
   kb_io1         : out std_logic;                 -- data output to keyboard
   kb_io2         : in  std_logic;                 -- data input from keyboard

   -- SD Card (internal on bottom)
   SD_RESET       : out std_logic;
   SD_CLK         : out std_logic;
   SD_MOSI        : out std_logic;
   SD_MISO        : in  std_logic;
   SD_CD          : in  std_logic;

   -- SD Card (external on back)
   SD2_RESET      : out std_logic;
   SD2_CLK        : out std_logic;
   SD2_MOSI       : out std_logic;
   SD2_MISO       : in  std_logic;
   SD2_CD         : in  std_logic;

   -- 3.5mm analog audio jack
   pwm_l          : out std_logic;
   pwm_r          : out std_logic;

   -- Joysticks
   joy_1_up_n     : in  std_logic;
   joy_1_down_n   : in  std_logic;
   joy_1_left_n   : in  std_logic;
   joy_1_right_n  : in  std_logic;
   joy_1_fire_n   : in  std_logic;

   joy_2_up_n     : in  std_logic;
   joy_2_down_n   : in  std_logic;
   joy_2_left_n   : in  std_logic;
   joy_2_right_n  : in  std_logic;
   joy_2_fire_n   : in  std_logic;

   -- Built-in HyperRAM
   hr_d           : inout std_logic_vector(7 downto 0);    -- Data/Address
   hr_rwds        : inout std_logic;               -- RW Data strobe
   hr_reset       : out std_logic;                 -- Active low RESET line to HyperRAM
   hr_clk_p       : out std_logic;
   hr_cs0         : out std_logic

   -- Optional additional HyperRAM in trap-door slot
--   hr2_d          : inout unsigned(7 downto 0);    -- Data/Address
--   hr2_rwds       : inout std_logic;               -- RW Data strobe
--   hr2_reset      : out std_logic;                 -- Active low RESET line to HyperRAM
--   hr2_clk_p      : out std_logic;
--   hr_cs1         : out std_logic
);
end entity mega65_r3;

architecture synthesis of mega65_r3 is

constant BOARD_CLK_SPEED   : natural := 100_000_000;

signal reset_n             : std_logic;
signal dbnce_reset_n       : std_logic;
  
signal dbnce_joy1_up_n     : std_logic;
signal dbnce_joy1_down_n   : std_logic;
signal dbnce_joy1_left_n   : std_logic;
signal dbnce_joy1_right_n  : std_logic;
signal dbnce_joy1_fire_n   : std_logic;
     
signal dbnce_joy2_up_n     : std_logic;
signal dbnce_joy2_down_n   : std_logic;
signal dbnce_joy2_left_n   : std_logic;
signal dbnce_joy2_right_n  : std_logic;
signal dbnce_joy2_fire_n   : std_logic;     

-- reset control (times in ms):
-- Press the MEGA65's reset button long to activate the M2M reset, press it short for a core-only reset
constant M2M_RST_TRIGGER   : natural := 1500;
constant RST_DURATION      : natural := 50;
signal reset_m2m_n         : std_logic;
signal reset_core_n        : std_logic;
signal reset_pressed       : std_logic := '0';
signal button_duration     : natural;
signal reset_duration      : natural;

signal clk_81mhz_mmcm      : std_logic;
signal clk_81mhz           : std_logic;
signal clk_fb              : std_logic;
signal clk_81mhz_reset_n   : std_logic;

begin

   -----------------------------------------------------------------------------------------
   -- Create 81 MHz clock for MAX10 handling
   -----------------------------------------------------------------------------------------

   max_clk_gen : MMCM_ADV
     generic map
      (BANDWIDTH            => "OPTIMIZED",
       CLKOUT4_CASCADE      => FALSE,
       CLOCK_HOLD           => FALSE,
       COMPENSATION         => "ZHOLD",
       STARTUP_WAIT         => FALSE,
   
       -- Create 812.5MHz clock from 8.125x100MHz/1
       DIVCLK_DIVIDE        => 1,
       CLKFBOUT_MULT_F      => 8.125,
       CLKFBOUT_PHASE       => 0.000,
       CLKFBOUT_USE_FINE_PS => FALSE,
   
       -- CLKOUT0 = 81.25 MHz clock for MAX 10
       CLKOUT0_DIVIDE_F     => 10.0,
       CLKOUT0_PHASE        => 0.000,
       CLKOUT0_DUTY_CYCLE   => 0.500,
       CLKOUT0_USE_FINE_PS  => FALSE,
          
       CLKIN1_PERIOD        => 10.000,
       REF_JITTER1          => 0.010)
     port map
       -- Output clocks
      (CLKFBOUT            => clk_fb,
       CLKOUT0             => clk_81mhz_mmcm,
       -- Input clock control
       CLKFBIN             => clk_fb,
       CLKIN1              => CLK,
       CLKIN2              => '0',       
       -- Tied to always select the primary input clock
       CLKINSEL            => '1',
       -- Ports for dynamic reconfiguration
       DADDR               => (others => '0'),
       DCLK                => '0',
       DEN                 => '0',
       DI                  => (others => '0'),
       DWE                 => '0',
       -- Ports for dynamic phase shift
       PSCLK               => '0',
       PSEN                => '0',
       PSINCDEC            => '0',
       -- Other control and status signals
       PWRDWN              => '0',
       RST                 => '0');
       
   clk_bufg : BUFG
      port map (
         I => clk_81mhz_mmcm,
         O => clk_81mhz
      );       
   
   -----------------------------------------------------------------------------------------
   -- MAX10 FPGA handling: extract reset signal
   -----------------------------------------------------------------------------------------
   
   MAX10 : entity work.max10
      port map (
         pixelclock        => clk_81mhz,
         cpuclock          => clk_81mhz,
         led               => open,
         
         max10_rx          => max10_rx,
         max10_tx          => max10_tx,
         max10_clkandsync  => max10_clkandsync,

         max10_fpga_commit => open,
         max10_fpga_date   => open,
         reset_button      => clk_81mhz_reset_n,
         dipsw             => open,
         j21in             => open,
         j21ddr            => (others => '0'),
         j21out            => (others => '0')
      );
      
   cdc_reset : XPM_CDC_ASYNC_RST
   generic map (
      RST_ACTIVE_HIGH      => 0
   )
   port map
   (
      src_arst             => clk_81mhz_reset_n,
      dest_clk             => CLK,
      dest_arst            => reset_n
   );

   -----------------------------------------------------------------------------------------
   -- Reset management: Differentiate long and short press
   -----------------------------------------------------------------------------------------

   reset_manager : process(CLK)
   begin
      if rising_edge(CLK) then
      
         -- button pressed
         if dbnce_reset_n = '0' then
            reset_pressed        <= '1';
            reset_core_n         <= '0';  -- the core resets immediately on pressing the button
            reset_duration       <= (BOARD_CLK_SPEED / 1000) * RST_DURATION;
            if button_duration = 0 then
               reset_m2m_n       <= '0';  -- the framework only resets if the trigger time is reached
            else
               button_duration   <= button_duration - 1;            
            end if;
            
         -- button released
         else
            if reset_pressed then
               if reset_duration = 0 then
                  reset_pressed  <= '0';
               else               
                  reset_duration <= reset_duration - 1;
               end if;
            else
               reset_m2m_n       <= '1';
               reset_core_n      <= '1';            
               button_duration   <= (BOARD_CLK_SPEED / 1000) * M2M_RST_TRIGGER;               
            end if;
         end if;
      end if;
   end process;
   
   -----------------------------------------------------------------------------------------
   -- Instantiate the whole machine
   -----------------------------------------------------------------------------------------
   
   MEGA65 : entity work.MEGA65_Core
      port map
      (
         CLK            => CLK,
         
         -- M2M's reset manager provides 2 signals:
         --    RESET_M2M_N:   Reset the whole machine: Core and Framework
         --    RESET_CORE_N:  Only reset the core
         RESET_M2M_N    => reset_m2m_n,
         RESET_CORE_N   => reset_core_n,

         -- serial communication (rxd, txd only; rts/cts are not available)
         -- 115.200 baud, 8-N-1
         UART_RXD       => UART_RXD,
         UART_TXD       => UART_TXD,

         -- VGA and VDAC
         VGA_RED        => VGA_RED,
         VGA_GREEN      => VGA_GREEN,
         VGA_BLUE       => VGA_BLUE,
         VGA_HS         => VGA_HS,
         VGA_VS         => VGA_VS,

         vdac_clk       => vdac_clk,
         vdac_sync_n    => vdac_sync_n,
         vdac_blank_n   => vdac_blank_n,

         -- Digital Video (HDMI)
         tmds_data_p    => tmds_data_p,
         tmds_data_n    => tmds_data_n,
         tmds_clk_p     => tmds_clk_p,
         tmds_clk_n     => tmds_clk_n,

         -- MEGA65 smart keyboard controller
         kb_io0         => kb_io0,
         kb_io1         => kb_io1,
         kb_io2         => kb_io2,

         -- SD Card (internal on bottom)
         SD_RESET       => SD_RESET,
         SD_CLK         => SD_CLK,
         SD_MOSI        => SD_MOSI,
         SD_MISO        => SD_MISO,
         SD_CD          => SD_CD,

         -- SD Card (external on back)
         SD2_RESET      => SD2_RESET,
         SD2_CLK        => SD2_CLK,
         SD2_MOSI       => SD2_MOSI,
         SD2_MISO       => SD2_MISO,
         SD2_CD         => SD2_CD,

         -- 3.5mm analog audio jack
         pwm_l          => pwm_l,
         pwm_r          => pwm_r,

         -- Joysticks
         joy_1_up_n     => dbnce_joy1_up_n,
         joy_1_down_n   => dbnce_joy1_down_n,
         joy_1_left_n   => dbnce_joy1_left_n,
         joy_1_right_n  => dbnce_joy1_right_n,
         joy_1_fire_n   => dbnce_joy1_fire_n,

         joy_2_up_n     => dbnce_joy2_up_n,
         joy_2_down_n   => dbnce_joy2_down_n,
         joy_2_left_n   => dbnce_joy2_left_n,
         joy_2_right_n  => dbnce_joy2_right_n,
         joy_2_fire_n   => dbnce_joy2_fire_n,

         hr_d           => hr_d,
         hr_rwds        => hr_rwds,
         hr_reset       => hr_reset,
         hr_clk_p       => hr_clk_p,
         hr_cs0         => hr_cs0
      );

   i_debouncer : entity work.debouncer
      generic map ( 
         CLK_FREQ             => BOARD_CLK_SPEED
      )
      port map (
         clk                  => CLK,
 
         reset_n              => RESET_N,
         dbnce_reset_n        => dbnce_reset_n,
 
         joy_1_up_n           => joy_1_up_n,
         joy_1_down_n         => joy_1_down_n,
         joy_1_left_n         => joy_1_left_n,
         joy_1_right_n        => joy_1_right_n,
         joy_1_fire_n         => joy_1_fire_n,
 
         dbnce_joy1_up_n      => dbnce_joy1_up_n,
         dbnce_joy1_down_n    => dbnce_joy1_down_n,
         dbnce_joy1_left_n    => dbnce_joy1_left_n,
         dbnce_joy1_right_n   => dbnce_joy1_right_n,
         dbnce_joy1_fire_n    => dbnce_joy1_fire_n,
 
         joy_2_up_n           => joy_2_up_n,
         joy_2_down_n         => joy_2_down_n,
         joy_2_left_n         => joy_2_left_n,
         joy_2_right_n        => joy_2_right_n,
         joy_2_fire_n         => joy_2_fire_n,
 
         dbnce_joy2_up_n      => dbnce_joy2_up_n,
         dbnce_joy2_down_n    => dbnce_joy2_down_n,
         dbnce_joy2_left_n    => dbnce_joy2_left_n,
         dbnce_joy2_right_n   => dbnce_joy2_right_n,
         dbnce_joy2_fire_n    => dbnce_joy2_fire_n
      );

end architecture synthesis;

