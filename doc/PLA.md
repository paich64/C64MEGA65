
p19 = addr:[8000..9fff] & i_loram & i_hiram & !i_aec & i_rd & (m_cart8k # m_cart16k);
p20 = addr:[8000..9fff] & !i_aec & m_ultimax;

p21 = addr:[a000..bfff] & i_hiram & !i_aec & i_rd & m_cart16k;
p22 = addr:[e000..ffff] & !i_aec & m_ultimax;
p23 = i_aec & i_va13 & i_va12 & m_ultimax;

o_roml = ! (p19 # p20);
o_romh = ! (p21 # p22 # p23);


P19 describes the ROML line behaviour in 8K CRT and 16K CRT mode.
P20 describes the ROML line behaviour in Ultimax mode.

P21 describes the ROMH line behaviour in 16K CRT mode.
P22 describes the ROMH line behaviour in Ultimax mode for CPU reads/writes from/to the cartridge.
P23 describes the ROMH line behaviour in Ultimax mode for VIC-II reads from the cartridge.