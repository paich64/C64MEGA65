----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- Complete pipeline processing of audio and video output (analog and digital)
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity analog_pipeline is
   generic (
      G_VGA_DX               : natural;              -- Actual format of video from Core (in pixels).
      G_VGA_DY               : natural;
      G_OSM_DX               : natural;              -- On-Screen-Menu width and height
      G_OSM_DY               : natural
   );
   port (
      -- Input from Core (video and audio)
      video_clk_i              : in  std_logic;
      video_rst_i              : in  std_logic;
      video_ce_i               : in  std_logic;
      video_red_i              : in  std_logic_vector(7 downto 0);
      video_green_i            : in  std_logic_vector(7 downto 0);
      video_blue_i             : in  std_logic_vector(7 downto 0);
      video_hs_i               : in  std_logic;
      video_vs_i               : in  std_logic;
      video_de_i               : in  std_logic;
      audio_clk_i              : in  std_logic;
      audio_rst_i              : in  std_logic;
      audio_left_i             : in  signed(15 downto 0); -- Signed PCM format
      audio_right_i            : in  signed(15 downto 0); -- Signed PCM format

      -- Video output (VGA)
      vga_red_o                : out std_logic_vector(7 downto 0);
      vga_green_o              : out std_logic_vector(7 downto 0);
      vga_blue_o               : out std_logic_vector(7 downto 0);
      vga_hs_o                 : out std_logic;
      vga_vs_o                 : out std_logic;
      vdac_clk_o               : out std_logic;
      vdac_syncn_o             : out std_logic;
      vdac_blankn_o            : out std_logic;

      -- Audio output (3.5 mm jack)
      pwm_l_o                  : out std_logic;
      pwm_r_o                  : out std_logic;

      -- Connect to QNICE and Video RAM
      video_osm_cfg_enable_i   : in  std_logic;
      video_osm_cfg_xy_i       : in  std_logic_vector(15 downto 0);
      video_osm_cfg_dxdy_i     : in  std_logic_vector(15 downto 0);
      video_osm_vram_addr_o    : out std_logic_vector(15 downto 0);
      video_osm_vram_data_i    : in  std_logic_vector(15 downto 0);
      sys_info_vga_o           : out std_logic_vector(79 downto 0)
   );
end entity analog_pipeline;

architecture synthesis of analog_pipeline is

   constant C_FONT_DX            : natural := 16;
   constant C_FONT_DY            : natural := 16;

   -- MiSTer video pipeline signals
   signal vs_hsync            : std_logic;
   signal vs_vsync            : std_logic;
   signal vs_hblank           : std_logic;
   signal vs_vblank           : std_logic;
   signal div                 : integer range 0 to 7;
   signal mix_r               : std_logic_vector(7 downto 0);
   signal mix_g               : std_logic_vector(7 downto 0);
   signal mix_b               : std_logic_vector(7 downto 0);
   signal mix_vga_de          : std_logic;
   signal ce_pix              : std_logic;

   signal video_ce_overlay       : std_logic_vector(1 downto 0) := "10"; -- Clock divider 1/2

   component video_mixer is
      port (
         CLK_VIDEO   : in  std_logic;
         CE_PIXEL    : out std_logic;
         ce_pix      : in  std_logic;
         scandoubler : in  std_logic;
         hq2x        : in  std_logic;
         gamma_bus   : inout std_logic_vector(21 downto 0);
         R           : in  unsigned(7 downto 0);
         G           : in  unsigned(7 downto 0);
         B           : in  unsigned(7 downto 0);
         HSync       : in  std_logic;
         VSync       : in  std_logic;
         HBlank      : in  std_logic;
         VBlank      : in  std_logic;
         HDMI_FREEZE : in  std_logic;
         freeze_sync : out std_logic;
         VGA_R       : out std_logic_vector(7 downto 0);
         VGA_G       : out std_logic_vector(7 downto 0);
         VGA_B       : out std_logic_vector(7 downto 0);
         VGA_VS      : out std_logic;
         VGA_HS      : out std_logic;
         VGA_DE      : out std_logic
      );
   end component video_mixer;

begin

   -- SHELL_M_XY
   sys_info_vga_o(15 downto  0) <=
      X"0000";

   -- SHELL_M_DXDY
   sys_info_vga_o(31 downto 16) <=
      std_logic_vector(to_unsigned((G_VGA_DX/C_FONT_DX) * 256 + (G_VGA_DY/C_FONT_DY), 16));

   -- SHELL_O_XY
   sys_info_vga_o(47 downto 32) <=
      std_logic_vector(to_unsigned((G_VGA_DX/C_FONT_DX-G_OSM_DX) * 256, 16));

   -- SHELL_O_DXDY
   sys_info_vga_o(63 downto 48) <=
      std_logic_vector(to_unsigned(G_OSM_DX * 256 + G_OSM_DY, 16));

   -- SYS_DXDY
   sys_info_vga_o(79 downto 64) <=
      std_logic_vector(to_unsigned((G_VGA_DX/C_FONT_DX) * 256 + (G_VGA_DY/C_FONT_DY), 16));


   ---------------------------------------------------------------------------------------------
   -- Audio output (3.5 mm jack)
   ---------------------------------------------------------------------------------------------

   -- Convert the C64's PCM output to pulse density modulation
   i_pcm2pdm : entity work.pcm_to_pdm
      port map
      (
         cpuclock         => audio_clk_i,
         pcm_left         => audio_left_i,
         pcm_right        => audio_right_i,
         -- Pulse Density Modulation (PDM is supposed to sound better than PWM on MEGA65)
         pdm_left         => pwm_l_o,
         pdm_right        => pwm_r_o,
         audio_mode       => '0'         -- 0=PDM, 1=PWM
      ); -- i_pcm2pdm


   ---------------------------------------------------------------------------------------------
   -- Video output (VGA)
   ---------------------------------------------------------------------------------------------

   --------------------------------------------------------------------------------------------------
   -- MiSTer video signal processing pipeline
   --
   -- We configured it (hardcoded) to perform a scan-doubling, but there are many more things
   -- we could do here, including to make sure that we output an old composite signal instead of VGA
   --------------------------------------------------------------------------------------------------

