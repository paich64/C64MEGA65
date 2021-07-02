----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework  
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2021 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
   generic (
      G_CORE_CLK_SPEED        : natural;
      
      -- @TODO adjust this to your needs
      G_OUTPUT_DX             : natural;
      G_OUTPUT_DY             : natural;     
      G_YOUR_GENERIC1         : boolean;
      G_ANOTHER_THING         : natural
   );
   port (
      main_clk               : in  std_logic;
      clk_audio              : in  std_logic;
      reset_n                : in  std_logic;

      -- MEGA65 smart keyboard controller
      kb_io0                 : out std_logic;
      kb_io1                 : out std_logic;
      kb_io2                 : in  std_logic

      -- MEGA65 audio
--      pwm_l                  : out std_logic;
--      pwm_r                  : out std_logic;

      -- MEGA65 joysticks
--      joy_1_up_n             : in std_logic;
--      joy_1_down_n           : in std_logic;
--      joy_1_left_n           : in std_logic;
--      joy_1_right_n          : in std_logic;
--      joy_1_fire_n           : in std_logic;

--      joy_2_up_n             : in std_logic;
--      joy_2_down_n           : in std_logic;
--      joy_2_left_n           : in std_logic;
--      joy_2_right_n          : in std_logic;
--      joy_2_fire_n           : in std_logic
   );
end main;

architecture synthesis of main is

