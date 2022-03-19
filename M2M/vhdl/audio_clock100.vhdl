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
      FS      : real;     -- sampling (clken) frequency (kHz)
      RATIO   : integer   -- clk to fs frequency ratio
   );
   port (
      audio_clk_i    : in  std_logic;        -- reference clock (60 MHz)
      audio_rst_i    : in  std_logic;        -- reference clock reset
      select_44100_i : in  std_logic;
      rst_o          : out std_logic;          -- reset out (from MMCM lock status)
      clk_o          : out std_logic;          -- audio clock out (fs * ratio)
      clken_o        : out std_logic           -- audio clock enable out (fs)
   );
end entity audio_clock;

architecture synth of audio_clock is

   signal clk_u    : std_logic;      -- unbuffered output clock
   signal count    : integer range 0 to ratio-1;
   signal clk12288_counter : unsigned(26 downto 0) := to_unsigned(0,27);

begin

   p_clk : process (audio_clk_i)
   begin
      if rising_edge(audio_clk_i) then
         -- 12.288 MHz is our goal, and we clock at 60MHz
         -- So we want to add 0.2038 x 2 = 0.4076 of a
         -- half-clock counter every cycle.
         -- 27487791 / 2^26 = .409600005
         -- 60MHz x .409600005 / 2 = 12.288000.137 MHz
         -- i.e., well within the jitter of everything

         -- N5998A HDMI protocol analyser claims we are producing only 47764 samples
         -- per second, instead of 48000.
         -- Also, some TVs might not do 48KHz, so we will make it run-time
         -- switchable to 44.1KHz.
         -- This requires an 11.2896 MHz clock instead of 12.288MHz
         -- 25254408 / 2^26 = 0.376320004
         -- 60MHz x .376320004 / 2 = 11.289600134
         -- i.e., with error in the milli-samples-per-second range
         if select_44100_i = '0' then
            -- 48KHz
            clk12288_counter <= clk12288_counter + 27487791;
         else
            -- 44.1KHz
            clk12288_counter <= clk12288_counter + 25254408;
         end if;

         -- Then pick out the right bit of our counter to
         -- get a very-close-to-12.288MHz-indeed clock
         clk_u <= clk12288_counter(26);
      end if;
   end process p_clk;

   BUFG_O : unisim.vcomponents.bufg
      port map (
         I   => clk_u,
         O   => clk_o
      );

   p_clken : process (audio_rst_i, clk_o)
   begin
      if audio_rst_i = '1' then
         count <= 0;
         clken_o <= '0';
      elsif rising_edge(clk_o) then
         clken_o <= '0';
         if count = RATIO-1 then
            count <= 0;
            clken_o <= '1';
         else
            count <= count + 1;
         end if;
      end if;
   end process p_clken;

   rst_o <= audio_rst_i;

end architecture synth;

