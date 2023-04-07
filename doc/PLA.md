PLA Equations
=============

Originally from "The C64 PLA Dissected", Revision 1.1, December 24, 2012
by Thomas ’skoe’ Giesel. Rewritten into CUPL and made them easier to read
by Daniel Mantione. Documented for C64MEGA65 by sy2002 in April 2023.


```
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
```

* "#" means or and "!" means not and "&" means "and"
* The formulas are high active logic and then they are turned into the correct
  low active by the "!" in o_roml = ! ... and o_romh = ! ...
* loram and hiram are the loram and hiram lines from the CPU or register $0001.
  They have the same polarity as your write to the register.
* aec decides who has the bus: Low = 6510, High = VIC-II.
  Therefore !i_aec means that the CPU has the bus.
* rd = R/W. Low=Write, High=Read
* m_cart8k means 8K cartridge mode, active high when GAME = 1, EXROM = 0
* m_cart16k means 16K cartridge mode, active high when GAME = 0, EXROM = 0
* m_ultimax means Ultimax mode, active high when GAME = 0, EXROM = 1
* The VIC-II has its own address bus lines, the 6510 and VIC-II are each
  connected to the PLA with their own address bus lies. So va12, va13 means
  address lines a12 and a13 direct from the VIC-II.
