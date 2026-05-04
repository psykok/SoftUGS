; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; !!!! NE PAS MODIFIER TOUT CE QUI SUIT !!!
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

VolumeMessage:
;    0123456789ABCDEF0123
.db "Volume :            ",FinChaine,0

VolMaxdBMessage:
;    0123456789ABCDEF0123
.db "0.00 dB ",FinChaine,0 

BalanceMessage:
;    0123456789ABCDEF0123
.db "   Volume Balance   ",FinChaine,0
BalanceMessage2:
;.db "                    ",FinChaine,0 
.db 5,"        ||        ",4,FinChaine,0

BalanceCenterMessage:
;    0123456789ABCDEF0123
.db 5," 0.00dB || 0.00dB ",4,FinChaine,0

BalanceGaucheMessage:
;    0123456789ABCDEF0123
.db 5," 0.00dB |>        ",4,FinChaine,0

BalanceDroiteMessage:
;    0123456789ABCDEF0123
.db 5,"        <| 0.00dB ",4,FinChaine,0

MenuSavingMessage:
;    0123456789ABCDEF0123
.db "..Saving New Value..",FinChaine,0

RienQueDesBlancs:
;    0123456789ABCDEF0123
.db "                    ",FinChaine,0

#if defined(BYPASS)
NoBypassMessageL1:
;    0123456789ABCDEF0123
.db " Bypass Disabled... ",FinChaine,0
NoBypassMessageL2:
;    0123456789ABCDEF0123
.db " (No input defined) ",FinChaine,0

; La seconde ligne pour le bypass
Bypass2Message:
;    0123456789ABCDEF0123
.db "Press Bypass to Exit",FinChaine,0
#endif

; Pour le menu principal

MenuSetupTopMessage:
;    0123456789ABCDEF0123
.db "  User Preferences  ",FinChaine,0			; La ligne du haut de l'afficheur

MenuVolumeSetupMessage:						; et les différentes lignes du bas
;    0123456789ABCDEF0123
.db "  Volume  Settings  ",FinChaine,0

MenuInputSetupMessage:
;    0123456789ABCDEF0123
.db "    Inputs Setup    ",FinChaine,0

MenuDisplaySetupMessage:
;    0123456789ABCDEF0123
.db "  Display Settings  ",FinChaine,0

MenuRC5SetupMessage:
;    0123456789ABCDEF0123
.db "   Remote Control   ",FinChaine,0

MenuMessagesSetup:
;    0123456789ABCDEF0123
.db "   Messages Setup   ",FinChaine,0

MenuEEPROMSetup:
;    0123456789ABCDEF0123
.db "  Manage  Settings  ",FinChaine,0

MenuEncodeurMessage:
;    0123456789ABCDEF0123
.db "<                  >",FinChaine,0

; Pour le menu des paramètres de volume

MenuVolumeTopMessage:						; La ligne du haut
;    0123456789ABCDEF0123
.db "  Volume  Settings  ",FinChaine,0

MenuVolumeBalanceMessage:					; et les différentes lignes du bas
;    0123456789ABCDEF0123
.db "<  Volume Balance  >",FinChaine,0

MenuVolumeStartupMessage:
;    0123456789ABCDEF0123
.db "<  Startup Volume  >",FinChaine,0

MenuVolumeMuteLevelMessage:
;    0123456789ABCDEF0123
.db "<    Mute Level    >",FinChaine,0

MenuVolumeDisplayMessage:
;    0123456789ABCDEF0123
.db "<  Volume Display  >",FinChaine,0

MenuVolumeDelayOffMessage:
;    0123456789ABCDEF0123
.db "<MBB Turn Off Delay>",FinChaine,0

MenuVolumeDelayOnMessage:
;    0123456789ABCDEF0123
.db "< MBB Turn On Time >",FinChaine,0

MenuVolSpeedupMessage:
;    0123456789ABCDEF0123
.db	" IR Volume Speed Up ",FinChaine,0

MenuVolSpeedupNoneMessage:
;    0123456789ABCDEF0123
.db	"<    No Speedup    >",FinChaine,0

MenuVolSpeedupOneMessage:
;    0123456789ABCDEF0123
.db	"<  Normal Speedup  >",FinChaine,0

MenuVolSpeedupTwoMessage:
;    0123456789ABCDEF0123
.db	"<   Fast Speedup   >",FinChaine,0

