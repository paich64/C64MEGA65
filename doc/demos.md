Version 4 regression tests using demos
======================================

done by AmokPhaze101 in October to December 2022

Arsenic
-------

```
2008 - Farbraus                                                       => OK 
2010 - FrightHof                                                      => OK 
2011 - Toxyc Taste                                                    => OK 
2012 - Cause of Death                                                 => OK 
2013 - To Hot To Trot                                                 => OK 
2016 - Incoherent Nightmare                                           => OK
```

Bonzai
------

```
2016 - The Phoenix Code                                                      => OK 
2018 - Unboxed                                                               => OK 
2020 - Christmas Megademo (coop demo)                                        => OK 
2020 - D50                                                                   => OK
2021 - Bromance                                                              => OK
2021 - The Sprites Demo ("space" to switch to next effect)                   => OK
2022 - All Hallows Eve-The Pumpkins (coop demo) [requires joystick in port2] => !! KO !! 
                     => fails on disk 2 after having run a few parts (crashes)                                                                                   
                     => Seems to fail just before another part gets loaded                                                                                   
                     => disk 1 & disk 3 are ok (disk 4 is not part of the demo)                                                                                   
                     => fails also on Mister with latest C64 core                                                                                   
                     => Runs fine on true C64 and Ultimate 64                                                                              
2022 - Cocktail_To_Go                                                        => OK
2022 - Sprite Bukkake                                                        => OK
2022 - T50                                                                   => OK
2022 - The World Is Not Enough - We Need More Scrollers                      => OK
2022 - Trapped Love                                                          => OK (Though make sure you make a fresh cold boot of the core)
```

The "All Hallows Eve" problem is tracked in
[MiSTer Issue 141](https://github.com/MiSTer-devel/C64_MiSTer/issues/141).

Booze Design
------------

```
2001 - Royal Arte                       => OK 
2003 - Industrial Breakdown             => OK 
2004 - Cycle                            => OK 
2006 - SlideShow                        => OK 
2007 - PartyPig                         => OK 
2008 - Edge of Disgrace                 => OK
2009 - Andropolis                       => OK 
2010 - Mekanix                          => OK 
2011 - 1991                             => OK 
2013 - Time Machine                     => OK 
2014 - Uncensored                       => OK 
2016 - Classics                         => OK 
2019 - The Elder Scrollers              => OK 
2020 - Remains BD                       => OK 
2022 - 30 years                         => OK 
```

Censor Design 
-------------

```
2012 - Wonderland XI                       => OK 
2013 - Daah Those Acid Pills               => OK
2013 - Matrix                              => OK
2013 - Wonderland XII                      => OK
2014 - Serpent                             => OK
2015 - ComaLand 100pct                     => OK
2015 - Fantasmolytic                       => OK
2016 - Wonderland XIII                     => OK
2018 - The Star Wars demo                  => OK
2018 - We come in Peace        (coop demo) => OK 
2019 - Rivalry                 (coop demo) => OK 
2020 - One                                 => OK 
2020 - The Magic of BenDaglish (coop demo) => OK 
2020 - Xmas 2020                           => OK 
2022 - Sideline2                           => OK
```

Fairlight
---------

```
2010 - We Are New                                                     => OK
2011 - Lash                                                           => OK
2011 - We Are Mature                                                  => OK
2012 - One Quarter        (press space after having flipped the disk) => OK
2014 - Redefinition                                                   => OK
2015 - Drinking Leroy                                                 => OK
2016 - In Memory Of                                                   => OK
2016 - We Shades                                                      => OK
2017 - Feliz Navidad                                                  => OK
2017 - K9 V Orange Main Sequence                                      => OK
2017 - Stoned Dragon                                                  => OK
2019 - Skaaneland 2                                                   => OK
2019 - The Last Truckstop 3                                           => OK
2020 - Predison 2020                                                  => OK
```
Genesis Project
---------------

```
2015 - Demo of the year 2014                                      => OK
       - (Use NumKeys and press space to access a specific part)
       - Press space to exit a demo part 
       - a few demo parts may not run immediately 
         => need to reset the core to have them working properly
2015 - Demo with bugs                                             => OK
2016 - Nothing But Petscii                                        => OK
2018 - Delirious11                                                => OK
2018 - The Hidden (coop with Atlantis)                            => OK
2018 - Xmarks The Spot                                            => OK
2019 - The Dive                                                   => OK
2020 - Diagonality                                                => OK
2020 - Memento Mori                                               => OK
```

Lethargy
--------

```
2017 - 25 years later             => OK 
2019 - Demolution                 => OK 
2020 - 5 Shades of Grey           => OK 
2020 - Gamertro                   => OK 
2021 - Median                     => OK 
2021 - We Love To Party           => OK
2021 - XXX                        => OK => Needs CIA model 8521 to work properly (Otherwise Last effect from First disk will flicker)
2022 - F20                        => OK 
2022 - I Adore My 64=             => OK 
2022 - Sprite Spirit              => OK 
2022 - XXX+1                      => OK
```

Offense Fairlight Prosonix
--------------------------

```
2010 - Another Beginning       (press "space" to switch to next parts) => OK
2011 - A Press Space Odissey   (press "space" to switch to next parts) => OK 
2012 - Trick and Treat         (press "space" to switch to next parts) => OK 
2013 - Famous Australians Vol1 (shitf lock to invert screen)           => OK
2013 - ScrollWars                                                      => OK
2013 - Too Old To Ror N Rol                                            => OK
2014 - Redefinition                                                    => OK
2014 - RGB                                                             => OK
2014 - We Are All Connected                                            => OK
2015 - GoatLight                                                       => OK
2015 - We are demo                                                     => OK
2016 - Area 64                                                         => OK
2017 - Datastorm Leftovers                                             => OK
2017 - Private Parts                                                   => OK
2018 - Fopcycle                                                        => OK 
2018 - Pain In The Asm                                                 => OK 
2019 - Monomania                                                       => OK 
2022 - Lifecycle                                                       => OK
```

Others
------

```
1994 - Taboo                   - Altered States 50%                      => OK
1994 - Reflex                  - Mathematica                             => OK
1995 - Oxyron                  - Parts [ load"1*",8,1 then run to start] => OK 
1996 - ByteRapers              - Unsound minds                           => OK 
2000 - Plush                   - +H2K                                    => OK 
                      [2 very slight glitches in 2 distinct parts, 
                      hard to capture but not ruining the effects
                      They seem related to displaying sprites on left
                      and right borders]
2000 - Crest and Oxyron        - Deus ex machina                         => OK 
2001 - Resource                - Soiled Legacy                           => OK 
2007 - Chorus and Resource     - Desert Dream                            => OK
                      [1 very slight glitch in 1 part, 
                       hard to capture but not ruining the effects
                       it seems related to displaying sprites on left
                       and right borders] 
2012 - Oxyron                  - Coma Light 13                           => OK
2016 - Lft                     - Lunatico                                => OK
2021 - TSJ                     - Barry Boomer Trapped Again              => OK
2022 - Dream                   - Fakfulce80                              => !! KO !!
2022 - Extend                  - Skybox                                  => OK
                      [had to watch on real hardware to confirm
                       that all the artifacts are also on real 
                       hardware] 
2022 - Extend,Artline Designs, - Still Rising                            => OK
       Bloodsuckers and Orange
2022 - Finnish Gold            - Artificial Intelligence                 => OK
```

The "Fakfulce80" problem is tracked in
[MiSTer Issue 136](https://github.com/MiSTer-devel/C64_MiSTer/issues/136).
