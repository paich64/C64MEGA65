-------------------------------------------------------------------------------------------------------------
-- Commodore 64 for MEGA65 (C64MEGA65)
--
-- Clock Generator using the Xilinx specific MMCME2_ADV:
--
--   MiSTer's Commodore 64 expects:
--      PAL:  31,527,778 MHz, this divided by 32 = 0,98525 MHz (C64 clock speed)
--            Additionall (PAL only) we use a 0.25% slower system clock for the HDMI flicker-fix
--      NTSC: @TODO
--
-- Powered by MiSTer2MEGA65
-- MEGA65 port done by MJoergen and sy2002 in 2023 and licensed under GPL v3
-------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i       : in  std_logic;   -- expects 100 MHz
      sys_rstn_i      : in  std_logic;   -- Asynchronous, asserted low

      -- switchable clock for the C64 core
      -- 00 = PAL, as close as possuble to the C64's original clock:
      --           @TODO exact clock values for main and video here
      --
      -- 01 = PAL  HDMI flicker-fix that makes sure the C64 is synchonous with the 50 Hz PAL frequency
      --           This is 99.75% of the original system speed.
      --           @TODO exact clock values for main and video here
      --
      -- 10 = NTSC @TODO
      core_speed_i      : unsigned(1 downto 0); -- must be in qnice clock domain

      main_clk_o        : out std_logic;
      main_rst_o        : out std_logic
   );
end entity clk;

architecture rtl of clk is

signal old_core_speed     : unsigned(1 downto 0);
signal reset_c64_mmcm     : std_logic;

signal sys_clk_9975_mmcm  : std_logic;
signal main_fb_mmcm       : std_logic;
signal main_clk_mmcm      : std_logic;
signal sys_clk_9975_mmcm  : std_logic;

signal sys_clk_9975_bg    : std_logic;

signal main_locked        : std_logic;
signal sys_9975_locked    : std_logic;

signal c64_clock_select   : std_logic;


begin

   ---------------------------------------------------------------------------------------
   -- Generate 0.25% slower system clock for HDMI flicker-fix version of the C64 clock
   ---------------------------------------------------------------------------------------

   i_clk_sys_9975 : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 49.875,     -- 997.50 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 10.0,       -- 99.75 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => sys_9975_fb_mmcm,
         CLKOUT0             => sys_clk_9975_mmcm,
         -- Input clock control
         CLKFBIN             => sys_9975_fb_mmcm,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => sys_9975_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_

   ---------------------------------------------------------------------------------------
   -- Generate as-close-as-possible-to-the-original version of the C64 clock
   ---------------------------------------------------------------------------------------

   i_clk_c64 : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 6,
         CLKFBOUT_MULT_F      => 56.750,     -- 945.833 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 30.000,     -- 31.5277777778 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 15,         -- 63,0555555556 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => main_fb_mmcm,
         CLKOUT0             => main_clk_mmcm,
         -- Input clock control
         CLKFBIN             => main_fb_mmcm,
         CLKIN1              => sys_clk_i,
         CLKIN2              => sys_clk_9975_bg,
         CLKINSEL            => not core_speed_i(0),
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => c64_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => reset_c64_mmcm or (not sys_9975_locked)
      ); -- i_clk_c64_org  

   p_resetman : process(qnice_clk_o)
   begin
      if rising_edge(qnice_clk_o) then
         if qnice_rst_o then
            old_core_speed <= core_speed_i;
            reset_c64_mmcm <= '1';
         else
            if core_speed_i /= old_core_speed then
               reset_c64_mmcm <= '1';
               old_core_speed <= core_speed_i;
            else
               reset_c64_mmcm <= '0';
            end if;
         end if;
      end if;
   end process p_resetman;

   -------------------------------------------------------------------------------------
   -- Output buffering
   -------------------------------------------------------------------------------------

   sys_2_bufg : BUFG
      port map (
         I => sys_clk_9975_mmcm,
         O => sys_clk_9975_bg
      );
      
   main_clk_bufg : BUFG
      port map (
         I => main_clk_mmcm,
         O => main_clk_o
      );      

   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_async_rst_main : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         src_arst  => not (main_locked and sys_rstn_i) or reset_c64_mmcm,   -- 1-bit input: Source reset signal.
         dest_clk  => main_clk_o,       -- 1-bit input: Destination clock.
         dest_arst => main_rst_o        -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );

end architecture rtl;

