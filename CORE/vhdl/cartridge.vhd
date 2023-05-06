library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cartridge is
   port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;

      -- From CRT file
      cart_loading_i : in  std_logic;
      cart_id_i      : in  std_logic_vector(15 downto 0);
      cart_exrom_i   : in  std_logic_vector( 7 downto 0);
      cart_game_i    : in  std_logic_vector( 7 downto 0);
      cart_size_i    : in  std_logic_vector(22 downto 0);

      -- From C64
      ioe_i          : in  std_logic;
      iof_i          : in  std_logic;
      wr_en_i        : in  std_logic;
      wr_data_i      : in  std_logic_vector( 7 downto 0);
      addr_i         : in  std_logic_vector(15 downto 0);

      -- To crt_cacher
      bank_lo_o      : out std_logic_vector( 6 downto 0);
      bank_hi_o      : out std_logic_vector( 6 downto 0);

      -- To C64
      io_rom_o       : out std_logic;
      exrom_o        : out std_logic;
      game_o         : out std_logic
   );
end entity cartridge;

architecture synthesis of cartridge is

   signal cart_disable : std_logic;
   signal ioe_ena      : std_logic;
   signal iof_ena      : std_logic;

   attribute mark_debug : string;
   attribute mark_debug of cart_loading_i : signal is "true";
   attribute mark_debug of cart_id_i      : signal is "true";
   attribute mark_debug of cart_exrom_i   : signal is "true";
   attribute mark_debug of cart_game_i    : signal is "true";
   attribute mark_debug of cart_size_i    : signal is "true";
   attribute mark_debug of ioe_i          : signal is "true";
   attribute mark_debug of iof_i          : signal is "true";
   attribute mark_debug of wr_en_i        : signal is "true";
   attribute mark_debug of wr_data_i      : signal is "true";
   attribute mark_debug of addr_i         : signal is "true";
   attribute mark_debug of bank_lo_o      : signal is "true";
   attribute mark_debug of bank_hi_o      : signal is "true";
   attribute mark_debug of exrom_o        : signal is "true";
   attribute mark_debug of game_o         : signal is "true";
   attribute mark_debug of cart_disable   : signal is "true";

begin

   io_rom_o <= (ioe_i and ioe_ena) or
               (iof_i and iof_ena);

   process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cart_loading_i = '1' then
            ioe_ena   <= '0';
            iof_ena   <= '0';
            game_o    <= '1';
            exrom_o   <= '1';
            bank_lo_o <= (others => '0');
            bank_hi_o <= (others => '0');
         end if;

         case to_integer(unsigned(cart_id_i)) is
            when 0 =>
               -- Generic 8k, 16k, or ultimax cartridge
               -- No bank swapping
               game_o    <= cart_game_i(0);
               exrom_o   <= cart_exrom_i(0);
               bank_lo_o <= (others => '0');
               bank_hi_o <= (others => '0');

            when 5 =>
               -- Ocean Type 1 - (game=0, exrom=0, 128k,256k or 512k in 8k banks)
               -- BANK is written to lower 6 bits of $DE00 - bit 8 is always set
               -- best to mirror banks at $8000 and $A000
               if ioe_i = '1' and wr_en_i = '1' then
                  bank_lo_o <= "0" & wr_data_i(5 downto 0);
                  bank_hi_o <= "0" & wr_data_i(5 downto 0);
               end if;
               -- Autodetect Ocean Type B (512k)
               -- Only $8000 is used, while $A000 is RAM
               if cart_loading_i = '1' then
                  if to_integer(unsigned(cart_size_i)) >= 512*1024 then
                     game_o <= '1';
                  else
                     game_o <= '0';
                  end if;
                  exrom_o   <= '0';
                  bank_lo_o <= (others => '0');
                  bank_hi_o <= (others => '0');
               end if;

            when 8 =>
               -- "Super Games"
               if iof_i = '1' and wr_en_i = '1' and cart_disable = '0' then
                  bank_lo_o    <= "00000" & wr_data_i(1 downto 0);
                  bank_hi_o    <= "00000" & wr_data_i(1 downto 0);
                  game_o       <= wr_data_i(2);
                  exrom_o      <= wr_data_i(2);
                  cart_disable <= wr_data_i(3);
               end if;
               if cart_loading_i = '1' then
                  cart_disable <= '0';
                  exrom_o      <= '0';
                  game_o       <= '0';
                  bank_lo_o    <= (others => '0');
                  bank_hi_o    <= (others => '0');
               end if;

            when 19 =>
               -- Magic Desk - (game=1, exrom=0 = 4/8/16 8k banks)
               if ioe_i = '1' and wr_en_i = '1' then
                  bank_lo_o <= "000" & wr_data_i(3 downto 0);
                  exrom_o   <= wr_data_i(7);
               end if;
               if cart_loading_i = '1' then
                  game_o    <= '1';
                  exrom_o   <= '0';
                  bank_lo_o <= (others => '0');
                  bank_hi_o <= (others => '0');
               end if;

            when 32 =>
               -- EASYFLASH - 1mb 128x8k/64x16k, XBank format(33) looks the same
               -- upd: original Easyflash(32) boots in ultimax mode.
               if ioe_i = '1' and wr_en_i = '1' then
                  if addr_i(1) = '1' then
                     game_o  <= (not wr_data_i(0)) and wr_data_i(2); -- assume jumper in boot position bit2=0 -> game=0
                     exrom_o <= not wr_data_i(1);
                  else
                     bank_lo_o <= "0" & wr_data_i(5 downto 0);
                     bank_hi_o <= "0" & wr_data_i(5 downto 0);
                  end if;
               end if;
               if cart_loading_i = '1' then
                  iof_ena   <= '1';
                  game_o    <= '0';
                  exrom_o   <= '1';
                  bank_lo_o <= (others => '0');
                  bank_hi_o <= (others => '0');
               end if;

            when others =>
               null;
         end case;

         if rst_i = '1' then
            ioe_ena   <= '0';
            iof_ena   <= '0';
            game_o    <= '1';
            exrom_o   <= '1';
            bank_lo_o <= (others => '0');
            bank_hi_o <= (others => '0');
         end if;
      end if;
   end process;

end architecture synthesis;

