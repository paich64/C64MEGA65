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

   signal video_ce_overlay       : std_logic_vector(1 downto 0) := "10"; -- Clock divider 1/2

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

