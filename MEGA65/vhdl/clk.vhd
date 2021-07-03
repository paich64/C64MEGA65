----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework  
--
-- Main clock, pixel clock and QNICE-clock generator using the Xilinx specific MMCME2_ADV:
--
--   Commodore 64 expects 32 MHz
--   QNICE expects 50 MHz
--   PAL @ 50 Hz expects 27 MHz (VGA) and 135 MHz (HDMI)
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2021 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity clk is
   port (
      sys_clk_i    : in  std_logic;   -- expects 100 MHz
      sys_rstn_i   : in  std_logic;   -- Asynchronous, asserted low
      
      main_clk_o   : out std_logic;   -- main's 32 MHz clock
      main_rst_o   : out std_logic;   -- main's reset, synchronized
      
      audio_clk_o  : out std_logic;   -- audio's 24.576 MHz main clock
      audio_rst_o  : out std_logic;   -- audio's reset, synchronized

      qnice_clk_o  : out std_logic;   -- QNICE's 50 MHz main clock
      qnice_rst_o  : out std_logic;   -- QNICE's reset, synchronized
      
      pixel_clk_o  : out std_logic;   -- VGA 27 MHz pixelclock for PAL @ 50 Hz
      pixel_rst_o  : out std_logic;   -- VGA's reset, synchronized
      pixel_clk5_o : out std_logic    -- VGA's 135 MHz pixelclock (27 MHz x 5) for HDMI
   );
end clk;

architecture rtl of clk is

signal clkfb1          : std_logic;
signal clkfb1_mmcm     : std_logic;
signal clkfb2          : std_logic;
signal clkfb2_mmcm     : std_logic;
signal audio_clk_mmcm  : std_logic;
signal qnice_clk_mmcm  : std_logic;
signal main_clk_mmcm   : std_logic;
signal pixel_clk_mmcm  : std_logic;
signal pixel_clk5_mmcm : std_logic;

begin

   -- generate Commodore 64 and QNICE clock
   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_main_qnice : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 8.0,        -- 800 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 32.552,     -- Audio @ 24.576 MHz TBD: Current value is ??? @TODO
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 16,         -- QNICE @ 50 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 25,         -- main @ 32 MHz
         CLKOUT2_PHASE        => 0.000,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb1_mmcm,
         CLKOUT0             => audio_clk_mmcm,
         CLKOUT1             => qnice_clk_mmcm,
         CLKOUT2             => main_clk_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb1,
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
         LOCKED              => open,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      );

   -- generate 27 MHz for PAL 720 x 576 @ 50 Hz and 5x27 MHz = 135 MHz for HDMI
   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_pal_hdmi : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 6.750,      -- f_VCO = 675 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 25.00,      -- 27 MHz for PAL 720 x 576 @ 50 Hz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 5,          -- 135 MHz = 27 MHz x 5 for HDMI
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb2_mmcm,
         CLKOUT0             => pixel_clk_mmcm,
         CLKOUT1             => pixel_clk5_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb2,
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
         LOCKED              => open,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => '0'
      );

   -------------------------------------
   -- Output buffering
   -------------------------------------

   clkfb1_bufg : BUFG
      port map (
         I => clkfb1_mmcm,
         O => clkfb1
      );

   clkfb2_bufg : BUFG
      port map (
         I => clkfb2_mmcm,
         O => clkfb2
      );
      
   audio_clk_bufg : BUFG
      port map (
         I => audio_clk_mmcm,
         O => audio_clk_o
      );
      
   qnice_clk_bufg : BUFG
      port map (
         I => qnice_clk_mmcm,
         O => qnice_clk_o
      );

   main_clk_bufg : BUFG
      port map (
         I => main_clk_mmcm,
         O => main_clk_o
      );

   pixel_clk_bufg : BUFG
      port map (
         I => pixel_clk_mmcm,
         O => pixel_clk_o
      );

   pixel_clk5_bufg : BUFG
      port map (
         I => pixel_clk5_mmcm,
         O => pixel_clk5_o
      );

   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_sync_rst_audio : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not sys_rstn_i,   -- 1-bit input: Source reset signal.
         dest_clk => audio_clk_o,      -- 1-bit input: Destination clock.
         dest_rst => audio_rst_o       -- 1-bit output: src_rst synchronized to the destination clock doaudio.
                                       -- This output is registered.
      );

   i_xpm_cdc_sync_rst_qnice : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not sys_rstn_i,   -- 1-bit input: Source reset signal.
         dest_clk => qnice_clk_o,      -- 1-bit input: Destination clock.
         dest_rst => qnice_rst_o       -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );

   i_xpm_cdc_sync_rst_main : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not sys_rstn_i,   -- 1-bit input: Source reset signal.
         dest_clk => main_clk_o,       -- 1-bit input: Destination clock.
         dest_rst => main_rst_o        -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );

   i_xpm_cdc_sync_rst_pixel : xpm_cdc_sync_rst
      generic map (
         INIT_SYNC_FF => 1  -- Enable simulation init values
      )
      port map (
         src_rst  => not sys_rstn_i,   -- 1-bit input: Source reset signal.
         dest_clk => pixel_clk_o,      -- 1-bit input: Destination clock.
         dest_rst => pixel_rst_o       -- 1-bit output: src_rst synchronized to the destination clock domain.
                                       -- This output is registered.
      );
      
end architecture rtl;
