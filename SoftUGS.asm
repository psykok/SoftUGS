; =============================
; ==                         ==
; == Le coeur du cerveau :o) ==
; ==                         ==
; =============================

;#define FLAT							; -- Pour bibi : ATMega64, Optrex et pas de bypass
;#define ATMEGA64_OPTREX				; -- Pour Marco & Alex : ATMega64, Optrex et bypass
;#define ATMEGA64_CRYSTALFONTZ			; -- Pour la majorité : ATMega64, CrystalFontz et bypass
;#define ATMEGA64_CRYSTALFONTZ_ALDO		; -- Pour Aldo : comme au-dessus, mais petite modif telco
;#define ATMEGA64_CRYSTALFONTZ_MFC		; -- Pour Manu : Petite modif sur des pinoches d'entrée sortie
#define ATMEGA128_CRYSTALFONTZ			; -- Pour Trung : Un ATMega128 à la place du 64
;#define ATMEGA64_VFD					; -- ATMega64 et afficheur VFD Noritake, avec Bypass
;#define ATMEGA64_VFD_NEWHAVEN			; -- ATMega64 et afficheur VFD Newhaven, avec Bypass
;#define ATMEGA64_VFD_ALDO				; -- Le même, avec modif télécommande pour Aldo
;#define ATMEGA128_VFD					; -- N'existe pas encore, mais ATMega128, Afficheur VFD et Bypass
;#define ATMEGA128_VFD_NEWHAVEN			; -- N'existe pas encore, mais ATMega128, Afficheur VFD Newhaven et Bypass



; -- Pour bibi : ATMega64, Optrex et pas de bypass

#if defined(FLAT)

#define M64								; Pour un ATmega64
#define LCD

#endif

; -- Pour Marco & Alex : ATMega64, Optrex et bypass

#if defined(ATMEGA64_OPTREX)

#define M64								; Pour un ATmega64
#define LCD
#define BYPASS

#endif

; -- Pour la majorité : ATMega64, CrystalFontz et bypass

#if defined(ATMEGA64_CRYSTALFONTZ)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS

#endif

; -- Pour Aldo : comme au-dessus, masi petite modif telco

#if defined(ATMEGA64_CRYSTALFONTZ_ALDO)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS
#define ALDO							; Spécial Landes

#endif

; -- Pour Manu : Petite modif sur des pinoches d'entrée sortie

#if defined(ATMEGA64_CRYSTALFONTZ_MFC)

#define M64								; Pour un ATmega64
#define LCD
#define CRYSTALFONTZ
#define BYPASS
#define MFC

#endif

; -- Pour Trung : Un ATMega128 à la place du 64

#if defined(ATMEGA128_CRYSTALFONTZ)

#define M128							; Pour un ATmega128
#define LCD
#define CRYSTALFONTZ
#define BYPASS

#endif

#if defined(ATMEGA64_VFD)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS

#endif

#if defined(ATMEGA64_VFD_ALDO)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS
#define ALDO

#endif

#if defined(ATMEGA64_VFD_NEWHAVEN)

#define M64								; Pour un ATmega64
#define VFD								; Afficheur VFD
#define NEWHAVEN						; de type Newhaven
#define BYPASS

#endif

#if defined(ATMEGA128_VFD)

#define M128							; Pour un ATmega128
#define VFD								; Afficheur VFD
#define NORITAKE						; de type Noritake
#define BYPASS

#endif

#if defined(ATMEGA128_VFD_NEWHAVEN)

#define M128							; Pour un ATmega128
#define VFD								; Afficheur VFD
#define NEWHAVEN
#define BYPASS

#endif

; == Les définitions pour l'ATmega64 (ou 128)

#if defined(M64)
#pragma AVRPART ADMIN PART_NAME ATmega64
#pragma AVRPART MEMORY INT_SRAM SIZE 4096
#pragma AVRPART MEMORY EEPROM 2048
#pragma AVRPART MEMORY PROG_FLASH 65536
.include "m64def.inc"
#endif
#if defined(M128)
#pragma AVRPART ADMIN PART_NAME ATmega128
#pragma AVRPART MEMORY INT_SRAM SIZE 4096
#pragma AVRPART MEMORY EEPROM 4096
#pragma AVRPART MEMORY PROG_FLASH 131072
.include "m128def.inc"
#endif


; == Les différentes définitions dont on a besoin (registres, constantes, adresses, etc...)

.include "Definitions.asm"

; == Quelques Macro-Instructions

