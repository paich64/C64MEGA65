----------------------------------------------------------------------------------
-- Commodore 64 for MEGA65  
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- based on C64_MiSTer by the MiSTer development team
-- port done by MJoergen and sy2002 in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vdrives_pkg.all;

entity main is
   generic (
      G_CORE_CLK_SPEED        : natural;      
      G_OUTPUT_DX             : natural;
      G_OUTPUT_DY             : natural     
   );
   port (
      clk_main_i              : in std_logic;    -- 31.528 MHz
      clk_video_i             : in std_logic;    -- 63.056 MHz
      reset_i                 : in std_logic;
      pause_i                 : in std_logic;
                  
      -- M2M Keyboard interface
      kb_key_num_i            : in integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?
      

      -- MEGA65 joysticks
      joy_1_up_n             : in std_logic;
      joy_1_down_n           : in std_logic;
      joy_1_left_n           : in std_logic;
      joy_1_right_n          : in std_logic;
      joy_1_fire_n           : in std_logic;

      joy_2_up_n             : in std_logic;
      joy_2_down_n           : in std_logic;
      joy_2_left_n           : in std_logic;
      joy_2_right_n          : in std_logic;
      joy_2_fire_n           : in std_logic;
      
      -- C64 video out (after scandoubler)
      VGA_R                   : out std_logic_vector(7 downto 0);
      VGA_G                   : out std_logic_vector(7 downto 0);
      VGA_B                   : out std_logic_vector(7 downto 0);
      VGA_VS                  : out std_logic;
      VGA_HS                  : out std_logic;
      VGA_DE                  : out std_logic;      
      
      -- C64 SID audio out: signed, see MiSTer's c64.sv
      sid_l                   : out signed(15 downto 0);
      sid_r                   : out signed(15 downto 0);
            
      -- C64 RAM: No address latching necessary and the chip can always be enabled
      c64_ram_addr_o          : out unsigned(15 downto 0);  -- C64 address bus
      c64_ram_data_o          : out unsigned(7 downto 0);   -- C64 RAM data out
      c64_ram_we_o            : out std_logic;              -- C64 RAM write enable      
      c64_ram_data_i          : in unsigned(7 downto 0);    -- C64 RAM data in 
      
      -- C64 IEC handled by QNICE
      c64_clk_sd_i            : in std_logic;               -- "sd card write clock" for floppy drive internal dual clock RAM buffer
      c64_qnice_addr_i        : in std_logic_vector(27 downto 0);
      c64_qnice_data_i        : in std_logic_vector(15 downto 0);
      c64_qnice_data_o        : out std_logic_vector(15 downto 0);
      c64_qnice_ce_i          : in std_logic;
      c64_qnice_we_i          : in std_logic                               
   );
end main;

architecture synthesis of main is

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

-- amount of virtual drives
-- CAUTION: i_iec_drive's reset needs to be adjusted manually, if you change this
constant VDNUM : natural := 1;

-- MiSTer C64 signals
signal c64_pause           : std_logic;
signal ce_pix              : std_logic;
signal c64_hsync           : std_logic;
signal c64_vsync           : std_logic;
signal c64_r               : unsigned(7 downto 0);
signal c64_g               : unsigned(7 downto 0);
signal c64_b               : unsigned(7 downto 0);
signal c64_ntsc            : std_logic;

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

-- directly connect the C64's CIA1 to the emulated keyboard matrix within keyboard.vhd
signal cia1_pa_i           : std_logic_vector(7 downto 0);
signal cia1_pa_o           : std_logic_vector(7 downto 0);
signal cia1_pb_i           : std_logic_vector(7 downto 0);
signal cia1_pb_o           : std_logic_vector(7 downto 0);

-- the Restore key is special: it creates a non maskable interrupt (NMI)
signal restore_key_n       : std_logic;

-- signals for RAM
signal c64_ram_ce          : std_logic;
signal c64_ram_we          : std_logic;

-- 18-bit SID from C64: Needs to go through audio processing ported from Verilog to VHDL from MiSTer's c64.sv
signal c64_sid_l           : std_logic_vector(17 downto 0);
signal c64_sid_r           : std_logic_vector(17 downto 0);
signal alo                 : std_logic_vector(15 downto 0); 
signal aro                 : std_logic_vector(15 downto 0);

