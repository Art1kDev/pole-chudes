{   ================================================================== }
{                                                                      }
{   POLE CHUDES (1992-1993) -- reverse-engineered source code          }
{                                                                      }
{   (C) Vadim Bashurov, Arzamas-16, 1992-1993                          }
{                                                                      }
{   Recovered by reverse engineering of the original POLE.EXE.         }
{                                                                      }
{   Needs POLE.LIB / FNT / OVL / PIC in the same directory.            }
{                                                                      }
{   The original was written for DOS. This reconstruction was          }
{   ported to Turbo Pascal 7.0 while preserving the original           }
{   program structure, procedures, variables and formulas.             }
{                                                                      }
{   Mode 10h 640x350x16, direct A000h access. No Crt, no Graph,        }
{   no BGI. Keys: arrows/mouse, SPACE, ENTER, Ctrl+S sound,            }
{   TAB blank, ESC quit.                                               }
{                                                                      }
{   ================================================================== }

program PoleChudes;

{$A+,B-,D-,E-,F+,G-,I-,L-,N-,O-,R-,S-,V-,X+}
{$M 16384,0,655360}

uses Dos;

const
  VideoSeg     = $A000;
  BPL          = 80;
  ScrW         = 640;
  ScrH         = 350;
  MaxRes       = 57;
  OvlRecSize   = 21;
  PicRecSize   = 13;
  MaxWordLen   = 20;
  Fnt6         = 5;
  Fnt8         = 7;
  Fnt14        = 13;
  NoTrans      = 16;

  ResWheel0    = 1;
  ResArrow     = 17;
  ResCell0     = 18;
  ResGirl0     = 24;
  ResYakub     = 28;
  ResSnickers  = 29;
  ResHand      = 30;
  ResMoney     = 31;
  ResBrick0    = 32;
  ResLamp      = 35;
  ResBubble    = 36;
  ResBoxClosed = 37;
  ResBoxOpen   = 38;
  ResBoxMoney  = 39;
  ResOppBub    = 40;
  ResWallL     = 41;
  ResWallR     = 42;
  ResYakOpen   = 43;
  ResYakEyes   = 44;
  ResYakEyesCl = 45;
  ResYakClosed = 46;
  ResTitlePole = 47;
  ResTitleChud = 48;
  ResPanel     = 53;
  ResEnter0    = 54;
  ResRuble     = 57;

  SectorType: array[0..15] of Word =
    (4,5,12,6,14,7,13,6,12,8,11,5,10,7,9,8);

  SectorValueTab: array[0..10] of Integer =
    (100,5,10,15,20,-1,202,204,0,300,25);

  Alphabet: array[1..32] of Char =
    (#$80,#$81,#$82,#$83,#$84,#$85,#$86,#$87,#$88,#$89,#$8A,#$8B,
     #$8C,#$8D,#$8E,#$8F,#$90,#$91,#$92,#$93,#$94,#$95,#$96,#$97,
     #$98,#$99,#$9A,#$9B,#$9C,#$9D,#$9E,#$9F);

  KbdLat   : string[33] = 'QWERTYUIOP{}ASDFGHJKL;'+#$27+'ZXCVBNM,./';
  KbdRus   : string[33] = #$89+#$96+#$93+#$8A+#$85+#$8D+#$83+#$98+#$99+#$87+#$95+#$9A+#$94+#$9B+#$82+#$80+#$8F+#$90+
                          #$8E+#$8B+#$84+#$86+#$9D+#$9F+#$97+#$91+#$8C+#$88+#$92+#$9C+#$81+#$9E+#$F0;

  ScoreX: array[1..3] of Word = (388,82,320);
  ScoreY: array[1..3] of Word = (120,120,294);
  NameX : array[1..3] of Word = (410,130,240);

  OppName: array[1..6] of string[10] =
    (#$8F#$9F#$92#$80#$97#$8E#$8A,
     #$82#$88#$8D#$8D#$88'-'#$8F#$93#$95,
     #$8A#$90#$8E#$8B#$88#$8A,
     #$88#$80'-'#$88#$80,
     #$8A#$80#$90#$8B#$91#$8E#$8D,
     #$91#$8E#$82#$80);

  OppSprite: array[1..6] of Byte = (22,23,49,50,51,52);

  PrizeName: array[0..9] of string[24] =
   (#$87#$93#$81#$8D#$93#$9E' '#$99#$85#$92#$8A#$93,
    #$8F#$AE#$E0#$AE#$E8#$AE#$AA' ARIEL',
    #$90#$A0#$E1#$E7#$A5#$E1#$E2#$AA#$E3' '#$A4#$AB#$EF' '#$E3#$E1#$AE#$A2,
    #$87#$E3#$A1#$AE#$E7#$A8#$E1#$E2#$AA#$E3,
    #$8A#$E0#$E3#$A3' '#$A4#$AB#$EF' '#$E3#$AD#$A8#$E2#$A0#$A7#$A0,
    #$90#$E3#$AB#$AE#$AD' '#$AC#$EF#$A3#$AA#$AE#$A9' '#$A1#$E3#$AC#$A0#$A3#$A8,
    #$98#$AD#$E3#$E0#$AA#$A8' '#$A4#$AB#$EF' '#$AA#$A0#$AB#$AE#$E8,
    #$8F#$AE#$A4#$E2#$EF#$A6#$AA#$A8' '#$A4#$AB#$EF' '#$AD#$AE#$E1#$AA#$AE#$A2,
    #$81#$A5#$E0#$E3#$E8#$A8' '#$A4#$AB#$EF' '#$E3#$E8#$A5#$A9,
    #$8F#$A8#$A2#$AD#$E3#$EE' '#$AE#$E2#$AA#$E0#$EB#$A2#$A0#$E8#$AA#$E3);

  sFirst       = #$8F+#$A5+#$E0+#$A2+#$EB+#$A9;
  sSecond      = #$82+#$E2+#$AE+#$E0+#$AE+#$A9;
  sThird       = #$92+#$E0+#$A5+#$E2+#$A8+#$A9;
  sPlayerBang  = ' '+#$A8+#$A3+#$E0+#$AE+#$AA+'!';
  sPlayer      = ' '+#$A8+#$A3+#$E0+#$AE+#$AA;
  sSpin        = #$82+#$E0+#$A0+#$E9+#$A0+#$A9+#$E2+#$A5+' '+#$A1+#$A0+#$E0+#$A0+#$A1+#$A0+#$AD+'!';
  sYouHave     = #$93+' '+#$82+#$A0+#$E1+' ';
  sPoints      = ' '+#$AE+#$E7+#$AA+#$AE+#$A2+'!';
  sNameLetter  = #$8D+#$A0+#$A7+#$AE+#$A2+#$A8+#$E2+#$A5+' '+#$A1+#$E3+#$AA+#$A2+#$E3+'!';
  sZero        = #$93+' '+#$82+#$A0+#$E1+' 0 '+#$AE+#$E7+#$AA+#$AE+#$A2+'..';
  sPass        = #$93+#$A2+#$EB+'! '+#$8F+#$A5+#$E0+#$A5+#$E5+#$AE+#$A4+' '+#$E5+#$AE+#$A4+#$A0+'..';
  sBankrupt    = #$82+#$E1+#$A5+' '+#$A4+#$A5+#$AD+#$EC+#$A3+#$A8+' '+#$E1+#$A3+#$AE+#$E0+#$A5+#$AB+#$A8+'!';
  sDouble      = #$84+#$A5+#$AD+#$EC+#$A3+#$A8+' '+#$E3+#$A4+#$A2+#$A0+#$A8+#$A2+#$A0+#$EE+#$E2+#$E1+#$EF+'!';
  sPlus        = #$91+#$A5+#$AA+#$E2+#$AE+#$E0+' '+#$8F+#$8B+#$9E+#$91+'!';
  sOpenAny     = #$8E+#$E2+#$AA+#$E0+#$AE+#$A9+' '+#$AB+#$EE+#$A1+#$E3+#$EE+' '+#$A1+#$E3+#$AA+#$A2+#$E3+'!';
  sPrizeSect   = #$91+#$A5+#$AA+#$E2+#$AE+#$E0+' '+#$8F+#$90+#$88+#$87+'!';
  sPrizeOrPl   = #$8F+#$90+#$88+#$87+' '+#$A8+#$AB+#$A8+' '+#$A8+#$A3+#$E0+#$A0+#$A5+#$AC+'?';
  sHasLetter   = #$85+#$E1+#$E2+#$EC+' '+#$E2+#$A0+#$AA+#$A0+#$EF+' '+#$A1+#$E3+#$AA+#$A2+#$A0+'!';
  sBravo2      = #$81+#$E0+#$A0+#$A2+#$AE+'!!';
  sNoLetter    = #$8D+#$A5+#$E2+' '+#$E2+#$A0+#$AA+#$AE+#$A9+' '+#$A1+#$E3+#$AA+#$A2+#$EB+'!';
  sPassShort   = #$8F+#$A5+#$E0+#$A5+#$E5+#$AE+#$A4+' '+#$E5+#$AE+#$A4+#$A0+'..';
  sWonRound    = #$A2+#$EB+#$A8+#$A3+#$E0+#$A0+#$AB+' '+#$E0+#$A0+#$E3+#$AD+#$A4+'!';
  s3Letters    = #$87+#$A0+' 3 '+#$A1+#$E3+#$AA+#$A2+#$EB+' '+#$8F+#$90+#$85+#$8C+#$88+#$9F+'!';
  sBoxesIn     = #$82+#$AD+#$A5+#$E1+#$A8+#$E2+#$A5+' '+#$E8+#$AA+#$A0+#$E2+#$E3+#$AB+#$AA+#$A8+'!';
  sWhereMoney  = #$83+#$A4+#$A5+' '+#$A4+#$A5+#$AD+#$EC+#$A3+#$A8+'?';
  sChoose      = #$82+#$EB+#$A1+#$A8+#$E0+#$A0+#$A9+#$E2+#$A5+'!';
  sBravo3      = #$81+#$E0+#$A0+#$A2+#$AE+'!!!';
  sYouGuessed  = #$82+#$EB+' '+#$AE+#$E2+#$A3+#$A0+#$A4+#$A0+#$AB+#$A8+'!';
  sAlasThis    = #$93+#$A2+#$EB+'! '+#$9D+#$E2+#$A0;
  sBoxEmpty    = #$E8+#$AA+#$A0+#$E2+#$E3+#$AB+#$AA+#$A0+' '+#$AF+#$E3+#$E1+#$E2+#$A0+'!';
  sWordIs      = #$87+#$A0+#$A3+#$A0+#$A4+#$A0+#$AD+#$AE+' '+#$E1+#$AB+#$AE+#$A2+#$AE+':';
  sStartGame   = #$8D+#$A0+#$E7+#$A8+#$AD+#$A0+#$A5+#$AC+' '+#$A8+#$A3+#$E0+#$E3+'!';
  sTheme       = #$92+#$A5+#$AC+#$A0+':';
  sRight1      = #$82+#$EB+' '+#$E1+#$AE+#$A2+#$A5+#$E0+#$E8+#$A5+#$AD+#$AD+#$AE;
  sRight2      = #$AF+#$E0+#$A0+#$A2+#$EB+'!!';
  sWrong1      = #$8D+#$A5+#$AF+#$E0+#$A0+#$A2+#$A8+#$AB+#$EC+#$AD+#$AE+'! '+#$82+#$EB;
  sWrong2      = #$AF+#$AE+#$AA+#$A8+#$A4+#$A0+#$A5+#$E2+#$A5+' '+#$A8+#$A3+#$E0+#$E3+'!';
  sCongrat1    = #$8F+#$AE+#$A7+#$A4+#$E0+#$A0+#$A2+#$AB+#$EF+#$EE+'! '+#$82+#$EB;
  sCongrat2    = #$A2+#$EB+#$A8+#$A3+#$E0+#$A0+#$AB+#$A8+' '+#$E4+#$A8+#$AD+#$A0+#$AB+'!';
  sSorry1      = #$8A+' '+#$E1+#$AE+#$A6+#$A0+#$AB+#$A5+#$AD+#$A8+#$EE+' '+#$82+#$EB;
  sSorry2      = #$AF+#$AE+#$AA+#$A8+#$A4+#$A0+#$A5+#$E2+#$A5+' '+#$A8+#$A3+#$E0+#$E3+'..';
  sIfSo1       = #$85+#$E1+#$AB+#$A8+' '+#$E2+#$A0+#$AA+', '+#$E2+#$AE;
  sIfSo2       = #$AD+#$A0+#$A7+#$AE+#$A2+#$A8+#$E2+#$A5+' '+#$A1+#$E3+#$AA+#$A2+#$E3+'.';
  sAdv1        = #$90+#$85+#$8A+#$8B+#$80+#$8C+#$8D+#$80+#$9F;
  sAdv2        = #$8F+#$80+#$93+#$87+#$80+'!';
  sPrizeOr     = #$8F+#$90+#$88+#$87+' '+#$A8+#$AB+#$A8;
  sRoubles     = ' '+#$E0+#$E3+#$A1+#$AB+#$A5+#$A9+'?';
  sTake1       = #$87+#$A0+#$A1+#$A8+#$E0+#$A0+#$A9+#$E2+#$A5;
  sTake2       = #$E1+#$A2+#$AE+#$A8+' '+#$84+#$85+#$8D+#$9C+#$83+#$88+'!';
  sPresent1    = #$8F+#$E0+#$A5+#$A4+#$E1+#$E2+#$A0+#$A2+#$AB+#$EF+#$EE;
  sPresent2    = #$E3+#$E7+#$A0+#$E1+#$E2+#$AD+#$A8+#$AA+#$AE+#$A2+'!';
  sYourPrize   = #$E1+#$A2+#$AE+#$A9+' '+#$8F+#$90+#$88+#$87+'!';
  sLetter     = #$81#$E3#$AA#$A2#$A0'  ';
  sNthLetter  = '-'#$EF' '#$A1#$E3#$AA#$A2#$A0;

  sCapital     = ' '+#$8A+#$80+#$8F+#$88+#$92+#$80+#$8B+#$98+#$8E+#$93+' ';
  sAuthor      = #$80+#$A2+#$E2+#$AE+#$E0+' '+#$84+#$A8+#$AC+#$A0+' '+#$81+#$A0+#$E8+#$E3+#$E0+#$AE+#$A2+' '+#$A8+#$A7+
                 ' '+#$90+#$AE+#$E1+#$E1+#$A8+#$A9+#$E1+#$AA+#$AE+#$A3+#$AE+' '+#$94+#$A5+#$A4+#$A5+#$E0+#$A0+#$AB+#$EC+
                 #$AD+#$AE+#$A3+#$AE+' '+#$9F+#$A4+#$A5+#$E0+#$AD+#$AE+#$A3+#$AE+' '+#$96+#$A5+#$AD+#$E2+#$E0+#$A0;
  sPhone       = #$92+#$A5+#$AB+#$A5+#$E4+#$AE+#$AD+' '+#$A2+' '+#$80+#$E0+#$A7+#$A0+#$AC+#$A0+#$E1+#$A5+
                 '-16 : (831-30) 5-92-73   E-mail: 0669 @ RFNC. NNOV. SU';
  sDedic       = #$8F+#$AE+#$E1+#$A2+#$EF+#$E9+#$A0+#$A5+#$E2+#$E1+#$EF+' '+#$A4+#$E0+#$E3+#$A7+#$EC+#$EF+#$AC;
  sHelp1       = #$91+#$8F+#$90+#$80+#$82+#$8A+#$80+': '+#$84+#$AB+#$EF+' '+#$AF+#$A5+#$E0+#$A5+#$AC+#$A5+#$E9+#$A5+#$AD+
                 #$A8+#$EF+' '+#$E1+#$A2+#$AE+#$A5+#$A9+' '+#$E0+#$E3+#$AA+#$A8+' '+#$A8+#$E1+#$AF+#$AE+#$AB+#$EC+#$A7+
                 #$A9+#$E2+#$A5+' '+#$AA+#$AB+#$A0+#$A2+#$A8+#$E8+#$A8+' '+#$E1+#$AE+' '+#$E1+#$E2+#$E0+#$A5+#$AB+#$AA+
                 #$A0+#$AC+#$A8+' '+#$A8+#$AB+#$A8;
  sHelp2       = '"'+#$AC+#$EB+#$E8+#$AA+#$E3+'". '+#$82+#$A2+#$AE+#$A4+' '+#$AE+#$E1+#$E3+#$E9+#$A5+#$E1+#$E2+#$A2+#$AB+
                 #$EF+#$A5+#$E2+#$E1+#$EF+' '+#$AD+#$A0+#$A6+#$A0+#$E2+#$A8+#$A5+#$AC+' '+#$AD+#$A0+' '+#$AA+#$AB+#$A0+
                 #$A2+#$A8+#$E8+#$E3+' '+#$8F+#$90+#$8E+#$81+#$85+#$8B+' '+#$A8+#$AB+#$A8+' '+#$AD+#$A0;
  sHelp3       = #$AB+#$A5+#$A2+#$E3+#$EE+' '+#$AA+#$AD+#$AE+#$AF+#$AA+#$E3+'"'+#$AC+#$EB+#$E8+#$AA+#$A8+'". '+#$8D+#$A0+
                 #$A6+#$A0+#$E2+#$A8+#$A5+' <Ctrl+S> '+#$A2+#$AA+#$AB+#$EE+#$E7+#$A0+#$A5+#$E2+'/'+#$A2+#$EB+#$AA+#$AB+
                 #$EE+#$E7+#$A0+#$A5+#$E2+' '+#$A7+#$A2+#$E3+#$AA+',';
  sHelp4       = #$A5+#$E1+#$AB+#$A8+' '+#$AF+#$E0+#$A8+#$E8+#$A5+#$AB+' '+#$AD+#$A0+#$E7+#$A0+#$AB+#$EC+#$AD+#$A8+#$AA+
                 ', '+#$AD+#$A0+#$A6+#$AC+#$A8+' '+#$AA+#$AB+#$A0+#$A2+#$A8+#$E8+#$E3+' TAB, ESC - '+#$A2+#$EB+#$E5+#$AE+
                 #$A4+' '+#$A8+#$A7+' '+#$A8+#$A3+#$E0+#$EB+'!';

  sQuarter     = #$97+#$85+#$92+#$82+#$85+#$90+#$92+#$9C+#$94+#$88+#$8D+#$80+#$8B;
  sSemi        = '  '+#$8F+#$8E+#$8B+#$93+#$94+#$88+#$8D+#$80+#$8B;
  sFinal       = '    '+#$94+#$88+#$8D+#$80+#$8B;

  sPl1         = #$8F+#$A5+#$E0+#$A2+#$EB+#$A9+' '+#$A8+#$A3+#$E0+#$AE+#$AA;
  sPl2         = #$82+#$E2+#$AE+#$E0+#$AE+#$A9+' '+#$A8+#$A3+#$E0+#$AE+#$AA;
  sPl3         = #$92+#$E0+#$A5+#$E2+#$A8+#$A9+' '+#$A8+#$A3+#$E0+#$AE+#$AA;
  sItsYou      = #$ED+#$E2+#$AE+' '+#$82+#$9B+'!';

  sSay1        = #$91+#$AA+#$A0+#$A6+#$E3+'   '+#$8A+#$E0+#$E3+#$E7+#$E3;
  sSay2        = #$91+#$8B+#$8E+#$82+#$8E+'  '+#$81+#$80+#$90+#$80+#$81+#$80+#$8D;
  sTakeA1      = #$81+#$A5+#$E0+#$E3+'   '+#$81+#$E3+#$A4+#$E3;
  sTakeA2      = #$8F+#$90+#$88+#$87+'  '+#$88+#$83+#$90+#$80+#$92+#$9C;
  sTakeB1      = #$81+#$A5+#$E0+#$E3+'    '+#$81+#$A5+#$E0+#$E3;
  sTakeB2      = #$8F+#$90+#$88+#$87+'   '+#$84+#$85+#$8D+#$9C+#$83+#$88;

  sHundred     = #$91#$92#$8E;
  sThousand    = #$92#$9B#$99#$80;
  sHundredK    = #$91+#$92+#$8E+' '+#$92+#$9B+#$99;
  sMillion     = #$8C+#$88+#$8B+#$8B+#$88+#$8E+#$8D;
  sPrizeWon    = #$82+#$EB+' '+#$A2+#$EB+#$A1+#$E0+#$A0+#$AB+#$A8+' '+#$8F+#$90+#$88+#$87+' '+#$A8+' '+#$AC+#$EB+' '+
                 #$82+#$A0+#$E1+' '+#$AF+#$AE+#$A7+#$A4+#$E0+#$A0+#$A2+#$AB+#$EF+#$A5+#$AC+'!';
  sFirmGives   = #$94+#$A8+#$E0+#$AC+#$A0+' '+#$88+#$8D+#$92+#$85+#$90+#$8C+#$8E+#$84+#$80+' '+#$A8+' '+#$8F+#$8E+#$8B+
                 #$85+' '+#$97+#$93+#$84+#$85+#$91+' '+#$A4+#$A0+#$E0+#$A8+#$E2+' '+#$82+#$A0+#$AC;
  sFromPG      = ' '+#$AA+#$AE+#$AC+#$AF+#$A0+#$AD+#$A8+#$A8+' PROCTER & GAMBLE!';
  sAddr        = #$87+#$A0+' '+#$8F+#$90+#$88+#$87+#$8E+#$8C+' '+#$AE+#$A1+#$E0+#$A0+#$E9+#$A0+#$A9+#$E2+#$A5+#$E1+#$EC+
                 ' '+#$AF+#$AE+' '+#$A0+#$A4+#$E0+#$A5+#$E1+#$E3+':';
  sMark2       = #$8D#$A0' '#$AA#$AE#$AD#$A2#$A5#$E0#$E2#$A5' '#$E1#$A4#$A5#$AB#$A0#$A9#$E2#$A5+
                 ' '#$AF#$AE#$AC#$A5#$E2#$AA#$E3' '#$8A#$8E#$8C#$8F#$9C#$9E#$92#$85#$90#$8D#$9B#$89+
                 ' '#$8F#$90#$88#$87;
  sMark        = '101000-'+#$96+', '+#$8C+#$AE+#$E1+#$AA+#$A2+#$A0+', '+#$AF+#$E0+#$AE+#$A5+#$A7+#$A4+' '+#$91+#$A5+#$E0+
                 #$AE+#$A2+#$A0+', 11';
  sYouWonFin   = #$82+#$EB+' '+#$A2+#$EB+#$A8+#$A3+#$E0+#$A0+#$AB+#$A8+' '+#$A2+' '+#$94+#$88+#$8D+#$80+#$8B+#$85+' '+
                 #$A8+' '+#$AD+#$A0+#$A1+#$E0+#$A0+#$AB+#$A8+' ';
  sPointsEx    = ' '+#$AE+#$E7+#$AA+#$AE+#$A2+'!';
  sTusar       = #$92+#$AE+#$E0+#$A3+#$AE+#$A2+#$EB+#$A9+' '+#$A4+#$AE+#$AC+' '+#$92+#$93+#$91+#$80+#$90+' '+#$A8+' '+
                 #$8F+#$8E+#$8B+#$85+' '+#$97+#$93+#$84+#$85+#$91+' '+#$A4+#$A0+#$E0+#$A8+#$E2+' '+#$82+#$A0+#$AC;
  sTop8a       = '8 '+#$AB+#$E3+#$E7+#$E8+#$A8+#$E5+' '+#$A8+#$A3+#$E0+#$AE+#$AA+#$AE+#$A2+',';
  sTop8b       = #$A2+#$EB+#$A8+#$A3+#$E0+#$A0+#$A2+#$E8+#$A8+#$E5+' '+#$94+#$88+#$8D+#$80+#$8B+'!';

  sSale1       = #$8A+#$AE+#$AC+#$AF+#$EC+#$EE+#$E2+#$A5+#$E0+#$AD+#$A0+#$EF+' '+#$A8+#$A3+#$E0+#$A0;
  sSale2       = #$AF+#$E0+#$AE+#$A4+#$A0+#$A5+#$E2+#$E1+#$EF+' '+#$AF+#$AE+' '+#$A0+#$A4+#$E0+#$A5+#$E1+#$E3;
  sSale3       = '101000-'+#$96+', '+#$8C+#$8E+#$91+#$8A+#$82+#$80+',';
  sSale4       = #$AF+#$E0+#$AE+#$A5+#$A7+#$A4+' '+#$91+#$A5+#$E0+#$AE+#$A2+#$A0+', 11.';
  sSale5       = '25 '+#$E1+#$A0+#$AC+#$EB+#$E5+' '+#$AF+#$A5+#$E0+#$A2+#$EB+#$E5;
  sSale6       = #$AF+#$AE+#$AA+#$E3+#$AF+#$A0+#$E2+#$A5+#$AB+#$A5+#$A9+' '+#$A1+#$E3+#$A4+#$E3+#$E2;
  sSale7       = #$AF+#$E0+#$A8+#$A3+#$AB+#$A0+#$E8+#$A5+#$AD+#$EB+' '+#$E1+#$AE;
  sSale8       = #$E1+#$A2+#$AE+#$A8+#$AC+#$A8+' '+#$E1+#$A5+#$AC+#$EC+#$EF+#$AC+#$A8;
  sSale9       = #$AD+#$A0+' '+#$E1+#$EA+#$A5+#$AC+#$AA+#$A8+' '+#$E2+#$A5+#$AB+#$A5+#$A8+#$A3+#$E0+#$EB;
  sSale10      = #$8F+#$8E+#$8B+#$85+' '+#$97+#$93+#$84+#$85+#$91+'!';

  YakX  = 480;   YakY  = 172;
  BubX  = 476;   BubY  = 142;   BubW = 161;  BubH = 40;
  WheelX = 160;  WheelY = 115;
  WheelBuf = $7D00;  WheelOfs = $2404;
  WheelRows = 173;   WheelBytes = 28;
  GirlPage = $7D00;  GirlTmp = $BB80;
  HandPage = $7D00;  HandTmp = $BB80;  HandBase = $59B0;
  BoxPage = $7D00;   BoxBase = $4B00;
  BubBase = $2BFB;   BubPage = $A8FB;
  SaleBase = $35FB;  SalePage = $B2FB;
  TopBufP = $B25C;   TopMovP = $B0CC;   TopMovV = $33CC;
  TopPage = $7D00;
  WordX = 120;   WordY = 36;
  AlphaX = 0;    AlphaY = 332;
  GirlY = 25;
  BoxX  = 6;     BoxY  = 272;
  InpX  = 8;     InpY  = 300;

  sNotFound   = ' not found. Put POLE.LIB/FNT/OVL/PIC next to the EXE.';
  sPressKey   = 'Press any key...';

type
  PResource = ^TResource;
  TResource = array[0..32767] of Byte;
  TPicRec   = record
                Name : string[10];
                Score: Word;
              end;

var
  Res      : array[1..MaxRes] of PResource;
  ResSize  : array[1..MaxRes] of Word;
  Font6    : PResource;
  Font8    : PResource;
  Font14   : PResource;
  Money    : array[0..3] of Integer;
  Player   : Word;
  RoundNo  : Word;
  SoundIsOn: Word;
  Key      : Char;
  Counter  : Word;
  SectorNo : Word;
  MouseOn  : Word;
  Chosen   : Char;
  Shuffle  : array[1..6] of Word;
  Pic      : array[1..8] of TPicRec;
  CurWord  : string[MaxWordLen];
  Theme    : string[MaxWordLen];
  Answer   : string[MaxWordLen];
  Buf      : string;
  FName    : string;
  DataDir  : string;
  Opened   : array[0..MaxWordLen] of Word;
  OpenShown: array[0..MaxWordLen] of Word;
  FoundPos : array[0..MaxWordLen] of Word;
  Used     : array[0..31] of Word;
  UsedWord : array[0..2] of Word;
  CurPal   : array[0..15] of Byte;
  GraphOn  : Boolean;
  MouseX   : Word;
  MouseBtn : Word;
  PendKey  : Char;
  I, J, T  : Word;
  Regs     : Registers;
  FRec     : file;

function TimerCount: Word; assembler;
asm
        cli
        xor     al, al
        out     43h, al
        jmp     @@1
@@1:    in      al, 40h
        mov     ah, al
        jmp     @@2
@@2:    in      al, 40h
        xchg    al, ah
        sti
end;

procedure Delay(MS: Word);
var Need, Acc: LongInt; Prev, Cur: Word;
begin
  if MS = 0 then Exit;
  Need := LongInt(MS) * 1193;
  Acc := 0;
  Prev := TimerCount;
  while Acc < Need do begin
    Cur := TimerCount;
    Acc := Acc + LongInt(Word(Prev - Cur));
    Prev := Cur;
  end;
end;

procedure Sound(Hz: Word);
var D: Word; B: Byte;
begin
  if Hz < 19 then begin
    B := Port[$61];
    Port[$61] := B and $FC;
    Exit;
  end;
  D := Word(1193180 div LongInt(Hz));
  Port[$43] := $B6;
  Port[$42] := Lo(D);
  Port[$42] := Hi(D);
  B := Port[$61];
  Port[$61] := B or 3;
end;

procedure NoSound;
var B: Byte;
begin
  B := Port[$61];
  Port[$61] := B and $FC;
end;

function BiosPeek: Boolean; assembler;
asm
        mov     ah, 1
        int     16h
        mov     al, 0
        jz      @@1
        mov     al, 1
@@1:
end;

function KeyPressed: Boolean;
begin
  if PendKey <> #0 then KeyPressed := True else KeyPressed := BiosPeek;
end;

function BiosKey: Word; assembler;
asm
        mov     ah, 0
        int     16h
end;

function ReadKey: Char;
var W: Word;
begin
  if PendKey <> #0 then begin
    ReadKey := PendKey;
    PendKey := #0;
    Exit;
  end;
  W := BiosKey;
  if Lo(W) = 0 then PendKey := Chr(Hi(W));
  ReadKey := Chr(Lo(W));
end;

procedure SetVideoMode(M: Byte);
begin
  Regs.AH := 0;
  Regs.AL := M;
  Intr($10, Regs);
end;

procedure SetPal(R, C: Byte);
begin
  CurPal[R and 15] := C;
  Regs.AX := $1000;
  Regs.BL := R;
  Regs.BH := C;
  Intr($10, Regs);
end;

procedure BlankPal;
var N: Byte;
begin
  for N := 0 to 15 do begin
    Regs.AX := $1000;
    Regs.BL := N;
    Regs.BH := 0;
    Intr($10, Regs);
  end;
end;

procedure RestorePal;
var N: Byte;
begin
  for N := 0 to 15 do begin
    Regs.AX := $1000;
    Regs.BL := N;
    Regs.BH := CurPal[N];
    Intr($10, Regs);
  end;
end;

procedure GcNormal;
begin
  Port[$3CE] := 0;  Port[$3CF] := 0;
  Port[$3CE] := 1;  Port[$3CF] := 0;
  Port[$3CE] := 3;  Port[$3CF] := 0;
  Port[$3CE] := 5;  Port[$3CF] := 2;
  Port[$3CE] := 8;  Port[$3CF] := $FF;
end;

function GetPix(X, Y: Integer): Byte;
var Ofs: Word; P, C, Bit: Byte;
begin
  GetPix := 0;
  if (X < 0) or (X >= ScrW) or (Y < 0) or (Y >= ScrH) then Exit;
  Ofs := Word(Y) * BPL + (Word(X) shr 3);
  Bit := 7 - (X and 7);
  C := 0;
  Port[$3CE] := 5;  Port[$3CF] := 0;
  for P := 0 to 3 do begin
    Port[$3CE] := 4;  Port[$3CF] := P;
    if (Mem[VideoSeg:Ofs] and (1 shl Bit)) <> 0 then C := C or (1 shl P);
  end;
  GcNormal;
  GetPix := C;
end;

procedure PutPixFast(Base: Word; X, Y: Integer; Color: Byte);
var Ofs: Word; D: Byte;
begin
  if (X < 0) or (X >= ScrW) or (Y < 0) or (Y >= ScrH) then Exit;
  Ofs := Base + Word(Y) * BPL + (Word(X) shr 3);
  Port[$3CF] := $80 shr (X and 7);
  D := Mem[VideoSeg:Ofs];
  Mem[VideoSeg:Ofs] := Color;
end;

procedure PutPixAt(Base: Word; X, Y: Integer; Color: Byte);
begin
  Port[$3CE] := 8;
  PutPixFast(Base, X, Y, Color);
end;

procedure PutPix(X, Y: Integer; Color: Byte);
begin
  PutPixAt(0, X, Y, Color);
end;

procedure HLineAt(Base: Word; X, Y, Count: Integer; Color: Byte);
var Ofs: Word; B, N, Last: Integer; M, D: Byte;
begin
  if (Y < 0) or (Y >= ScrH) or (Count <= 0) then Exit;
  if X < 0 then begin
    Inc(Count, X);
    X := 0;
  end;
  if X >= ScrW then Exit;
  if X + Count > ScrW then Count := ScrW - X;
  if Count <= 0 then Exit;
  while Count > 0 do begin
    B := X and 7;
    N := 8 - B;
    if N > Count then N := Count;
    Last := B + N - 1;
    M := Byte(($FF shr B) and Byte($FF shl (7 - Last)));
    Ofs := Base + Word(Y) * BPL + (Word(X) shr 3);
    Port[$3CE] := 8;
    Port[$3CF] := M;
    D := Mem[VideoSeg:Ofs];
    Mem[VideoSeg:Ofs] := Color;
    Inc(X, N);
    Dec(Count, N);
  end;
  Port[$3CE] := 8;
  Port[$3CF] := $FF;
end;

procedure HLine(X, Y, Count: Integer; Color: Byte);
begin
  HLineAt(0, X, Y, Count, Color);
end;

procedure FillRect(X1, Y1, X2, Y2: Integer; Color: Byte);
var Y, T: Integer;
begin
  if X1 > X2 then begin T := X1; X1 := X2; X2 := T end;
  if Y1 > Y2 then begin T := Y1; Y1 := Y2; Y2 := T end;
  if X1 < 0 then X1 := 0;
  if Y1 < 0 then Y1 := 0;
  if X2 >= ScrW then X2 := ScrW - 1;
  if Y2 >= ScrH then Y2 := ScrH - 1;
  if (X1 > X2) or (Y1 > Y2) then Exit;
  GcNormal;
  for Y := Y1 to Y2 do HLine(X1, Y, X2 - X1 + 1, Color);
end;

procedure ClearScreen(Color: Byte);
begin
  FillRect(0, 0, ScrW - 1, ScrH - 1, Color);
end;

procedure Rect(X1, Y1, X2, Y2: Integer; Color: Byte);
begin
  FillRect(X1, Y1, X2, Y1, Color);
  FillRect(X1, Y2, X2, Y2, Color);
  FillRect(X1, Y1, X1, Y2, Color);
  FillRect(X2, Y1, X2, Y2, Color);
end;

procedure Line1(X1, Y1, X2, Y2: Integer; Color: Byte);
var DX, DY, SX, SY, Err, E2: Integer;
begin
  GcNormal;
  if Y1 = Y2 then begin
    if X1 > X2 then begin E2 := X1; X1 := X2; X2 := E2 end;
    HLine(X1, Y1, X2 - X1 + 1, Color);
    Exit;
  end;
  DX := Abs(X2 - X1);
  DY := -Abs(Y2 - Y1);
  if X1 < X2 then SX := 1 else SX := -1;
  if Y1 < Y2 then SY := 1 else SY := -1;
  Err := DX + DY;
  Port[$3CE] := 8;
  while True do begin
    PutPixFast(0, X1, Y1, Color);
    if (X1 = X2) and (Y1 = Y2) then Break;
    E2 := Err + Err;
    if E2 >= DY then begin
      Err := Err + DY;
      X1 := X1 + SX;
    end;
    if E2 <= DX then begin
      Err := Err + DX;
      Y1 := Y1 + SY;
    end;
  end;
end;

procedure Line(X1, Y1, X2, Y2: Integer; Color: Byte);
begin
  Line1(X1, Y1, X2, Y2, Color);
  if Abs(X2 - X1) >= Abs(Y2 - Y1) then begin
    Line1(X1, Y1 - 1, X2, Y2 - 1, Color);
    Line1(X1, Y1 + 1, X2, Y2 + 1, Color);
  end else begin
    Line1(X1 - 1, Y1, X2 - 1, Y2, Color);
    Line1(X1 + 1, Y1, X2 + 1, Y2, Color);
  end;
end;

procedure PutSpriteAt(N: Byte; Base: Word; X, Y: Integer; Transparent: Byte);
var
  P: PResource;
  Pos, LineEnd, W, H, R, Cnt, K: Word;
  Ctrl, Col: Byte;
  PX: Integer;
begin
  if (N < 1) or (N > MaxRes) then Exit;
  P := Res[N];
  if P = nil then Exit;
  W := P^[0] + P^[1] shl 8;
  H := P^[2] + P^[3] shl 8;
  Pos := 6;
  GcNormal;
  for R := 0 to H - 1 do begin
    if Pos + 1 >= ResSize[N] then Exit;
    LineEnd := Pos + 2 + (P^[Pos] + P^[Pos + 1] shl 8);
    if LineEnd > ResSize[N] then LineEnd := ResSize[N];
    Inc(Pos, 2);
    PX := X;
    while Pos < LineEnd do begin
      Ctrl := P^[Pos];
      Inc(Pos);
      if Ctrl >= $80 then begin
        Cnt := Ctrl - $80;
        if Pos >= LineEnd then Break;
        Col := P^[Pos];
        Inc(Pos);
        if Col <> Transparent then
          HLineAt(Base, PX, Y + R, Cnt, Col);
        Inc(PX, Cnt);
      end else begin
        for K := 1 to Ctrl do begin
          if Pos >= LineEnd then Break;
          Col := P^[Pos];
          Inc(Pos);
          if Col <> Transparent then PutPixAt(Base, PX, Y + R, Col);
          Inc(PX);
        end;
      end;
    end;
    Pos := LineEnd;
  end;
  Port[$3CE] := 8;
  Port[$3CF] := $FF;
end;

procedure Draw(N: Byte; X, Y: Integer; Transparent: Byte);
begin
  PutSpriteAt(N, 0, X, Y, Transparent);
end;

procedure OutTxtAt(Base: Word; S: string; X, Y: Integer;
  Color, LastRow, Advance: Word);
var
  N, R, Hgt: Word;
  Ofs: Word;
  Ch, BitL, BitR, D: Byte;
  F: PResource;
  YY: Integer;
begin
  if not GraphOn then Exit;
  case LastRow of
    Fnt6 : begin F := Font6;  Hgt := 6  end;
    Fnt8 : begin F := Font8;  Hgt := 8  end;
  else     begin F := Font14; Hgt := 14 end;
  end;
  if F = nil then Exit;
  GcNormal;
  for N := 1 to Length(S) do begin
    if (X > -8) and (X < ScrW) then begin
      BitL := X and 7;
      BitR := 8 - BitL;
      for R := 0 to Hgt - 1 do begin
        Ch := F^[Ord(S[N]) * Hgt + R];
        if Ch <> 0 then begin
          YY := Y + Integer(R);
          if (YY >= 0) and (YY < ScrH) then begin
            Ofs := Base + Word(YY) * BPL + (Word(X) shr 3);
            Port[$3CE] := 8;
            Port[$3CF] := Ch shr BitL;
            D := Mem[VideoSeg:Ofs];
            Mem[VideoSeg:Ofs] := Color;
            if (BitR < 8) and ((Word(X) shr 3) + 1 < BPL) then begin
              Port[$3CE] := 8;
              Port[$3CF] := Byte(Ch shl BitR);
              D := Mem[VideoSeg:Ofs + 1];
              Mem[VideoSeg:Ofs + 1] := Color;
            end;
          end;
        end;
      end;
    end;
    Inc(X, Advance);
  end;
  Port[$3CE] := 8;
  Port[$3CF] := $FF;
end;

procedure OutTxt(S: string; X, Y: Integer; Color, LastRow, Advance: Word);
begin
  OutTxtAt(0, S, X, Y, Color, LastRow, Advance);
end;

procedure BufFill(Offset, Rows, Bytes: Word; Color: Byte);
var R, B, O: Word; D: Byte;
begin
  if Bytes = 0 then Exit;
  GcNormal;
  Port[$3CE] := 8;
  Port[$3CF] := $FF;
  for R := 0 to Rows do begin
    O := Offset + R * BPL;
    for B := 1 to Bytes do begin
      D := Mem[VideoSeg:O];
      Mem[VideoSeg:O] := Color;
      Inc(O);
    end;
  end;
end;

procedure BufMove(Src, Dst, Rows, Bytes: Word);
var R: Word;
begin
  if Bytes = 0 then Exit;
  Port[$3CE] := 0;  Port[$3CF] := 0;
  Port[$3CE] := 1;  Port[$3CF] := 0;
  Port[$3CE] := 3;  Port[$3CF] := 0;
  Port[$3CE] := 8;  Port[$3CF] := $FF;
  Port[$3CE] := 5;  Port[$3CF] := 1;
  for R := 0 to Rows do
    Move(Mem[VideoSeg:Src + R * BPL], Mem[VideoSeg:Dst + R * BPL], Bytes);
  GcNormal;
end;

function FileHere(N: string): Boolean;
var F: file; R: Integer;
begin
  Assign(F, N);
  Reset(F, 1);
  R := IOResult;
  if R = 0 then Close(F);
  FileHere := R = 0;
end;

function AddSlash(P: string): string;
begin
  if P = '' then AddSlash := ''
  else if (P[Length(P)] = '\') or (P[Length(P)] = ':') then AddSlash := P
  else AddSlash := P + '\';
end;

function ExeDir: string;
var P: string; N: Integer;
begin
  P := ParamStr(0);
  N := Length(P);
  while (N > 0) and (P[N] <> '\') and (P[N] <> ':') do Dec(N);
  ExeDir := Copy(P, 1, N);
end;

procedure Bye;
begin
  NoSound;
  if GraphOn then SetVideoMode(3);
  GraphOn := False;
  Halt(0);
end;

procedure Fatal(S: string);
var C: Char;
begin
  NoSound;
  if GraphOn then SetVideoMode(3);
  GraphOn := False;
  WriteLn;
  WriteLn(S);
  WriteLn(sPressKey);
  C := ReadKey;
  Halt(1);
end;

procedure TryDir(P: string);
var D: string;
begin
  if DataDir <> #255 then Exit;
  D := AddSlash(P);
  if FileHere(D + 'POLE.LIB') and FileHere(D + 'POLE.FNT')
     and FileHere(D + 'POLE.OVL') then DataDir := D;
end;

procedure FindDataDir;
begin
  DataDir := #255;
  TryDir('');
  TryDir(ExeDir);
  TryDir(GetEnv('POLE'));
  TryDir('..');
  TryDir('C:\POLE');
  if DataDir = #255 then begin
    DataDir := '';
    Fatal('POLE.LIB' + sNotFound);
  end;
end;

function GameFile(N: string): string;
begin
  GameFile := DataDir + N;
end;

procedure LoadResources;
var
  F: file;
  Header: array[0..127] of Byte;
  N, K, Got: Word;
begin
  FName := GameFile('POLE.LIB');
  Assign(F, FName);
  Reset(F, 128);
  BlockRead(F, Header, 1, Got);
  if Got <> 1 then begin
    Close(F);
    Fatal('POLE.LIB: bad header');
  end;
  N := Header[0];
  if N > MaxRes then N := MaxRes;
  for K := 1 to N do begin
    ResSize[K] := Header[K] shl 7;
    GetMem(Res[K], ResSize[K]);
    if Res[K] = nil then begin
      Close(F);
      Fatal('Not enough DOS memory for POLE.LIB');
    end;
    BlockRead(F, Res[K]^, Header[K], Got);
  end;
  Close(F);

  FName := GameFile('POLE.FNT');
  Assign(F, FName);
  Reset(F, 128);
  GetMem(Font6, $600);
  BlockRead(F, Font6^, 12, Got);
  GetMem(Font8, $800);
  BlockRead(F, Font8^, 16, Got);
  GetMem(Font14, $E00);
  BlockRead(F, Font14^, 28, Got);
  Close(F);
  if (Font6 = nil) or (Font8 = nil) or (Font14 = nil) then
    Fatal('Not enough DOS memory for POLE.FNT');

  FName := GameFile('POLE.PIC');
  if FileHere(FName) then begin
    Assign(F, FName);
    Reset(F, PicRecSize);
    for K := 1 to 8 do BlockRead(F, Pic[K], 1, Got);
    Close(F);
  end else
    for K := 1 to 8 do begin
      if Odd(K) then Pic[K].Name := #$8B#$88#$91#$92#$9C#$85#$82
                else Pic[K].Name := #$9F#$8A#$93#$81#$8E#$82#$88#$97;
      Pic[K].Score := 135 - K * 15;
    end;
end;

procedure SavePic;
var K: Word;
begin
  Assign(FRec, GameFile('POLE.PIC'));
  Rewrite(FRec, PicRecSize);
  if IOResult = 0 then begin
    for K := 1 to 8 do BlockWrite(FRec, Pic[K], 1);
    Close(FRec);
  end;
end;

procedure InitGraphics;
begin
  SetVideoMode($10);
  GraphOn := True;
  CurPal[0] := $00; CurPal[1] := $01; CurPal[2] := $02; CurPal[3] := $03;
  CurPal[4] := $14; CurPal[5] := $27; CurPal[6] := $2E; CurPal[7] := $07;
  CurPal[8] := $38; CurPal[9] := $39; CurPal[10] := $3A; CurPal[11] := $3B;
  CurPal[12] := $3C; CurPal[13] := $3D; CurPal[14] := $3E; CurPal[15] := $3F;
  RestorePal;
  GcNormal;
  ClearScreen(0);
  BufFill(WheelBuf + WheelOfs, WheelRows, WheelBytes, 7);
  MouseOn := 0;
  Regs.AX := 0;
  Regs.BX := 0;
  Intr($33, Regs);
  if Regs.AX = $FFFF then MouseOn := 1;
  if MouseOn > 0 then begin
    Regs.AX := 7;
    Regs.CX := 0;
    Regs.DX := 639;
    Intr($33, Regs);
    Regs.AX := 8;
    Regs.CX := 0;
    Regs.DX := 349;
    Intr($33, Regs);
  end;
end;

procedure MouseShow;
begin
  if MouseOn > 0 then begin
    Regs.AX := 1;
    Intr($33, Regs);
  end;
end;

procedure MouseHide;
begin
  if MouseOn > 0 then begin
    Regs.AX := 2;
    Intr($33, Regs);
  end;
end;

procedure MouseTo(X, Y: Word);
begin
  if MouseOn > 0 then begin
    Regs.AX := 4;
    Regs.CX := X;
    Regs.DX := Y;
    Intr($33, Regs);
  end;
end;

procedure MouseCenter;
begin
  if MouseOn > 0 then begin
    Regs.AX := 4;
    Regs.CX := 320;
    Regs.DX := 100;
    Intr($33, Regs);
  end;
end;

procedure FlushKeys;
begin
  PendKey := #0;
  while BiosPeek do Key := Chr(Lo(BiosKey));
  if MouseOn > 0 then
    repeat
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
    until MouseBtn = 0;
end;

procedure BossKey;
begin
  BlankPal;
  FlushKeys;
  repeat
    MouseBtn := 0;
    if MouseOn > 0 then begin
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
    end;
    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #27 then Bye;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
  until (Key = ' ') or (MouseBtn = 1);
  Key := #7;
  RestorePal;
end;

procedure Poll;
begin
  Key := #7;
  if KeyPressed then Key := ReadKey;
  if Key = #27 then Bye;
  if Key = #19 then SoundIsOn := 1 - SoundIsOn;
  if Key = #9 then BossKey;
end;

procedure Wait(Ticks: Word);
begin
  FlushKeys;
  repeat
    if Ticks > 0 then Dec(Ticks);
    Delay(50);
    MouseBtn := 0;
    if MouseOn > 0 then begin
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
    end;
    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #27 then Bye;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
  until (Key = ' ') or (MouseBtn = 1) or (Ticks = 1);
end;

procedure Beep(Hz, MS: Word);
begin
  if SoundIsOn > 0 then Sound(Hz);
  Delay(MS);
  NoSound;
end;

function RusKey(C: Char): Char;
var K: Byte; N: Word;
begin
  K := Ord(UpCase(C));
  RusKey := ' ';
  if K < $80 then
    for N := 1 to Length(KbdLat) do
      if KbdLat[N] = Chr(K) then RusKey := KbdRus[N];
  if (K >= $80) and (K < $A0) then RusKey := Chr(K);
  if (K >= $A0) and (K < $B0) then RusKey := Chr(K - $20);
  if (K >= $E0) and (K < $F0) then RusKey := Chr(K - $50);
end;

procedure Noise;
var N: Word;
begin
  for N := 1 to 6 do begin
    if SoundIsOn > 0 then Sound(Random(100) + 20);
    Delay(6 - N);
    NoSound;
    Delay(1);
  end;
end;

procedure DrawYak;
begin
  Draw(ResYakub, 480, 172, 7);
  Draw(ResYakClosed, 511, 173, NoTrans);
  Draw(ResYakEyes, 532, 209, NoTrans);
end;

procedure Talk;
begin
  Noise;
  Draw(ResYakEyes, 532, 201, NoTrans);
  Delay(100);
  Draw(ResYakEyesCl, 532, 201, NoTrans);
  Delay(100);
end;

procedure YakAnimate;
var N: Word;
begin
  Noise;
  Draw(ResYakEyesCl, 532, 209, NoTrans);
  Delay(200);
  Draw(ResYakEyes, 532, 209, NoTrans);
  Delay(150);
  Draw(ResYakEyesCl, 532, 209, NoTrans);
  Delay(150);
  Draw(ResYakOpen, 511, 173, NoTrans);
  Draw(ResYakEyesCl, 532, 201, NoTrans);
  for N := 1 to 3 do begin
    Noise;
    Draw(ResYakClosed, 511, 173, NoTrans);
    Draw(ResYakEyes, 532, 209, NoTrans);
    Delay(Random(2) * 200 + 100);
    Draw(ResYakOpen, 511, 173, NoTrans);
    Delay(Random(2) * 50 + 100);
  end;
end;

procedure Say(N: Word);
var L1, L2, S: string;
begin
  YakAnimate;
  BufMove(BubBase, BubPage, 190, 21);
  Draw(ResBubble, BubX, BubY, 1);
  L1 := '';
  L2 := '';
  S := sThird;
  if Player = 1 then S := sFirst;
  if Player = 2 then S := sSecond;
  case N of
    1: begin L1 := S + sPlayerBang;  L2 := sSpin end;
    2: begin
         if (Money[0] > 0) and (Money[0] < 100) then begin
           Str(Money[0], Buf);
           L1 := sYouHave + Buf + sPoints;
           L2 := sNameLetter;
         end;
         if Money[0] = 0 then begin L1 := sZero; L2 := sPass end;
         if Money[0] < 0 then begin L1 := sBankrupt; L2 := sPass end;
         if (Money[0] div 100) = 2 then begin
           L1 := sDouble;
           L2 := sNameLetter;
         end;
         if Money[0] = 100 then begin L1 := sPlus; L2 := sOpenAny end;
         if Money[0] = 300 then begin L1 := sPrizeSect; L2 := sPrizeOrPl end;
       end;
    3: if Opened[0] > 0 then begin L1 := sBravo2; L2 := sHasLetter end
       else begin L1 := sNoLetter; L2 := sPassShort end;
    4: begin L1 := S + sPlayer;  L2 := sWonRound end;
    5: begin L1 := s3Letters;    L2 := sBoxesIn end;
    6: begin L1 := sWhereMoney;  L2 := sChoose end;
    7: begin L1 := sBravo3;      L2 := sYouGuessed end;
    8: begin L1 := sAlasThis;    L2 := sBoxEmpty end;
    9: begin L1 := sStartGame;   L2 := sWordIs end;
   10: begin L1 := sTheme;       L2 := Theme end;
   11: begin L1 := sRight1;      L2 := sRight2 end;
   12: begin L1 := sWrong1;      L2 := sWrong2 end;
   13: begin L1 := sCongrat1;    L2 := sCongrat2 end;
   14: begin L1 := sSorry1;      L2 := sSorry2 end;
   15: begin L1 := sIfSo1;       L2 := sIfSo2 end;
   16: begin L1 := sAdv1;        L2 := sAdv2 end;
   17: begin L1 := sPrizeOr;     L2 := Buf + sRoubles end;
   18: begin L1 := sTake1;       L2 := sTake2 end;
   19: begin L1 := sPresent1;    L2 := sPresent2 end;
   20: begin L1 := sTake1;       L2 := sYourPrize end;
  end;
  OutTxt(L1, 554 - Length(L1) * 4, 145, 0, Fnt14, 8);
  OutTxt(L2, 554 - Length(L2) * 4, 158, 0, Fnt14, 8);
  Talk;
  Talk;
end;

procedure HideBubble;
begin
  BufMove(BubPage, BubBase, 190, 21);
  Noise;
  Draw(ResYakClosed, 511, 173, NoTrans);
  Delay(30);
  Draw(ResYakEyes, 532, 209, NoTrans);
end;

procedure SayWait(N: Word);
begin
  Say(N);
  Wait(0);
  HideBubble;
end;

procedure DrawScore(P: Word);
var N: Word; DX, DY: Integer;
begin
  BufFill(Word(ScoreY[P] - 1) * BPL + (Word(ScoreX[P] - 4) div 8), 29, 13, 7);
  if Money[P] > 0 then begin
    for N := 1 to Money[P] do begin
      Sound(SoundIsOn * (Random(10) + 50));
      Draw(ResMoney, ScoreX[P] - 4 + Random(12),
           ScoreY[P] - 1 + Random(7), 1);
      NoSound;
    end;
    Draw(ResMoney, ScoreX[P], ScoreY[P], 1);
    Str(Money[P], Buf);
    for DX := -1 to 1 do
      for DY := -1 to 1 do
        OutTxt(Buf, ScoreX[P] + 34 - Length(Buf) * 4 + DX,
               ScoreY[P] + 4 + DY, 0, Fnt14, 8);
    OutTxt(Buf, ScoreX[P] + 34 - Length(Buf) * 4, ScoreY[P] + 4, 15, Fnt14, 8);
  end else
    Draw(ResSnickers, ScoreX[P] + 4, ScoreY[P] + 10, 2);
end;

function CellX(N: Word): Integer;
begin
  CellX := (N + 5) * 16 + 121;
end;

procedure DrawBoardCells;
var N: Word;
begin
  for N := 1 to Length(CurWord) do
    FillRect(CellX(N), 36, CellX(N) + 13, 54, 8);
end;

procedure DrawOpenLetters;
var N: Word;
begin
  for N := 1 to Length(CurWord) do
    if OpenShown[N] > 0 then
      OutTxt(CurWord[N], (N + 5) * 16 + 125, 38, 15, Fnt14, 8);
end;

procedure ClearBoard;
var N: Word;
begin
  for N := 0 to MaxWordLen do begin
    Opened[N] := 0;
    OpenShown[N] := 0;
  end;
  DrawBoardCells;
end;

procedure DrawCell(N, Hi: Word);
begin
  if Used[N] <> 0 then begin
    FillRect(N * 20, 332, N * 20 + 19, 349, 0);
    Exit;
  end;
  Draw(ResCell0, N * 20, 332, NoTrans);
  OutTxt(Alphabet[N + 1], N * 20 + 4, 334, 0, Fnt14, 8);
end;

procedure DrawAlphabet;
var N: Word;
begin
  for N := 0 to 31 do DrawCell(N, 0);
end;

procedure DrawWheel;
var K, X, Y: Integer;
begin
  Draw(ResWheel0 + (Counter + 3) mod 4, 160, 115, 3);
  for K := 0 to 15 do begin
    X := Trunc(Cos((Counter + K * 2) * Pi / 16) * 84) + 261;
    Y := Trunc(Sin((Counter + K * 2) * Pi / 16) * 63) + 196;
    Draw(SectorType[K] + 1, X, Y, 7);
  end;
  Draw(ResArrow, 267, 152, 7);
end;

procedure SpinWheel;
var Speed, Steps, Tick, Moved, K: Word;
    Bse, X, Y: Integer;
begin
  Speed := 0;
  Steps := 0;
  Tick := 0;
  Bse := WheelOfs;

  repeat
    Moved := 0;
    if Speed > 0 then begin
      if Speed = 4 then begin
        Inc(Counter);
        Moved := 1;
      end else
      if Speed = 3 then begin
        if Tick mod 2 = 0 then begin
          Moved := 1;
          Inc(Counter);
        end;
      end else
      if Speed = 2 then begin
        if Tick mod 3 = 0 then begin
          Moved := 1;
          Inc(Counter);
        end;
      end else
      if Speed = 1 then
        if Tick mod 4 = 0 then begin
          Moved := 1;
          Inc(Counter);
        end;
    end;

    if (Speed = 0) and (Steps > 0) then
      if Counter mod 2 = 1 then Inc(Counter);

    if Counter >= 32 then Dec(Counter, 32);

    BufFill(WheelBuf + Bse, 172, 28, 7);
    PutSpriteAt(ResWheel0 + (Counter + 3) mod 4, WheelBuf, 160, 115, 3);

    if Moved > 0 then
      Sound(SoundIsOn * ((Steps - Tick) * 10 + Speed * 100 + 55));

    for K := 0 to 15 do begin
      X := Trunc(Cos((Counter + K * 2) * Pi / 16) * 84) + 261;
      Y := Trunc(Sin((Counter + K * 2) * Pi / 16) * 63) + 196;
      PutSpriteAt(SectorType[K] + 1, WheelBuf, X, Y, 7);
      NoSound;
    end;
    NoSound;

    if Speed > 0 then Inc(Tick);
    if Tick > Steps then begin
      Steps := Random(10) + 5;
      if Speed > 0 then Dec(Speed);
      Tick := 0;
    end;

    PutSpriteAt(ResArrow, WheelBuf, 267, 152, 7);
    BufMove(WheelBuf + Bse, Bse, 172, 28);

    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
    if MouseOn > 0 then begin
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
    end else
      MouseBtn := 0;

    if (Speed = 0) and (Steps = 0) then begin
      if Player < 3 then Wait(50);
      HideBubble;
      Speed := 4;
      Steps := Random(20) + 10;
    end;

    if Key = #27 then Bye;
  until (Speed = 0) and (Steps > 0) and (Counter mod 2 = 0);

  SectorNo := (28 - Counter div 2) mod 16;
  Money[0] := SectorValueTab[SectorType[SectorNo] - 4];

  for K := 1 to 30 do begin
    Sound(SoundIsOn * (1000 - K * 30));
    Delay(K div 5);
    Delay(K div 3);
    NoSound;
  end;
end;

procedure GirlOpens;
var
  Num, Ph, Sprite, N, Pause: Word;
  X, Y, Step, StopX: Integer;
  Cur, Prev, Buf2, TextOfs, TextX: Word;
begin
  NoSound;
  Num := 1;
  StopX := (FoundPos[Num] + 5) * 16 + 110;
  BufMove(0, GirlPage, 120, BPL);
  Buf2 := $BB80;
  X := 40;
  Y := 25;
  Pause := 0;
  Ph := 0;
  TextOfs := 0;
  TextX := 0;
  Cur := Y * BPL + (X shr 3);
  Prev := Cur;

  for Step := 20 to 100 do begin
    Sound(SoundIsOn * Step);
    Delay(1);
    NoSound;
    Delay((100 - Step) div 5);
  end;
  Step := 10;

  repeat
    Cur := Y * BPL + (X shr 3);
    Inc(Ph);

    if Pause = 10 then begin
      BufMove(TextOfs, TextOfs + $640, 19, 2);
      Buf := Chosen;
      OutTxtAt(GirlPage, Buf, TextX, 38, 0, Fnt14, 8);
    end;

    BufMove(GirlPage + Cur, Buf2, 90, 6);

    if Pause > 0 then Sprite := 24
    else
      case Ph mod 4 of
        0: begin Sprite := 25; Step := 10 end;
        1: begin Sprite := 27; Step := 0  end;
        2: begin Sprite := 26; Step := 12 end;
      else begin Sprite := 27; Step := 3  end;
      end;

    if Pause > 0 then Inc(Pause);
    if Pause > 20 then Pause := 0;

    PutSpriteAt(Sprite, GirlPage, X, Y, 2);
    BufMove(GirlPage + Cur, Cur, 90, 6);
    BufMove(GirlPage + Prev, Prev, 90, 6);
    Prev := Cur;

    if Pause = 0 then Sound(SoundIsOn * (Random(100) + 1000));

    BufMove(Buf2, GirlPage + Prev, 90, 6);
    NoSound;

    if Pause = 0 then Inc(X, Step);

    if X > StopX then begin
      TextOfs := FoundPos[Num] * 2 + $81B0 + 25;
      TextX := (FoundPos[Num] + 5) * 16 + 125;
      Inc(Num);
      if Num > Opened[0] then StopX := 1000
      else StopX := (FoundPos[Num] + 5) * 16 + 110;
      Pause := 1;
    end;

    Delay(50);
    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
    if Key = #27 then Bye;
  until X > 582;

  BufMove(GirlPage + Cur, Cur, 91, 8);

  Step := 100;
  repeat
    Sound(SoundIsOn * Step);
    Delay((100 - Step) div 10);
    NoSound;
    Delay(1);
    Dec(Step);
  until Step = 20;

  if Money[0] < 100 then
    Inc(Money[Player], Money[0] * Integer(Opened[0]))
  else
    if (Money[0] div 100) = 2 then
      Money[Player] := Money[Player] * (Money[0] mod 100);
  DrawScore(Player);
end;

procedure CountMatches;
var K: Word;
begin
  Opened[0] := 0;
  for K := 1 to Length(CurWord) do
    if (CurWord[K] = Chosen) and (Opened[K] = 0) then begin
      Inc(Opened[0]);
      FoundPos[Opened[0]] := K;
      Opened[K] := 1;
    end;
end;

procedure MarkLetter(Sel: Word);
var K, N, X, Y: Word;
begin
  X := Sel * 20;
  Y := $14C;
  for K := 0 to 3 do begin
    if K < 3 then
      Draw(ResCell0 + 1 + K, X, Y, NoTrans)
    else
      FillRect(X, Y, X + $13, Y + $12, 7);
    for N := 1 to 10 do begin
      Sound(SoundIsOn * (K * 100 + N * 10 + 50));
      Delay(1);
      NoSound;
      Delay(K * 4 + N div 5);
    end;
  end;
end;

procedure ChooseLetter;
var Sel, Done, K, Cnt, Cheat, Prev, Cur: Word;
begin
  Sel := 0;
  if Player = 3 then begin
    BufMove(HandBase, HandPage + HandBase, 60, BPL);
    MouseCenter;
    Done := 0;
    FlushKeys;
    Cur := 314 * BPL + (Sel * 20) div 8;
    Prev := Cur;
    repeat
      Cur := 314 * BPL + (Sel * 20) div 8;
      BufMove(HandPage + Cur, HandTmp, 26, 3);
      PutSpriteAt(ResHand, HandPage, Sel * 20, 314, 2);
      BufMove(HandPage + Prev, Prev, 26, 3);
      BufMove(HandPage + Cur, Cur, 26, 3);
      BufMove(HandTmp, HandPage + Cur, 26, 3);
      Prev := Cur;

      Key := #7;
      if KeyPressed then Key := ReadKey;
      if Key = #19 then SoundIsOn := 1 - SoundIsOn;
      if Key = #9 then BossKey;
      if Key = #0 then begin
        Key := ReadKey;
        if Key = #$4B then Dec(Sel);
        if Key = #$4D then Inc(Sel);
        Key := #7;
      end;

      MouseBtn := 0;
      if MouseOn > 0 then begin
        Regs.AX := 3;
        Intr($33, Regs);
        MouseBtn := Regs.BX;
        MouseX := Regs.CX;
        if MouseX < $131 then begin
          Dec(Sel);
          MouseCenter;
        end;
        if MouseX > $14F then begin
          Inc(Sel);
          MouseCenter;
        end;
      end;

      if Integer(Sel) < 0 then Sel := 0;
      if Sel > 31 then Sel := 31;

      if Key = #27 then Bye;
      if (Key = ' ') or (MouseBtn = 1) then begin
        if Used[Sel] = 0 then Done := 1
        else begin
          if SoundIsOn > 0 then Sound(1000);
          Delay(50);
          NoSound;
        end;
      end;
      Delay(30);
    until Done > 0;
    if SoundIsOn > 0 then Sound(100);
    BufMove(HandPage + Prev, Prev, 26, 3);
    NoSound;
  end else begin
    Cnt := 0;
    for K := 1 to Length(CurWord) do if Opened[K] = 0 then Inc(Cnt);
    if (Cnt * 2 > Length(CurWord)) and (Cnt > 1) then Cheat := 0
    else if Random(RoundNo + 2) = 0 then Cheat := 0 else Cheat := 1;
    if Cheat = 1 then begin
      repeat
        K := Random(Length(CurWord)) + 1;
      until Opened[K] = 0;
      Chosen := CurWord[K];
      Sel := 0;
      while (Sel < 31) and (Alphabet[Sel + 1] <> Chosen) do Inc(Sel);
      if Used[Sel] <> 0 then Cheat := 0;
    end;
    if Cheat = 0 then begin
      Cnt := 0;
      for K := 0 to 31 do if Used[K] = 0 then Inc(Cnt);
      if Cnt = 0 then Exit;
      repeat
        Sel := Random(32);
      until Used[Sel] = 0;
    end;
    Chosen := Alphabet[Sel + 1];
    Cur := (NameX[Player] div 8) + $2260;
    BufMove(Cur, HandPage + Cur, 40, 20);
    Draw(ResOppBub, NameX[Player], 110, 2);
    Buf := sLetter + Chosen + '!';
    OutTxt(Buf, NameX[Player] + 6, 118, 0, Fnt14, 8);
    Wait(40);
    BufMove(HandPage + Cur, Cur, 40, 20);
  end;

  Used[Sel] := 1;
  Chosen := Alphabet[Sel + 1];
  MarkLetter(Sel);
  CountMatches;
  SayWait(3);
end;

procedure OpenAnyLetter;
var Pos, Done, K, Cur, Prev: Word;
begin
  Pos := 1;
  if Player = 3 then begin
    BufMove($320, HandPage + $320, 60, BPL);
    MouseCenter;
    Pos := 1;
    Done := 0;
    FlushKeys;
    Cur := 12 * BPL + (Pos * 16 + 200) div 8;
    Prev := Cur;
    repeat
      Cur := 12 * BPL + (Pos * 16 + 200) div 8;
      BufMove(HandPage + Cur, HandTmp, 26, 3);
      PutSpriteAt(ResHand, HandPage, Pos * 16 + 200, 12, 2);
      BufMove(HandPage + Prev, Prev, 26, 3);
      BufMove(HandPage + Cur, Cur, 26, 3);
      BufMove(HandTmp, HandPage + Cur, 26, 3);
      Prev := Cur;

      Key := #7;
      if KeyPressed then Key := ReadKey;
      if Key = #19 then SoundIsOn := 1 - SoundIsOn;
      if Key = #9 then BossKey;
      if Key = #0 then begin
        Key := ReadKey;
        if Key = #$4B then Dec(Pos);
        if Key = #$4D then Inc(Pos);
        Key := #7;
      end;

      MouseBtn := 0;
      if MouseOn > 0 then begin
        Regs.AX := 3;
        Intr($33, Regs);
        MouseBtn := Regs.BX;
        MouseX := Regs.CX;
        if MouseX < $131 then begin
          Dec(Pos);
          MouseCenter;
        end;
        if MouseX > $14F then begin
          Inc(Pos);
          MouseCenter;
        end;
      end;

      if Integer(Pos) < 1 then Pos := 1;
      if Pos > Length(CurWord) then Pos := Length(CurWord);

      if Key = #27 then Bye;
      if (Key = ' ') or (MouseBtn = 1) then begin
        if Opened[Pos] = 0 then Done := 1
        else begin
          if SoundIsOn > 0 then Sound(1000);
          Delay(50);
          NoSound;
        end;
      end;
      Delay(30);
    until Done > 0;
    if SoundIsOn > 0 then Sound(100);
    BufMove(HandPage + Prev, Prev, 26, 3);
    NoSound;
  end else begin
    repeat
      Pos := Random(Length(CurWord)) + 1;
    until Opened[Pos] = 0;
    Cur := (NameX[Player] div 8) + $2260;
    BufMove(Cur, HandPage + Cur, 40, 20);
    Draw(ResOppBub, NameX[Player], 110, 2);
    Str(Pos, Buf);
    Buf := Buf + sNthLetter;
    OutTxt(Buf, NameX[Player] + 6, 118, 0, Fnt14, 8);
    Wait(40);
    BufMove(HandPage + Cur, Cur, 40, 20);
  end;
  Chosen := CurWord[Pos];
  for K := 0 to 31 do
    if Alphabet[K + 1] = Chosen then begin
      Used[K] := 1;
      MarkLetter(K);
    end;
  CountMatches;
  DrawAlphabet;
  Say(3);
  Wait(40);
  HideBubble;
end;

function WrongAnswer: Boolean;
var Pos, Blink, Bad, K, L: Word; Cur: Word;
begin
  L := Length(CurWord);
  for K := 0 to L - 1 do
    Rect(K * 16 + 4, 300, K * 16 + 20, 320, 0);

  Pos := 0;
  Answer := '';
  Cur := $5EB1;
  Blink := 0;

  repeat
    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
    if Key = #27 then Bye;

    if (Key = #8) and (Pos > 0) then begin
      Delete(Answer, Pos, 1);
      BufFill(Pos * 2 + Cur, 13, 1, 7);
      Dec(Pos);
      BufFill(Pos * 2 + Cur, 13, 1, 7);
    end;

    if Key > ' ' then Key := RusKey(Key);

    if (Key > ' ') and (L > Pos) then begin
      BufFill(Pos * 2 + Cur, 13, 1, 7);
      Buf := Key;
      OutTxt(Buf, Pos * 16 + 8, 303, 0, Fnt14, 8);
      Answer := Answer + Key;
      Inc(Pos);
    end;

    Delay(25);
    Inc(Blink);
    if Blink > 39 then Blink := 0;
    if Pos < L then
      BufFill(Pos * 2 + Cur + $320, 2, 1, (Blink div 20) * 7);
  until Key = #13;

  BufFill($5DC0, 20, L * 2 + 3, 7);

  Bad := 0;
  if Length(Answer) <> L then Bad := 1
  else
    for K := 1 to L do
      if Answer[K] <> CurWord[K] then Bad := 1;
  WrongAnswer := Bad > 0;
end;

procedure NewWord;
var F: file; N, Idx, Code: Integer; K, Got: Word;
begin
  Assign(F, GameFile('POLE.OVL'));
  Reset(F, OvlRecSize);
  if IOResult <> 0 then Fatal('POLE.OVL' + sNotFound);
  BlockRead(F, Theme, 1, Got);
  Val(Theme, N, Code);
  if (Code <> 0) or (N < 1) then N := 1;
  repeat
    Idx := Random(N) + 1;
  until (Idx <> UsedWord[0]) and (Idx <> UsedWord[1]) and (Idx <> UsedWord[2]);
  UsedWord[RoundNo] := Idx;
  Seek(F, Idx * 2 - 1);
  BlockRead(F, CurWord, 1, Got);
  BlockRead(F, Theme, 1, Got);
  Close(F);
  if Length(CurWord) > MaxWordLen then CurWord[0] := Chr(MaxWordLen);
  if Length(Theme) > MaxWordLen then Theme[0] := Chr(MaxWordLen);
  for K := 1 to Length(CurWord) do CurWord[K] := Chr(Ord(CurWord[K]) - $20);
  for K := 1 to Length(Theme) do Theme[K] := Chr(Ord(Theme[K]) - $20);
  if Length(CurWord) = 0 then CurWord := #$91#$8B#$8E#$82#$8E;
end;

function SelectYesNo: Word;
var Choice, Done: Word;
begin
  MouseCenter;
  Choice := 1;
  Done := 0;
  FlushKeys;
  repeat
    BufFill(BoxPage + BoxBase, 26, 20, 7);
    PutSpriteAt(ResHand, BoxPage, Choice * 60 + 30, 240, 2);
    BufMove(BoxPage + BoxBase, BoxBase, 26, 20);

    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #9 then BossKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #0 then begin
      Key := ReadKey;
      if (Key = #$4B) or (Key = #$4D) then Choice := 1 - Choice;
      Key := #7;
    end;

    MouseBtn := 0;
    if MouseOn > 0 then begin
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
      MouseX := Regs.CX;
      if (MouseX < $12C) or (MouseX > $154) then begin
        Choice := 1 - Choice;
        MouseCenter;
      end;
    end;

    if Key = #27 then Bye;
    if (Key = ' ') or (MouseBtn = 1) then Done := 1;
    Delay(30);
  until Done > 0;
  BufFill(BoxBase, 26, 20, 7);
  SelectYesNo := Choice;
end;

function SelectBox: Word;
var Choice, Done: Word;
begin
  MouseCenter;
  Choice := 1;
  Done := 0;
  FlushKeys;
  repeat
    BufFill(BoxPage + BoxBase, 26, 20, 7);
    PutSpriteAt(ResHand, BoxPage, Choice * 60 + 18, 240, 2);
    BufMove(BoxPage + BoxBase, BoxBase, 26, 20);

    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
    if Key = #0 then begin
      Key := ReadKey;
      if (Key = #$4B) or (Key = #$4D) then Choice := 1 - Choice;
      Key := #7;
    end;

    MouseBtn := 0;
    if MouseOn > 0 then begin
      Regs.AX := 3;
      Intr($33, Regs);
      MouseBtn := Regs.BX;
      MouseX := Regs.CX;
      if (MouseX < $12C) or (MouseX > $154) then begin
        Choice := 1 - Choice;
        MouseCenter;
      end;
    end;

    if Key = #27 then Bye;
    if (Key = ' ') or (MouseBtn = 1) then Done := 1;
    Delay(30);
  until Done > 0;
  BufFill(BoxBase, 26, 20, 7);
  SelectBox := Choice;
end;

procedure MoneyBoxes;
var Choice, Where, Steps, N, X1, X2: Word;
begin
  BufFill(BoxPage, BPL, 20, 7);
  PutSpriteAt(ResBoxClosed, BoxPage, 6, $110 - 5, 7);
  PutSpriteAt(ResBoxClosed, BoxPage, $40, $118 - 5, 7);
  PutSpriteAt(ResBoxMoney, BoxPage, $42, $118 - $18, 7);
  BufMove(BoxPage + BoxBase, BoxBase, 80, 20);
  Wait(0);

  BufFill(BoxPage, BPL, 20, 7);
  Sound(SoundIsOn * 1000);
  PutSpriteAt(ResBoxClosed, BoxPage, 6, $110, 7);
  NoSound;
  Sound(SoundIsOn * 100);
  PutSpriteAt(ResBoxClosed, BoxPage, $40, $118, 7);
  BufMove(BoxPage + BoxBase, BoxBase, 80, 20);
  Wait(40);

  Steps := Random(20) + 10;
  Where := 1;
  for N := 1 to Steps do begin
    BufFill(BoxPage, BPL, 20, 7);
    if Odd(N) then begin
      PutSpriteAt(ResBoxClosed, BoxPage, 40, 262, 7);
      PutSpriteAt(ResBoxClosed, BoxPage, 30, 290, 7);
    end else begin
      PutSpriteAt(ResBoxClosed, BoxPage, 6, 272, 7);
      PutSpriteAt(ResBoxClosed, BoxPage, 64, 280, 7);
      Where := 1 - Where;
    end;
    Sound(SoundIsOn * (Random(100) + 50));
    BufMove(BoxPage + BoxBase, BoxBase, 80, 20);
    NoSound;
    Delay(50);
  end;
  HideBubble;

  Say(6);
  Choice := SelectBox;
  HideBubble;

  BufFill(BoxPage, BPL, 20, 7);
  if Choice = 0 then begin
    X1 := 6; X2 := 8;
  end else begin
    X1 := 64; X2 := 66;
  end;
  if Choice = 0 then
    PutSpriteAt(ResBoxOpen, BoxPage, X1, 272, 7)
  else
    PutSpriteAt(ResBoxOpen, BoxPage, X1, 280, 7);

  if Where = Choice then begin
    Inc(Money[Player], 100);
    if Choice = 0 then
      PutSpriteAt(ResBoxMoney, BoxPage, X2, 272, 7)
    else
      PutSpriteAt(ResBoxMoney, BoxPage, X2, 280, 7);
  end;
  BufMove(BoxPage + BoxBase, BoxBase, 80, 20);

  if Where = Choice then begin
    Say(7);
    DrawScore(Player);
  end else
    Say(8);
  Wait(0);
  HideBubble;
  BufFill(BoxBase, 80, 20, 7);
end;

function Dialog(Mode: Word): Word;
var Choice, N: Word;
begin
  BufFill(BoxPage + BoxBase, 80, 20, 7);
  PutSpriteAt(ResSnickers, BoxPage, 2, 270, 2);
  PutSpriteAt(ResSnickers, BoxPage, 68, 270, 2);

  if Mode = 1 then begin
    OutTxtAt(BoxPage, sSay1, 12, 290, 0, Fnt14, 8);
    OutTxtAt(BoxPage, sSay2, 12, 305, 0, Fnt14, 8);
  end;
  if Mode = 2 then begin
    OutTxtAt(BoxPage, sTakeA1, 18, 290, 0, Fnt14, 8);
    OutTxtAt(BoxPage, sTakeA2, 18, 305, 0, Fnt14, 8);
  end;
  if Mode = 3 then begin
    OutTxtAt(BoxPage, sTakeB1, 18, 290, 0, Fnt14, 8);
    OutTxtAt(BoxPage, sTakeB2, 18, 305, 0, Fnt14, 8);
  end;

  for N := 40 downto 0 do begin
    Sound(SoundIsOn * (1000 - N * 20));
    BufMove(BoxPage + BoxBase, BoxBase + N * 2 * BPL, 80 - N * 2, 20);
    NoSound;
    Delay(N);
  end;

  Choice := SelectYesNo;
  BufFill(BoxBase, 80, 20, 7);
  if Choice = 1 then Dialog := 0 else Dialog := Mode;
end;

procedure Signature;
begin
  Buf := sAuthor;
  OutTxt(Buf, 320 - Length(Buf) * 4, 332, 0, Fnt8, 8);
  Buf := sPhone;
  OutTxt(Buf, 320 - Length(Buf) * 4, 341, 0, Fnt8, 8);
end;

procedure PrizeGame;
var Step, Choice, Y, N: Word; Sum: LongInt;
begin
  BufFill(0, 350, 80, 7);
  Draw(ResTitlePole, 10, 10, 7);
  Draw(ResTitleChud, 200, 10, 7);
  Draw(ResYakub, 480, 172, 7);
  Draw(ResYakClosed, 511, 173, NoTrans);
  Draw(ResYakEyes, 532, 209, NoTrans);

  Step := 0;
  Sum := 10;
  Choice := 0;
  repeat
    if Step = 0 then begin Buf := sHundred;  Sum := 10 end;
    if Step = 1 then begin Buf := sThousand; Sum := 100 end;
    if Step = 2 then begin Buf := sHundredK; Sum := 10000 end;
    if Step = 3 then begin Buf := sMillion;  Sum := 100000 end;
    Say(17);
    Choice := Dialog(3);
    HideBubble;
    Inc(Step);
  until (Step > 3) or (Choice = 0);

  if Choice = 0 then begin
    Say(18);
    while Sum > 0 do begin
      Dec(Sum);
      Sound(SoundIsOn * Random(50));
      Draw(ResRuble, Random(400), Random(295), 2);
      NoSound;
    end;
  end else begin
    Y := $BE;
    Buf := sPrizeWon;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 0, Fnt14, 8);
    Inc(Y, $12);
    Buf := sFirmGives;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 0, Fnt14, 8);
    Inc(Y, $12);
    Buf := PrizeName[Random(10)] + sFromPG;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 15, Fnt14, 8);
    Inc(Y, $12);
    Buf := sAddr;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 0, Fnt14, 8);
    Inc(Y, $12);
    Buf := sMark;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 15, Fnt14, 8);
    Inc(Y, $12);
    Buf := sMark2;
    OutTxt(Buf, $F0 - Length(Buf) * 4, Y, 0, Fnt14, 8);
  end;
  Signature;
  Wait(0);
  HideBubble;
end;

procedure StartScreen;
var K, N, X, Y: Integer;
begin
  ClearScreen(0);

  for K := 0 to 159 do begin
    FillRect(K + 20, 345 - K, 620 - K, 345 - K, 7);
    Delay(4);
  end;

  for K := 0 to 159 do begin
    Line(20, 345, 180 - K, 185 - K, 7);
    FillRect(180 - K, 185 - K, 460 + K, 185 - K, 7);
    Line(460 + K, 185 - K, 620, 345, 7);
    if Odd(K) then Poll;
  end;

  FillRect(20, 25, 620, 345, 7);

  for N := 1 to 60 do begin
    for K := 0 to 8 do
      FillRect(20 + (N - 1) * 10, 25 + K * 40, 20 + N * 10, 27 + K * 40, 4);
    Delay(6);
    Poll;
  end;
  for N := 1 to 40 do begin
    for K := 0 to 12 do
      FillRect(19 + K * 50, 25 + (N - 1) * 8, 21 + K * 50, 25 + N * 8, 4);
    Delay(6);
    Poll;
  end;
  Wait(50);

  Wait(50);
  Draw(ResTitlePole, 90, 60, 7);
  Draw(ResTitleChud, 280, 60, 7);
  Wait(50);

  Buf := sCapital;
  for K := 1 to Length(Buf) do begin
    if K < 9 then X := K * 50 - 15 else X := K * 50;
    for N := -1 to 1 do
      for Y := -1 to 2 do
        OutTxt(Buf[K], X + N, 238 + Y, 0, Fnt14, 8);
    if SoundIsOn > 0 then Sound(K * 100);
    OutTxt(Buf[K], X, 238, 15, Fnt14, 8);
    OutTxt(Buf[K], X, 239, 15, Fnt14, 8);
    NoSound;
    Delay(250);
  end;

  OutTxt(sDedic, 320 - Length(sDedic) * 12, 27, 0, Fnt14, 25);
  BufFill($6040, 71, 80, 0);
  OutTxt(sAuthor, 320 - Length(sAuthor) * 4, 2, 7, Fnt8, 8);
  OutTxt(sPhone, 320 - Length(sPhone) * 4, 12, 7, Fnt8, 8);
  OutTxt(sHelp1, 27, 310, 7, Fnt8, 8);
  OutTxt(sHelp2, 99, 320, 7, Fnt8, 8);
  OutTxt(sHelp3, 99, 330, 7, Fnt8, 8);
  OutTxt(sHelp4, 99, 340, 7, Fnt8, 8);
  Wait(0);
end;

procedure SaleInfo;
var Y: Word;
begin
  BufMove(SaleBase, SalePage, 170, 21);
  Draw(ResPanel, 481, 173, NoTrans);
  Y := 174;
  OutTxt(sSale1, 557 - Length(sSale1) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 74);
  OutTxt(sSale2, 557 - Length(sSale2) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale3, 557 - Length(sSale3) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale4, 557 - Length(sSale4) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale5, 557 - Length(sSale5) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale6, 557 - Length(sSale6) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale7, 557 - Length(sSale7) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale8, 557 - Length(sSale8) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 8);
  OutTxt(sSale9, 557 - Length(sSale9) * 4, Y, 14, Fnt8, 8);
  Inc(Y, 10);
  OutTxt(sSale10, 557 - Length(sSale10) * 4, Y, 14, Fnt8, 8);
  Wait(0);
  BufMove(SalePage, SaleBase, 170, 21);
  Draw(ResYakub, 480, 172, 7);
  Draw(ResYakClosed, 511, 173, NoTrans);
  Draw(ResYakEyes, 532, 209, NoTrans);
end;

procedure IntroPlayers;
var P, Opp, X, Y, Ph, N: Word;
begin
  Say(19);
  for P := 0 to 2 do begin
    if P < 2 then Opp := Shuffle[RoundNo * 2 + 1 + P] else Opp := 0;
    case P of
      0: begin X := $30; Y := $95 end;
      1: begin X := $0A; Y := $95 end;
    else begin X := $1E; Y := $DC end;
    end;

    if P < 2 then
      for Ph := 0 to 3 do begin
        BufFill(GirlPage + Y * BPL + X, 90, 10, 7);
        if Ph < 3 then
          PutSpriteAt(ResEnter0 + Ph, GirlPage, X * 8, Y, 2)
        else
          PutSpriteAt(OppSprite[Opp], GirlPage, X * 8, Y, 2);
        BufMove(GirlPage + Y * BPL + X, Y * BPL + X, 90, 10);
        for N := 1 to 20 do begin
          Sound(SoundIsOn * (Ph * 100 + N * 10 + 50));
          Delay(1);
          NoSound;
          Delay(Ph * 4 + N div 4);
        end;
      end;

    if P = 0 then Buf := sPl1;
    if P = 1 then Buf := sPl2;
    if P = 2 then Buf := sPl3;

    if Opp = 0 then begin
      OutTxt(Buf, (X + 9) * 8, Y + $48, 0, Fnt14, 8);
      Buf := sItsYou;
      OutTxt(Buf, (X + 9) * 8 + $18, Y + $56, 0, Fnt14, 8);
    end else begin
      OutTxt(Buf, X * 8, Y - $1D, 0, Fnt14, 8);
      OutTxt(OppName[Opp], X * 8 + 4, Y - $10, 0, Fnt14, 8);
    end;
  end;
  Wait(0);
  HideBubble;
end;

procedure InputName(Slot: Word);
var Pos, Blink: Word; Bse: Word; S: string;
begin
  Pos := 0;
  S := '';
  Bse := (Slot * 14 + 195) * BPL + 62;
  Blink := 0;

  repeat
    Key := #7;
    if KeyPressed then Key := ReadKey;
    if Key = #19 then SoundIsOn := 1 - SoundIsOn;
    if Key = #9 then BossKey;
    if Key = #27 then Bye;

    if (Key = #8) and (Pos > 0) then begin
      Delete(S, Pos, 1);
      BufFill(Bse + Pos, 13, 1, 0);
      Dec(Pos);
      BufFill(Bse + Pos, 13, 1, 0);
    end;

    if Key > ' ' then Key := RusKey(Key);

    if (Key > #31) and (Pos < 10) then begin
      BufFill(Bse + Pos, 13, 1, 0);
      Buf := Key;
      OutTxt(Buf, Pos * 8 + 497, Slot * 14 + 195, 7, Fnt14, 8);
      OutTxt(Buf, Pos * 8 + 496, Slot * 14 + 195, 15, Fnt14, 8);
      S := S + Key;
      Inc(Pos);
    end;

    Delay(25);
    Inc(Blink);
    if Blink > 39 then Blink := 0;
    BufFill(Bse + Pos + $320, 2, 1, (Blink div 20) * 11);
  until Key = #13;

  Pic[Slot].Name := S;
end;

procedure HallOfFame;
var Y, Slot, K, N, Color: Word;
begin
  BufFill(0, 350, 80, 7);
  Draw(ResTitlePole, 10, 10, 7);
  Draw(ResTitleChud, 200, 10, 7);
  Draw(ResYakub, 480, 172, 7);
  Draw(ResYakClosed, 511, 173, NoTrans);
  Draw(ResYakEyes, 532, 209, NoTrans);

  Y := 190;
  Str(Money[3], Buf);
  Buf := sYouWonFin + Buf + sPointsEx;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 0, Fnt14, 8);
  Buf := sTusar;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 0, Fnt14, 8);
  Buf := PrizeName[Random(10)] + sFromPG;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 15, Fnt14, 8);
  Buf := sAddr;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 0, Fnt14, 8);
  Buf := sMark;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 15, Fnt14, 8);
  Buf := sMark2;
  Inc(Y, 18);
  OutTxt(Buf, 240 - Length(Buf) * 4, Y, 0, Fnt14, 8);
  Signature;
  SayWait(13);

  Slot := 0;
  if Money[3] > Pic[8].Score then begin
    K := 8;
    while (K > 1) and (Money[3] > Pic[K - 1].Score) do Dec(K);
    for N := 8 downto K + 1 do Pic[N] := Pic[N - 1];
    Pic[K].Score := Money[3];
    Pic[K].Name := '';
    Slot := K;
  end;

  BufFill(TopBufP, 160, 20, 0);
  OutTxtAt(TopPage, sTop8a, 489, 170, 15, Fnt14, 8);
  OutTxtAt(TopPage, sTop8a, 488, 170, 7, Fnt14, 8);
  OutTxtAt(TopPage, sTop8b, 489, 184, 15, Fnt14, 8);
  OutTxtAt(TopPage, sTop8b, 488, 184, 7, Fnt14, 8);
  for K := 1 to 8 do begin
    if K = Slot then Color := 15 else Color := 11;
    Str(K, Buf);
    Buf := Buf + '. ' + Pic[K].Name;
    OutTxtAt(TopPage, Buf, 481, K * 14 + 195, Color - 8, Fnt14, 8);
    OutTxtAt(TopPage, Buf, 480, K * 14 + 195, Color, Fnt14, 8);
    Str(Pic[K].Score, Buf);
    OutTxtAt(TopPage, Buf, 591, K * 14 + 195, Color - 8, Fnt14, 8);
    OutTxtAt(TopPage, Buf, 590, K * 14 + 195, Color, Fnt14, 8);
  end;
  for K := 80 downto 0 do begin
    if SoundIsOn > 0 then Sound(1600 - K * 20);
    BufMove(TopMovP, TopMovV + K * 2 * BPL, 160 - K * 2, 19);
    NoSound;
    Delay(K div 2);
  end;
  if Slot > 0 then begin
    InputName(Slot);
    SavePic;
  end;
  Wait(0);
