; ============================================
; === Les menus de configuration du biniou ===
; ============================================

Menu:

; -- On commence par tester à nouveau le bouton de menu pour le debounce

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		ret											; non,fausse alerte -> Cassos

        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle était en train de tourner,
		call	StopIdle							; alors on l'arrête
		call	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosité

		call	IRClearIRSup						; Autre action que IR -> Efface le registre de speedup

; -- On est bien en mode menu

WaitMenu:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenu							; On attend le relachement du bouton de menu

; -- Si jamais on était en mute (par IR), on rétablit le mode normal

		sbrs	StatReg2,FlagIRMute					; On est déjà en mute ?
		rjmp	MenuDebut							; 	-Non -> Alors, quetattends ?
													; 	-Oui, alors on réactive la sortie
		MacroMuteOff
		cbr		StatReg1,EXP2(FlagMute)				; Signale qu'on n'est plus en mute (bit à 0)
		cbr		StatReg2,EXP2(FlagIRMute)			; efface le bit de mute du registre IR

; -- Avant tout, on inhibe les interruptions externes

MenuDebut:
		clr     Work
		out     EIMSK,Work

		sbr		StatReg1,EXP2(FlagMenu)				; on indique qu'on passe en mode menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Debut de seconde ligne

		ldi		ZH,HIGH(MenuVolumeSetupMessage*2)
		ldi		ZL,LOW(MenuVolumeSetupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		clr		MenuReg1

LoopLevel0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeSetupMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir ?
		rjmp	ExitMenu							; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevel0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevel0							; Non, on boucle

		rjmp	WhatMenuToEnter						; sinon on entre dans le menu de config qu'il faut
			
ChangeSetupMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMenuReg1							; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMenuReg1							; vesr le bas ?
		rjmp	LoopLevel0							; Aucun des deux, alors cassos

IncMenuReg1:										; Incrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,5								; c'est le dernier menu ?
		brne	DoIncMR1							; non, alors on peut incrémenter sans pb

		clr		MenuReg1							; sinon, on le repasse à 0		
		rjmp	AfficheMenuLevel0					; et on va afficher la chaine qu'il faut
DoIncMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	AfficheMenuLevel0					; et on va afficher la chaine qu'il faut

DecMenuReg1:										; Décrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,5
		mov		MenuReg1,Work						; sinon, on le repasse à 5		
		rjmp	AfficheMenuLevel0					; et on va afficher la chaine qu'il faut
DoDecMR1:
		dec		MenuReg1							; On décrémente le registre

AfficheMenuLevel0:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 3)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; Curseur au début de la seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; On met le registre dans un registre immédiat