.MACRO MacroMuteOn
#if defined(MFC)
		lds		Work,PortRelaisMute
		cbr		Work,EXP2(RelaisMute)				; Passe le relais de mute à 0 (c'est muté au repos)
		sts		PortRelaisMute,Work
#else
		cbi		PortRelaisMute,RelaisMute			; Passe le relais de mute à 0 (c'est muté au repos)
#endif
.ENDM

.MACRO MacroMuteOff
#if defined(MFC)
		lds		Work,PortRelaisMute
		sbr		Work,EXP2(RelaisMute)				; Passe le relais de mute à 1 (La sortie devient active)
		sts		PortRelaisMute,Work
#else
		sbi		PortRelaisMute,RelaisMute			; Passe le relais de mute à 1 (La sortie devient active)
#endif
.ENDM

; ------------------------------
; --- Le contenu de l'EEPROM ---
; ------------------------------

.eseg                                   ; Segment en EEPROM           
.org 0                                  ; Commencer à l'adresse $0000 de l'EEPROM

;*** Table de conversion des nibbles du compteur, stockée en EEPROM ***
;*** La valeur est en réalité l'adresse d'une valeur dans l'EEPROM  ***

tableconv:
; valeur en entrée 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
; Action           N  I  D  E  D  N  E  I  I  E  N  D  E  D  I  N
              .db  0, 1, 2, 3, 2, 0, 3, 1, 1, 3, 0, 2, 3, 2, 1, 0	; La valeur convertie
; N  = la position n'a pas changé (0)
; I  = Incrémenter la position    (1)
; D  = Décrémenter la position    (2)
; E  = Erreur, les deux bits ont changé en même temps (3)

; **********************************************************
; ***                                                    ***
; *** Les adresses suivantes en EEPROM (commencent à 16) ***
; *** contiennent les préférences de l'utilisateur       ***
; ***                                                    ***
; *** en 16 -> Comportement des entrées au démarrage     ***
; ***          =0 Entrée prédéfinie                      ***
; ***          =1 Dernière entrée activée                ***
; ***                                                    ***
; *** en 17 -> Numéro de l'entrée à activer au Power On  ***
; ***                                                    ***
; *** en 18 -> Numéro de l'entrée à activer au repos     ***
; ***                                                    ***
; *** en 19 -> Comportement du volume au démarrage :     ***
; ***          =0       -> Volume au minimum             ***
; ***          =1       -> Preset de volume              ***
; ***          =2       -> Dernier volume enregistré     ***
; ***                                                    ***
; *** en 20 -> Soit la valeur du preset de volume,       ***
; ***          soit la valeur du dernier volume          ***
; ***                                                    ***
; *** en 21 -> Mode d'affichage du volume :              ***
; ***          0 ->Affichage en dB                       ***
; ***          1 ->Affichage en décimal (de 0 à 127)     ***
; ***          2 ->Affichage en binaire                  ***
; ***                                                    ***
; *** en 22 -> Délai sur les relais de volume            ***
; ***                                                    ***
; *** en 23 -> Délai de recollage des relais de volume   ***
; ***                                                    ***
; *** en 24 -> Valeur du Volume en Mute                  ***
; ***                                                    ***
; *** en 25 -> Valeur de la Balance (0 au centre)        ***
; ***                                                    ***
; *** en 26 -> Luminosité de l'afficheur au démarrage    ***
; ***                                                    ***
; *** en 27 -> Contraste de l'afficheur au démarrage     ***
; ***                                                    ***
; *** en 28 -> Luminosité de l'afficheur en mode idle    ***
; ***                                                    ***
; *** en 29 -> Valeur du TimeOut d'Idle                  ***
; ***                                                    ***
; *** en 30 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'entrée 1         ***
; ***                                                    ***
; *** en 31 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'entrée 2         ***
; ***                                                    ***
; *** en 32 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'entrée 3         ***
; ***                                                    ***
; *** en 33 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'entrée 4         ***
; ***                                                    ***
; *** en 34 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'entrée 5         ***
; ***                                                    ***
; *** en 35 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande des amplis            ***
; ***                                                    ***
; *** en 36 -> Envoi (autre) ou non (0) d'un trigger     ***
; ***          sur la télécommande de l'ampli casque     ***
; ***                                                    ***
; *** en 37 -> Entrée 1 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 38 -> Entrée 2 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 39 -> Entrée 3 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 40 -> Entrée 4 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 41 -> Entrée 5 en XLR(0) ou RCA (autre)         ***
; ***                                                    ***
; *** en 42 -> Si Entrée 1 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 43 -> Si Entrée 2 en RCA, ......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 44 -> Si Entrée 3 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 45 -> Si Entrée 4 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 46 -> Si Entrée 5 en RCA,.......................***
; ***          augmenter vol de 6dB (1) ou Non (0)       ***
; ***                                                    ***
; *** en 47 -> Correction de volume sur entrée 1         ***
; ***                                                    ***
; *** en 48 -> Correction de volume sur entrée 2         ***
; ***                                                    ***
; *** en 49 -> Correction de volume sur entrée 3         ***
; ***                                                    ***
; *** en 50 -> Correction de volume sur entrée 4         ***
; ***                                                    ***
; *** en 51 -> Correction de volume sur entrée 5         ***
; ***                                                    ***
; *** en 52 -> Accélération du volume à la télécomande   ***
; ***                                                    ***
; *** en 53 -> Nombre de pulses de l'encodeur            ***
; ***          avant une action effective                ***
; ***                                                    ***
; *** en 54 -> Extinction (autre) ou non (0)             ***
; ***          de la led "on" en mode Idle               ***
; ***                                                    ***
; **********************************************************

#if defined(LCD)
#if defined(CRYSTALFONTZ)
;   16 17 18 19 20 21 22  23 24  25 26  27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,222,14, 0,2 ,0 ,0
#else
;   16 17 18 19 20 21 22  23 24  25 26  27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,222,2, 21,1, 0 ,0
#endif
#endif

#if defined(VFD)
;   16 17 18 19 20 21 22  23 24  25 26 27 28 29 30 31
.db 0, 1 ,4, 1 ,63,0 ,195,32,128,0 ,3 ,0, 0, 1, 0 ,0
#endif

;   32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
.db 0, 0, 0, 0, 1, 0, 0 ,0 ,1 ,1 ,1 ,1 ,1, 1, 1 ,0

;   48 49 50 51 52  53   54 55 56 57 58 59 60 61 62 63
.db 0, 0, 0, 0, 1, StEc, 0, 0, 0, 0 ,0 ,0 ,0 ,0 ,0 ,0 

; Les valeurs suivantes (commencent à l'adresse 64 en EEProm) contiennent les commandes IR RC5

;   64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
#if defined (ALDO)
.db 5,12,54,16,17,33,32, 1, 2 ,3 ,4 ,5,52,50,28,36
#else
.db 16,12,13,16,17,27,26, 1, 2 ,3 ,4 ,56,32,33,7,0
#endif

; les valeurs des octets pour définir les caractères accentués (Commence en 80)

; ASCII 0 (80)	(du vide condamné à être remplacé) 
.db 0,0,0,0,0,0,0,0	

; ASCII 1 (88)
.db 0b00000010,0b00000100,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E accent aigu

; ASCII 2 (96)
.db 0b00001000,0b00000100,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E accent grave

#if defined (CRYSTALFONTZ)
; ASCII 3 (104)
.db 0b00001110,0b00001010,0b00001110,0b00000000,0b00000000,0b00000000,0b00000000,0				; Le caractère "°"
#else
; ASCII 3 (104)
.db 0b00001000,0b00000100,0b00001110,0b00000001,0b00001111,0b00010001,0b00001111,0				; A accent grave
#endif

#if defined(LCD)
; ASCII 4 (112)
.db 0b00011000,0b00011100,0b00011110,0b00011111,0b00011111,0b00011110,0b00011100,0b00011000		; Flèche vers la droite

; ASCII 5 (120)
.db 0b00000011,0b00000111,0b00001111,0b00011111,0b00011111,0b00001111,0b00000111,0b00000011		; Flèche vers la gauche
#endif

#if defined(VFD)
; ASCII 4 (112)
.db 0b00011000,0b00011100,0b00011110,0b00011111,0b00011110,0b00011100,0b00011000,0				; Flèche vers la droite

; ASCII 5 (120)
.db 0b00000011,0b00000111,0b00001111,0b00011111,0b00001111,0b00000111,0b00000011,0				; Flèche vers la gauche
#endif

#if defined (CRYSTALFONTZ)
; ASCII 6 (128)
.db 0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111,0b00011111		; Le charactère "Block"
#else
; ASCII 6 (128)
.db 0b00001010,0b00000000,0b00001110,0b00010001,0b00011111,0b00010000,0b00001110,0				; E tréma
#endif

; ASCII 7 (136)
.db 0b00000000,0b00001010,0b00000000,0b00000100,0b00010001,0b00001110,0b00000000,0				; Un petit Smiley ;)


; Les 5 lignes suivantes contiennent les intitulés des entrées (12 caractères Max)
; Ils sont stockés en EEPROM pour pouvoir être modifiés
; 144 0123456789ABCDEF
.db  "ZET1            "													; Entrée 1
; 160 0123456789ABCDEF
.db  "EMT 948         "													; Entrée 2
; 176
.db  "DAC             "													; Entrée 3
; 192
.db  "T.S.F.          "													; Entrée 4
#if defined (BYPASS)
; 208
;   0123456789ABCDEF0123
.db  "Input N Bypassed"													; Bypass du preamp
#else
; 208
.db  "Tape Input      "													; Entrée Tape
#endif

; Le message de bienvenue 

.org 0x0100
;    0123456789ABCDEF0123
.db "  UGS Preamp V",'0'+VersionMajor,'.','0'+VersionMinor/10,'0'+VersionMinor-(VersionMinor/10*10),"  ",FinLigne	; Ligne 1
;    0123456789ABCDEF0123
.db	"   Thanks Nelson   ",7,FinChaine									; Ligne 2

.org 0x0130
; Le message de fin 
;    0123456789ABCDEF0123
.db "  O mo thruaighe !  ",FinLigne										; Ligne 1
;    0123456789ABCDEF0123
.db " Tiaraidh an drasda ",FinChaine									; Ligne 2

.org 0x0160
;Le Message de Mute 
;    0123456789ABCDEF0123
.db "Ce silence est aussi",FinLigne
#if defined(CRYSTALFONTZ)
.db "sponsoris",130," par NP..",7,FinChaine
#else
.db "sponsoris",1," par NP..",7,FinChaine
#endif

; ===============================
; La zone de réglages "User1" ;)
; ===============================

.org 0x0200
.db Vide											; Vide (0x0F) indique que rien n'a été sauvé ici 
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les réglages "utilisateurs"

; ===============================
; La zone de réglages "User2" ;)
; ===============================

