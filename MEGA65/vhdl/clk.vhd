-------------------------------------------------------------------------------------------------------------
-- Commodore 64 for MEGA65 (C64MEGA65)
--
-- Clock Generator using the Xilinx specific MMCME2_ADV:
--
--   MiSTer's Commodore 64 expects:
--      PAL:  31,527,778 MHz, this divided by 32 = 0,98525 MHz (C64 clock speed)
--      NTSC: @TODO
--   QNICE expects 50 MHz
--   HDMI 720p (50 Hz or 60 Hz) expects 74.25 MHz (HDMI) and 371.25 MHz (TMDS)
-- 
-- This machine is based on C64_MiSTer
-- Powered by MiSTer2MEGA65
-- MEGA65 port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
-------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i       : in  std_logic;   -- expects 100 MHz
      sys_rstn_i      : in  std_logic;   -- Asynchronous, asserted low

      qnice_clk_o     : out std_logic;   -- QNICE's 50 MHz main clock
      qnice_rst_o     : out std_logic;   -- QNICE's reset, synchronized

      hr_clk_x1_o     : out std_logic;   -- MEGA65 HyperRAM @ 100 MHz
      hr_clk_x2_o     : out std_logic;   -- MEGA65 HyperRAM @ 200 MHz
      hr_clk_x2_del_o : out std_logic;   -- MEGA65 HyperRAM @ 200 MHz phase delayed
      hr_rst_o        : out std_logic;   -- MEGA65 HyperRAM reset, synchronized

      hdmi_clk_sel_i  : in  std_logic;   -- 0: Chose 74.25 Mhz, 1: Choose 27.00 MHz
      tmds_clk_o      : out std_logic;   -- HDMI's 371.25 MHz pixelclock (74.25 MHz x 5) for TMDS
      hdmi_clk_o      : out std_logic;   -- HDMI's 74.25 MHz pixelclock for 720p @ 50 Hz
      hdmi_rst_o      : out std_logic;   -- HDMI's reset, synchronized

      audio_clk_o     : out std_logic;   -- Audio's 30 MHz clock
      audio_rst_o     : out std_logic;   -- Audio's reset, synchronized

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

signal qnice_fb_mmcm      : std_logic;
signal hdmi_720p_fb_mmcm  : std_logic;
signal hdmi_576p_fb_mmcm  : std_logic;
signal sys_9975_fb_mmcm   : std_logic;
signal main_fb_mmcm       : std_logic;
signal qnice_clk_mmcm     : std_logic;
signal hr_clk_x1_mmcm     : std_logic;
signal hr_clk_x2_mmcm     : std_logic;
signal hr_clk_x2_del_mmcm : std_logic;
signal audio_clk_mmcm     : std_logic;
signal tmds_720p_clk_mmcm : std_logic;
signal hdmi_720p_clk_mmcm : std_logic;
signal tmds_576p_clk_mmcm : std_logic;
signal hdmi_576p_clk_mmcm : std_logic;
signal main_clk_mmcm      : std_logic;
signal sys_clk_9975_mmcm  : std_logic;

signal sys_clk_9975_bg    : std_logic;

signal qnice_locked       : std_logic;
signal hdmi_720p_locked   : std_logic;
signal hdmi_576p_locked   : std_logic;
signal c64_locked         : std_logic;
signal sys_9975_locked    : std_logic;

signal c64_clock_select   : std_logic;