TestMenuVolume:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuInputs						; Nan...

		ldi		ZH,HIGH(MenuVolumeSetupMessage*2)	; Oui, c'est 0
		ldi		ZL,LOW(MenuVolumeSetupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevel0							; et on continue la boucle

TestMenuInputs:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuDisplay						; Nan...

		ldi		ZH,HIGH(MenuInputSetupMessage*2)	; Oui, c'est 1
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevel0							; et on continue la boucle

TestMenuDisplay:

		cpi		Work,2								; C'est 2 ?
		brne	TestMenuRC5							; Nan...

		ldi		ZH,HIGH(MenuDisplaySetupMessage*2)	; Oui, c'est 2
		ldi		ZL,LOW(MenuDisplaySetupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevel0							; et on continue la boucle

TestMenuRC5:

		cpi		Work,3								; C'est 3 ?
		brne	TestMenuMessages					; Nan...

		ldi		ZH,HIGH(MenuRC5SetupMessage*2)		; Oui c'est 3
		ldi		ZL,LOW(MenuRC5SetupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevel0							; et on continue la boucle

TestMenuMessages:

		cpi		Work,4								; C'est 4 ?
		brne	TestMenuEEProm						; Nan...

		ldi		ZH,HIGH(MenuMessagesSetup*2)		; Oui c'est 4
		ldi		ZL,LOW(MenuMessagesSetup*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevel0							; et on continue la boucle

TestMenuEEProm:

		ldi		ZH,HIGH(MenuEEPROMSetup*2)			; Ici, c'est obligatoirement 5
		ldi		ZL,LOW(MenuEEPROMSetup*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevel0							; et on continue la boucle

WhatMenuToEnter:

		mov		Work,MenuReg1						; Transfert en immédiat

TestMVo:cpi		Work,0								; si c'est 0
		brne	TestMIn
		rjmp	EnterMenuVolume						; on va triturer le menu de volume

TestMIn:cpi		Work,1								; si c'est 1
		brne	TestMDi
		rjmp	EnterMenuInputs						; on va triturer le menu des entrées

TestMDi:cpi		Work,2								; si c'est 2
		brne	TestMRC
		rjmp	EnterMenuDisplay					; on va triturer le menu de l'afficheur
		
TestMRC:cpi		Work,3								; si c'est 3
		brne	TestMMe
		rjmp	EnterMenuRC5						; on va triturer le menu de l'infra rouge

TestMMe:cpi		Work,4								; si c'est 4
		brne	TestMEE
		rjmp	EnterMenuMessages					; on va triturer le menu des messages

TestMEE:cpi		Work,5								; si c'est 5
		brne	TestMVo
		rjmp	EnterMenuEEProm						; on va triturer le menu de l'EEPROM

EnterMenuVolume:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolume						; Sinon,on revient au bon endroit

		call	MenuVolume							; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Debut de seconde ligne

		clr		Work
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolume						; Sinon,on revient au bon endroit

EnterMenuInputs:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputs						; Sinon,on revient au bon endroit

		call	MenuInputs							; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Debut de seconde ligne

		ldi		Work,1
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInputs						; Sinon,on revient au bon endroit

EnterMenuDisplay:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuDisplay						; et on revient au bon endroit

		call	MenuDisplay							; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Debut de seconde ligne

		ldi		Work,2
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuDisplay						; et on revient au bon endroit

EnterMenuRC5:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuRC5							; Sinon,on revient au bon endroit

		call	MenuRC5								; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Début de seconde ligne

		ldi		Work,3
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuRC5							; et on revient au bon endroit

EnterMenuMessages:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuMessages					; Sinon,on revient au bon endroit

		call	MenuMessages						; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Début de seconde ligne

		ldi		Work,4
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuMessages					; et on revient au bon endroit

EnterMenuEEProm:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuEEProm						; Sinon,on revient au bon endroit

		call	MenuEEPROM							; On y va

; -- Au retour, on réaffiche ce qu'il y avait avant d'entrer dans le menu

		ldi		Work,0								; Début de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSetupTopMessage*2)
		ldi		ZL,LOW(MenuSetupTopMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup

		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Début de seconde ligne

		ldi		Work,5
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuEEProm						; et on revient au bon endroit

ExitMenu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; Un appui sur l'annulation pour sortir ?
		rjmp	LoopLevel0							; Non, on replonge dans la boucle

WaitBeforeExitMenu:
		sbis	PinSwitchMC,SwitchMC				; Oui, on veut sortir, mais on va attendre d'avoir relaché le bouton d'annulation
		rjmp	WaitBeforeExitMenu					; pour ne pas redéclencher un interruption à la sortie

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

        ldi     Work,0b00000011                 	; On réautorise les interruptions externes INT 0 & INT 1
        out     EIMSK,Work                      	; (Enable Interrupt Mask)

		ret											; et on se casse

; ------------------------------------------------------
; -- Routine pour lancer le clignotement de la LED On --
; ------------------------------------------------------

LanceClignotementLED:

		ldi		Work,UneSecHi
		sts		TCNT3H,Work
		ldi		Work,UneSecLo
		sts		TCNT3L,Work
		ldi		Work,TimerLed								; et relance le timer en CK/64, si bien qu'il va compter 16 fois plus vite que pour CK/1024
		sts		TCCR3B,Work							; -> Prochaine interruption dans 1/16 de seconde (contre les 1 s à CK/1024)				

		ret

; -------------------------------------------------------
; -- Routine pour arrêter le clignotement de la LED On --
; -------------------------------------------------------

ArreteClignotementLED:

		clr		Work
		sts		TCCR3B,Work							; arrête le timer 3

		sbis	PortLedOn,LedOn						; si la led était éteinte
		sbi		PortLedOn,LedOn						; on l'allume

		ret											; et c'est tout

; Routines de configuration des paramètres de volume
.include "MenuVolume.asm"

; Routines de configuration des paramètres des entrées
.include "MenuInputs.asm"

; Routines de configuration des paramètres de l'afficheur
.include "MenuDisplay.asm"

; Routines de configuration des paramètres de réception RC5
.include "MenuRC5.asm"

; Routines de configuration des Messages affichés
.include "MenuMessages.asm"

; Routines de configuration des sauvegardes en EEPROM
.include "MenuEEProm.asm"
