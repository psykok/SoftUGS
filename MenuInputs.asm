; ================================================
; == Le menu pour le le paramétrage des entrées ==
; ================================================

MenuInputs :

WaitMenuInput:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuInput						; On attend le relachement du bouton de menu

; OK, on a lâché le bouton

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNoMessage*2)
		ldi		ZL,LOW(MenuInputNoMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les flèches de l'encodeur

		ldi		Work,0x4B							; Se place à la position
		call	DisplayPlaceCurseur					; où on écrit le numéro de l'entrée
		ldi		Char,'1'
		call	DisplayWriteChar

		clr		MenuReg1

LoopLevelI0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitInputMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelI0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevelI0							; Non, on boucle

		rjmp	WhatInputMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeInputMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncInpMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecInpMenuReg1						; vers le bas ?
		rjmp	LoopLevelI0							; Aucun des deux, alors cassos

IncInpMenuReg1:										; Incrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,(MaxInput+IMM)					; c'est le dernier menu ?
		brne	DoIncInpMR1							; non, alors on peut incrémenter sans pb

		clr		MenuReg1							; sinon, on le repasse à 0		
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut
DoIncInpMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut

DecInpMenuReg1:										; Décrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecInpMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,(MaxInput+IMM)
		mov		MenuReg1,Work						; sinon, on le repasse à MaxInput	
		rjmp	AfficheMenuInp						; et on va afficher la chaine qu'il faut
DoDecInpMR1:
		dec		MenuReg1							; On décrémente le registre

AfficheMenuInp: 									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 4)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

TestMenuInp:
		mov		Work,MenuReg1						; On met le registre dans un registre immédiat

		cpi		Work,MaxInput						; On veut paramétrer une des entrées ?
		brlo	TestMenuInpNb						; Oui, alors on y va
		rjmp	TestMenuInpSup						; Non, alors on s'occupe des autres menus entrée

TestMenuInpNb:

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNoMessage*2)
		ldi		ZL,LOW(MenuInputNoMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow						; et les flèches de l'encodeur

		ldi		Work,0x4B							; Se place à la position
		call	DisplayPlaceCurseur					; où on écrit le numéro de l'entrée
		mov		Char,MenuReg1
		subi	Char,-49
		call	DisplayWriteChar

		rjmp	LoopLevelI0							; et on continue la boucle

TestMenuInpSup:

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

#if defined(BYPASS)
		cpi		Work,(MaxInput+IMM)					; Si c'est le dernier menu,			
		brne	TestMenuInpBypass					; c'est l'entrée de Bypass qui est concernée
#endif
		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)		; Ici, c'est obligatoirement le paramétrage de l'entrée préférée
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelI0							; et on continue la boucle

#if defined(BYPASS)