end;

procedure DrawStudio;
var N: Word;
begin
  ClearScreen(0);
  FillRect(0, 0, 639, 10, 3);
  FillRect(0, 10, 639, 12, 8);
  FillRect(0, 13, 639, 107, 1);
  FillRect(0, 108, 639, 110, 8);
  FillRect(0, 111, 639, 349, 7);
  FillRect(0, 330, 639, 331, 8);

  for N := 0 to 35 do
    Draw(ResBrick0 + Random(3), (N mod 12) * 52 + 5, (N div 12) * 31 + 15, 1);
  Draw(ResWallL, 0, 25, 7);
  Draw(ResWallR, 600, 25, 7);
  Draw(ResLamp, 69, 3, 1);
  Draw(ResLamp, 559, 3, 1);

  FillRect(120, 15, 520, 95, 7);
  for N := 0 to 4 do
    FillRect(120, 15 + N * 20, 520, 15 + N * 20, 0);
  for N := 0 to 25 do
    FillRect(120 + N * 16, 15, 120 + N * 16, 95, 0);
  case RoundNo of
    0: Buf := sQuarter;
    1: Buf := sSemi;
  else Buf := sFinal;
  end;
  OutTxt(Buf, 204, 78, 0, Fnt14, 16);

  DrawYak;
  DrawBoardCells;
  DrawOpenLetters;
  DrawAlphabet;
  Counter := 0;
  DrawWheel;
  IntroPlayers;
  for N := 1 to 3 do DrawScore(N);