begin

   ---------------------------------------------------------------------------------------
   -- Generate QNICE and HyperRAM clock
   ---------------------------------------------------------------------------------------

   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE

   i_clk_qnice : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 12.0,       -- 1200 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 24.000,     -- QNICE @ 50 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 12,          -- HyperRAM @ 100 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 6,          -- HyperRAM @ 200 MHz
         CLKOUT2_PHASE        => 0.000,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE,
         CLKOUT3_DIVIDE       => 6,          -- HyperRAM @ 200 MHz phase delayed
         CLKOUT3_PHASE        => 180.000,
         CLKOUT3_DUTY_CYCLE   => 0.500,
         CLKOUT3_USE_FINE_PS  => FALSE,
         CLKOUT4_DIVIDE       => 40,         -- Audio @ 30 MHz
         CLKOUT4_PHASE        => 0.000,
         CLKOUT4_DUTY_CYCLE   => 0.500,
         CLKOUT4_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => qnice_fb_mmcm,
         CLKOUT0             => qnice_clk_mmcm,
         CLKOUT1             => hr_clk_x1_mmcm,
         CLKOUT2             => hr_clk_x2_mmcm,
         CLKOUT3             => hr_clk_x2_del_mmcm,
         CLKOUT4             => audio_clk_mmcm,
         -- Input clock control
         CLKFBIN             => qnice_fb_mmcm,
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
         LOCKED              => qnice_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_qnice

   ---------------------------------------------------------------------------------------
   -- Generate 74.25 MHz for 720p (50 Hz or 60 Hz) and 5x74.25 MHz = 371.25 MHz for TMDS
   ---------------------------------------------------------------------------------------

   i_clk_hdmi_720p : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 37.125,     -- f_VCO = (100 MHz / 5) x 37.125 = 742.5 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 2.000,      -- 371.25 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 10,         -- 74.25 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => hdmi_720p_fb_mmcm,
         CLKOUT0             => tmds_720p_clk_mmcm,
         CLKOUT1             => hdmi_720p_clk_mmcm,
         -- Input clock control
         CLKFBIN             => hdmi_720p_fb_mmcm,
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
         LOCKED              => hdmi_720p_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_hdmi_720p

   ---------------------------------------------------------------------------------------
   -- Generate 27.00 MHz for 576p @ 50 Hz and 5x27.00 MHz = 135.0 MHz for TMDS
   ---------------------------------------------------------------------------------------

   i_clk_hdmi_576p : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 47.250,     -- f_VCO = (100 MHz / 5) x 47.250 = 945 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 7.000,      -- 135.0 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 35,         -- 27.00 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => hdmi_576p_fb_mmcm,
         CLKOUT0             => tmds_576p_clk_mmcm,
         CLKOUT1             => hdmi_576p_clk_mmcm,
         -- Input clock control
         CLKFBIN             => hdmi_576p_fb_mmcm,
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
         LOCKED              => hdmi_576p_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      ); -- i_clk_hdmi_576p

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

   ---------------------------------------------------------------------------------------
   -- Output buffering
   ---------------------------------------------------------------------------------------

   sys_2_bufg : BUFG
      port map (
         I => sys_clk_9975_mmcm,
         O => sys_clk_9975_bg
      );

   qnice_clk_bufg : BUFG
      port map (
         I => qnice_clk_mmcm,
         O => qnice_clk_o
      );

   hr_clk_x1_bufg : BUFG
      port map (
         I => hr_clk_x1_mmcm,
         O => hr_clk_x1_o
      );

   hr_clk_x2_bufg : BUFG
      port map (
         I => hr_clk_x2_mmcm,
         O => hr_clk_x2_o
      );

   hr_clk_x2_del_bufg : BUFG
      port map (
         I => hr_clk_x2_del_mmcm,
         O => hr_clk_x2_del_o
      );

   audio_clk_bufg : BUFG
      port map (
         I => audio_clk_mmcm,
         O => audio_clk_o
      );

   tmds_clk_bufgmux : BUFGMUX
      port map (
         S  => hdmi_clk_sel_i,
         I0 => tmds_720p_clk_mmcm,
         I1 => tmds_576p_clk_mmcm,
         O  => tmds_clk_o
      );

   hdmi_clk_bufgmux : BUFGMUX
      port map (
         S  => hdmi_clk_sel_i,
         I0 => hdmi_720p_clk_mmcm,
         I1 => hdmi_576p_clk_mmcm,
         O  => hdmi_clk_o
      );

   main_clk_bufg : BUFG
      port map (
         I => main_clk_mmcm,
         O => main_clk_o
      );

   ---------------------------------------------------------------------------------------
   -- Reset generation
   ---------------------------------------------------------------------------------------

   i_xpm_cdc_async_rst_qnice : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_arst  => not (qnice_locked and sys_rstn_i),   -- 1-bit input: Source reset signal.
         dest_clk  => qnice_clk_o,      -- 1-bit input: Destination clock.
         dest_arst => qnice_rst_o       -- 1-bit output: src_rst synchronized to the destination clock domain.
                                        -- This output is registered.
      );

   i_xpm_cdc_async_rst_hr : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         -- 1-bit input: Source reset signal
         -- Important: The HyperRAM needs to be reset when ascal is being reset! The Avalon memory interface
         --  assumes that both ends maintain state information and agree on this state information. Therefore,
         -- one side can not be reset in the middle of e.g. a burst transaction, without the other end becoming confused.         
         src_arst  => not (qnice_locked and sys_rstn_i) or main_rst_o or hdmi_rst_o or reset_c64_mmcm,
         dest_clk  => hr_clk_x1_o,      -- 1-bit input: Destination clock.
         dest_arst => hr_rst_o          -- 1-bit output: src_rst synchronized to the destination clock domain.
                                        -- This output is registered.
      );

   i_xpm_cdc_async_rst_audio : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         src_arst  => not (qnice_locked and sys_rstn_i) or reset_c64_mmcm,   -- 1-bit input: Source reset signal.
         dest_clk  => audio_clk_o,      -- 1-bit input: Destination clock.
         dest_arst => audio_rst_o       -- 1-bit output: src_rst synchronized to the destination clock domain.
                                        -- This output is registered.
      );

   i_xpm_cdc_async_rst_hdmi : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         src_arst  => not (hdmi_720p_locked and hdmi_576p_locked and sys_rstn_i) or reset_c64_mmcm,   -- 1-bit input: Source reset signal.
         dest_clk  => hdmi_clk_o,       -- 1-bit input: Destination clock.
         dest_arst => hdmi_rst_o        -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );

   i_xpm_cdc_async_rst_main : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1,
         DEST_SYNC_FF    => 10
      )
      port map (
         src_arst  => not (c64_locked and sys_rstn_i) or reset_c64_mmcm,   -- 1-bit input: Source reset signal.
         dest_clk  => main_clk_o,       -- 1-bit input: Destination clock.
         dest_arst => main_rst_o        -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );

end architecture rtl;