TestMenuInpBypass:
		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuPrefInpBypassMessage*2)	; Message correspondant
		ldi		ZL,LOW(MenuPrefInpBypassMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur
		rjmp	LoopLevelI0							; et on continue la boucle
#endif

WhatInputMenuToEnter:

		mov		Work,MenuReg1						; Transfert en immédiat
		cpi		Work,MaxInput						; si c'est une des entrées
		brlo	EnterMenuInput						; on s'en occupe
		rjmp	EnterMenuInputSup					; sinon on les autres options

EnterMenuInput:										; on va triturer le menu de l'entrée

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInp							; Sinon,on revient au bon endroit

		rcall	MenuEntree							; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

;		clr		Work
;		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInp							; et on revient au bon endroit

EnterMenuInputSup:									; Autres options des entrées
#if defined(BYPASS)
		cpi		Work,(MaxInput+IMM)					; Si c'est plus de MaxInput			
		brne	TestMenuInpPrefBypass				; c'est l'entrée de Bypass qui est concernée
#endif

EnterMenuPrefInput:									; sinon, on va triturer le menu de l'entrée à l'allumage

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInpSup						; Sinon,on revient au bon endroit

		rcall	MenuStartInput						; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,(MaxInput+IMM)
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInpSup						; et on revient au bon endroit

#if defined(BYPASS)
TestMenuInpPrefBypass:								; c'est l'entrée de Bypass qui est concernée

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInpSup						; Sinon,on revient au bon endroit

		rcall	MenuBypassInput						; On y va

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputSetupMessage*2)
		ldi		ZL,LOW(MenuInputSetupMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,(MaxInput)
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuInpSup						; et on revient au bon endroit

#endif

ExitInputMenu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelI0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitInputMenu:
		sbis	PinSwitchMC,SwitchMC				; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitInputMenu				; des sorties de menu en cascade

		ret											; on se casse de ce menu

; =========================================================
; == Le Menu de configuration pour une entrée quelconque ==
; == Le numéro de l'entrée considérée est dans MenuReg1  ==
; ==                                                     ==
; ==    - Navigation entre les paramètres par l'encodeur ==
; ==    - Entrée dans un sous-menu par le bouton Menu    ==
; ==    - Remontée au niveau supérieur par "StandBy/on"  ==
; =========================================================

MenuEntree:

WaitMenuEntree:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntree						; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur					; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputName*2)
		ldi		ZL,LOW(MenuInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		clr 	MenuReg2

LoopLevelI1:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputMenuL1					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitEntreeMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelI1							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevelI1							; Non, on boucle

		rjmp	WhatInputMenuToEnterL1				; sinon on entre dans le menu de config qu'il faut
			
ChangeInputMenuL1:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncInpMenuReg2						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecInpMenuReg2						; vers le bas ?
		rjmp	LoopLevelI1							; Aucun des deux, alors cassos

IncInpMenuReg2:										; Incrémentation du numéro de menu
		mov		Work,MenuReg2						; transfert dans un registre immédiat
		cpi		Work,4								; c'est le dernier menu ?
		brne	DoIncInpMR2							; non, alors on peut incrémenter sans pb

		clr		MenuReg2							; sinon, on le repasse à 0		
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DoIncInpMR2:
#ifndef	BYPASS
		mov		Work2,MenuReg1
		cpi		Work2,MaxInput-1					; On est sur l'entrée supplémentaire ?
		brne	DoIncTestInpMR1
		cpi		Work,0								; Est-on (en l'absence de bypass) juste avant le menu de type RCA/XLR ?
		brne	DoIncTestInpMR1
		ldi		Work,2								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1
#endif

DoIncTestInpMR1:
		cpi		Work,1								; Est-on juste avant le paramètre de volume + 6dB ? 
		brne	ReallyIncInpMR2						; Non, on incrémente sans pb

		ldi		ZH,RAM_Start						; oui, alors...
		ldi		ZL,RAM_BalIn1						; On va vérifier que l'entrée en question est asymétrique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2
		cpi		Work2,0								; Si on n'a pas zéro, on est asymétrique,
		brne	ReallyIncInpMR2						; et on peut passer au menu suivant

		ldi		Work,3								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1

ReallyIncInpMR2:
		inc		MenuReg2							; On incrémente le registre
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DecInpMenuReg2:										; Décrémentation du numéro de menu
		mov		Work,MenuReg2						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecInpMR2							; non, alors on peut décrémenter sans pb

		ldi		Work,4
		mov		MenuReg2,Work						; sinon, on le repasse à 2		
		rjmp	AfficheMenuInp1						; et on va afficher la chaine qu'il faut

DoDecInpMR2:
#ifndef	BYPASS
		mov		Work2,MenuReg1
		cpi		Work2,MaxInput-1					; On est sur l'entrée supplémentaire ?
		brne	DoDecTestInpMR1
		cpi		Work,2								; Est-on (en l'absence de bypass) juste avant le paramètre de volume + 6dB ?
		brne	DoDecTestInpMR1
		clr		MenuReg2						; 
		rjmp	AfficheMenuInp1
#endif

DoDecTestInpMR1:
		cpi		Work,3								; Est-on juste avant le paramètre de volume + 6dB ? 
		brne	ReallyDecInpMR2						; Non, on incrémente sans pb

		
		ldi		ZH,RAM_Start						; oui, alors...
		ldi		ZL,RAM_BalIn1						; On va vérifier que l'entrée en question est asymétrique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2
		cpi		Work2,0								; Si on n'a pas zéro, on est asymétrique, et on peut passer au menu suivant
		brne	ReallyDecInpMR2						; et on peut passer au menu suivant

		ldi		Work,1								; Sinon, on saute cet item de menu
		mov		MenuReg2,Work						; 
		rjmp	AfficheMenuInp1

ReallyDecInpMR2:
		dec		MenuReg2							; On décrémente le registre

AfficheMenuInp1:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 4)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		mov		Work,MenuReg2						; On met le registre dans un registre immédiat

TestMenuInputName:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuInputType					; Nan...

		ldi		ZH,HIGH(MenuInputName*2)
		ldi		ZL,LOW(MenuInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputType:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuInput6dB					; Nan...

		ldi		ZH,HIGH(MenuInputType*2)			; Oui, c'est 1
		ldi		ZL,LOW(MenuInputType*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInput6dB:

		cpi		Work,2								; C'est 2 ?
		brne	TestMenuInputVol					; Nan...

		ldi		ZH,HIGH(MenuInput6dB*2)				; Oui, c'est 2
		ldi		ZL,LOW(MenuInput6dB*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputVol:

		cpi		Work,3								; C'est 3 ?
		brne	TestMenuInputTrig					; Nan...

		ldi		ZH,HIGH(MenuInputVol*2)				; Yes, c'est Troie
		ldi		ZL,LOW(MenuInputVol*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

TestMenuInputTrig:

		ldi		ZH,HIGH(MenuInputTrig*2)			; Ici, c'est obligatoirement 4
		ldi		ZL,LOW(MenuInputTrig*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow

		rjmp	LoopLevelI1							; et on continue la boucle

WhatInputMenuToEnterL1:

		mov		Work,MenuReg2						; Transfert en immédiat
		cpi		Work,0								; si c'est 0
		breq	GotoEnterMenuInputName				; on va triturer le nom de l'entrée
		cpi		Work,1								; si c'est 1
		breq	GotoEnterMenuInputType				; on va triturer le type de l'entrée 
		cpi		Work,2								; si c'est 2
		breq	GotoEnterMenuInput6dB				; on va triturer les 6dB de l'entrée
		cpi		Work,3								; si c'est 3
		breq	GotoEnterMenuInputVol				; on va triturer le volume de l'entrée
		cpi		Work,4								; si c'est 4
		breq	GotoEnterMenuInputTrig				; on va triturer le trigger de l'entrée

GotoEnterMenuInputName:
		rjmp	EnterMenuInputName
GotoEnterMenuInputType:
		rjmp	EnterMenuInputType 
GotoEnterMenuInput6dB:
		rjmp	EnterMenuInput6dB 
GotoEnterMenuInputVol:
		rjmp	EnterMenuInputVol 
GotoEnterMenuInputTrig:
		rjmp	EnterMenuInputTrig 


EnterMenuInputName:									; on va triturer le nom de l'entrée

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputName					; Sinon,on revient au bon endroit

		rcall	MenuEntreeName						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur						; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputName					; et on revient au bon endroit

EnterMenuInputType:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputType					; Sinon,on revient au bon endroit

		rcall	MenuEntreeType						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur					; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur						; sur la seconde ligne de l'afficheur

; -- On vérifie que l'entrée qu'on vient d'éditer n'est pas l'entrée active
; -- auquel cas, il faut prendre en compte la modif pour qu'elle soit répercutée sur l'affichage

		call	MenuCheckActiveInput

		ldi		Work,1
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputType					; et on revient au bon endroit

EnterMenuInput6dB:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntree6dB						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur						; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

; -- On vérifie que l'entrée qu'on vient d'éditer n'est pas l'entrée active
; -- auquel cas, il faut prendre en compte la modif pour qu'elle soit répercutée sur l'affichage

		call	MenuCheckActiveInput6dB

		ldi		Work,2
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInput6dB					; et on revient au bon endroit

EnterMenuInputVol:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntreeVol						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur						; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar						; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,3
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputVol					; et on revient au bon endroit

EnterMenuInputTrig:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuInputTrig					; Sinon,on revient au bon endroit

		rcall	MenuEntreeTrig						; On y va

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbParam*2)
		ldi		ZL,LOW(MenuInputNbParam*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,9								; Le numéro de l'entrée
		call 	DisplayPlaceCurseur						; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar						; et on l'affiche

		ldi		Work,0x40							; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,4
		mov		MenuReg2,Work						; On remet la bonne valeur dans MenuReg2
		rjmp	TestMenuInputTrig					; et on revient au bon endroit

ExitEntreeMenu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelI1							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitEntreeMenu:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitEntreeMenu			; des sorties de menu en cascade

		ret											; on se casse de ce menu

; ========================================================
; == Edition du libellé l'entrée  (12 caractères)       ==
; == Le numéro de l'entrée considérée est dans MenuReg1 ==
; ==                                                    ==
; ==    - L'encodeur change de position de caractère    ==
; ==      ou après un appui sur "menu", change le code  ==
; ==      ASCII du caractère                            ==
; ==                                                    ==
; ==    - Appui court sur le bouton "Menu" :            ==
; ==      Choix du caractère à éditer                   ==
; ==      Validation du caractère édité                 ==
; ==                                                    ==
; ==    - Appui long sur le bouton "Menu" :             ==
; ==      Validation du nouveau libellé                 ==
; ==                                                    ==
; ==    - Le bouton de Standby/On :                     ==
; ==      En modification d'un caractère, annulation de ==
; ==      la saisie courante du caractère               ==
; ==      Sinon, annulation de l'édition du libellé     ==
; ==      et retour au libellé d'origine                ==
; ==                                                    ==
; ========================================================

MenuEntreeName:

WaitMenuEntreeName:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeName					; On attend le relachement du bouton de menu

; -- Bouton relâché, on continue
; -- Normalement l'affichage est bon et n'a pas changé
; -- On fait juste apparaître le curseur

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuInputNbName*2)
		ldi		ZL,LOW(MenuInputNbName*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x0B							; Le numéro de l'entrée
		call 	DisplayPlaceCurseur						; est affiché en 10ème position
		mov		Char,MenuReg1						; On passe le N° de l'entrée
		subi	Char,-49							; en ASCII
		call	DisplayWriteChar					; et on l'affiche

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuChangeInputName*2)
		ldi		ZL,LOW(MenuChangeInputName*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu
		call	DisplayArrow

		rcall	MenuAfficheNomEntree				; Affiche le nom de l'entrée qui est en EEPROM

		ldi		Work,0x40+(DisplaySize-NameSize)/2	; On replace le curseur
		call	DisplayPlaceCurseur					; au début du libellé
		call	DisplayCursorBlock					; On affiche le curseur en bloc
													; et on est prêt pour l'édition
		clr		MenuReg2							; Registre qui va servir à connaître le numéro du caractère

; -- Boucle pour l'édition --

LoopInpName:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeCurrentLetter					; l'un des duex en tout cas...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeNameNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopInpName							; Non, on boucle

		clr		Work								; Sinon on va lancer le timer pour savoir si on a un appui long
		out		TCCR1B,Work							; Arrête le timer aucazou
		sbr		StatReg2,EXP2(FlagWait)				

		ldi     Work,UneSecHi						; Et c'est parti pour 1 s
		out     TCNT1H,Work							
		ldi		Work,UneSecLo
		out     TCNT1L,Work
		ldi     Work,TimerDiv		        		; On démarre le Timer avec CK/1024
		out     TCCR1B,Work                     	; et il va compter pendant à peu 1 seconde avant l'overflow

; Maintenant on va boucler en attendant le relâchement du bouton Menu ou la fin de la seconde fatidique

WaitMenuLib:
		sbrs	StatReg2,FlagWait					; Le flag d"attente est passé à zéro ?
		rjmp	ExitMenuEntreeName					; 	- oui -> On sauve d'office
		sbis	PinMenu,SwitchMenu					; 	- non, mais menu toujours appuyé ?
		rjmp 	WaitMenuLib							; Oui, on boucle

		sbrc	StatReg2,FlagWait					; Le flag de wait est-il revenu à 0 (La seconde est écoulée) ?
		rjmp 	EditCurrentChar		 				; 	- Nan, pas de timeout, alors on change le caractère à éditer
		rjmp	ExitMenuEntreeName					;   - Oui, alors on va sauver le nouveau libellé

EditCurrentChar:									; On veut éditer un caractère particulier

		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	EditCurrentChar						; des sorties de menu en cascade (Bouton Menu relâché ?)

		clr		Work
		out		TCCR1B,Work							; On arrête le timer 1
		cbr		StatReg2,EXP2(FlagWait)				; et on réinitialise le flag d'attente

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au début de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caractère
		ld		Char,Z								; On récupère le code du caractère

		ldi		ZH,RAM_Start						; On va stocker le caratère édité en RAM
		ldi		ZL,RAM_TempChar						; pour le récupérer en cas d'annulation
		st		Z,Char

		call	DisplayCursorOn						; Passe le curseur en souligné, c'est plus lisible 

LoopInpNameChar:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeNameLetter					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour valider/sortir ?
		rjmp	ExitLoopNameChar					; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopInpNameChar						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpNameChar						; Non, on boucle

		rjmp 	SaveCurrentChar	 					; Change de caractère à éditer

ExitLoopNameChar:									; On annule la modif du caractère

		sbis	PinSwitchMC,SwitchMC				; Petite boucle
		rjmp	ExitLoopNameChar					; de debounce réglementaire

		ldi		ZH,RAM_Start						; On va lire le caratère édité en RAM
		ldi		ZL,RAM_TempChar						; pour le récupérer 
		ld		Char,Z

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au début de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caractère
		st		Z,Char								; On remet le bon code du caractère

		ldi		Work,0x44							; Il faut aussi le réécrire sur l'afficheur
		add		Work,MenuReg2						; et on bon endroit
		call	DisplayPlaceCurseur
		call	DisplayWriteChar

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		call	DisplayCursorBlock					; On remet le curseeur en bloc

		rjmp	LoopInpName							; et on reboucle

; -- Sauvegarde du caractère édité --

SaveCurrentChar:									; Pas vraiment de sauvegarde car tout est en RAM automatiquement

		sbis	PinMenu,SwitchMenu					; Petite boucle
		rjmp	SaveCurrentChar						; de debounce réglementaire

		call	DisplayCursorBlock					; Repasse le curseur en bloc

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		rjmp	LoopInpName

; -- Change la position du curseur --

ChangeCurrentLetter:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncCurrentLetter					; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecCurrentLetter					; vers le bas ?
		rjmp	LoopInpName							; Aucun des deux, alors cassos

IncCurrentLetter:
		ldi		Work,NameSize-1						; On est arrivé
		cp		MenuReg2,Work						; au dernier caractère ?
		breq	GoToFirstChar						; 	- Oui, alors on repasse au premier
		inc		MenuReg2							; 	- Non, alors on incrémente	
		rjmp	GotoNextLetter						; 	et on shifte le curseur

GoToFirstChar:
		clr		MenuReg2							
		rjmp	GotoNextLetter						; 	et on shifte le curseur

DecCurrentLetter:
		ldi		Work,0								; On est arrivé
		cp		MenuReg2,Work						; au premier caractère ?
		breq	GoToLastChar						; 	- Oui, alors on repasse au dernier
		dec		MenuReg2							; 	- Non, alors on décrémente	
		rjmp	GotoNextLetter						; 	et on shifte le curseur

GoToLastChar:
		ldi		Work,NameSize-1
		mov		MenuReg2,Work							

GotoNextLetter:
		ldi		Work,0x44							; Premier caractère du nom
		add		Work,MenuReg2						; et décalage pour aller à la bonne place
		call	DisplayPlaceCurseur

		cbr		StatReg1,EXP2(FlagIncremente)		; Remet les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)		; à zéro
		rjmp	LoopInpName							; Mission terminée, on s'en va
		
; --- Change le code ascii du caractère (0 à 255) ---

ChangeNameLetter:
		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au début de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caractère
		ld		Char,Z								; On récupère le code du caractère

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteLetter						
		rcall	LanceClignotementLED

MenuTesteLetter:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMenuASCII						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMenuASCII						; vers le bas ?
		rjmp	LoopInpNameChar						; Aucun des deux, alors cassos

IncMenuASCII:										; Incrémentation du numéro de menu
		cpi		Char,CodeCharMax					; dernier caractère autorisé ?
		brne	DoIncMenuASCII						; non, alors on peut incrémenter sans pb

		ldi		Char,CodeCharMin					; sinon, on le repasse au code Ascii Min		
		rjmp	MenuAfficheNewChar					; et on va afficher le nouveau caractère

DoIncMenuASCII:
#if defined(CRYSTALFONTZ)
		inc		Char								; On incrémente le registre
#else
		call	TestDisplayIncASCII					; Cherche les caractères autorisés
#endif
		rjmp	MenuAfficheNewChar
		
DecMenuASCII:										; Décrémentation du numéro de menu
		cpi		Char,CodeCharMin					; c'est le plus petit code ascii autorisé ?
		brne	DoDecMenuASCII						; non, alors on peut décrémenter sans pb

		ldi		Char,CodeCharMax					; sinon, on le repasse au code ascii max	
		rjmp	MenuAfficheNewChar					; et on va afficher la chaine qu'il faut

DoDecMenuASCII:
#if defined(CRYSTALFONTZ)
		dec		Char								; On décrémente le registre
#else
		call	TestDisplayDecASCII					; Cherche les caractères autorisés
#endif

MenuAfficheNewChar:									; affiche nouveau caractère et le stocke en RAM

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au début de la chaine en RAM
		add		ZL,MenuReg2							; Offset pour aller sur le bon caractère
		st		Z,Char								; Stockage en RAM

		ldi		Work,0x44
		add		Work,MenuReg2						; Met le curseur au bon endroit
		call	DisplayPlaceCurseur					; (Début + numéro du caractère - icelui allant de 0 à 7)

		call	DisplayWriteChar					; Ecrit le caractère

		ldi		Work,0x44
		add		Work,MenuReg2						; et remet le curseur au bon endroit
		call	DisplayPlaceCurseur					; car normalement il avance automatiquement

		rjmp	LoopInpNameChar						; et on reboucle

; -- Sortie avec recopie en EEPROM du libellé modifié qui est en RAM

ExitMenuEntreeName:

		call	DisplayCursorOff					; On fait disparaître le curseur 
		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSavingName					; Affiche le message de sauvegarde

; -- Sauvegarde du nouvel intitulé en EEPROM

		ldi		Work,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM

		mov		Work1,MenuReg1						; Copie le numéro de l'entrée éditée
		lsl		Work1								; 
		lsl		Work1								; 4 Shifts left -> Multiplication par 16
		lsl		Work1
		lsl		Work1
		add		Work,Work1							; Auquel on ajoute l'adresse de départ pour pointer sur le bon libellé

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; Récupère en RAM l'adresse de début du libellé qu'on vient d'éditer

		clr 	Count1								; 12 caractères à récupérer
				
MenuCopieLibellesSave:								
		ld		Work2,Z+							; on récupère le caractère dans la RAM, tout en incrémentant l'adresse RAM
		call	WriteEEprom							; et on écrit
		inc		Work								; incrémente l'adresse en EEPROM
		inc		Count1								; Incrémente le compteur de caractères

		cpi		Count1,NameSize						; teste si on a fini d'écrire tous les caractères
		brne	MenuCopieLibellesSave				; et boucle si on n'a pas tout écrit


; -- On sauvegarde aussi en RAM pour l'affichage

		mov		Work1,MenuReg1						; Copie le numéro de l'entrée éditée
		lsl		Work1								; 
		lsl		Work1								; 4 Shifts left -> Multiplication par 16
		lsl		Work1
		lsl		Work1

		ldi		ZH,RAM_Start						
		ldi		Work,RAM_TitreIn1					; Adresse RAM du 1er libellé
		add		Work,Work1							; On se décale pour pointer sur le bon libellé

		ldi		Work1,RAM_TitreActif				; Adresse RAM du libellé édité

		clr		Count1								; Compteur de caractères

MenuCopieLibellesSaveRAM:								

		mov		ZL,Work1							; Libellé édité
		ld		Char,Z								; lu en RAM
		mov		ZL,Work								; Libellé final
		st		Z,Char								; écrit en RAM
		inc		Work								; Caractère suivant
		inc		Work1								; sur les deux positions de RAM
		inc		Count1								; Nombre de caractères écrits
		cpi		Count1,NameSize						; Dernier caractère ?
		brne	MenuCopieLibellesSaveRAM			; 	- nan -> Bouclage		

MenuInpLibWaitForRet:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	MenuInpLibWaitForRet				; des sorties de menu en cascade (Bouton Menu relâché ?)

		ret											; On a fini

ExitMenuEntreeNameNoSave:
		sbis	PinSwitchMC,SwitchMC				; Attente d'un éventuel relâchement du bouton d'annulation...
		rjmp	ExitMenuEntreeNameNoSave

		call	DisplayCursorOff					; On fait disparaître le curseur 
		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; et on se casse de ce menu

; =========================================================
; == Edition du type de l'entrée (XLR/RCA)               ==
; == Le numéro de l'entrée considérée est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre XLR et RCA            ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeType:

WaitMenuEntreeType:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeType					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputTypeMessage*2)
		ldi		ZL,LOW(MenuInputTypeMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x0B							; Cuseur en 10ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur d'entrée symétrique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2

		mov		MenuReg2,Work2						; On transfère la valeur dans MenuReg2

		call	MenuAfficheTypeEntree				; Affiche le type de l'entrée	

LoopInpType:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputType						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeTypeNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpType							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpType							; Non, on boucle

		rjmp 	ExitMenuEntreeType					; Sortie avec sauvegarde

ChangeInputType:									; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteType						
		call	LanceClignotementLED

MenuTesteType:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transfère l'ancienne valeur dans un registre immédiat
		cpi		Work,0								; C'était No ?
		breq	MenuTypeUTB							; 	- Oui -> on change

		clr		MenuReg2							; 	- Non -> on change aussi
		rjmp	ActualiseMenuType

MenuTypeUTB:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenuType:
		rcall 	MenuAfficheTypeEntree				; On affiche la nouvelle valeur
		rjmp	LoopInpType							; et on reboucle		

ExitMenuEntreeType:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMenuEntreeType

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donnée de l'EEPROM		
		ldi		Work,EE_BalIn1						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on écrit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur de trigger sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		clr		MenuReg2							; Dans tous les cas, on va annuler l'augmentation de volume de 6dB pour cette entrée, qu'elle soit XLR ou RCA
		call	MenuModif6dBFromType				; Stockage en RAM en en EEPROM

		ret											; et c'est fini

ExitMenuEntreeTypeNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeTypeNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Activation du volume de +6dB pour une entrée unbal  ==
; == Le numéro de l'entrée considérée est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre Yes et No             ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntree6dB:

WaitMenuEntree6dB:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntree6dB					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInput6dBMessage*2)
		ldi		ZL,LOW(MenuInput6dBMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

		ldi		Work,0x40							; début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEncodeurMessage*2)		; Chaine à afficher
		ldi		ZL,LOW(MenuEncodeurMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In1_6dB 						; Récupère en RAM l'indicateur de 6dB sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2

		mov		MenuReg2,Work2						; On transfère la valeur dans MenuReg2

		rcall	MenuAffiche6dB						; et affiche la valeur

LoopInp6dB:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInput6dB						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntree6dBNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInp6dB							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInp6dB							; Non, on boucle

		rjmp 	ExitMenuEntree6dB					; Sortie sans sauvegarde

ChangeInput6dB:										; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTeste6dB						
		call	LanceClignotementLED

MenuTeste6dB:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transfère l'ancienne valeur dans un registre immédiat
		cpi		Work,0								; C'était No ?
		breq	Menu6dBNoToYes						; 	- Oui -> on change

		ldi		Work,0								; 	- Non -> on change aussi
		mov		MenuReg2,Work
		rjmp	ActualiseMenu6dB

Menu6dBNoToYes:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenu6dB:
		rcall 	MenuAffiche6dB						; On affiche la nouvelle valeur
		rjmp	LoopInp6dB							; et on reboucle		

ExitMenuEntree6dB:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMenuEntree6dB

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

MenuModif6dBFromType:								; Point d'entrée pour modifier la valeur si on a changé le type d'entrée

		mov		Work2,MenuReg2						; valeur dans le registre de donnée de l'EEPROM		
		ldi		Work,EE_In1_6dB						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on écrit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In1_6dB 						; Récupère en RAM l'indicateur de 6dB sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ret											; et c'est fini

ExitMenuEntree6dBNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntree6dBNoSave				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Activation de la sortie trigger pour une entrée     ==
; == Le numéro de l'entrée considérée est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur commute entre Yes et No             ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeTrig:

WaitMenuEntreeTrig:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeTrig					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputTrigMessage*2)
		ldi		ZL,LOW(MenuInputTrigMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

		ldi		Work,0x40							; début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEncodeurMessage*2)		; Chaine à afficher
		ldi		ZL,LOW(MenuEncodeurMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TrigIn1 						; Récupère en RAM l'indicateur de trigger sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2

		mov		MenuReg2,Work2						; On transfère la valeur dans MenuReg2

		rcall	MenuAfficheTrig						; et affiche la valeur

LoopInpTrig:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputTrig						; l'un des deux...

		sbis	PinSwitchMC,SwitchmC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeTrigNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpTrig							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpTrig							; Non, on boucle

		rjmp 	ExitMenuEntreeTrig					; Sortie sans sauvegarde

ChangeInputTrig:									; Comme on n'a que deux valeurs, le choix est facile...

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteTrig						
		call	LanceClignotementLED

MenuTesteTrig:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg2						; On transfère l'ancienne valeur dans un registre immédiat
		cpi		Work,0								; C'était No ?
		breq	MenuTrigNoToYes						; 	- Oui -> on change

		ldi		Work,0								; 	- Non -> on change aussi
		mov		MenuReg2,Work
		rjmp	ActualiseMenuTrig

MenuTrigNoToYes:
		ldi		Work,1
		mov		MenuReg2,Work

ActualiseMenuTrig:
		rcall 	MenuAfficheTrig						; On affiche la nouvelle valeur
		rjmp	LoopInpTrig							; et on reboucle		

ExitMenuEntreeTrig:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMenuEntreeTrig

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donnée de l'EEPROM		
		ldi		Work,EE_TrigIn1						; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on écrit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TrigIn1 						; Récupère en RAM l'indicateur de trigger sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ret											; et c'est fini

ExitMenuEntreeTrigNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeTrigNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =========================================================
; == Modification particulière du volume pour une entrée ==
; == Le numéro de l'entrée considérée est dans MenuReg1  ==
; ==                                                     ==
; ==    - L'encodeur change la valeur                    ==
; ==    - Ajout (bit 7 à 0) ou retrait (bit 7 à 1)       ==
; ==    - Annulation par le bouton de menu               ==
; ==    - Et la sortie/sauvegarde par le bouton StandBy  ==
; =========================================================

MenuEntreeVol:

WaitMenuEntreeVol:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeVol					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; On commence par regarder si l'entrée éditée n'est pas l'entrée en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; Sont-ce les mêmes ?
		rjmp	MenuEntreeVolNotSame				; nan, on passe à la suite

		call	MenuRecupereVolume					; Sinon, on récupère la valeur du volume "vrai"

MenuEntreeVolNotSame:
		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputVolMessage*2)
		ldi		ZL,LOW(MenuInputVolMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,6								; Cuseur en 7ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_ModVol_In1 					; Récupère en RAM l'indicateur de trigger sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2

		mov		MenuReg2,Work2						; On transfère la valeur dans MenuReg2

		rcall	MenuAfficheInpVol					; et affiche la valeur

LoopInpVol:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputVol						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitMenuEntreeVolNoSave				; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpVol							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpVol							; Non, on boucle

		rjmp 	ExitMenuEntreeVol					; Sortie sans sauvegarde

ChangeInputVol:
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteVol						
		call	LanceClignotementLED

MenuTesteVol:
		mov		Work,MenuReg2						; On transfère l'ancienne valeur dans un registre immédiat
		cbr		Work,0b10000000						; On efface le bit de signe dans ce registre

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVolInpVal						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVolInpVal						; vers le bas ?
		rjmp	LoopInpVol							; Aucun des deux, alors cassos

IncVolInpVal:										; On incrémente
		sbrc	MenuReg2,7							; On était négatif ?
		rjmp	DoDecVolInpVal						; Oui, alors on diminue la valeur absolue pour augmenter (c'est futé, hein ?)

DoIncVolInpVal:										; Incrémentation effective
		cpi		Work,8								; On était au max ?
		breq	ActualiseInpVolOnly					; oui, alors, on ne fait rien

		inc		Work								; Sinon on incrémente
		rjmp	FinLoopInpVol						; et on termine

DecVolInpVal:										; On décrémente
		sbrc	MenuReg2,7							; On était positif ?
		rjmp	DoIncVolInpVal						; Oui, alors on augmente la valeur absolue pour diminuer (c'est futé, hein ?)
						
DoDecVolInpVal:										; Décrémentation effective
		ldi		Work1,0
		cp		Work1,MenuReg2						; Avait-on zéro avant modif ?
		brne	ReallyDecVolInputVal
		ldi		Work1,0b10000000
		mov		MenuReg2,Work1
		rjmp	DoIncVolInpVal

ReallyDecVolInputVal:
		cpi		Work,0								; On était au min ?
		breq	ActualiseInpVolOnly					; oui, alors, on ne fait rien

		dec		Work								; Sinon on décrémente

FinLoopInpVol:
		cpi		Work,0
		breq	FinFinLoopInpVol

		mov		Work1,MenuReg2						; Efface tous les bits de MenuReg2, sauf le bit de signe
		cbr		Work1,0b01111111
		mov		MenuReg2,Work1

		add		MenuReg2,Work						; et y place la nouvelle valeur
		rjmp	ActualiseInpVol						; pour finalement afficher la nouvelle valeur

FinFinLoopInpVol:
		mov		MenuReg2,Work

ActualiseInpVol:
		ldi		ZH,RAM_Start						; Si l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les mêmes ?
		rjmp	ActualiseInpVolOnly					; nan, on passe à la suite

		ldi		ZH,RAM_Start						; Oui, l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; récupère la valeur du volume qui était stockée

		mov		Work2,MenuReg2						; Transfère la valeur dans Work2
		call	InputVolNewNoRam					; Modfie le volume avec le trim
		call	SetVolume							; et règle le volume en conséquence

ActualiseInpVolOnly:
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call 	MenuAfficheInpVol					; Affiche la nouvelle valeur (contenue dans MenuReg2)

		rjmp	LoopInpVol							; et retourne scruter encodeur et touches

ExitMenuEntreeVol:									; On se sauve en sauvant
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMenuEntreeVol

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg2						; valeur dans le registre de donnée de l'EEPROM		
		ldi		Work,EE_ModVol_In1					; il faut juste la mettre en EEPROM
		add		Work,MenuReg1						; Translation pour pointer au bon endroit
		call	WriteEEprom							; et on écrit

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_ModVol_In1 					; Récupère en RAM l'indicateur de trigger sur l'entrée
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		st		Z,Work2								; sauve en RAM

		ldi		ZH,RAM_Start						; Si l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les mêmes ?
		ret											; nan, on passe à la suite

		ldi		ZH,RAM_Start						; Oui, l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; récupère la valeur du volume qui était stockée

		mov		Work2,MenuReg2
		call	InputVolNewNoRam					; Modfie le volume avec le trim
		call	SetVolume							; et règle le volume en conséquence

		ret											; et c'est fini

ExitMenuEntreeVolNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeVolNoSave				; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start						; Si l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les mêmes ?
		ret											; nan, on passe à la suite

		ldi		ZH,RAM_Start						; Oui, l'entrée éditée est l'entrée en cours
		ldi		ZL,RAM_TempVolume
		ld		VolReg,Z							; récupère la valeur du volume qui était stockée

		call	InputVolNew							; Modfie le volume avec le trim
		call	SetVolume							; et règle le volume en conséquence

		ret											; on se casse de ce menu

; =========================================================
; == Choix de l'entrée à activer au démarrage            ==
; ==                                                     ==
; ==    - L'encodeur commute entre les entrées           ==
; ==    - Validation par le bouton de menu               ==
; ==    - Et la sortie/annulation par le bouton StandBy  ==
; =========================================================

MenuStartInput:

WaitMenuEntreeStart:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeStart					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		ld		MenuReg1,Z							; Charge le comportement actuel de l'entrée de startup
		mov		Work,MenuReg1

		cpi		Work,0								; Entrée prédéfinie
		breq	MenuSIAffichePreset					; 	- Vi -> On y va

		ldi		Work,0x40							; 	- No -> Dernière entrée
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpLastMessage*2)	; Chaine à afficher
		ldi		ZL,LOW(MenuPrefInpLastMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow
		rjmp	MenuLoopSI

MenuSIAffichePreset:
		ldi		Work,0x40							; Entrée prédéfinie
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpPresetMessage*2)	; Chaine à afficher
		ldi		ZL,LOW(MenuPrefInpPresetMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

; -- Boucle d'édition

MenuLoopSI:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputStartType				; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeStartTypeNoSave		; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	MenuLoopSI							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	MenuLoopSI							; Non, on boucle

		rjmp	ExitMenuEntreeStartTypeSave			; Sortie avec sauvegarde

; -- Changement du type de l'entrée préférée

ChangeInputStartType:
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteStartType						
		call	LanceClignotementLED

MenuTesteStartType:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncDecStartTypeInput				; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	IncDecStartTypeInput				; vers le bas ?
		rjmp	MenuLoopSI							; Aucun des deux, alors cassos

IncDecStartTypeInput:								; Changement de la valeur
		mov		Work,MenuReg1
		cpi		Work,0								; C'est 0 ?
		breq	MenuSIType0to1						; 	- Oui -> on passe à 1

		clr		MenuReg1							; 	- Non -> On passe à 0
		rjmp	MenuAfficheNewInpStartType			; Et on va afficher

MenuSIType0to1:										; Passe la valeur à 1
		ldi		Work,1
		mov		MenuReg1,Work

MenuAfficheNewInpStartType:							; On affiche le type de comportement
		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		mov		Work,MenuReg1
		cpi		Work,0								; C'est une entrée fixe ?
		breq	MenuAfficheSI_Pref					; 	- Oui -> On y va

		ldi		Work,0x40							;	- No -> C'est la dernière entrée active
		call	DisplayPlaceCurseur						; Curseur en début de seconde ligne
		ldi		ZH,HIGH(MenuPrefInpLastMessage*2)	; 
		ldi		ZL,LOW(MenuPrefInpLastMessage*2)
		call	DisplayAfficheChaine				; et on affiche
		call	DisplayArrow

		rjmp	MenuLoopSI
				
MenuAfficheSI_Pref:									; Entrée Fixe
		ldi		Work,0x40
		call	DisplayPlaceCurseur					; Curseur en début de seconde ligne
		ldi		ZH,HIGH(MenuPrefInpPresetMessage*2)
		ldi		ZL,LOW(MenuPrefInpPresetMessage*2)
		call	DisplayAfficheChaine				; et on affiche
		call	DisplayArrow

		rjmp	MenuLoopSI

; -- Sauvegarde du type d'entrée au démarrage, ou passage à la suite

ExitMenuEntreeStartTypeSave:						; Sauvegarde du comportement
		call 	Attendre							; On attend pour le débounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur Standby/On pour sortir ?
		rjmp	MenuLoopSI							; Non, fausse arlette et on replonge dans la boucle

WaitExitMenuEntreeStartTypeSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitExitMenuEntreeStartTypeSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		mov		Work,MenuReg1
		cpi		Work,0								; Si c'est 0 (entrée fixée) on passe à la suite
		breq	MenuEnterStartInputName

; -- Sinon on mémorise qu'il faut mémoriser la dernière entrée

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- On sauve en RAM

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		st		Z,MenuReg1
				
; -- En EEPROM

		ldi		Work,EE_StartInputBehave			; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transférée dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on écrit

		ret											; Et c'est fini pour ici

; -- Sort d'ici sans sauvegarder

ExitMenuEntreeStartTypeNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeStartTypeNoSave		; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; -------------------------------------------------------------------------------------------------------------
; -- Changement du numéro de l'entrée préférée

MenuEnterStartInputName:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_StartInputBehave
		st		Z,MenuReg1							; On sauvegarde le comportement

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInputPrefMessage*2)
		ldi		ZL,LOW(MenuInputPrefMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpNameMessage*2)	; Chaine à afficher
		ldi		ZL,LOW(MenuPrefInpNameMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_StartInput 					; Récupère en RAM le numéro de l'entrée préférée
		ld		MenuReg1,Z							; et récupère la valeur dans MenuReg1

; On affiche le libellé de l'entrée préférée depuis l'EEPROM

MenuStartEEPROMSeek:
		ldi		Work1,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM
		clr		Work

		ldi		Work1,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM
		mov		Work,MenuReg1						; Copie le numéro de l'entrée éditée
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de départ pour pointer sur le bon libellé

MenuStartLib:										; Arrivé ici, l'adresse de début du libellé est dans Work1
		ldi		Count1,NameSize						; 12 caractères à écrire
		ldi		Work,0x46							; On se place sur la seconde ligne, au 5ème caractère pour centrer les 12 cacatères
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritStartLib:
		out		EEARL,Work1							; Adresse à atteindre en EEPROM
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		call	DisplayWriteChar					; et on l'écrit
		inc		Work1								; On incrémente l'adresse EEPROM
		dec 	Count1								; Arrivé au 12ème caractère ?
		brne	MenuEcritStartLib					;	 -Non, on continue la boucle

		ldi		Work,0x43							; Cuseur en 4ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

; -- Boucle pour l'édition --

LoopInpStart:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputStart					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeStartNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpStart						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpStart						; Non, on boucle

		rjmp	ExitMenuEntreeStartSave				; Sortie avce sauvegarde

ChangeInputStart:									
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteStart						
		call	LanceClignotementLED

MenuTesteStart:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncStartInput						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecStartInput						; vers le bas ?
		rjmp	LoopInpStart						; Aucun des deux, alors cassos

IncStartInput:										; Incrémentation du numéro de l'entrée
		mov		Work,MenuReg1
		cpi		Work,(MaxInput-1)					; dernière entrée ?
		brne	DoIncStartInput						; non, alors on peut incrémenter sans pb

;		clr		MenuReg1							; sinon, on le à la première		
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libellé correspondant à l'entrée
DoIncStartInput:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libellé correspondant à l'entrée

DecStartInput:										; Décrémentation du numéro de l'entrée
		clr		Work
		cp		MenuReg1,Work						; c'est la première entrée ?
		brne	DoDecStartInput						; non, alors on peut décrémenter sans pb

;		ldi		Work,3								; sinon, on le positionne sur la dernière entrée	
;		mov		MenuReg1,Work
		rjmp	MenuAfficheNewInpStart				; et on affiche le nouveau libellé correspondant à l'entrée

DoDecStartInput:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuAfficheNewInpStart				; et on afficher le nouveau libellé correspondant à l'entrée

MenuAfficheNewInpStart:								; Nouvelle entrée, nouveau libellé

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rjmp	MenuStartEEPROMSeek					; et on va chercher le libellé en EEPROM

ExitMenuEntreeStartSave:
		call 	Attendre							; On attend pour le débounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur Standby/On pour sortir ?
		rjmp	LoopInpStart 						; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitMenuEntreeStartSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitMenuEntreeStartSave	; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- Sauvegarde de la nouvelle valeur

; -- En RAM

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_StartInput 					; Récupère en RAM l'indicateur d'entrée symétrique
		st		Z,MenuReg1							; et sauvegarde la valeur en RAM

; -- En EEPROM

		ldi		Work,EE_StartInput					; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transférée dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on écrit

		ret											; et on se casse de ce menu

ExitMenuEntreeStartNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeStartNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; =====================================================
; == Affichage du nom de l'entrée considérée         ==
; == Le numéro de l'entrée est dans MenuReg1         ==
; ==                                                 ==
; == On en profite pour stocker le libellé en RAM,   ==
; == Pour le cas où on voudrait l'éditer juste après ==
; =====================================================

MenuAfficheNomEntree:

		ldi		Work1,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM

		mov		Work,MenuReg1						; Copie le numéro de l'entrée éditée
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de départ pour pointer sur le bon libellé

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; Récupère en RAM l'adresse de début du libellé à éditer

		clr 	Count1								; 8 caractères à récupérer
				
MenuCopieLibelles:
		out		EEARL,Work1							; Adresse à atteindre en EEPROM
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Work,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		st		Z+,Work								; et stocke la valeur en RAM, avec incrémentation automatique de l'adresse

		inc		Work1								; incrémente l'adresse en EEPROM
		inc		Count1								; Incrémente le compteur de caractères

		cpi		Count1,NameSize						; teste si on a fini de lire tous les caractères
		brne	MenuCopieLibelles					; et boucle on n'a pas tout lu

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_TitreActif 					; On se replace au début de la chaine en RAM

		ldi		Count1,NameSize						; 12 caractères à écrire
				
		ldi		Work,0x40+(DisplaySize-NameSize)/2	; On va centrer l'initulé, encadré par des ' " '
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritLibelle:
		ld		Char,Z+								; Récupère le caractère et incrémente l'adresse en RAM
		call	DisplayWriteChar					; et on l'écrit
		dec 	Count1								; Arrivé au 8ème caractère ?
		brne	MenuEcritLibelle					;	 -Non, on continue la boucle

		ret											; et c'est fini

; ==============================================
; == Affichage du type de l'entrée considérée ==
; == Le numéro de l'entrée est dans MenuReg1  ==
; ==============================================

MenuAfficheTypeEntree:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2						; On transfère la valeur dans MenuReg2

		cpi		Work2,0								; C'est une entrée symétrique ?
		brne	MenuInputEcrireRCA					; 	- Non (Valeur non nulle)

		ldi		ZH,HIGH(MenuInputBalMessage*2)
		ldi		ZL,LOW(MenuInputBalMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; évouala

MenuInputEcrireRCA:
		ldi		ZH,HIGH(MenuInputUnBalMessage*2)
		ldi		ZL,LOW(MenuInputUnBalMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow


		ret											; écétou

; ====================================================
; == Affiche si on augmente ou non le volume de 6dB ==
; == pour l'entrée considérée                       ==
; == Le numéro de l'entrée est dans MenuReg1        ==
; ====================================================

MenuAffiche6dB:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2
		cpi		Work2,0								; 6dB en plus ?
		breq	MenuInputEcrire6dBNo				; 	- Non (Valeur à 0)

		ldi		ZH,HIGH(MenuInput6dBOnMessage*2)
		ldi		ZL,LOW(MenuInput6dBOnMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; évouala

MenuInputEcrire6dBNo:
		ldi		ZH,HIGH(MenuInput6dBOffMessage*2)
		ldi		ZL,LOW(MenuInput6dBOffMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; écéfini

; =================================================
; == Affiche le trigger pour l'entrée considérée ==
; == Le numéro de l'entrée est dans MenuReg1     ==
; =================================================

MenuAfficheTrig:

		ldi		Work,0x40							; Début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work2,MenuReg2
		cpi		Work2,0								; Y'a un trigger ?
		breq	MenuInputEcrireNo					; 	- Non (Valeur à 0)

		ldi		ZH,HIGH(MenuInputTrigOnMessage*2)
		ldi		ZL,LOW(MenuInputTrigOnMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; évouala

MenuInputEcrireNo:
		ldi		ZH,HIGH(MenuInputTrigOffMessage*2)
		ldi		ZL,LOW(MenuInputTrigOffMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ret											; écéfini

; ===========================================================================
; == Teste si l'entrée dont on vient de modifier le type                   ==
; == est l'entrée active, et modifie le relais de Bal/Unbal en conséquence ==
; ===========================================================================

MenuCheckActiveInput:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les mêmes ?
		ret											; Non	-> On termine normalement

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur d'entrée symétrique
		add		ZL,MenuReg1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work2,Z								; et récupère la valeur dans Work2

		cpi		Work2,0								; C'est une RCA ?
		breq	MenuInputNewTypeXLR					; Non, c'est du XLR	

		sbr		StatReg1,EXP2(FlagAsym)				; Oui, alors passe les flags correspondants à 1
		lds		Work,PortAutresRelais				; Récupère l'état des autres relais sur le même port
		sbr		Work,EXP2(RelaisAsym)				; Et fait passer à 1 le relais de dissymétrisation
		sts		PortAutresRelais,Work				; et on met ça dans le relais
		ret											; et bye

MenuInputNewTypeXLR:
		cbr		StatReg1,EXP2(FlagAsym)
		lds		Work,PortAutresRelais				; Récupère l'état des autres relais sur le même port
		cbr		Work,EXP2(RelaisAsym)				; Et les fait passer à 0
		sts		PortAutresRelais,Work				; et on met ça dans le relais

		ret											; et bye

; ======================================================================
; == Teste si on vient de modifier le comportement de l'entrée active ==
; == et si c'est le cas, vérifie si il faut y ajouter 6dB             ==
; ======================================================================

MenuCheckActiveInput6dB:

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		cpse	MenuReg1,Work1						; ce sont les mêmes ?
		ret											; Non	-> On termine normalement

		call	Want6dBMore							; Oui   -> On va tester si il faut ajouter 6dB
		call	SetVolume							; 		   et on actualise le volume

		ret											; et bye

; =========================================================
; == Choix de l'entrée à bypasser au repos               ==
; ==                                                     ==
; ==    - L'encodeur commute entre les entrées           ==
; ==    - Validation par le bouton de menu               ==
; ==    - Et la sortie/annulation par le bouton StandBy  ==
; =========================================================

MenuBypassInput:

WaitMenuEntreeBypass:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuEntreeBypass				; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_In_Bypass
		ld		MenuReg1,Z							; Charge le numéro de l'entrée bypassée

		ldi		Work,0								; Message de la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPrefInpBypassMessage*2)
		ldi		ZL,LOW(MenuPrefInpBypassMessage*2)
		call	DisplayAfficheChaine

MenuBypassAfficheLigne2:
		ldi		Work,0x40							; début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; Récupère la valeur de cette entrée bypassée
		cpi		Work,4								; On vérifie que le bypass existe (4 -> Pas de bypass)
		brne	MenuBypassNormal

		ldi		ZH,HIGH(MenuPrefInpNoBypassMessage*2); Chaine à afficher
		ldi		ZL,LOW(MenuPrefInpNoBypassMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow
		rjmp	LoopInpBypass

MenuBypassNormal:
		ldi		ZH,HIGH(MenuPrefInpNameMessage*2)	; Chaine à afficher
		ldi		ZL,LOW(MenuPrefInpNameMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

; On affiche le libellé de l'entrée bypassée depuis l'EEPROM

MenuBypassEEPROMSeek:
		ldi		Work1,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM
		clr		Work

		ldi		Work1,EE_TitreIn1					; On se place au début de la zone des libellés en EEPROM
		mov		Work,MenuReg1						; Copie le numéro de l'entrée éditée
		lsl		Work								; 
		lsl		Work								; 4 Shifts left -> Multiplication par 16
		lsl		Work
		lsl		Work
		add		Work1,Work							; Auquel on ajoute l'adresse de départ pour pointer sur le bon libellé

MenuBypassLib:										; Arrivé ici, l'adresse de début du libellé est dans Work1
		ldi		Count1,NameSize						; 12 caractères à écrire
		ldi		Work,0x46							; On se place sur la seconde ligne, au 5ème caractère pour centrer les 12 cacatères
		call	DisplayPlaceCurseur					; Met le curseur en bonne position	

MenuEcritBypassLib:
		out		EEARL,Work1							; Adresse à atteindre en EEPROM
	    sbi		EECR,EERE							; Prépare l'EEPROM à la lecture
		in		Char,EEDR							; lit la valeur en EEPROM et la met dans le registre Work

		call	DisplayWriteChar					; et on l'écrit
		inc		Work1								; On incrémente l'adresse EEPROM
		dec 	Count1								; Arrivé au 12ème caractère ?
		brne	MenuEcritBypassLib					;	 -Non, on continue la boucle

		ldi		Work,0x43							; Cuseur en 4ème position
		call	DisplayPLaceCurseur
		mov		Char,MenuReg1						; affiche le N° de l'entrée
		subi	Char,-49
		call	DisplayWriteChar

; -- Boucle pour le changement de l'entrée bypassée --

LoopInpBypass:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeInputBypass					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir sans sauvegarde ?
		rjmp	ExitMenuEntreeBypassNoSave			; 	- Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider/sortir ?
		rjmp 	LoopInpBypass						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopInpBypass						; Non, on boucle

		rjmp	ExitMenuEntreeBypassSave			; Sortie avec sauvegarde

ChangeInputBypass:									
		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuTesteBypass						
		call	LanceClignotementLED

MenuTesteBypass:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncBypassInput						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecBypassInput						; vers le bas ?
		rjmp	LoopInpBypass						; Aucun des deux, alors cassos

IncBypassInput:										; Incrémentation du numéro de l'entrée
		mov		Work,MenuReg1
		cpi		Work,MaxInput   					; dernière entrée ?
		brne	DoIncBypassInput					; non, alors on peut incrémenter sans pb

;		clr		MenuReg1							; sinon, on le à la première		
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libellé correspondant à l'entrée
DoIncBypassInput:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libellé correspondant à l'entrée

DecBypassInput:										; Décrémentation du numéro de l'entrée
		clr		Work
		cp		MenuReg1,Work						; c'est la première entrée ?
		brne	DoDecBypassInput					; non, alors on peut décrémenter sans pb

		rjmp	MenuAfficheNewInpBypass				; et on affiche le nouveau libellé correspondant à l'entrée

DoDecBypassInput:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuAfficheNewInpBypass				; et on afficher le nouveau libellé correspondant à l'entrée

MenuAfficheNewInpBypass:								; Nouvelle entrée, nouveau libellé

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rjmp	MenuBypassAfficheLigne2				; et on va chercher quoi afficher en ligne 2

ExitMenuEntreeBypassSave:
		call 	Attendre							; On attend pour le débounce
		sbic	PinMenu,SwitchMenu					; C'est un vrai appui sur l'annulation pour sortir ?
		rjmp	LoopInpBypass						; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitMenuEntreeBypassSave:
		sbis	PinMenu,SwitchMenu					; petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitMenuEntreeBypassSave	; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

; -- Sauvegarde de la nouvelle valeur

; -- En RAM

		ldi		ZH,RAM_Start
 		ldi		ZL,RAM_In_Bypass 					; Récupère l'adresse
		st		Z,MenuReg1							; et sauvegarde la valeur en RAM

; -- En EEPROM

		ldi		Work,EE_In_Bypass					; Position dans l'EEPROM
		mov		Work2,MenuReg1						; Valeur transférée dans Work2 pour la routine d'EEPROM
		call	WriteEEprom							; et on écrit

		ret											; et on se casse de ce menu

ExitMenuEntreeBypassNoSave:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	ExitMenuEntreeBypassNoSave			; des sorties de menu en cascade

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; on se casse de ce menu

; ==================================================================================================
; == Routine pour sauter certains caractères non utiles dans la table de caractère de l'afficheur ==
; == Utilisé pour l'OPTREX seulement                                                              ==
; ==================================================================================================

TestDisplayIncASCII:
		inc		Char								; On incrémente le registre
		cpi		Char,8								; Saute la zone 8-15
		brne	IncTestChar128						; va tester la zone 128-160
		ldi		Char,32								
		ret
IncTestChar128:
		cpi		Char,128							; Pour sauter une zone non définie
		brne	IncTestChar166						; dans la mémoire du Display (entre 128 et 160 compris)
		ldi		Char,161
		ret											; et on va afficher la chaine qu'il faut
IncTestChar166:										; Saute les caractères japonais (166-175)
		cpi		Char,166
		brne	IncTestChar177
		ldi		Char,176
		ret											; et on va afficher la chaine qu'il faut
IncTestChar177:										; Garde le 176 et saute 177-222
		cpi		Char,177
		brne	IncTestBye
		ldi		Char,223
IncTestBye:
		ret											; et on se casse
		

TestDisplayDecASCII:								; Décrémentation du numéro de menu
		dec		Char								; On décrémente le registre
		cpi		Char,222
		brne	DecTestChar175
		ldi		Char,176
		ret
DecTestChar175:
		cpi		Char,175
		brne	DecTestChar160
		ldi		Char,165
		ret
DecTestChar160:
		cpi		Char,160
		brne	DecTestChar31
		ldi		Char,127
		ret
DecTestChar31:
		cpi		Char,31
		brne	DecTestBye
		ldi		Char,7
DecTestBye:
		ret

; ---------------------------------------------------------
; --                                                     --
; -- Affichage de la correction de volume sur une entrée --
; --                                                     --
; -- La valeur à afficher est dans MenuReg2              --
; -- Si le bit 7 est à 1, la valeur est négative         --
; -- et si elle est à zéro, c'est positif                --
; --                                                     --
; ---------------------------------------------------------

MenuAfficheInpVol:

; On commence par effacer l'ancienne valeur en réécrivant toute la ligne

		ldi		Work,0x40							; début de seconde ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuInpVolValMessage*2)		; Chaine à afficher
		ldi		ZL,LOW(MenuInpVolValMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

	    ldi		Work,0x4A							; On se place au bon endroit
		call	DisplayPlaceCurseur					; pour écrire la valeur

		sbrs	MenuReg2,7							; C'est une valeur négative ?
		rjmp	MenuTestTrimPlus		    		; Non, c'est positif (ou nul)
		
		ldi		Char,'-'							; Oui, c'est négatif
		call	DisplayWriteChar					; et on commence par écrire un '-'
		rjmp	MenuAfficheTrimValue

MenuTestTrimPlus:
	    ldi		Work,0								; Vérifie que ce n'est pas une valeur nulle 
		cp		Work,MenuReg2
		brne 	TrimPlus							; C'est pas zéro

		ldi		Char,32								; Sinon, on n'écrit pas de signe
		call	DisplayWriteChar
		rjmp	MenuAfficheTrimValue

TrimPlus:
		ldi		Char,'+'							; Ecrit le "+"
		call	DisplayWriteChar

MenuAfficheTrimValue:
		mov		Work,MenuReg2						; Copie la valeur dans un reistre de travail
		cbr		Work,0b10000000						; Efface le bit de signe pour ne garder que la valeur

; -- On convertit la valeur en décimal --

		mov		Work3,Work							; 3 additions -> Multiplication par 3
		add		Work3,Work							; 
		add		Work3,Work							; la valeur max est 3x8 donc on n'a pas besoin du bit de carry... 

		mov		Work2,Work3							; Conserve la valeur, on va en avoir besoin car les deux derniers bits vont être perdus durant le décalage à droite
		lsr		Work3								; Première division par 2,pas besoin de shifter le bit de "Carry"
		lsr		Work3								; Seconde division par deux

		andi	Work2,0b00000011					; on ne garde que les deux bits qui auraient été perdus lors du shift
		mov		LSDVol,Work3						; et le nombre "principal"

; Arrivés ici, on a le résultat de l'opération dans LSDVol et les décimales dans Work2

		call	BinaireToBCD						; transforme ça en un nombre à deux chiffres (MSDVol et LSDVol)

		mov		Char,LSDVol				
		call	DisplayWriteChar					; Affiche le chiffre des unités

		ldi		Char,'.'							; Affiche le point décimal
		call	DisplayWriteChar

; -- On s'attaque maintenant aux décimales (contenues dans Work2)

		cpi		Work2,0								; Si on a zéro, c'est '00' qu'il faut afficher
		brne	NextTenthTrim1						; c'est pas zéro

		ldi		Char,'0'							; Deux écritures de "0"
		call	DisplayWriteChar
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim1:	

		cpi		Work2,1								; si on a 1, c'est "0.25"
		brne	NextTenthTrim2						; c'est pas ça

		ldi		Char,'2'							; on écrit "25"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim2:	

		cpi		Work2,2								; si on a 2, c'est "0.50"
		brne	NextTenthTrim3						; c'est toujours pas ça

		ldi		Char,'5'							; on écrit "50"
		call	DisplayWriteChar
		ldi		Char,'0'
		call	DisplayWriteChar
		rjmp	TrimFinDB

NextTenthTrim3:										; arrivé ici, c'est sûrement 3, donc il faut écrire "0.75"

		ldi		Char,'7'							; on écrit "50"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar

TrimFinDB:											; Termine en écrivant 'dB'

		ldi		Char,'d'
		call	DisplayWriteChar
		ldi		Char,'B'
		call	DisplayWriteChar

		ret											; Et mission accomplie

; ==============================================
; == Récupère la valeur du volume avant modif ==
; ==============================================

MenuRecupereVolume:

		ldi		ZL,RAM_ModVol_In1					; Quelle valeur de modif de volume avait-on ?
		add		ZL,MenuReg1							; Pointe sur la bonne entrée
		ld		Work2,Z

		cpi		Work2,0								; Si c'était zéro
		breq	MenuStoreVol						; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'était une valeur négative (bit 7 à 1) 
	    rjmp	MenuInputVolWasMore					; ou positive (bit 7 à 0)
		rjmp	MenuInputVolWasLess

MenuInputVolWasMore:
		cp		VolReg,Work2						; Avant de soustraire la valeur, on vérifie qu'on peut bien l'enlever
		brlo	MenuOldVol2Min						; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	MenuStoreVol

MenuOldVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	MenuStoreVol						; et on passe au volume de la nouvelle entrée

MenuInputVolWasLess:								; On avait enlevé du volume
		cbr		Work2,0b10000000					; on met le bit 7 à 0
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	MenuOldVol2Max						; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranchée
		rjmp	MenuStoreVol						; et on passe au nouveau volume

MenuOldVol2Max:
		ldi		Work,VolumeMaxi						; sinon on met au maxi
		mov		VolReg,Work							; et on passe à la suite

MenuStoreVol:
		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_TempVolume					; le volume non corrigé
		st		Z,VolReg

		ret

				