MenuVolEncoderStepMessage:
;    0123456789ABCDEF0123
.db	"  Encoder Stepping  ",FinChaine,0

MenuVolEncoderStepValueMessage:
;    0123456789ABCDEF0123
.db	"   Step Value :     ",FinChaine,0



; Pour la config du volume de départ

MenuStartVolumeTopMessage:					; La ligne du haut
;    0123456789ABCDEF0123
.db "   Startup Volume   ",FinChaine,0

MenuVolStartMiniMessage:
;    0123456789ABCDEF0123
.db	"<  Minimum Volume  >",FinChaine,0

MenuVolStartPresetMessage:
;    0123456789ABCDEF0123
.db	"<  Preset  Volume  >",FinChaine,0

MenuVolStartLastMessage:
;    0123456789ABCDEF0123
.db	"<   Last  Volume   >",FinChaine,0

; == Pour le preset de volume

MenuPresetVolumeTopMessage:					; La ligne du haut
;    0123456789ABCDEF0123
.db "   Preset  Volume   ",FinChaine,0

MenuPresetVolumeLowMessage:					; La ligne du bas
;    0123456789ABCDEF0123
.db " Volume:            ",FinChaine,0

; == Pour le volume du mute

MenuMuteLevelTopMessage:					; La ligne du haut
;    0123456789ABCDEF0123
.db "     Mute Level     ",FinChaine,0

MenuMuteLevelLowMessage:					; La ligne du bas
;    0123456789ABCDEF0123
.db "  Level:            ",FinChaine,0

; == Pour le menu du mode d'affichage du volume

MenuVolumeTypeTopMessage:					; La ligne du haut
;    0123456789ABCDEF0123
.db "Volume Display Mode ",FinChaine,0

MenuVolTypeDBMessage:
;    0123456789ABCDEF0123
.db	"<    dB Display    >",FinChaine,0

MenuVolTypeDecMessage:
;    0123456789ABCDEF0123
.db	"< Decimal  Display >",FinChaine,0

MenuVolTypeBinaryMessage:
;    0123456789ABCDEF0123
.db	"<  Binary Display  >",FinChaine,0

MenuVolTypeGraphicMessage:
;    0123456789ABCDEF0123
.db	"< BarGraph Display >",FinChaine,0

; Pour le menu de délai de MBB

MenuVolumeDelayOffTopMessage:				; La ligne du haut
;    0123456789ABCDEF0123
.db " MBB Turn Off Delay ",FinChaine,0

MenuVolumeDelayOnTopMessage:				; La ligne du haut
;    0123456789ABCDEF0123
.db "  MBB Turn On Time  ",FinChaine,0

MenuVolumeDelayLowMessage:					; La ligne du bas
;    0123456789ABCDEF0123
.db "  Value :           ",FinChaine,0

; == Pour le menu des paramètres des entrées

MenuInputNoMessage:
;    0123456789ABCDEF0123
.db "< Input N",Nb,"   Setup >",FinChaine,0

MenuInputPrefMessage:
;    0123456789ABCDEF0123
.db "   Start Up Input   ",FinChaine,0

MenuInputNbParam:
;    0123456789ABCDEF0123
.db " Input N",Nb,"  Settings ",FinChaine,0

MenuInputName:
;    0123456789ABCDEF0123
.db "<    Input Name    >",FinChaine,0

MenuInputNbName:
;    0123456789ABCDEF0123
.db "   Input N",Nb,"1 Name   ",FinChaine,0

MenuChangeInputName:
;    0123456789ABCDEF0123
.db "   ",0x22,"            ",0x22,"   ",FinChaine,0           

MenuSaveName:
;    0123456789ABCDEF0123
.db " Saving New Name... ",FinChaine,0

MenuInputType:
;    0123456789ABCDEF0123
.db "<    Input Type    >",FinChaine,0

MenuInputTrig:
;    0123456789ABCDEF0123
.db "< Activate Trigger >",FinChaine,0

MenuInputVol:
;    0123456789ABCDEF0123
.db "< Volume  Trimming >",FinChaine,0

MenuInput6dB:
;    0123456789ABCDEF0123
.db "<Add 6 dB to Volume>",FinChaine,0

MenuInputParamName:
;    0123456789ABCDEF0123
.db "   Input N",Nb,"  Name   ",FinChaine,0