end;

procedure PrepareRound;
var N: Word;
begin
  Money[1] := 0;
  Money[2] := 0;
  Money[3] := 0;
  for N := 1 to 2 do Money[N] := (Random(4) * 15 + 5) * RoundNo;
  NewWord;
  for N := 0 to MaxWordLen do begin
    Opened[N] := 0;
    OpenShown[N] := 0;
  end;
  for N := 0 to 31 do Used[N] := 0;
  Counter := 0;
  DrawStudio;
  SayWait(9);
  SayWait(10);
  Player := 3;
end;

function LettersLeft: Word;
var N, C: Word;
begin
  C := 0;
  for N := 1 to Length(CurWord) do if Opened[N] = 0 then Inc(C);
  LettersLeft := C;
end;

procedure PlayGame;
var Status, Streak, N: Word;
begin
  RoundNo := 0;
  repeat
    PrepareRound;
    Status := 0;
    Streak := 0;
    repeat
      Status := 0;
      if Player = 3 then begin
        Say(15);
        Status := Dialog(1);
        HideBubble;
      end;

      if Status <> 0 then begin
        if WrongAnswer then begin
          SayWait(12);
          Status := 2;
        end else begin
          for N := 1 to Length(CurWord) do begin
            Opened[N] := 1;
            OpenShown[N] := 1;
          end;
          DrawBoardCells;
          DrawOpenLetters;
          SayWait(11);
          Status := 1;
        end;
      end;

      if Status = 0 then begin
        SayWait(1);
        SpinWheel;
        SayWait(2);

        if Money[0] < 0 then begin
          Money[Player] := 0;
          DrawScore(Player);
        end;

        if Money[0] <= 0 then begin
          Inc(Player);
          Streak := 0;
        end else begin
          if Money[0] = 100 then OpenAnyLetter
          else begin
            if (Money[0] = 300) and (Player = 3) then begin
              Say(2);
              Status := Dialog(2);
              HideBubble;
              if Status <> 0 then begin
                PrizeGame;
                Status := 2;
              end;
            end;
            if Status = 0 then ChooseLetter;
          end;

          if Status = 0 then begin
            if Opened[0] > 0 then begin
              GirlOpens;
              Inc(Streak);
              if Streak >= 3 then begin
                SayWait(5);
                if Player = 3 then MoneyBoxes
                else if Random(2) = 1 then Inc(Money[Player], 100);
                DrawScore(Player);
                Streak := 0;
              end;
            end else begin
              Inc(Player);
              Streak := 0;
            end;
          end;
        end;
        if Player > 3 then Player := 1;
      end;

      if (Status = 0) and (LettersLeft = 0) then begin
        SayWait(4);
        if Player = 3 then Status := 1 else Status := 2;
      end;
    until Status <> 0;

    if Status = 1 then begin
      Inc(RoundNo);
      if RoundNo < 3 then begin
        SayWait(16);
        SaleInfo;
      end;
    end;
  until (Status = 2) or (RoundNo > 2);

  if RoundNo > 2 then HallOfFame
  else SayWait(14);
end;

begin
  GraphOn := False;
  PendKey := #0;
  Randomize;
  SoundIsOn := 1;
  Counter := 0;
  MouseBtn := 0;
  Key := #7;
  for I := 1 to MaxRes do Res[I] := nil;
  Font6 := nil;
  Font8 := nil;
  Font14 := nil;
  for I := 0 to 2 do UsedWord[I] := 0;

  FindDataDir;
  LoadResources;
  InitGraphics;

  for I := 1 to 6 do Shuffle[I] := I;
  for J := 1 to 20 do begin
    I := Random(6) + 1;
    T := Random(6) + 1;
    Money[0] := Shuffle[I];
    Shuffle[I] := Shuffle[T];
    Shuffle[T] := Money[0];
  end;
  Money[0] := 0;

  StartScreen;
  PlayGame;

  NoSound;
  SetVideoMode(3);
  GraphOn := False;
end.