-- Component declaration for the module in c64.sv
component emu is
   port (
      -- Master input clock
      CLK_50M          : in  std_logic;

      -- Async reset from top-level module.
      -- Can be used as initial reset.
      RESET            : in  std_logic;

      -- Must be passed to hps_io module
      HPS_BUS          : inout std_logic_vector(45 downto 0);

      -- Base video clock. Usually equals to CLK_SYS.
      CLK_VIDEO        : out std_logic;

      -- Multiple resolutions are supported using different CE_PIXEL rates.
      -- Must be based on CLK_VIDEO
      CE_PIXEL         : out std_logic;

      -- Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
      -- if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
      VIDEO_ARX        : out std_logic_vector(12 downto 0);
      VIDEO_ARY        : out std_logic_vector(12 downto 0);

      VGA_R            : out std_logic_vector(7 downto 0);
      VGA_G            : out std_logic_vector(7 downto 0);
      VGA_B            : out std_logic_vector(7 downto 0);
      VGA_HS           : out std_logic;
      VGA_VS           : out std_logic;
      VGA_DE           : out std_logic;   -- = ~(VBlank | HBlank)
      VGA_F1           : out std_logic;
      VGA_SL           : out std_logic_vector(1 downto 0);
      VGA_SCALER       : out std_logic;   -- Force VGA scaler

      HDMI_WIDTH       : in  std_logic_vector(11 downto 0);
      HDMI_HEIGHT      : in  std_logic_vector(11 downto 0);
      HDMI_FREEZE      : out std_logic;

---- `ifdef MISTER_FB
--      -- Use framebuffer in DDRAM (USE_FB=1 in qsf)
--      -- FB_FORMAT:
--      --    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
--      --    [3]   : 0=16bits 565 1=16bits 1555
--      --    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
--      --
--      -- FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
--      FB_EN            : out std_logic;
--      FB_FORMAT        : out std_logic_vector(4 downto 0);
--      FB_WIDTH         : out std_logic_vector(11 downto 0);
--      FB_HEIGHT        : out std_logic_vector(11 downto 0);
--      FB_BASE          : out std_logic_vector(31 downto 0);
--      FB_STRIDE        : out std_logic_vector(13 downto 0);
--      FB_VBL           : in  std_logic;
--      FB_LL            : in  std_logic;
--      FB_FORCE_BLANK   : out std_logic;
--
---- `ifdef MISTER_FB_PALETTE
--      -- Palette control for 8bit modes.
--      -- Ignored for other video modes.
--      FB_PAL_CLK       : out std_logic;
--      FB_PAL_ADDR      : out std_logic_vector(7 downto 0);
--      FB_PAL_DOUT      : out std_logic_vector(23 downto 0);
--      FB_PAL_DIN       : in  std_logic_vector(23 downto 0);
--      FB_PAL_WR        : out std_logic;
----`endif MISTER_FB_PALETTE
----`endif MISTER_FB

      LED_USER         : out std_logic;  -- 1 - ON, 0 - OFF.

      -- b[1]: 0 - LED status is system status OR'd with b[0]
      --       1 - LED status is controled solely by b[0]
      -- hint: supply 2'b00 to let the system control the LED.
      LED_POWER        : out std_logic_vector(1 downto 0);
      LED_DISK         : out std_logic_vector(1 downto 0);

      -- I/O board button press simulation (active high)
      -- b[1]: user button
      -- b[0]: osd button
      BUTTONS          : out std_logic_vector(1 downto 0);

      CLK_AUDIO        : in  std_logic; -- 24.576 MHz
      AUDIO_L          : out std_logic_vector(15 downto 0);
      AUDIO_R          : out std_logic_vector(15 downto 0);
      AUDIO_S          : out std_logic;   -- 1 - signed audio samples, 0 - unsigned
      AUDIO_MIX        : out std_logic_vector(1 downto 0); -- 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

      -- ADC
      ADC_BUS          : inout std_logic_vector(3 downto 0);

      -- SD-SPI
      SD_SCK           : out std_logic;
      SD_MOSI          : out std_logic;
      SD_MISO          : in  std_logic;
      SD_CS            : out std_logic;
      SD_CD            : in  std_logic;

      -- High latency DDR3 RAM interface
      -- Use for non-critical time purposes
      DDRAM_CLK        : out std_logic;
      DDRAM_BUSY       : in  std_logic;
      DDRAM_BURSTCNT   : out std_logic_vector(7 downto 0);
      DDRAM_ADDR       : out std_logic_vector(28 downto 0);
      DDRAM_DOUT       : in  std_logic_vector(63 downto 0);
      DDRAM_DOUT_READY : in  std_logic;
      DDRAM_RD         : out std_logic;
      DDRAM_DIN        : out std_logic_vector(63 downto 0);
      DDRAM_BE         : out std_logic_vector(7 downto 0);
      DDRAM_WE         : out std_logic;

      -- SDRAM interface with lower latency
      SDRAM_CLK        : out std_logic;
      SDRAM_CKE        : out std_logic;
      SDRAM_A          : out std_logic_vector(12 downto 0);
      SDRAM_BA         : out std_logic_vector(1 downto 0);
      SDRAM_DQ         : inout std_logic_vector(15 downto 0);
      SDRAM_DQML       : out std_logic;
      SDRAM_DQMH       : out std_logic;
      SDRAM_nCS        : out std_logic;
      SDRAM_nCAS       : out std_logic;
      SDRAM_nRAS       : out std_logic;
      SDRAM_nWE        : out std_logic;

----`ifdef MISTER_DUAL_SDRAM
--      -- Secondary SDRAM
--      -- Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
--      SDRAM2_EN        : in  std_logic;
--      SDRAM2_CLK       : out std_logic;
--      SDRAM2_A         : out std_logic_vector(12 downto 0);
--      SDRAM2_BA        : out std_logic_vector(1 downto 0);
--      SDRAM2_DQ        : inout std_logic_vector(15 downto 0);
--      SDRAM2_nCS       : out std_logic;
--      SDRAM2_nCAS      : out std_logic;
--      SDRAM2_nRAS      : out std_logic;
--      SDRAM2_nWE       : out std_logic;
----`endif MISTER_DUAL_SDRAM

      UART_CTS         : in  std_logic;
      UART_RTS         : out std_logic;
      UART_RXD         : in  std_logic;
      UART_TXD         : out std_logic;
      UART_DTR         : out std_logic;
      UART_DSR         : in  std_logic;

      -- Open-drain User port.
      -- 0 - D+/RX
      -- 1 - D-/TX
      -- 2..6 - USR2..USR6
      -- Set USER_OUT to 1 to read from USER_IN.
      USER_IN          : in  std_logic_vector(6 downto 0);
      USER_OUT         : out std_logic_vector(6 downto 0);

      OSD_STATUS       : in std_logic
   );
end component emu;

