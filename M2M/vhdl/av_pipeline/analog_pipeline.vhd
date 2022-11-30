----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65
--
-- Complete pipeline processing of analog audio and video output (VGA and 3.5 mm)
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity analog_pipeline is
   generic (
      G_VGA_DX               : natural;              -- Actual format of video from Core (in pixels).
      G_VGA_DY               : natural;
      G_FONT_FILE            : string;
      G_FONT_DX              : natural;
      G_FONT_DY              : natural
   );
   port (
      -- Input from Core (video and audio)
      video_clk_i            : in  std_logic;
      video_rst_i            : in  std_logic;
      video_ce_i             : in  std_logic;
      video_red_i            : in  std_logic_vector(7 downto 0);
      video_green_i          : in  std_logic_vector(7 downto 0);
      video_blue_i           : in  std_logic_vector(7 downto 0);
      video_hs_i             : in  std_logic;
      video_vs_i             : in  std_logic;
      video_hblank_i         : in  std_logic;
      video_vblank_i         : in  std_logic;
      audio_clk_i            : in  std_logic;
      audio_rst_i            : in  std_logic;
      audio_left_i           : in  signed(15 downto 0); -- Signed PCM format
      audio_right_i          : in  signed(15 downto 0); -- Signed PCM format

      -- Video output (VGA)
      vga_red_o              : out std_logic_vector(7 downto 0);
      vga_green_o            : out std_logic_vector(7 downto 0);
      vga_blue_o             : out std_logic_vector(7 downto 0);
      vga_hs_o               : out std_logic;
      vga_vs_o               : out std_logic;
      vdac_clk_o             : out std_logic;
      vdac_syncn_o           : out std_logic;
      vdac_blankn_o          : out std_logic;

      -- Audio output (3.5 mm jack)
      pwm_l_o                : out std_logic;
      pwm_r_o                : out std_logic;

      -- Connect to QNICE and Video RAM
      video_osm_cfg_enable_i : in  std_logic;
      video_osm_cfg_xy_i     : in  std_logic_vector(15 downto 0);
      video_osm_cfg_dxdy_i   : in  std_logic_vector(15 downto 0);
      video_osm_vram_addr_o  : out std_logic_vector(15 downto 0);
      video_osm_vram_data_i  : in  std_logic_vector(15 downto 0);
      scandoubler_i          : in  std_logic;
      sys_info_vga_o         : out std_logic_vector(47 downto 0)
   );
end entity analog_pipeline;