.org 0x0400
.db Vide											; Vide (0x0F) indique que rien n'a été sauvé ici 
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les réglages "utilisateurs"

; ==================================
; La zone de réglages "Usine" ;)
; ==================================

.org 0x0600
.db Vide											; Vide (0x0F) indique qu'à la première mise sous tension,
													; il faut recopier l'EEPROM dans cette zone
													; pour sauvegarder les réglages "usine"
; ----------------------------
; --- Le code commence ici ---
; ----------------------------

.cseg
.org 0

; Les différents Handlers d'interruption

		rjmp	Init								; Routine de reset

.org INT0addr
		rjmp	Power								; Routine pour l'interruption INT0 (Appui sur le bouton power)

.org INT1addr
		rjmp	IRRecInt							; Routine pour l'interruption INT1 (Réception d'un ordre IR d'allumage)

.org INT2addr
		reti										; Routine pour l'interruption INT2

.org INT3addr
		reti										; Routine pour l'interruption INT3

.org INT4addr
		reti										; Routine pour l'interruption INT4

.org INT5addr
		reti										; Routine pour l'interruption INT5

.org INT6addr
		reti										; Routine pour l'interruption INT6

.org INT7addr
		reti										; Routine pour l'interruption INT7

.org OC2addr
		reti										; Timer 2 compare (unused)

.org OVF2addr
		rjmp	IRTimer								; Timer 2 overflow : Les timings de la récéption RC5

.org ICP1addr
		reti										; Timer 1 capture (unused)

.org OC1Aaddr
		reti										; Timer 1 compare A (unused)

.org OC1Baddr
		reti										; Timer 1 compare B (unused)

.org OVF1addr
		rjmp	RelayTimer							; Timer 1 overflow : Le timing des relais d'entrée et de mute

.org OC0addr
		reti										; Timer 0 compare (unused)

.org OVF0addr
		rjmp	DelayRelayMBB						; Timer 0 overflow : Le délai de MBB pour les relais de volume

.org SPIaddr
		reti										; SPI transfer complete (unused)

.org URXC0addr
		reti										; USART 0 RX complete (unused)

.org UDRE0addr
		reti										; USART 0 UDR empty (unused)

.org UTXC0addr
		reti										; USART 0 TX complete (unused)

.org ADCCaddr
		reti										; ADC complete (unused)

.org ERDYaddr
		reti										; EEPROM ready (unused)

.org ACIaddr
		reti										; Analog comparator (unused)

.org OC1Caddr
		reti										; Timer 1 compare C (unused)

.org ICP3addr
		reti										; Timer 3 capture (unused)

.org OC3Aaddr
		reti										; Timer 3 compare A (unused)

.org OC3Baddr
		reti										; Timer 3 compare B (unused)

.org OC3Caddr
		reti										; Timer 3 compare C (unused)

.org OVF3addr
		rjmp	MultiDelay							; Timer 3 overflow : Plusieurs utilisations

.org URXC1addr
		reti										; USART 1 RX complete (unused)

.org UDRE1addr
		reti										; USART 1 UDR empty (unused)

.org UTXC1addr
		reti										; USART 1 TX complete (unused)

.org TWIaddr
		reti										; Two-Wire serial interface (unused)

.org SPMRaddr
		reti										; SPM ready (unused)


.include "Interruptions.asm"


; =====================================
; == Routine d'interruption de reset ==
; =====================================

Init:

; --- Stack Pointer ---

        ldi     Work,low(RAMEND)            	    ; Charge le premier octet de l'adresse de fin de RAM dans Work
        out     SPL,Work                       		; Met cette valeur dans le stack pointer
        ldi     Work,high(RAMEND)               	; Charge le second octet
        out     SPH,Work                        	; 

; --- L'adresse haute (dont on ne sert pas - pour l'instant) de l'EEPROM ---

        clr     Work
        out     EEARH,Work
        
; --- Port A : Données de volume + Mute ---

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
        out     DDRA,Work                       	; 
		clr		VolRegG								; On met le volume au minimum
		out		PortVolume,VolRegG					; Le mute en profite également

; --- Port B : Switches et  encodeur -> C'est tout des entrées ---

        clr     Work			                	; Tout le port B est en entrée
        out     DDRB,Work                       	; 
        out     PORTB,Work                      	; et on profite pour désactiver les pull-ups sur les entrées

; --- Port G : Relais bal/unbal,relais tape/bypass et alim -> tout des sorties ---
; --- On commence par celui-là pour éviter les ronflettes

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
		sts		DDRG,Work							; Syntaxe un peu spéciale (sts au lieu de out) car c'est un port étendu (même chose pour le port F)

#if defined(BYPASS)
	    clr		Work								; Tout désactivé,
		sbr		Work,EXP2(RelaisBypass)				; sauf le relais de bypass pour commencer
		sts		PortAutresRelais,Work				; (Bypass désactivé quand le relais est activé)
#endif

; --- Port C : Les relais des entrées ---

        ldi     Work,$FF                        	; Toutes les pins sont des sorties
        out     DDRC,Work                       	; 
		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entrées
		out		PortRelaisIn,Work					; pour éviter de ronfler (enfin on espère)


; --- Port D : Switch On, Réception RC5, et lecture trigger en entrée ---
; ---          Latches Volume Droite et trigger out, et commande AD8402 en sortie ---

		ldi 	Work,0b11101100						; 1 pour les sorties, 0 pour les entrées
		out		DDRD,Work
		clr		Work								; et on désactive les pullups
		out		PORTD,Work							; sur les entrées de ce port
		
; --- Port E : Les 2 premiers bits en entrée (MOSI et MISO sont sur un bateau),
; ---          les 3 lignes de commande de l'afficheur en sortie,
; ---          le switch de menu en entrée, et le latch de volume et la loupiote de On en sortie
        
		ldi		Work,0b11011100						; 1 pour les sorties, 0 pour les entrées
		out 	DDRE,Work							
		clr		Work
		out		PORTE,Work							; et pas de pullups

; --- Port F : Les bits de données de l'afficheur -> Entrées/Sorties, mais pour l'instant, juste des sorties ---

		ldi		Work,$FF							; Syntaxe un peu spéciale pour les ports F et G de l'ATmega64
		sts		DDRF,Work							; utiliser sts/lds au lieu de out/in

; --- Pour les interruptions INT 0 et INT 1 ---

        clr     Work                            	; On inhibe les interruptions externes.....
        out     EIMSK,Work                      	; par mesure de précaution avant de changer leur mode de déclenchement

		ldi		Work,0b00000000						; INT0=niveau bas, INT1=niveau bas
		sts 	EICRA,Work							; (sts au lieu de out)

        ldi     Work,0b00010000                 	; Autorise le Sleep Mode en PowerDown 
        out     MCUCR,Work                      	; + les interruptions externes
 
        ldi     Work,0b00000011                 	; On réautorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