-- IEC drives
signal iec_led             : std_logic;
signal iec_drive_ce        : std_logic;      -- chip enable for iec_drive (clock divider, see generate_drive_ce below)
signal iec_dce_sum         : integer := 0;   -- caution: we expect 32-bit integers here and we expect the initialization to 0
signal iec_drive_8_type    : std_logic_vector(1 downto 0);     -- 00=1541 emulated GCR(D64), 01=1541 real GCR mode (G64,D64), 10=1581 (D81)
signal iec_drive_9_type    : std_logic_vector(1 downto 0);
signal iec_drive_mounted   : std_logic_vector(VDNUM - 1 downto 0);
signal iec_drive_readonly  : std_logic;
signal iec_drive_imgsize   : std_logic_vector(31 downto 0);
signal c64_iec_clk_o       : std_logic;
signal c64_iec_clk_i       : std_logic;
signal c64_iec_atn_o       : std_logic;
signal c64_iec_data_o      : std_logic;
signal c64_iec_data_i      : std_logic;
signal iec_sd_lba_o        : vd_vec_array(VDNUM - 1 downto 0)(31 downto 0);
signal iec_sd_blk_cnt_o    : vd_vec_array(VDNUM - 1 downto 0)(5 downto 0);
signal iec_sd_rd_o         : vd_std_array(VDNUM - 1 downto 0);
signal iec_sd_wr_o         : vd_std_array(VDNUM - 1 downto 0);
signal iec_sd_ack_i        : vd_std_array(VDNUM - 1 downto 0);
signal iec_sd_buf_addr_i   : std_logic_vector(13 downto 0);
signal iec_sd_buf_data_i   : std_logic_vector(7 downto 0);
signal iec_sd_buf_wr_i     : std_logic;
signal iec_par_stb_i       : std_logic;
signal iec_par_stb_o       : std_logic;
signal iec_par_data_i      : std_logic_vector(7 downto 0);
signal iec_par_data_o      : std_logic_vector(7 downto 0);
signal iec_rom_std_i       : std_logic;
signal iec_rom_addr_i      : std_logic_vector(15 downto 0);
signal iec_rom_data_i      : std_logic_vector(7 downto 0);
signal iec_rom_wr_i        : std_logic;

attribute MARK_DEBUG : string;
attribute MARK_DEBUG of iec_drive_mounted : signal is "TRUE";
attribute MARK_DEBUG of iec_sd_rd_o : signal is "TRUE";