--   -- This shortens the hsync pulse width to 4.82 us, still with a period of 63.94 us.
--   i_video_sync : entity work.video_sync
--      port map (
--         clk32     => clk_main_i,
--         pause     => c64_pause,
--         hsync     => c64_hsync,
--         vsync     => c64_vsync,
--         ntsc      => c64_ntsc_i,
--         wide      => '0',
--         hsync_out => vs_hsync,
--         vsync_out => vs_vsync,
--         hblank    => vs_hblank,
--         vblank    => vs_vblank
--      ); -- i_video_sync

   p_div : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         div <= div + 1;
      end if;
   end process p_div;
   ce_pix <= '1' when div = 0 else '0';

   -- This halves the hsync pulse width to 2.41 us, and the period to 31.97 us (= 2016 clock cycles @ clk_video_i).
   -- According to the document CEA-861-D, PAL 720x576 @ 50 Hz runs with a pixel
   -- clock frequency of 27.00 MHz and with 864 pixels per scan line, therefore
   -- a horizontal period of 32.00 us. The difference here is 0.1 %.
   -- The ratio between clk_video_i and the pixel frequency is 7/3.
   --
   -- Using a logic analyzer it's observed that the output has the following parameters:
   -- H_PIXELS = 658 pixels (1536 clock cycles)
   -- H_PULSE  =  65 pixels ( 152 clock cycles)
   -- H_BP     = 105 pixels ( 244 clock cycles)
   -- H_FP     =  36 pixels (  84 clock cycles)
   -- TOTAL    = 864 pixels (2016 clock cycles)
   -- V_PIXELS = 540 lines
   -- V_PULSE  =   8 lines
   -- V_BP     =  17 lines
   -- V_FP     =  59 lines
   -- TOTAL    = 624 lines

   i_video_mixer : video_mixer
      port map (
         CLK_VIDEO   => video_clk_i,      -- 63.056 MHz
         CE_PIXEL    => open,
         ce_pix      => ce_pix,
         scandoubler => '1',
         hq2x        => '0',
         gamma_bus   => open,
         R           => unsigned(video_red_i),
         G           => unsigned(video_green_i),
         B           => unsigned(video_blue_i),
         HSync       => vs_hsync,
         VSync       => vs_vsync,
         HBlank      => vs_hblank,
         VBlank      => vs_vblank,
         HDMI_FREEZE => '0',
         freeze_sync => open,
         VGA_R       => mix_r,
         VGA_G       => mix_g,
         VGA_B       => mix_b,
         VGA_VS      => vga_vs_o,
         VGA_HS      => vga_hs_o,
         VGA_DE      => mix_vga_de
      );

   vga_data_enable : process(mix_r, mix_g, mix_b, mix_vga_de)
   begin
      if mix_vga_de = '1' then
         vga_red_o   <= mix_r;
         vga_green_o <= mix_g;
         vga_blue_o  <= mix_b;
      else
         vga_red_o   <= (others => '0');
         vga_green_o <= (others => '0');
         vga_blue_o  <= (others => '0');
      end if;
   end process vga_data_enable;


   -- Clock enable for Overlay video streams
   p_video_ce : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         video_ce_overlay <= video_ce_overlay(0) & video_ce_overlay(video_ce_overlay'left downto 1);
      end if;
   end process p_video_ce;


   i_video_overlay_video : entity work.video_overlay
      generic  map (
         G_VGA_DX         => G_VGA_DX,
         G_VGA_DY         => G_VGA_DY,
         G_FONT_DX        => C_FONT_DX,
         G_FONT_DY        => C_FONT_DY
      )
      port map (
         vga_clk_i        => video_clk_i,
         vga_ce_i         => video_ce_overlay(0),
         vga_red_i        => video_red_i,
         vga_green_i      => video_green_i,
         vga_blue_i       => video_blue_i,
         vga_hs_i         => video_hs_i,
         vga_vs_i         => video_vs_i,
         vga_de_i         => video_de_i,
         vga_cfg_enable_i => video_osm_cfg_enable_i,
         vga_cfg_xy_i     => video_osm_cfg_xy_i,
         vga_cfg_dxdy_i   => video_osm_cfg_dxdy_i,
         vga_vram_addr_o  => video_osm_vram_addr_o,
         vga_vram_data_i  => video_osm_vram_data_i,
         vga_ce_o         => open,
         vga_red_o        => vga_red_o,
         vga_green_o      => vga_green_o,
         vga_blue_o       => vga_blue_o,
         vga_hs_o         => vga_hs_o,
         vga_vs_o         => vga_vs_o,
         vga_de_o         => open
      ); -- i_video_overlay_video

   -- Make the VDAC output the image
   vdac_syncn_o  <= '0';
   vdac_blankn_o <= '1';
   vdac_clk_o    <= not video_clk_i;

end architecture synthesis;

