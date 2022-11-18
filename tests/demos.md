Version 4 regression tests using demos
======================================

done by AmokPhaze101 in October to December 2022

Suggestion/Idea for AmokPhaze101
--------------------------------

If we use a table instead of the below mentioned headlines, the whole thing
might be easier to understand for people.

|Group            |Year       |Demo                         |Status              |Comment                                                                                                                                      |Image
|:----------------|-----------|:----------------------------|:-------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|:---------------------
| Arise           |           | ES1RA                       | :white_check_mark: | Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat     |<img src="https://github.com/MJoergen/C64MEGA65/blob/develop/tests/demos_img/test1.jpg" width="200">
| Arsenic         |           | Farbraus                    | :x:                | D öalk ak d öqlwödkqlökfpov pjkc adsclkas jqlwkjd lajkd                                                                                     |
| XYZ             |           | ABC                         | :white_check_mark: |                                                                                                                                             |
| XYZ             |           | ABC                         | :white_check_mark: |                                                                                                                                             |
| XYZ             |           | ABC                         | :white_check_mark: |                                                                                                                                             |
| Atlantis        |           | Beezarro                    | :bangbang:         | Kind of OK but not perfect, look at the glitch and the fix at [here](https://github.com/MJoergen/C64MEGA65/issues/9#issuecomment-1315137015)|<img src="https://github.com/MJoergen/C64MEGA65/blob/develop/tests/demos_img/test2.jpg" width="200">
| Atlantis        |           | Scene of the living Dead    | :white_check_mark: |                                                                                                                                             |
| Atlantis        |           | Royal Arte                  | :white_check_mark: |                                                                                                                                             |

Arise
-----

```
2017 - ES1RA                                                            => OK
2022 - E2IRA                                                            => OK
```                                                                     
                                                                                                                           
Arsenic                                                                 
-------                                                                 
                                                                                                                           
```                                                                     
2008 - Farbraus                                                         => OK 
2010 - FrightHof                                                        => OK 
2011 - Toxyc Taste                                                      => OK 
2012 - Cause of Death                                                   => OK 
2013 - To Hot To Trot                                                   => OK 
2016 - Incoherent Nightmare                                             => OK
```                                                                     
                                                                                                                           
Atlantis                                                                
--------                                                                 
                                                                                                                           
```                                                                     
2018 - Xcusemo                                                          => OK
2019 - Beezarro                                                         => OK
2020 - Scene of the living Dead                                         => OK
2021 - Sit Tibi Terra Levis                                             => OK
2021 - thirsty                                                          => OK
2022 - Eroismo                                                          => OK 
```

Bonzai
------

```
2016 - The Phoenix Code                                                 => OK 
2018 - Unboxed                                                          => OK 
2020 - Christmas Megademo (coop demo)                                   => OK 
2020 - D50                                                              => OK
2021 - Bromance                                                         => OK
2021 - The Sprites Demo ("space" to switch to next effect)              => OK
2022 - All Hallows Eve-The Pumpkins (coop demo)                         => !! KO !! see [Major issues and fix status] section
       [requires joystick in port2]                                     
        * fails on disk 2 after having run a few parts (crashes)                                                                                   
        * Seems to fail just before another part gets loaded
        * the part with a pumpkin and candles around it is not correct: 
           * the pumpkin is flickering and not colored.                              
        * disk 1 & disk 3 are ok (disk 4 is not part of the demo)                                                                                   
        * fails also on Mister with latest C64 core                                                                                   
        * Runs fine on true C64 and Ultimate 64                                                                              
2022 - Cocktail_To_Go                                                  => OK
2022 - Sprite Bukkake                                                  => OK
2022 - T50                                                             => OK
2022 - The World Is Not Enough - We Need More Scrollers                => OK
2022 - Trapped Love                                                    => OK
```

Booze Design
------------

```
2001 - Royal Arte                                                      => OK 
2003 - Industrial Breakdown                                            => OK 
2004 - Cycle                                                           => OK 
2006 - SlideShow                                                       => OK 
2007 - PartyPig                                                        => OK 
2008 - Edge of Disgrace                                                => OK
2009 - Andropolis                                                      => OK 
2010 - Mekanix                                                         => OK 
2011 - 1991                                                            => OK 
2013 - Time Machine                                                    => OK 
2014 - Uncensored                                                      => OK 
2016 - Classics                                                        => OK 
2019 - The Elder Scrollers                                             => OK 
2020 - Remains BD                                                      => OK 
2022 - 30 years                                                        => OK 
```

Censor Design 
-------------

```
2012 - Wonderland XI                                                   => OK 
2013 - Daah Those Acid Pills                                           => OK
2013 - Matrix                                                          => OK
2013 - Wonderland XII                                                  => OK
2014 - Serpent                                                         => OK
2015 - ComaLand 100pct                                                 => OK
2015 - Fantasmolytic                                                   => OK
2016 - Wonderland XIII                                                 => OK
2018 - The Star Wars demo                                              => OK
2018 - We come in Peace        (coop demo)                             => OK 
2019 - Rivalry                 (coop demo)                             => OK 
2020 - One                                                             => OK 
2020 - The Magic of BenDaglish (coop demo)                             => OK 
2020 - Xmas 2020                                                       => OK 
2022 - Sideline2                                                       => OK
```

Fairlight
---------

```
2010 - We Are New                                                      => OK
2011 - Lash                                                            => OK
2011 - We Are Mature                                                   => OK
2012 - One Quarter        (press space after having flipped the disk)  => OK
2014 - Redefinition                                                    => OK
2015 - Drinking Leroy                                                  => OK
2016 - In Memory Of                                                    => OK
2016 - We Shades                                                       => OK
2017 - Feliz Navidad                                                   => OK
2017 - K9 V Orange Main Sequence                                       => OK
2017 - Stoned Dragon                                                   => OK
2019 - Skaaneland 2                                                    => OK
2019 - The Last Truckstop 3                                            => OK
2020 - Predison 2020                                                   => OK
2020 - 2600                                                            => OK
```                                                                    
                                                                                                                          
Fatzone                                                                
-------                                                                
                                                                                                                          
```                                                                    
2022 - fatzoomania                                                     => OK
2022 - Partypopper                                                     => OK
```                                                                    
                                                                                                                          
Finnish Gold                                                           
------------                                                           
                                                                                                                          
```                                                                    
2021 - Lost in Transmission                                            => OK
2022 - Artificial Intelligence                                         => OK
```                                                                    

Fossil
------

```
2018 - Old Men in Used Cars                                            => OK
2018 - Space Beer                                                      => OK 
```
                                                                                                                          
Genesis Project                                                        
---------------                                                        
                                                                                                                          
```                                                                    
2015 - Demo of the year 2014                                           => OK
       - (Use NumKeys and press space to access a specific part)       
       - Press space to exit a demo part                               
       - a few demo parts may not run immediately                      
         => need to reset the core to have them working properly       
2015 - Demo with bugs                                                  => OK
2016 - Nothing But Petscii                                             => OK
2018 - Delirious11                                                     => OK
2018 - The Hidden (coop with Atlantis)                                 => OK
2018 - Xmarks The Spot                                                 => OK
2019 - The Dive                                                        => OK
2020 - Diagonality                                                     => OK
2020 - Memento Mori                                                    => OK
```                                                                    
                                                                                                                          
Glance                                                                 
------                                                                 
                                                                                                                          
```                                                                    
2010 - Snapshot                                                        => OK 
2020 - Protogeo100                                                     => OK 
```                                                                    
                                                                                                                          
Hitmen                                                                 
------                                                                 
                                                                                                                          
```                                                                    
2012 - Artphosis                                                       => OK
2016 - Monumentum                                                      => OK
```                                                                    
                                                                                                                          
Lethargy                                                               
--------                                                               
                                                                                                                          
```                                                                    
2017 - 25 years later                                                  => OK 
2019 - Demolution                                                      => OK 
2020 - 5 Shades of Grey                                                => OK 
2020 - Gamertro                                                        => OK 
2021 - Median                                                          => OK 
2021 - We Love To Party                                                => OK
2021 - XXX                                                             => OK
       [Needs CIA model 8521 to work properly - Otherwise Last effect  
          from First disk will flicker]                                   
2022 - F20                                                             => OK 
2022 - I Adore My 64=                                                  => OK 
2022 - Sprite Spirit                                                   => OK 
2022 - XXX+1                                                           => OK
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

Oxyron
------

```
1995 - Parts [ load"1*",8,1 then run to start]                         => OK 
2012 - Coma Light 13                                                   => OK
```

Padua
-----

```
2017 - Reluge 101%                                                     => OK
2021 - Stacked                                                         => OK
```

Performers
----------

```
2016 - Concert                                                         => OK
2018 - C=BIT18                                                         => OK
```

Pretzel Logic
-------------

```
2021 - Merry Twistmas                                                  => OK
2021 - Party Animals                                                   => OK
```

Samar Productions
-----------------

```
2019 - NGC 1277 100%                                                   => OK
2022 - Amanita (80%)                                                   => OK
```

Shape
-----

```
2014 - Disco Apocalypso                                                => OK
2017 - The Shores of Reflection                                        => OK
                               [!!!Change of disk is not detected but 
                                                     all parts from the 2 disks are ok]       
```

Triad
-----

```
2013 - Revolved                                                        => OK
2014 - Continuum                                                       => OK
2017 - Neon                                                            => OK
2018 - Soft Machine                                                    => OK
2020 - Uncle PETSCII's Christmas Show                                  => OK
2021 - Uncle Petsciis Droids of Star Wars                              => OK
```

Others
------

```
1989 - Upfront                         - Mixer                         => OK
        
              [* To exit part 2 hit "Restore"
               * To exit part 6 hit "C=" + "Run/stop"
               * In Part 6 hit "C=" to enter menu
               * For other parts hit "SPACE" and waitto exit]
               * when asked for disk 2 insert disk 2 and hit "SPACE]
                               
1991 - Demotion                        - Unbounded                     => !! KO !! 
        
              [Joystick in port 2, hit button when disk has been swapped]
              
        Issue [each part can be loaded and run successfully 
              individually, but the main loader keeps loading and 
              re-loading but never starts the first part, 
              It works even on early Mister C64 cores]                 => see [Major issues and fix status] section
                               

1991 - Crest                           - Ice Cream Castle              => !KO!
          
          [Joystick in port 2 needed to select Ice cream
          flavours combination,depending on the chosen flavours 
          the loaded and ran parts are different]
   
       Issue [asked to flip disk and press space but doing so, it keeps
              asking for flipping disk - Similar issue on Mister]      => see [Major issues and fix status] section
                               
1991 - Black Mail                      - Dutch Breeze                  => !KO!

        Issue [When hitting space to switch to part 5, screen goes 
              black, loading occures then stops and screen remains black,
              Impossible to reset the core, it resets when accessing 
              the menu.
              Not fixed by C64MEGA65-dev-irqdisp
              Not fixed by C64MEGA65-313c468 
              Same problem on True C64 + 1541 cartridge
              Same problem on Mister C64_20221117.rbf 
              But it works on mister with a Fastloader]                => see [Major issues and fix status] section

1992 - Panoramic Designs               - Mentallic                     => OK
1994 - Camelot                         - Camel Park                    => OK
1994 - Taboo                           - Altered States 50%            => OK
1994 - Reflex                          - Mathematica                   => OK
1994 - Camelot                         - Tower Power 100%              => OK
1997 - Coma                            - Void                          => OK
1996 - ByteRapers                      - Unsound minds                 => OK 
                                                                                                                          
2000 - Plush                           - +H2K                          => OK but not 100%
       [2 very slight glitches in 2 distinct parts,                              
        hard to capture but not ruining the effects                              
        * one sprite displayed when it should not                                
              * sprites on left and right borders flashing                             
           when the should not]                                        => see [Minor issues and fix status] section
                                                                                                                          
2000 - Crest and Oxyron                - Deus ex machina               => OK 
2001 - Resource                        - Soiled Legacy                 => OK 
2006 - Focus, Horizon, Instinct, Triad - The Wild Bunch                => OK
                                                                                                                          
2007 - Chorus and Resource             - Desert Dream                  => OK but not 100%
       [1 very slight glitch in 1 part, 
        hard to capture but not ruining the effects
        it seems related to displaying sprites on left
        and right borders]                                             => see [Minor issues and fix status] section

2008 - Xenon                           - Pearls for Pigs               => OK
2011 - Lepsi De, Miracles              - Apparatus                     => OK                                                                                                                              
2014 - Exceed, Resource, The Dreams    - Cauldron 101% +++             => OK
2015 - chorus                          - rocketry                      => OK
2016 - Lft                             - Lunatico                      => OK
2017 - Algotech                        - VF-SSDPCM1 Super Plus         => OK
2018 - c0zmo and others                - Drinking Buddies              => OK
2018 - Profik                          - Go Gray                       => OK
2019 - Delysid                         - Snakepit                      => OK
2019 - OMG                             - OMG Got Balls!                => OK
2019 - Padawans                        - Padawans' Awakening           => OK
2021 - Atlantis & Padua                - Unity                         => OK 
2021 - Desire                          - 1981                          => OK 
2021 - Focus                           - Thirty                        => OK
2021 - Hoaxers                         - Submerged                     => OK
2021 - Atlantis and Delysid            - ASOA 2021                     => OK   
                                                                                                                          
2021 - TSJ                             - Barry Boomer Trapped Again    => OK
                                                                                                                          
2022 - Dream                           - Fakfulce80                    => !! KO !! see [Major issues and fix status] section
                                                                                                                                    
2022 - Extend                          - Skybox                        => OK
2022 - Extend,Artline Designs,         - Still Rising                  => OK
       Bloodsuckers and Orange                                         
2022 - Cadets                          - Starfleet Academy             => OK
2022 - Atlantis and Delysid            - Madwoods Ahoy                 => OK
       [unpleasant creaking noises with  
              8580,OK with 6581]
```

Major issues and fix status
---------------------------

```
1991 - Demotion                        - Unbounded                     => !! KO !! 
        
              [Joystick in port 2, hit button when disk has been swapped]
              
        Issue [each part can be loaded and run successfully 
              individually, but the main loader keeps loading and 
              re-loading but never starts the first part. It works 
              even on early Mister C64 cores]

              => Fixed with C64MEGA65-313c468 (unreleased)
              Download the experimental core here:
              https://github.com/MJoergen/C64MEGA65/issues/2#issuecomment-1315170122

1991 - Crest                           - Ice Cream Castle              => !! KO !!
       
          [Joystick in port 2 needed to select Ice cream 
          flavours combination, depending on the chosen 
          flavours the loaded and ran parts are different]
   
       Issue [asked to flip disk and press space but doing so, it
              keeps asking for flipping disk - Similar issue on Mister]

              => Fixed with C64MEGA65-313c468 (unreleased)  
              Download the experimental core here:
              https://github.com/MJoergen/C64MEGA65/issues/2#issuecomment-1315170122
                               
1991 - Black Mail                      - Dutch Breeze                  => !! KO !!

        Issue [When hitting space to switch to part 5, screen goes black,
               loading occures then stops and screen remains black,
               Impossible to reset the core, it resets when accessing the menu,
               Not fixed by C64MEGA65-dev-irqdisp
               Not fixed by C64MEGA65-313c468 
               Same problem on True C64 + 1541 cartridge
               Same problem on Mister C64_20221117.rbf 
               But it works on mister with a Fastloader]               => NOT FIXED YET 


2017 - Shape - The Shores of Reflection                                => !! KO !! 
        
              Issue [!!!Change of disk is not detected but 
                        all parts from the 2 disks are ok
                        Runs fine on Mister C64_20221117.rbf
                        Runs fine on True C64 + 1541 cartridge
                        Not fixed by C64MEGA65-313c468
                        Not fixed by C64MEGA65-dev-irqdisp
                        Not fixed by changing CIA 
                        ]                                              => NOT FIXED YET 
                                                                                       
2022 - Dream                           - Fakfulce80                    => !! KO !! 

Status to be clarified.

2022 - All Hallows Eve-The Pumpkins (coop demo)                        => !! KO !! 
       
          [requires joystick in port2] 
       
          Issue[fails on disk 2 after having run a few parts (crashes)                                                                                   
             Seems to fail just before another part gets loaded
             the part with a pumpkin and candles around it is not correct: 
                      the pumpkin is flickering and not colored.                                   
             disk 1 & disk 3 are ok (disk 4 is not part of the demo)                                                                                   
             Runs fine on Mister C64_20221117.rbf                                                                             
             Runs fine on true C64 and Ultimate 64

          => Fixed with C64MEGA65-dev-irqdisp (unreleased)
          https://github.com/MJoergen/C64MEGA65/issues/9#issuecomment-1315137015
```

The "All Hallows Eve" problem was tracked in
[MiSTer Issue 141](https://github.com/MiSTer-devel/C64_MiSTer/issues/141).

The "Fakfulce80" problem is tracked in
[MiSTer Issue 136](https://github.com/MiSTer-devel/C64_MiSTer/issues/136).

Minor issues and fix status
---------------------------

```
2000 - Plush                   - +H2K                                   => OK but no 100% 
       Issue [2 very slight glitches in 2 distinct parts, 
       hard to capture but not ruining the effects
       * one sprite displayed when it should not
       * sprites on left and right borders flashing
              when they should not]                                     => NOT FIXED YET 


2007 - Chorus and Resource     - Desert Dream                           => OK but no 100%
       Issue [1 very slight glitch in 1 part, 
       hard to capture but not ruining the effects
       it seems related to displaying sprites on left
       and right borders]                                               => NOT FIXED YET  

```