architecture synthesis of analog_pipeline is

   signal video_ce           : std_logic_vector(1 downto 0);
   signal video_ce_overlay   : std_logic;

   -- MiSTer video pipeline signals
   signal vs_hsync           : std_logic;
   signal vs_vsync           : std_logic;
   signal vs_hblank          : std_logic;
   signal vs_vblank          : std_logic;
   signal mix_r              : std_logic_vector(7 downto 0);
   signal mix_g              : std_logic_vector(7 downto 0);
   signal mix_b              : std_logic_vector(7 downto 0);
   signal mix_vga_de         : std_logic;
   signal ce_pix             : std_logic;

   signal vga_red            : std_logic_vector(7 downto 0);
   signal vga_green          : std_logic_vector(7 downto 0);
   signal vga_blue           : std_logic_vector(7 downto 0);
   signal vga_hs             : std_logic;
   signal vga_vs             : std_logic;
   
   -- registers used to implement the phase-shifting of the VGA output signals
   signal vga_red_ps         : std_logic_vector(7 downto 0);
   signal vga_green_ps       : std_logic_vector(7 downto 0);
   signal vga_blue_ps        : std_logic_vector(7 downto 0);
   signal vga_hs_ps          : std_logic;
   signal vga_vs_ps          : std_logic;      

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

   -- SYS_DXDY
   sys_info_vga_o(15 downto 0) <=
      std_logic_vector(to_unsigned((G_VGA_DX/G_FONT_DX) * 256 + (G_VGA_DY/G_FONT_DY), 16));

   -- SHELL_M_XY
   sys_info_vga_o(31 downto  16) <=
      X"0000";

   -- SHELL_M_DXDY
   sys_info_vga_o(47 downto 32) <=
      std_logic_vector(to_unsigned((G_VGA_DX/G_FONT_DX) * 256 + (G_VGA_DY/G_FONT_DY), 16));

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
   --------------------------------------------------------------------------------------------------

   p_div : process (video_clk_i)
   begin
      if rising_edge(video_clk_i) then
         video_ce <= video_ce + 1;
      end if;
   end process p_div;
   ce_pix <= '1' when video_ce = 0 else '0';

   -- This halves the hsync pulse width to 2.41 us, and the period to 31.97 us (= 1008 clock cycles @ 31.528 MHz).
   -- According to the document CEA-861-D, PAL 720x576 @ 50 Hz runs with a pixel
   -- clock frequency of 27.00 MHz and with 864 pixels per scan line, therefore
   -- a horizontal period of 32.00 us. The difference here is 0.1 %.
   -- The ratio between clk_video_i and the pixel frequency is 7/6.

   i_video_mixer : video_mixer
      port map (
         CLK_VIDEO   => video_clk_i,      -- 31.528 MHz
         CE_PIXEL    => open,
         ce_pix      => ce_pix,
         scandoubler => scandoubler_i,
         hq2x        => '0',
         gamma_bus   => open,
         R           => unsigned(video_red_i),
         G           => unsigned(video_green_i),
         B           => unsigned(video_blue_i),
         HSync       => video_hs_i,
         VSync       => video_vs_i,
         HBlank      => video_hblank_i,
         VBlank      => video_vblank_i,
         HDMI_FREEZE => '0',
         freeze_sync => open,
         VGA_R       => mix_r,
         VGA_G       => mix_g,
         VGA_B       => mix_b,
         VGA_VS      => vga_vs,
         VGA_HS      => vga_hs,
         VGA_DE      => mix_vga_de
      );

   vga_data_enable : process(mix_r, mix_g, mix_b, mix_vga_de)
   begin
      if mix_vga_de = '1' then
         vga_red   <= mix_r;
         vga_green <= mix_g;
         vga_blue  <= mix_b;
      else
         vga_red   <= (others => '0');
         vga_green <= (others => '0');
         vga_blue  <= (others => '0');
      end if;
   end process vga_data_enable;

   -- Clock enable for Overlay video streams

   video_ce_overlay <= '1' when scandoubler_i = '1' else video_ce(1) and video_ce(0);

   i_video_overlay : entity work.video_overlay
      generic  map (
         G_VGA_DX         => G_VGA_DX,
         G_VGA_DY         => G_VGA_DY,
         G_FONT_FILE      => G_FONT_FILE,
         G_FONT_DX        => G_FONT_DX,
         G_FONT_DY        => G_FONT_DY
      )
      port map (
         vga_clk_i        => video_clk_i,
         vga_ce_i         => video_ce_overlay,
         vga_red_i        => mix_r,
         vga_green_i      => mix_g,
         vga_blue_i       => mix_b,
         vga_hs_i         => vga_hs,
         vga_vs_i         => vga_vs,
         vga_de_i         => mix_vga_de,
         vga_cfg_shift_i  => 0,
         vga_cfg_enable_i => video_osm_cfg_enable_i,
         vga_cfg_double_i => scandoubler_i,
         vga_cfg_xy_i     => video_osm_cfg_xy_i,
         vga_cfg_dxdy_i   => video_osm_cfg_dxdy_i,
         vga_vram_addr_o  => video_osm_vram_addr_o,
         vga_vram_data_i  => video_osm_vram_data_i,
         vga_ce_o         => open,
         vga_red_o        => vga_red_ps,
         vga_green_o      => vga_green_ps,
         vga_blue_o       => vga_blue_ps,
         vga_hs_o         => vga_hs_ps,
         vga_vs_o         => vga_vs_ps,
         vga_de_o         => open
      ); -- i_video_overlay_video

   -- We need to phase-shift the output signal so that the VDAC can sample a nice and steady signal.
   -- We also need to make sure that not only the RGB signals are phase-shifted, but also the
   -- HS and VS signals, otherwise on real analog VGA screens there might be undesired effects.
   -- Last but not least for guaranteeing a minimum of routing delays, we are putting these registers
   -- in a VHDL block so that we can use a PBLOCK in the XDC file to tack the registers near to the
   -- FPGAs VGA output pins.
   VGA_OUT_PHASE_SHIFTED : block
   begin  
      phase_shift_vga_signals : process(video_clk_i)
      begin
         if falling_edge(video_clk_i) then -- phase shifting by using the negative edge of the video clock
            vga_red_o   <= vga_red_ps;
            vga_green_o <= vga_green_ps;
            vga_blue_o  <= vga_blue_ps;
            vga_hs_o    <= vga_hs_ps;
            vga_vs_o    <= vga_vs_ps;            
         end if;
      end process;
   end block VGA_OUT_PHASE_SHIFTED;

   -- Make the VDAC output the image
   vdac_syncn_o  <= '0';
   vdac_blankn_o <= '1';
   vdac_clk_o    <= video_clk_i;

end architecture synthesis;