MenuInputTypeMessage:
;    0123456789ABCDEF0123
.db "   Input N",Nb,"  Type   ",FinChaine,0

MenuInputBalMessage:
;    0123456789ABCDEF0123
.db "<  Balanced Input  >",FinChaine,0

MenuInputUnBalMessage:
;    0123456789ABCDEF0123
.db "< Unbalanced Input >",FinChaine,0

MenuInputTrigMessage:
;    0123456789ABCDEF0123
.db "Input 1  Trigger Out",FinChaine,0

MenuInputTrigOnMessage:
;    0123456789ABCDEF0123
.db "<    Trigger On    >",FinChaine,0

MenuInputTrigOffMessage:
;    0123456789ABCDEF0123
.db "<    Trigger Off   >",FinChaine,0

MenuInput6dBMessage:
;    0123456789ABCDEF0123
.db "Input 1 Volume + 6dB",FinChaine,0

MenuInput6dBOnMessage:
;    0123456789ABCDEF0123
.db "<     Add 6 dB     >",FinChaine,0

MenuInput6dBOffMessage:
;    0123456789ABCDEF0123
.db "<   Same  Volume   >",FinChaine,0

MenuPrefInpPresetMessage:
;    0123456789ABCDEF0123
.db "<  Preset  Input   >",FinChaine,0

MenuPrefInpLastMessage:
;    0123456789ABCDEF0123
.db "<    Last Input    >",FinChaine,0

MenuPrefInpNameMessage:
;    0123456789ABCDEF0123
.db "<N",Nb," :              >",FinChaine,0

;db "<No1: NomEntree>"

MenuPrefInpBypassMessage:
;    0123456789ABCDEF0123
.db "   Bypassed Input   ",FinChaine,0

MenuPrefInpNoBypassMessage:
;    0123456789ABCDEF0123
.db "     No  Bypass     ",FinChaine,0

MenuInputVolMessage:
;    0123456789ABCDEF0123
.db "Input 1 Volume Trim ",FinChaine,0

MenuInpVolValMessage:
;    0123456789ABCDEF0123
.db "<  Trim :          >",FinChaine,0

; == Pour le menu des paramètres de l'afficheur

MenuDisplayTopMessage:
;    0123456789ABCDEF0123
.db " LCD Display Setup  ",FinChaine,0

MenuDisplayBrightMessage:
;    0123456789ABCDEF0123
.db "<    Brightness    >",FinChaine,0

MenuDisplayContrastMessage:
;    0123456789ABCDEF0123
.db	"<     Contrast     >",FinChaine,0

MenuDisplayIdleBrightMessage:
;    0123456789ABCDEF0123
.db	"< Idle  Brightness >",FinChaine,0

MenuDisplayIdleTimeOutMessage:
;    0123456789ABCDEF0123
.db	"<   Idle Timeout   >",FinChaine,0

MenuDisplayIdleLedMessage:
;    0123456789ABCDEF0123
.db	"<  Led Brightness  >",FinChaine,0

MenuDisplayBrightTopMessage:
;    0123456789ABCDEF0123
.db " Display Brightness ",FinChaine,0

MenuDisplayContrastTopMessage:
;    0123456789ABCDEF0123
.db "  Display Contrast  ",FinChaine,0

MenuDisplayIdleTopMessage:
;    0123456789ABCDEF0123
.db "  Idle  Brightness  ",FinChaine,0

MenuDisplayIdleTimeOutTopMessage:
;    0123456789ABCDEF0123
.db " Idle Timeout Value ",FinChaine,0

MenuDisplayIdleLedTopMessage:
;    0123456789ABCDEF0123
.db	"   Led Brightness   ",FinChaine,0

MenuDisplayValueMessage:
;    0123456789ABCDEF0123
.db "< Value :          >",FinChaine,0

MenuDisplayTOValueMessage:
;    0123456789ABCDEF0123
.db "<                  >",FinChaine,0

MenuIdleLedOnMessage:
;    0123456789ABCDEF0123
.db "<   Keep Led On    >",FinChaine,0

MenuIdleLedOffMessage:
;    0123456789ABCDEF0123
.db "<  Switch Led Off  >",FinChaine,0

; == Pour le menu des paramètres de la télécommande

MenuRC5Key2learnMessage:
;    0123456789ABCDEF0123
.db	"  Assigned RC Code  ",FinChaine,0