begin
   -- for now, we hardcode PAL, NTSC will follow later
   c64_ntsc <= '0';

   -- MiSTer Commodore 64 core / main machine
   i_fpga64_sid_iec : entity work.fpga64_sid_iec
      port map (
         clk32       => clk_main_i,      
         reset_n     => not reset_i,
         bios        => "01",             -- standard C64, internal ROM
         
         pause       => pause_i,
         pause_out   => c64_pause,
      
         -- keyboard interface: directly connect the CIA1
         cia1_pa_i   => cia1_pa_i,
         cia1_pa_o   => cia1_pa_o,
         cia1_pb_i   => cia1_pb_i,
         cia1_pb_o   => cia1_pb_o,
               
         -- external memory
         ramAddr     => c64_ram_addr_o,
         ramDin      => c64_ram_data_i,
         ramDout     => c64_ram_data_o,
         ramCE       => c64_ram_ce,
         ramWE       => c64_ram_we,
      
         io_cycle    => open,
         ext_cycle   => open,
         refresh     => open,
      
         cia_mode    => '0',              -- 0 - 6526 "old", 1 - 8521 "new"
         turbo_mode  => "00",
         turbo_speed => "00",
      
         -- VGA/SCART interface
         ntscMode    => c64_ntsc,
         hsync       => c64_hsync,
         vsync       => c64_vsync,
         r           => c64_r,
         g           => c64_g,
         b           => c64_b,
      
         -- cartridge port
         game        => '1',              -- low active, 1 is default so that KERNAL ROM can be read
         exrom       => '1',              -- ditto
         io_rom      => '0',
         io_ext      => '0',
         io_data     => x"00",
         irq_n       => '1',
         nmi_n       => restore_key_n,    -- TODO: "freeze_key" handling also regarding the cartrige (see MiSTer)
         nmi_ack     => open,
         romL        => open,
         romH        => open,
         UMAXromH 	=> open,
         IOE			=> open,
         IOF			=> open,
--         freeze_key  => open,
--         mod_key     => open,
--         tape_play   => open,
      
         -- dma access
         dma_req     => '0',
         dma_cycle   => open,
         dma_addr    => x"0000",
         dma_dout    => x"00",
         dma_din     => open,
         dma_we      => '0',
         irq_ext_n   => '1',
      
         -- paddle interface
         pot1        => x"00",
         pot2        => x"00",
         pot3        => x"00",
         pot4        => x"00",
      
         -- SID
         audio_l     => c64_sid_l,
         audio_r     => c64_sid_r,
         sid_filter  => "11",          -- filter enable = true for both SIDs, low bit = left SID
         sid_ver     => "00",          -- SID version, 0=6581, 1=8580, low bit = left SID
         sid_mode    => "000",         -- Right SID Port: 0=same as left, 1=DE00, 2=D420, 3=D500, 4=DF00
         sid_cfg     => "0000",        -- filter type: 0=Default, 1=Custom 1, 2=Custom 2, 3=Custom 3, lower two bits = left SID
         
         -- mechanism for loading custom SID filters: not supported, yet
         sid_ld_clk  => '0',
         sid_ld_addr => "000000000000",
         sid_ld_data => x"0000",
         sid_ld_wr   => '0',
         
         -- USER
         pb_i        => x"00",
         pb_o        => open,
         pa2_i       => '0',
         pa2_o       => open,
         pc2_n_o     => open,
         flag2_n_i   => '1',
         sp2_i       => '0',
         sp2_o       => open,
         sp1_i       => '0',
         sp1_o       => open,
         cnt2_i      => '0',
         cnt2_o      => open,
         cnt1_i      => '0',
         cnt1_o      => open,
            
         -- IEC
         iec_clk_i	=> c64_iec_clk_i,        
         iec_clk_o	=> c64_iec_clk_o,
         iec_atn_o	=> c64_iec_atn_o,
         iec_data_i	=> c64_iec_data_i,
         iec_data_o	=> c64_iec_data_o,
         
         c64rom_addr => "00000000000000",
         c64rom_data => x"00",
         c64rom_wr   => '0',
      
         cass_motor  => open,
         cass_write  => open,
         cass_sense  => '0',
         cass_read   => '0'            
      );
      
   -- RAM write enable also needs to check for chip enable
   c64_ram_we_o <= c64_ram_ce and c64_ram_we; 
                      
   -- Convert MEGA65 keystrokes to the C64 keyboard matrix that the CIA1 can scan
   -- and convert the MEGA65 joystick signals to CIA1 signals as well
   i_m65_to_c64 : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,
            
         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,
         
         -- Interface to the MEGA65 joysticks
         joy_1_up_n           => joy_1_up_n,
         joy_1_down_n         => joy_1_down_n,
         joy_1_left_n         => joy_1_left_n,
         joy_1_right_n        => joy_1_right_n,
         joy_1_fire_n         => joy_1_fire_n,
   
         joy_2_up_n           => joy_2_up_n,
         joy_2_down_n         => joy_2_down_n,
         joy_2_left_n         => joy_2_left_n,
         joy_2_right_n        => joy_2_right_n,
         joy_2_fire_n         => joy_2_fire_n,     

         -- Interface to the MiSTer C64 core that directly connects to the C64's CIA1 instead of
         -- going the detour of converting the MEGA65 keystrokes into PS/2 keystrokes first. 
         -- This means, that the "fpga64_keyboard" entity of the original core is not used. Instead,
         -- we are modifying the "fpga64_sid_iec" entity so that we can route the CIA1's ports
         -- A and B into this keyboard driver which then emulates the behavior of the physical
         -- C64 keyboard including the possibility to "scan" via the row, i.e. pull one or more bits of 
         -- port A to zero (one by one) and read via the "column" (i.e. from port B) or vice versa.
         cia1_pai_o           => cia1_pa_i,
         cia1_pao_i           => cia1_pa_o,
         cia1_pbi_o           => cia1_pb_i,
         cia1_pbo_i           => cia1_pb_o,
         
         -- Restore key = NMI
         restore_n            => restore_key_n         
      );

   --------------------------------------------------------------------------------------------------
   -- MiSTer audio signal processing: Convert the core's 18-bit signal to a signed 16-bit signal
   --------------------------------------------------------------------------------------------------

   audio_processing : process(clk_main_i)
      variable alm, arm : std_logic_vector(16 downto 0);      
   begin
      -- "alm" and "alr" are used to mix various audio sources
      -- Additional to SID, MiSTer supports OPL, DAC and the noise of the tape drive. All these sound
      -- inputs are meant to be added here (see c64.sv in the MiSTER source) as soon as we support it.
      alm(16)           := c64_sid_l(17);
      alm(15 downto 0)  := c64_sid_l(17 downto 2);
      arm(16)           := c64_sid_r(17);
      arm(15 downto 0)  := c64_sid_r(17 downto 2);
      
      -- Anti-overflow mechanism for alm and arm. Right now this is not yet needed, because we are
      -- not adding multiple audio sources, but as soon as we will do that in future, we are prepared
      if alm(16) /= alm(15) then
         alo(15)           <= alm(16);
         alo(14 downto 0)  <= (others => alm(15));
      else
         alo               <= alm(15 downto 0);
      end if;   

      if arm(16) /= arm(15) then
         aro(15)           <= arm(16);
         aro(14 downto 0)  <= (others => arm(15));
      else
         aro               <= arm(15 downto 0);
      end if;               
   end process;
   
   sid_l <= signed(alo);
   sid_r <= signed(aro);
   
   --------------------------------------------------------------------------------------------------
   -- MiSTer video signal processing pipeline
   --
   -- We configured it (hardcoded) to perform a scan-doubling, but there are many more things
   -- we could do here, including to make sure that we output an old composite signal instead of VGA
   --------------------------------------------------------------------------------------------------
   
   i_video_sync : entity work.video_sync
      port map (
         clk32     => clk_main_i,
         pause     => c64_pause,
         hsync     => c64_hsync,
         vsync     => c64_vsync,
         ntsc      => '0',
         wide      => '0',
         hsync_out => vs_hsync,
         vsync_out => vs_vsync,
         hblank    => vs_hblank,
         vblank    => vs_vblank
      ); -- i_video_sync

   p_div : process (clk_video_i)
   begin
      if rising_edge(clk_video_i) then
         div <= div + 1;
      end if;
   end process p_div;
   ce_pix <= '1' when div = 0 else '0';

   i_video_mixer : video_mixer
      port map (
         CLK_VIDEO   => clk_video_i,      -- 63.056 MHz
         CE_PIXEL    => open,
         ce_pix      => ce_pix,
         scandoubler => '1',
         hq2x        => '0',
         gamma_bus   => open,
         R           => c64_r,
         G           => c64_g,
         B           => c64_b,
         HSync       => vs_hsync,
         VSync       => vs_vsync,
         HBlank      => vs_hblank,
         VBlank      => vs_vblank,
         HDMI_FREEZE => '0',
         freeze_sync => open,
         VGA_R       => mix_r,
         VGA_G       => mix_g,
         VGA_B       => mix_b,
         VGA_VS      => VGA_VS,
         VGA_HS      => VGA_HS,
         VGA_DE      => mix_vga_de
      );
      
   VGA_DE <= mix_vga_de;
   vga_data_enable : process(mix_r, mix_g, mix_b, mix_vga_de)
   begin
      if mix_vga_de = '1' then
         VGA_R <= mix_r;
         VGA_G <= mix_g;
         VGA_B <= mix_b;
      else
         VGA_R <= (others => '0');
         VGA_G <= (others => '0');
         VGA_B <= (others => '0');
      end if;
   end process;
   
   --------------------------------------------------------------------------------------------------
   -- MiSTer IEC drives
   --------------------------------------------------------------------------------------------------

   iec_drive_8_type     <= "00";    -- @TODO: remove hardcoded value (00=1541 emulated GCR(D64), 01=1541 real GCR mode (G64,D64), 10=1581 (D81))
   
   -- Parallel C1541 port: not implemented, yet
   iec_par_stb_i        <= '0';
   iec_par_data_i       <= (others => '0'); 
   
   -- Custom ROM load facility: not implemented, yet
   iec_rom_std_i        <= '1';     -- use the factory default ROM
   iec_rom_addr_i       <= (others => '0');
   iec_rom_data_i       <= (others => '0');
   iec_rom_wr_i         <= '0';   
   
   i_iec_drive : entity work.iec_drive
      generic map (
         PARPORT        => 0,                -- Parallel C1541 port for faster (~20x) loading time using DolphinDOS
         DUALROM        => 0,
         DRIVES         => VDNUM      
      )
      port map (
         clk            => clk_main_i,
         ce             => iec_drive_ce,
         reset          => reset_i or not iec_drive_mounted(0),
         pause          => pause_i,
         
         -- interface to the C64 core
         iec_clk_i      => c64_iec_clk_o,
         iec_clk_o      => c64_iec_clk_i,
         iec_atn_i      => c64_iec_atn_o,
         iec_data_i     => c64_iec_data_o,
         iec_data_o     => c64_iec_data_i,
         
         -- disk image status
         img_mounted    => iec_drive_mounted,
         img_readonly   => iec_drive_readonly,
         img_size       => iec_drive_imgsize,
         img_type       => iec_drive_8_type,       -- 00=1541 emulated GCR(D64), 01=1541 real GCR mode (G64,D64), 10=1581 (D81)

         -- QNICE SD-Card/FAT32 interface
         clk_sys        => c64_clk_sd_i,           -- "SD card" clock for writing to the drives' internal data buffers
         
         sd_lba         => iec_sd_lba_o,
         sd_blk_cnt     => iec_sd_blk_cnt_o,
         sd_rd          => iec_sd_rd_o,
         sd_wr          => iec_sd_wr_o,
         sd_ack         => iec_sd_ack_i,
         sd_buff_addr   => iec_sd_buf_addr_i,
         sd_buff_dout   => iec_sd_buf_data_i,   -- data from SD card to the buffer RAM within the drive ("dout" is a strange name)
         sd_buff_din    => open,                -- possibility to read the buffer RAM within the drive
         sd_buff_wr     => iec_sd_buf_wr_i,
                 
         -- drive led
         led            => iec_led,             -- not used, right now
         
         -- Parallel C1541 port
         par_stb_i      => iec_par_stb_i,
         par_stb_o      => iec_par_stb_o,
         par_data_i     => iec_par_data_i,
         par_data_o     => iec_par_data_o,
         
         -- Facility to load custom rom (currently not used)
         -- Important: If we want to use it, we need to replace "iecdrv_mem" in c1581_multi.sv
         -- by "dualport_2clk_ram" due to QNICE's falling-edge reading and writing
         rom_std        => iec_rom_std_i,       -- hardcoded to '1', use the factory default ROM
         rom_addr       => iec_rom_addr_i,
         rom_data       => iec_rom_data_i,
         rom_wr         => iec_rom_wr_i
      );

   generate_drive_ce : process(clk_main_i)
      variable msum : integer;   -- caution: we expect a 32-bit integer here
   begin
      if rising_edge(clk_main_i) then
         if c64_ntsc = '1' then
            msum := 32727264;
         else
            msum := 31527954;
         end if;
         
         iec_drive_ce <= '0';
         iec_dce_sum <= iec_dce_sum + 16000000;
         if iec_dce_sum >= msum then
            iec_dce_sum <= iec_dce_sum - msum;
            iec_drive_ce <= '1';
         end if;
      end if;
   end process;
   
   i_vdrives : entity work.vdrives
      generic map (
         VDNUM                => VDNUM,               -- only one drive
         BLKSZ                => 1                    -- 1 = 256 bytes block size
      )
      port map (
         clk_qnice_i          => c64_clk_sd_i,
         clk_core_i           => clk_main_i,
         reset_core_i         => reset_i,
         
         -- MiSTer's "SD config" interface, which runs in the core's clock domain
         img_mounted_o        => iec_drive_mounted,
         img_readonly_o       => iec_drive_readonly,
         img_size_o           => iec_drive_imgsize,
         
         -- MiSTer's "SD block level access" interface, which runs in QNICE's clock domain
         -- using dedicated signal on Mister's side such as "clk_sys"
         sd_lba_i             => iec_sd_lba_o,
         sd_blk_cnt_i         => iec_sd_blk_cnt_o,    -- number of blocks-1
         sd_rd_i              => iec_sd_rd_o,
         sd_wr_i              => iec_sd_wr_o,
         sd_ack_o             => iec_sd_ack_i,

         -- MiSTer's "SD byte level access": the MiSTer components use a combination of the drive-specific sd_ack and the sd_buff_wr
         -- to determine, which RAM buffer actually needs to be written to (using the clk_qnice_i clock domain)
         sd_buff_addr_o       => iec_sd_buf_addr_i,
         sd_buff_dout_o       => iec_sd_buf_data_i,
         sd_buff_din_i        => (others => (others => '0')),
         sd_buff_wr_o         => iec_sd_buf_wr_i,

         -- QNICE interface (MMIO, 4k-segmented)
         -- qnice_addr is 28-bit because we have a 16-bit window selector and a 4k window: 65536*4096 = 268.435.456 = 2^28
         qnice_addr_i         => c64_qnice_addr_i,  
         qnice_data_i         => c64_qnice_data_i,
         qnice_data_o         => c64_qnice_data_o,
         qnice_ce_i           => c64_qnice_ce_i,
         qnice_we_i           => c64_qnice_we_i
      );

end synthesis;
