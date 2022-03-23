--------------------------------------------------------------------------------
-- audio_clock.vhd                                                            --
-- Audio clock (e.g. 256Fs = 12.288MHz) and enable (e.g Fs = 48kHz).          --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity audio_clock is
   generic (
      FS      : real;     -- NOT USED
      RATIO   : integer   -- clk to fs frequency ratio
   );
   port (
      audio_clk_i    : in  std_logic;        -- reference clock (60 MHz)
      audio_rst_i    : in  std_logic;        -- reference clock reset
      select_44100_i : in  std_logic;        -- NOT USED
      rst_o          : out std_logic;        -- reset out (from MMCM lock status)
      clk_o          : out std_logic;        -- audio clock out (fs * ratio)
      clken_o        : out std_logic         -- audio clock enable out (fs)
   );
end entity audio_clock;

architecture synth of audio_clock is

   signal count : integer range 0 to RATIO-1;

begin

   i_clk_synthetic : entity work.clk_synthetic
      generic map (
         G_SRC_FREQ_HZ  => 60_000_000,
         G_DEST_FREQ_HZ => 12_288_000
      )
      port map (
         src_clk_i  => audio_clk_i,
         src_rst_i  => audio_rst_i,
         dest_clk_o => clk_o,
         dest_rst_o => rst_o
      ); -- i_clk_synthetic

   p_clken : process (clk_o)
   begin
      if rising_edge(clk_o) then
         if count = RATIO-1 then
            count   <= 0;
            clken_o <= '1';
         else
            count   <= count + 1;
            clken_o <= '0';
         end if;

         if rst_o = '1' then
            count   <= 0;
            clken_o <= '0';
         end if;
      end if;
   end process p_clken;

end architecture synth;