MenuRC5SystemIDMessage:
;    0123456789ABCDEF0123
.db	"< System ID :      >",FinChaine,0

MenuRC5CmdOnMessage:
;    0123456789ABCDEF0123
.db	"< Standby/On :     >",FinChaine,0

MenuRC5CmdMuteMessage:
;    0123456789ABCDEF0123
.db	"<Mute Output :     >",FinChaine,0

MenuRC5CmdVolPMessage:
;    0123456789ABCDEF0123
.db	"< Volume +   :     >",FinChaine,0

MenuRC5CmdVolMMessage:
;    0123456789ABCDEF0123
.db	"< Volume -   :     >",FinChaine,0

MenuRC5CmdBalGMessage:
;    0123456789ABCDEF0123
.db	"<Balance Left :    >",FinChaine,0

MenuRC5CmdBalDMessage:
;    0123456789ABCDEF0123
.db	"<Balance Right:    >",FinChaine,0

MenuRC5CmdInp1Message:
;    0123456789ABCDEF0123
.db	"<Input N",Nb,"1 :       >",FinChaine,0

MenuRC5CmdInp2Message:
;    0123456789ABCDEF0123
.db	"<Input N",Nb,"2 :       >",FinChaine,0

MenuRC5CmdInp3Message:
;    0123456789ABCDEF0123
.db	"<Input N",Nb,"3 :       >",FinChaine,0

MenuRC5CmdInp4Message:
;    0123456789ABCDEF0123
.db	"<Input N",Nb,"4 :       >",FinChaine,0

#if defined (BYPASS)
MenuRC5CmdBypassMessage:
;    0123456789ABCDEF0123
.db	"< Bypass UGS :     >",FinChaine,0
#else
MenuRC5CmdTapeMessage:
;    0123456789ABCDEF0123
.db	"< Tape Input :     >",FinChaine,0
#endif

MenuRC5CmdBrightPMessage:
;    0123456789ABCDEF0123
.db	"<Brightness +:     >",FinChaine,0

MenuRC5CmdBrightMMessage:
;    0123456789ABCDEF0123
.db	"<Brightness -:     >",FinChaine,0

MenuRC5CmdContrastPMessage:
;    0123456789ABCDEF0123
.db	"< Contrast + :     >",FinChaine,0

MenuRC5CmdContrastMMessage:
;    0123456789ABCDEF0123
.db	"< Contrast - :     >",FinChaine,0

MenuRC5PressKeyMessage:
;    0123456789ABCDEF0123
.db	" Press key to learn ",FinChaine,0

MenuRC5PressAnyKeyMessage:
;    0123456789ABCDEF0123
.db	"Press any key on RC ",FinChaine,0

MenuRC5DuplicateMessage:
;    0123456789ABCDEF0123
.db	"Key already used !!!",FinChaine,0

; == Pour les éditions de message ==

MenuMessageWelcome:
;    0123456789ABCDEF0123
.db	"  Power On Message  ",FinChaine,0

MenuMessageBye:
;    0123456789ABCDEF0123
.db	"   ByeBye Message   ",FinChaine,0

MenuMessageMute:
;    0123456789ABCDEF0123
.db	"    Mute Message    ",FinChaine,0

MenuSaveMessage:
;    0123456789ABCDEF0123
.db "   Messages Setup   ",FinLigne,"Saving New Message..",FinChaine

MenuEEPromRestoreFactory:
;    0123456789ABCDEF0123
.db	"  Restore Defaults  ",FinChaine,0

MenuEEPromSaveUser:
.db	"  Settings ",Fld," Mem 1  ",FinChaine,0

MenuEEPromLoadUser:
.db	"  Mem 1 ",Fld," Settings  ",FinChaine,0

MenuEEPromSure:
;    0123456789ABCDEF0123
.db	"   Are You Sure ?   ",FinChaine,0

MenuEEPromSureSure:
;    0123456789ABCDEF0123
.db	"Really Really Sure ?",FinChaine,0

MenuEEPromLoadingDefaults:
;    0123456789ABCDEF0123
.db "..Loading Defaults..",FinChaine,0

MenuEEPromSavingUser:
;    0123456789ABCDEF0123
.db "..Saving  Settings..",FinChaine,0

MenuEEPromLoadingUser:
;    0123456789ABCDEF0123
.db "..Loading Settings..",FinChaine,0