begin

   -- Component instantiation for the module in c64.sv
   i_emu : emu
      port map (
         CLK_50M          => main_clk,          -- input
         RESET            => not reset_n,       -- input
         HPS_BUS          => open,              -- input/output
         CLK_VIDEO        => open,              -- output
         CE_PIXEL         => open,              -- output
         VIDEO_ARX        => open,              -- output
         VIDEO_ARY        => open,              -- output
         VGA_R            => open,              -- output
         VGA_G            => open,              -- output
         VGA_B            => open,              -- output
         VGA_HS           => open,              -- output
         VGA_VS           => open,              -- output
         VGA_DE           => open,              -- output
         VGA_F1           => open,              -- output
         VGA_SL           => open,              -- output
         VGA_SCALER       => open,              -- output
         HDMI_WIDTH       => (others => '0'),   -- input
         HDMI_HEIGHT      => (others => '0'),   -- input
         HDMI_FREEZE      => open,              -- output
--         FB_EN            => open,              -- output
--         FB_FORMAT        => open,              -- output
--         FB_WIDTH         => open,              -- output
--         FB_HEIGHT        => open,              -- output
--         FB_BASE          => open,              -- output
--         FB_STRIDE        => open,              -- output
--         FB_VBL           => '0',               -- input
--         FB_LL            => '0',               -- input
--         FB_FORCE_BLANK   => open,              -- output
--         FB_PAL_CLK       => open,              -- output
--         FB_PAL_ADDR      => open,              -- output
--         FB_PAL_DOUT      => open,              -- output
--         FB_PAL_DIN       => (others => '0'),   -- input
--         FB_PAL_WR        => open,              -- output
         LED_USER         => open,              -- output
         LED_POWER        => open,              -- output
         LED_DISK         => open,              -- output
         BUTTONS          => open,              -- output
         CLK_AUDIO        => clk_audio,         -- input
         AUDIO_L          => open,              -- output
         AUDIO_R          => open,              -- output
         AUDIO_S          => open,              -- output
         AUDIO_MIX        => open,              -- output
         ADC_BUS          => open,              -- input/output
         SD_SCK           => open,              -- output
         SD_MOSI          => open,              -- output
         SD_MISO          => '0',               -- input
         SD_CS            => open,              -- output
         SD_CD            => '1',               -- input
         DDRAM_CLK        => open,              -- output
         DDRAM_BUSY       => '0',               -- input
         DDRAM_BURSTCNT   => open,              -- output
         DDRAM_ADDR       => open,              -- output
         DDRAM_DOUT       => (others => '0'),   -- input
         DDRAM_DOUT_READY => '0',               -- input
         DDRAM_RD         => open,              -- output
         DDRAM_DIN        => open,              -- output
         DDRAM_BE         => open,              -- output
         DDRAM_WE         => open,              -- output
         SDRAM_CLK        => open,              -- output
         SDRAM_CKE        => open,              -- output
         SDRAM_A          => open,              -- output
         SDRAM_BA         => open,              -- output
         SDRAM_DQ         => open,              -- input/output
         SDRAM_DQML       => open,              -- output
         SDRAM_DQMH       => open,              -- output
         SDRAM_nCS        => open,              -- output
         SDRAM_nCAS       => open,              -- output
         SDRAM_nRAS       => open,              -- output
         SDRAM_nWE        => open,              -- output
--         SDRAM2_EN        => '0',               -- input
--         SDRAM2_CLK       => open,              -- output
--         SDRAM2_A         => open,              -- output
--         SDRAM2_BA        => open,              -- output
--         SDRAM2_DQ        => open,              -- input/output
--         SDRAM2_nCS       => open,              -- output
--         SDRAM2_nCAS      => open,              -- output
--         SDRAM2_nRAS      => open,              -- output
--         SDRAM2_nWE       => open,              -- output
         UART_CTS         => '0',               -- input
         UART_RTS         => open,              -- output
         UART_RXD         => '0',               -- input
         UART_TXD         => open,              -- output
         UART_DTR         => open,              -- output
         UART_DSR         => '0',               -- input
         USER_IN          => (others => '0'),   -- input
         USER_OUT         => open,              -- output
         OSD_STATUS       => '0'                -- input
      ); -- i_emu : emu is

end synthesis;