; --- Pour les timers ---

        ldi     Work,TimerStop
        out     TCCR0,Work                      	; On arrête le timer 0
        out     TCCR1A,Work                     	; On arrête le timer 1
        out     TCCR1B,Work
        sts     TCCR1C,Work
        out     TCCR2,Work                      	; On arrête le timer 2
        sts     TCCR3A,Work                     	; On arrête le timer 3
        sts     TCCR3B,Work
        sts     TCCR3C,Work

        
        ldi     Work,0b01000101                 	; On autorise les interruptions par overflow
        out     TIMSK,Work                      	; sur les timers 0,1 & 2
		ldi 	Work,0b00000100						; et aussi sur le timer 3
		sts		ETIMSK,Work

		clr		Work								; Interdit le mode asynchrone
		out		ASSR,Work							; sur les timers

; --- Switch off le comparateur ---

        sbi     ACSR,ACD            	            ; Eteint le comparateur analogique pour économiser l'énergie
		cbi		ACSR,ACIE							; C'est vrai, ça... Pas la peine de faire chauffer la bête inconsidérément :o)

; --- Même chose pour le convertisseur A/D ---

#if defined(M64)
		cbi		ADCSRA,ADEN							; Eteint le convertisseur Analogique/digital
		cbi		ADCSRA,ADIE
#endif

#if defined(M128)
		cbi		ADCSR,ADEN							; Eteint le convertisseur Analogique/digital
		cbi		ADCSR,ADIE
#endif

		sbi		PortAD8402,CS_AD8402				; Désactive le ChipSelect de l'AD8402

	    clr		IRSup								; Vide le registre IR sbézial

; -- On récupère les élements en EEPROM qui vont permettre de réveiller la bestiole par IR

RC5EEReadID:
		sbic	EECR,EEWE
		rjmp	RC5EEReadID
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRSytemID					; Ce qu'on cherche à atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRSytemID					; ID RC5 du système
		st		Z,Work2								; sauvegardée pour le réveil

RC5EEReadOn:
		sbic	EECR,EEWE
		rjmp	RC5EEReadOn

        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRStandbyOn				; Ce qu'on cherche à atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRStandbyOn					; Sauvergarde aussi
		st		Z,Work2								; la commande IR de mise en route

#if defined (BYPASS)
RC5EEReadBp:
		sbic	EECR,EEWE
		rjmp	RC5EEReadBp

        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_IRInputBypass				; Ce qu'on cherche à atteindre en EEPROM
		out		EEARL,Work1							; 
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Work2,EEDR							; lit la valeur en EEPROM et la met dans un registre

		ldi		ZH,RAM_Start						; Et si besoin,
		ldi		ZL,RAM_IRInputBypass				; sauvergarde aussi
		st		Z,WOrk2								; la commande IR de bypass
#endif

; =======================================================================================
; == A la première mise sous tension, recopie des paramètres "usine" stockés en EEPROM ==
; == On recopie toute l'EEPROM de 0x0000 à 0x01FF en 0x0400-0x5FF                      ==
; =======================================================================================

; Début de la zone d'écriture (0x0600)
		ldi		ZH,Default							; Adresse haute 
		clr 	ZL									; Adresse basse

; Lit d'abord le contenu de la première adresse destinée à l'écriture

CheckEEprom:
		sbic	EECR,EEWE							; Si EEWE n'est pas à 0
		rjmp	CheckEEprom							; on attend

		out     EEARL,ZL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH

		sbi		EECR,EERE							; Signale à l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; récupère la donnée

		cpi		Work,Vide							; Si l'adresse 0x0200 contient "Vide" (0x0F)
		brne	Main								; c'est qu'elle n'a pas été recopiée				
													; On va donc le faire
; Début de la zone de lecture (0x0000)
		clr		YL									; Adresse basse de lecture
		clr		YH									; Adresse haute de lecture

; Lecture de l'EEPROM

LoopReadEEpromInit:
		sbic	EECR,EEWE							; Si EEWE n'est pas à 0
		rjmp	LoopReadEEpromInit					; on attend

		out     EEARL,YL	  	                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,YH
		sbi		EECR,EERE							; Signale à l'EEPROM qu'on veut lire
													; (4 cycles d'horloge)
		in		Work,EEDR							; récupère la donnée

; Ecriture dans la zone haute de l'EEPROM

	    cli											; inhibe les interruptions
LoopWriteEEpromInit:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit prête pour l'écriture
        rjmp    LoopWriteEEpromInit
        
		out     EEARL,ZL		                    ; On charge "l'adresse" pour l'EEPROM
		out		EEARH,ZH
		out     EEDR,Work	                        ; ainsi que la donnée
        
        sbi     EECR,EEMWE                         	; Master Write Enable
        sbi     EECR,EEWE                         	; On écrit dans l'EEPROM (arrête le CPU pendant 2 cycles)
	    sei											; Réautorise les interruptions

		adiw	YL,0x01								; Incrémente les adresses de lecture
		adiw	ZL,0x01								; et d'écriture

		cpi		YH,Memory1							; Tant qu'on n'a pas atteint la fin de la zone de lecture
		brne	LoopReadEEpromInit					; On continue la boucle

LoopWriteEEpromInitEnd:
        sbic    EECR,EEWE                   	    ; On attend que l'EEprom soit prête pour l'écriture
        rjmp    LoopWriteEEpromInitEnd

; -- Terminé pour les initialisations

; *************************************************
; ***                                           ***
; *** Routine principale : Mise en route        ***
; ***                      Télécommande externe ***
; ***                      Boucle principale    ***
; ***                      Arrêt du biniou      ***
; ***                                           ***
; *************************************************

Main:   cli                        	    	        ; Pour démarrer, on interdit les interruptions
		clr		StatReg1							; Efface les deux registres d'état
		clr		StatReg2							; 
		sei											; Autorise les interruptions

#if defined(BYPASS)
		call	StartOrByeBypass					; On va configurer le relais de Bypass et l'entrée bypassée au repos
#endif

; -----------------------
; -- Boucle somnolente --
; -----------------------

Dodo :
		sbrs	StatReg2,FlagIRRec					; On a reçu une commande IR ?
		rjmp	WakeOnPowerSwitch					; 	- Non, alors on va voir si c'est le bouton On/StandBy qui nous a réveillé 

													; 	- Oui, alors on va voir si c'était pour se réveiller...
		ldi 	Work,1								; Pour la réception IR, on est obligé de redémarrer le Timer 2 pour effectuer le décodage
		out		TCCR2,Work							; Démarre le Timer 2 à CK (pas de prescaler) -> 1 cycle de comptage dure 250ns

		call	RecRC5								; On va voir quelle commande c'était

WakeOnPowerSwitch:

		sbrc    StatReg1,FlagPower	            	; On m'a réveillé pour allumer le biniou ?
													; (On a appuyé sur le bouton de mise en route ou on a recu une commande infrarouge qui a réveillé la bête)
		rjmp	AllezDebout							; Ben oui, alors faut y aller, pôvre mortel..
#if defined (BYPASS)
		sbrc	StatReg2,FlagIRBypass				; Nan, c'est pas du power on, mais est-ce du bypass pour les triggers ?
		call	TrigAmps							; ben vi, alors on va lancer les triggers
PowRelease:											; Si jamais "le triggage" était commandé par les boutons 
		sbis    PinSwitchOn,SwitchOn				; on attend le relâchement du bouton de power on
		rjmp    PowRelease							; Sinon on boucle

#endif
													; Ben non, rien de tout ça, alors on retourne se coucher... Chouette.
		clr		Work								; Au cas où on l'aurait démarré
		out		TCCR2,Work							; on arrête le timer 2

		cli											; Section atomique
		sbrc	StatReg1,FlagPower					; L'ISR a-t-elle positionné FlagPower ?
		rjmp	DodoWake							; Oui -> On se réveille
		clr		StatReg1							; Non -> Efface les registres d'état
		clr		StatReg2
        ldi     Work,0b00000011 	                ; On réautorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work          	            ; (Enable Interrupt Mask)
		sei
		rjmp	Dodo								; et se rendort aussi sec...

DodoWake:
		sei
		rjmp	AllezDebout							; On se réveille !

; -----------------------------------------
; -- Le plus dur : la phase de réveil... --
; -----------------------------------------

AllezDebout:

; -- On se réveille en douceur

		ldi     Work,50		        				; On attend un petit peu avant de se lancer
Wait1:	dec     Work
		brne    Wait1

; ----------------------------------------------------------
; -- Pendant 2 secondes, on teste si on a un second appui --
; -- sur le bouton PowerOn, pour savoir si on allume les  --
; -- amplis ou bien seulement l'ampli casque              --
; ----------------------------------------------------------

		clr		Work
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		st      Z,Work			        			; Stocke 0 en Ram (indicateur d'un second appui) 

        ldi     Work,DeuxSecHi                 	 	; On commence par fixer la période de 2 secondes 
        sts     TCNT3H,Work	                		; 
        ldi     Work,DeuxSecLo                  	; Pour l'instant, les interruptions INT0 et INT1 sont inhibées,
        sts     TCNT3L,Work                     	; on ne les autorisera qu'une fois les 2 secondes écoulées

        sbr		StatReg2,EXP2(FlagWait)				; On met a 1 le flag d'attente dans le registre d'etat
                                                	; c'est lui qui va nous servir a tester la fin des 2 secondes

        ldi     Work,TimerDiv		     	    	; On démarre le Timer 3 avec CK/1024
        sts     TCCR3B,Work                     	; et il va compter pendant 2 secondes
                                                	; le temps de voir si on appuie une seconde fois sur
                                                	; le bouton Power On
        
; -- On n'oublie pas d'autoriser les interruptions externes --

        ldi     Work,0b00000001                 	; On autorise seulement INT0 (bouton power) pendant le démarrage
        out     EIMSK,Work                      	; INT1 (IR) sera activé plus tard dans MainLoop

; --------------------------------------------------------------------------------------
; -- On commence par fixer la luminosité au minimum avant l'alimentation du backlight --
; -- pour éviter un "flash" au démarrage                                              --
; --------------------------------------------------------------------------------------

#if defined(LCD)
		ldi		Work,ContrasteMaxi					; Contraste au mini
		call	SetContrast							; On envoie ça 

		ldi		Work,0								; Luminosité à 0
		call	SetBrightness						; On envoie ça au potar numérique
#endif
		 
; -- On alimente les relais et la Led de Power On

		lds		Work,PortRelaisAlim
		sbr		Work,EXP2(RelaisAlim)				; C'est un port étendu, alors on utilise la méthode alternative...
		sts		PortRelaisAlim,Work					; On fait attention de conserver le bypass en état (il est sur ce port)

		rcall	Attendre							; On attend qq dizaines de ms avant de passer à la suite
#if defined(VFD)
	    rcall	Attendre
#endif
		sbi		PortLedOn,LedOn						; Et on allume la Led

#if defined(BYPASS)
;		clr		Work								; On fait passer tous les relais d'entrée
;		out		PortRelaisIn,Work					; au repos (on coupe tout) pour annuler le bypass
;
;		call	Attendre							; Légère attente...
;
;		lds		Work,PortAutresRelais				; Récupère l'état des autres relais
;		sbr		Work,EXP2(RelaisBypass)				; et désactive le relais de bypass
;		sts		PortAutresRelais,Work				; (Bypass désactivé quand le relais est activé)
#endif

; ================================
; === Démarrage de l'afficheur ===
; ================================

; --- On initialise l'afficheur

	    call	DisplayInit

; -- On écrit dans la RAM de l'afficheur pour définir les caractères accentués

		call 	DisplayCGRamDefaut

; ==============================================================================================
; == Ensuite, on recopie en RAM les valeurs de config et les commandes RC5 qui sont en EEPROM ==
; ==============================================================================================

		call	EEPromToRam

; =====================================================
; == Son et lumière.... Mise en route de l'afficheur ==
; =====================================================

; -- On fixe le contraste

#if defined (LCD)
		ldi		Work,ContrasteMaxi					; Récupère la valeur stockée en RAM dans Work
		call 	SetContrast							; et envoie ça sur le potar numérique
#endif

; -- La lumière à zéro --

#if defined(VFD)
		call	DisplayOff
#endif

		ldi		Work,0								; On commence à Zéro
		call 	SetBrightness						; et envoie ça sur le potar numérique
#if defined(VFD)
		call 	Attendre
#endif

; -- On affiche le message de bienvenue          --
; -- La luminosité est au minimum pour l'instant --

		ldi		Work,0
		call	DisplayPlaceCurseur
		ldi		ZH,Ram_Start
		ldi		ZL,RAM_Welcome_M
		call	DisplayAfficheChaineRAM

		ldi		Work,0								; On commence à Zéro
		call 	SetBrightness						; et envoie ça sur le potar numérique

#if defined(VFD)
		call 	Attendre
		call 	DisplayOn
#endif

#if defined(LCD)
; -- On augmente progressivement le contraste

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce paramètre en RAM

		ld		Work1,Z								; Récupère la valeur stockée en RAM dans Work1
		ldi		Work,ContrasteMaxi					; Contraste minimum

BoucleStartContrast:
		call 	SetContrast							; et envoie ça sur le potar numérique

		ldi		Count1,WaitBright
		rcall	MyWait								; Petite temporisation

		dec		Work								; Tant qu'on n'est pas arrivé au contraste final
		cpse	Work1,Work
		brne	BoucleStartContrast					; On boucle			
#endif

; -- On fixe la luminosité du backlight de l'afficheur - La valeur est en RAM
; -- On démarre de la luminosité minimale pour augmenter vers la valeur finale

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM

		ld		Work1,Z								; Récupère la valeur stockée en RAM dans Work1
		ldi		Work,0								; On commence à Zéro

BoucleStartBrightness:
		call 	SetBrightness						; et envoie ça sur le potar numérique

	    cpi		Work1,0								; Si Le brightness est à zéro au départ
		breq	SetStartBalance						; pas besoin d'augmenter... (Merci Philby ;) )

#if defined(LCD)
		mov		Count1,Work1
		sub		Count1,Work
		rcall	MyWait								; Petite temporisation
#endif
#if defined(VFD)
		ldi		Work2,VFDBrightDelayS
WaitVFD:
		rcall	Attendre							; Petite temporisation
		dec		Work2
		brne	WaitVFD
#endif

		inc		Work								; Tant qu'on n'est pas arrivé à la valeur finale,
		cpse	Work,Work1							; on augmente la luminosité
		rjmp	BoucleStartBrightness				

		rcall 	SetBrightness						; et on a finalement atteint le max

; ==========================================================================================
; == Balance de volume et délai de MBB récupérés depuis la RAM et mis dans des registres  ==
; ==========================================================================================

SetStartBalance:

; --- On copie dans un registre la valeur de la balance qui est en RAM. Ca sera plus rapide pour la suite

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Balance						; Adresse de la valeur en RAM
		ld		BalanceReg,Z						; et on met la valeur dans le register BalanceReg

; --- Copie dans des registres des délais de potar pour le Make Before Break

		ldi		ZL,RAM_DelaiVolume					; Pointe sur la bonne adresse de Ram
		ld		DelayPot,Z							; et met ça dans le registre
		ldi		ZL,RAM_DelaiRecolleVol				; Pointe sur la bonne adresse de Ram
		ld		SeqMBB,Z							; et met ça dans le registre

; ===================================
; == Valeur du volume au démarrage ==
; ===================================

; -- D'abord, initialisation de l'encodeur (Stockage de sa position initiale) ---

		call 	InitEncodeur

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartVolume					; Adresse pour le comportement du volume au démarrage
		ld		Work,Z								; et on récupère la valeur

		cpi		Work,0								; Volume au minimum ?
		brne	VolTest								; 	- Non, alors on teste les autres possibilités
		clr		VolReg								; 	- Oui, alors on met le registre de volume au minimum
		rjmp	StartIns							; et passe à la suite

VolTest:
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_VolumePreset					; Si on arrive là, de toute façon, il faut consulter la valeur stockée
		ld		VolReg,Z							; dans la valeur de preset (c'est soit un preset, soit la dernière valeur de volume)
		
; ==================================================
; == Entrée active au démarrage et télécommandage ==
; ==================================================

StartIns: 

; -- On récupère en RAM le numéro de l'entrée à activer à l'allumage
; -- Puis on envoie un trigger sur la télécommande de cette entrée si nécessaire
; -- Et finalement, on active le relais d'entrée correspondant dans le preamp

		ldi		ZH,Ram_Start
		ldi		ZL,RAM_StartInput					; Récupère la valeur en RAM
		ld		Work1,Z

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_AncienneEntreeActive			; On feinte pour les triggers
		ldi		Work,4								; en faisant croire que c'était l'entrée tape/bypass qui était activée
		st		Z,Work								; et on met ça en RAM

		call	StartRelays
		call	Attendre							; Attend un peu avant de coller le relais de signal
		call	ActiveRelaisEntree					; et va activer le relais de l'entrée sélectionnée

		call	SetBalance							; Modifie les registres droits et gauche en fonction de la balance
		call 	SetStartVolume						; et fixe le volume


; -------------------------------------------------------------------------------
; -- On va maintenant attendre l'overflow du Timer 3 (bit T de SREG passe à 0) --
; -- tout en testant si on a appuyé une deuxième fois sur le bouton Power On   --
; -------------------------------------------------------------------------------

WaitForT:
		sbrc	StatReg2,FlagWait					; Si le flag d'attente est à zéro, on passe à la suite
        rjmp    WaitForT           		 	        ; Sinon, on continue la boucle

; ---------------------------------------------------               
; -- Les 2 secondes fatidiques sont écoulées.      --
; -- On va donc télécommander l'ampli si besoin,   --
; -- activer le relais de sortie et finalement se  --
; -- lancer dans la boucle de scrutation           --
; ---------------------------------------------------               

InitTriggers:
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
        ld      Work3,Z						        ; On teste si on a appuyé deux fois
        cpi     Work3,0
        breq    TrigLesAmplis      		        	; Non, on télécommande l'ampli
		call	TrigLeCasque						; Oui, alors on adresse l'ampli casque				
		rjmp 	EnRoute

TrigLesAmplis:
	    call 	TrigAmps

; -- Derniers trucs avant la mise en route --

EnRoute:
		call	AfficheVolume						; Affichage du volume	 
		call	AfficheEntree						; Affichage de l'intitulé de l'entrée

		clr		IdleCounter							; initialise le compteur d'Idle

		MacroMuteOff								; Passe le relais de mute à 1 (La sortie devient active)
		cbr		StatReg1,EXP2(FlagMute)				; Signale qu'on n'est plus en mute (bit à 0)

; -- On lance le timer 2 pour les timings IR

		ldi 	Work,1
		out		TCCR2,Work							; Démarre le Timer 2 à CK (pas de prescaler) -> 1 cycle de comptage dure 250ns

; -- Et puis le timer 3 pour le passage en mode Idle --

		call	StartIdle

; -- On n'oublie pas d'autoriser les interruptions externes --

        ldi     Work,0b00000011                 	; On autorise les interruptions externes INT 0 et INT1 
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

		cbr		StatReg2,EXP2(FlagIRRec)			; Réinitialise le Flag de réception IR	

		clr		IRSup								; Efface le registre de speedup

; ======================================================
; == Et c'est parti mon kiki...                       ==
; == La boucle principale qu'on va parcourir sans fin ==
; ======================================================

MainLoop:

; -- On vérifie d'abord qu'on ne doit pas s'arrêter --

        sbrs    StatReg1,FlagPower             		 ; Bit 0 de StatReg1 à 0 ?
        rjmp    FallAsleep                     		 ; Oui, alors on arrête le biniou

; -- Si le flag de réception IR est positionné, c'est qu'on a reçu une commande Infra-Rouge

		sbrc	StatReg2,FlagIRRec					; Flag de réception IR à 1 ?
		call	RecRC5								; 	- Bé oui, alors on va ouar ce que c'est

        sbrs    StatReg1,FlagPower             		 ; Si jamais l'ordre IR était d'arrêter le biniou
        rjmp    FallAsleep                     		 ; on y va immédiatement

; -- Faut traiter les autres possibilités ?

#if defined (BYPASS)
		sbrc	StatReg2,FlagBypass					; Si on est en bypass, on ne peut pas faire autre chose
		rjmp	TestBypass							; que d'attendre un appui sur le bouton Bypass
#endif
		sbrc	StatReg2,FlagIRMute					; On ne peut faire les autres actions que si on n'a pas reçu une commande IR de Mute
		rjmp	Mainloop							; sinon, pas la peine d'aller plus loin

; -- Veut-on passer en mode menu ? --

		sbis	PinMenu,SwitchMenu					; Un appui sur le bouton de menu ?
		call	Menu								; Oui -> Alors on passe en mode menu
		sbrc	StatReg1,FlagMenu					; Revient-on d'une balade dans le menu ?
		rjmp	AfterMenu							; 	- Oui -> On finit le travail

; -- A-t-on appuyé sur un des boutons des entrées ? --

		sbis	PinsSwitches,SwitchIn1				; On a appuyé sur l'entrée 1 (actif à 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn2				; On a appuyé sur l'entrée 2 (actif à 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn3				; On a appuyé sur l'entrée 3 (actif à 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

		sbis	PinsSwitches,SwitchIn4				; On a appuyé sur l'entrée 4 (actif à 0) ?
		rcall	ChangeEntree						; Oui, alors on y va

TestBypass:
		sbis	PinsSwitches,SwitchTapeOrBypass		; On a appuyé sur le bouton Tape/Bypass (actif à 0) ?
#if defined (BYPASS)
		rcall	BypassOnOff							; Oui, alors on va voir le bypass où qu'il en est
#else
		rcall	ChangeEntree						; Oui, alors on va chager d'entrée pour tape
#endif

#if defined (BYPASS)
		sbrc	StatReg2,FlagBypass					; Si on est en bypass,
		rjmp	Mainloop							; on ne peut pas non plus toucher au volume
#endif

; -- On a touché au volume ? --

		rcall 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter le volume
		sbrc	StatReg1,FlagDecremente				; ou le décrémenter ?
		rcall	ChangeVolume						; l'un des deux...

		rjmp 	MainLoop							; et on boucle

; -- On remet tout comifo après un passage dans le menu --

AfterMenu:
		cbr		StatReg1,EXP2(FlagMenu)				; On n'est plus en mode menu
		rcall	AfficheEntree						; alors on remet l'affichage
		rcall	AfficheVolume						; en mode normal,
		rcall	StartIdle							; On relance le timer de "fout rien"
		rjmp	MainLoop							; et on reboucle à l'envie

; ----------------------------------------- 
; -- On se prépare à arrêter la bestiole --
; ----------------------------------------- 

FallAsleep:
        clr     Work			                 	; On inhibe les interruptions externes le temps de s'arrêter
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle était en train de tourner,
		rcall	StopIdle							; alors on l'arrête
		rcall	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosité

GoToBed:

; -- On arrête tous les timers

		ldi		Work,TimerStop
		out		TCCR0,Work							; On arrête le Timer 0
		out		TCCR1B,Work							; On arrête le Timer 1
		out		TCCR2,Work							; On arrête le Timer 2
		sts		TCCR3B,Work							; On arrête le Timer 3

; -- On affiche le message de fin --

		call	DisplayClear
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Bye_M
		call	DisplayAfficheChaineRAM

; -- On met le volume au minimum, puis on coupe la sortie --

		ldi		Work,0b10000000						; Pour ne pas couper la sortie (relais de mute reste activé)

		out		PortVolume,Work						; Le volume sur le port des relais
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG

		out		PortVolume,Work						; Le volume de la voie droite sur le port des relais
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

		rcall	Attendre							; on attend un petit peu
		MacroMuteOn									; Passe le relais de mute à 0 (Muté au repos)
		rcall	Attendre

; -- On coupe les relais de Tape/Bypass et d'entrée asymétrique

		lds		Work,PortRelaisAsym				
		cbr		Work,EXP2(RelaisAsym)
#if ! defined(BYPASS)
		cbr		Work,EXP2(RelaisTape)
#endif
		sts		PortRelaisAsym,Work

; -- On diminue progressivement la luminosité de l'afficheur

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de ce paramètre en RAM

		ld		Work1,Z								; Récupère la valeur stockée en RAM dans Work1

BoucleEndBrightness:
		mov		Work,Work1							; Transfère dans le bon registre
		rcall 	SetBrightness						; et envoie ça sur le potar numérique

		ldi		Count1,WaitBrightEnd
#if defined(LCD)
		rcall	MyWait								; Petite temporsiation
#endif
#if defined(VFD)
		ldi		Work2,VFDBrightDelay
WaitVFDBye:
		rcall	Attendre							; Petite temporisation
		dec		Work2
		brne	WaitVFDBye
#endif

		dec		Work1								; Tant qu'on n'est pas arrivé à une luminosité de 0,
		brne	BoucleEndBrightness					; On la diminue				

		ldi		Work,0
		call	SetBrightness						; pour finalement arriver à 0

#if defined(LCD)
; -- On diminue progressivement le contraste

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartContrast				; L'adresse de ce paramètre en RAM

		ld		Work1,Z								; Récupère la valeur stockée en RAM dans Work1

BoucleEndContrast:
		mov		Work,Work1							; Transfère dans le bon registre
		rcall 	SetContrast							; et envoie ça sur le potar numérique

		ldi		Count1,WaitBrightEnd
		rcall	MyWait								; Petite temporisation

		inc		Work1								; Tant qu'on n'est pas arrivé à un contrast min,
		cpi		Work1,ContrasteMaxi
		brne	BoucleEndContrast					; On la diminue				
#endif

; -- On va éteindre tous les appareils si ils étaient allumés

		clr		Work								; Comptage des trigs à partir de 0
NextRC:
		rcall 	Attendre							; Petite attente pour la stabilité
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbis	PinTriggerIn,LectureTrigIn			; Si l'appareil était déjà allumé,
		rjmp	FinRC								; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la télécommande

	    ldi		Work1,8
WaitByRC:
		call	Attendre							; Le temps que l'impulsion fasse effet
		dec 	Work1
		brne	WaitByRC

		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro
FinRC:
		inc		Work								; Incrémente l'adresse
		cpi		Work,8								; Dernier appareil ?
		brne	NextRC								; 	- Non, on continue la boucle

; -- Si la politique de volume au démarrage était de stocker le dernier volume, on va le faire --

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartVolume
		ld		Work,Z								; Récupère cette politique 

		cpi		Work,2								; Faut stocker le volume ?
		brne	StoreInput							; 	- Non -> on va voir si il faut stocker l'entrée

		sbrs	StatReg2,Flag6dB					;   - Oui, mais est-ce que ce volume était augmenté de 6dB pour une entrée asymétrique ? 
		rjmp	WriteEndVolume						; 		- Non, alors on le stocke directement

		ldi		Work,SixdBMore						; 		- Oui, alors faut les enlever
		cp		VolReg,Work							; 	  		si on peut...
		brge	Substract6dBEndVol					;     		et là, on peut.
		clr		VolReg								; 			sinon on le met au min
		rjmp	WriteEndVolume						; 			et on passe à la suite

Substract6dBEndVol:
		sub		VolReg,Work							; On retranche les 6dB

WriteEndVolume:
		mov		Work2,VolReg						; On récupère la valeur de volume dans Work2	
		ldi		Work,EE_VolumePreset				; et l'adresse en EEPROM
		rcall	WriteEEprom					

; -- Y Faut-y stocker l'entrée active ?

StoreInput:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		ld		Work,Z								; Récupère le comportement de l'entrée au démarrage 
	
		cpi		Work,0								; C'est une entrée fixe ?
		breq	ByeBye								; 	- Oui -> On finit de finir

		ldi		ZH,RAM_Start						; 	- Nan -> On stocke l'entrée actuellement en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work2,Z								; Elle est là

#ifndef BYPASS
		cpi		Work2,4								; C'est l'entrée Bypass ?
		breq	ByeBye								; Vi, alors on stocke pas
#endif
		ldi		Work,EE_StartInput
		rcall	WriteEEprom							; Et on la met en EEPROM

; - On éteint l'afficheur et on coupe l'alim des relais --
 
ByeBye:
		call	DisplayOff

; -- Et finalement, on coupe le relais d'alim  et la led "On" --

		lds		Work,PortRelaisAlim				
		cbr		Work,EXP2(RelaisAlim)
		sts		PortRelaisAlim,Work

		cbi		PortLedOn,LedOn

; -- Et finalement, soit on s'occupe du bypass ou on coupe toutes les entrées

#if defined (BYPASS)
		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entrées
		out		PortRelaisIn,Work					; pour éviter de ronfler (enfin on espère)
		call	StartOrByeBypass					; et on met le bypass si besoin
#else
		clr		Work
		out		PortRelaisIn,Work					; toutes les sorties à 0
#endif

; -- Et on s'endort complètement

FaisDodo:
	    clr		IRSup								; Vide le registre IR spécial

		clr		StatReg1							; efface les registres d'état
		clr		StatReg2							; 
        ldi     Work,0b00000011                 	; On réautorise seulement les 2 interruptions externes INT 1 et INT 0
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

		rjmp	Dodo								; Et on s'endort complètement...

; -- Chhhhhhhhhhuuuuuuutttttttt............

; ================================================================================================================================

; ==============================
; == Petites routines annexes ==
; ==============================

; -----------------------------------------------------
; - Envoi de triggers sur les amplis ou ampli casques - 
; -----------------------------------------------------
 
TrigAmps:

; -- Allumage de l'ampli ou de l'ampli casque --

; -- Avant d'envoyer l'impulsion d'allumage,
; -- on va interroger les amplis au cas où ils seraient déjà allumés
; -- Si c'est le cas, pas la peine d'envoyer l'impulsion, sinon ça les éteindrait 

		ldi		Work, AdresseAmpliG					; Adresse de l'ampli de gauche
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
#if defined (BYPASS)
		sbrs    StatReg1,FlagPower	            	; Est-ce que le biniou est éteint ?
		rjmp	SendTAG								; Oui -> On n'interroge pas, on commute directement
#endif
		sbic	PinTriggerIn,LectureTrigIn			; Si l'ampli était déjà allumé,
		rjmp	NextAmp								; Pas besoin de le refaire...
SendTAG:
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la télécommande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro

NextAmp:
		ldi		Work, AdresseAmpliD					; Adresse de l'ampli de droite
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
#if defined (BYPASS)
		sbrs    StatReg1,FlagPower	            	; Est-ce que le biniou est éteint ?
		rjmp	SendTAD								; Oui -> On n'interroge pas, on commute directement
#endif
		sbic	PinTriggerIn,LectureTrigIn			; Si l'ampli était déjà allumé,
		ret											; Pas besoin de le refaire...
SendTAD:
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la télécommande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro

		ret											; et on passe à la suite

TrigLeCasque:
		ldi		Work, AdresseCasque					; Adresse de l'ampli casque
		out		PortAdresTrig,Work					; Met l'adresse des amplis sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbic	PortTriggers,LectureTrigIn			; Si l'ampli était déjà allumé,
		ret											; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la télécommande
		call 	Attendre
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro

		ret

; -----------------------------------------------------------------------------
; -- Démarrage du Timer 3 pour la temporisation avant de passer en mode Idle --
; -----------------------------------------------------------------------------

StartIdle:

		sbrc	StatReg2,FlagIRMute					; Si on vient de passer en Mute, on ne lance pas l'Idle
		ret

		sbrc	StatReg1,FlagBalance				; Si on était en train de modifier la balance
		ret											; on ne le lance pas non plus

 		sbrs	StatReg1,FlagPower					; Si la bestiole était éteinte ou va s'éteindre, on ne s'occupe pas de l'Idle
		ret

		ldi		ZH,RAM_Start						; Récupère la durée du délai avant timeout
		ldi		ZL,RAM_IdleTimeOut					; 
		ld		Work,Z								; Et met ça dans un registre 

		cpi		Work,0								; Si la valeur n'est pas zéro,
		brne	IdleOK								; On va lancer le compteur de timeout
		ret											; sinon, on s'en va
IdleOK:
		mov		IdleCounter,Work					; On transfère la valeur dans le bon registre

WaitEndMBB:
		sbrc	StatReg2,FlagMBB					; Si jamais, on était en train d'attendre la fin d'un Make Before Break
		rjmp	WaitEndMBB							; On va laisser cette étape se terminer...

        ldi     Work,QuinzeSecHi					; Quinze secondes de timeout pour le timer3
        sts     TCNT3H,Work							
		ldi		Work,QuinzeSecLo
        sts     TCNT3L,Work

		sbr		StatReg1,EXP2(FlagIdle)				; On positionne le flag qui indique qu'on est en train d'attendre

        ldi     Work,TimerDiv		        		; On démarre le Timer 1 avec CK/1024
        sts     TCCR3B,Work                     	; et il va compter pendant à peu près 15 secondes avant l'overflow
	
		ret

; -----------------------------------
; -- Arrêt du Timer 3 du mode Idle --
; -----------------------------------

StopIdle:

        ldi     Work,TimerStop						; On arrête le Timer
 		sts		TCCR3B,Work
		
		cbr		StatReg1,EXP2(FlagIdle)				; On passe le flag à 0

		ret

; ------------------------------
; -- Petite routine d'attente --
; ------------------------------

Attendre:
        ldi     Count1,255
Wait3_0:ldi     Count2,255
Wait3_1:dec     Count2
        brne    Wait3_1
        dec     Count1
        brne    Wait3_0

		ret

; ======================================================
; == Routine d'attente un peu plus générale           ==
; == On charge	Count1 avce une valeur entre 0 et 255 ==
; ======================================================

MyWait:
		ldi     Count2,255
MyWait_1:
		dec     Count2
        brne    MyWait_1
        dec     Count1
        brne    MyWait

		ret

;===================================
; == Impulsion de trig des amplis ==
; ==================================

TrigWait:
		nop
		nop
		nop

		ret

; ************************************
; ***                              ***
; *** Routine d'écriture en EEprom ***
; ***                              ***
; *** L'adresse (basse) est dans   ***
; *** le registre Work             ***
; ***                              ***
; *** La donnée est dans Work2     ***
; ***                              ***
; ************************************

WriteEEprom:
	    cli										; inhibe les interruptions
WaitWEEProm:
        sbic    EECR,EEWE                       ; On attend que l'EEprom soit prête pour l'écriture
        rjmp    WaitWEEProm

		out     EEARL,Work                      ; On charge "l'adresse" pour l'EEPROM
		out     EEDR,Work2                      ; ainsi que la donnée
        
        sbi     EECR,EEMWE                      ; Master Write Enable
        sbi     EECR,EEWE                       ; On écrit dans l'EEPROM           

                                                ; (arrête le CPU pendant 2 cycles)
	    sei										; Réautorise les interruptions
		ret                                     ; et on a fini
        

; ************************************
; ***                              ***
; *** Routine de lecture en EEprom ***
; ***                              ***
; *** L'adresse (basse) est dans   ***
; *** le registre Work             ***
; ***                              ***
; *** La donnée est dans Work2     ***
; ***                              ***
; ************************************

ReadEEprom:
		sbic	EECR,EEWE						; Si EEWE n'est pas à 0
		rjmp	ReadEEprom						; on attend

		out     EEARL,Work                      ; On charge "l'adresse" pour l'EEPROM

		sbi		EECR,EERE						; Signale à l'EEPROM qu'on veut lire
												; (4 cycles d'horloge)
		in		Work2,EEDR						; récupère la donnée

		ret										; et ouali

; Routines pour l'AD8402 - Inutilisé avec un VFD
#if defined(LCD)
.include "AD8402.asm"
#endif

; Routines pour l'afficheur
#if defined (LCD)
.include "LCD.asm"
#else
.include "VFD.asm"
#endif

; Routines pour le contrôle de volume
.include "Volume.asm"

; Routines pour la lecture de l'encodeur rotatif
.include "Encodeur.asm"

; Routines pour la réception RC5
.include "RC5.asm"

; Routines pour la gestion des relais d'entrée/sorties
.include "Inputs.asm"

; Routines d'affichage du volume et des intitulés des entrées
.include "Affichage.asm"

; Routines de conversion Binaire-BCD
.include "BinaireToBCD.asm"

; Routine de configuration de la bestiole
.include "Menu.asm"

; Les différents messages à afficher
.include "Messages.asm"

