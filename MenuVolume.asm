; ==========================================================
; == Le menu pour le volume                               ==
; ==                                                      == 
; ==   - Encodeur -> Navigue dans les différentes options ==
; ==   - Menu     -> Entrer dans une option               ==
; ==   - Standby  -> Remonter au niveau précédent         ==
; ==                                                      == 
; ==========================================================

MenuVolume :

WaitMenuVol:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuVol							; On attend le relachement du bouton de menu

; OK, on a lâché le bouton

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message"

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuVolumeBalanceMessage*2)
		ldi		ZL,LOW(MenuVolumeBalanceMessage*2)
		call	DisplayAfficheChaine				; Et on affiche le premier item du menu (la balance)
		call	DisplayArrow						; et les flèches de l'encodeur

		clr		MenuReg1

LoopLevelV0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVolumeMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitVolumeMenu						; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelV0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevelV0							; Non, on boucle

		rjmp	WhatVolumeMenuToEnter				; sinon on entre dans le menu de config qu'il faut
			
ChangeVolumeMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVolMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVolMenuReg1						; vers le bas ?
		rjmp	LoopLevelV0							; Aucun des deux, alors cassos

IncVolMenuReg1:										; Incrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,7								; c'est le dernier menu ?
		brne	DoIncVolMR1							; non, alors on peut incrémenter sans pb

		clr		MenuReg1							; sinon, on le repasse à 0		
		rjmp	AfficheMenuVol0						; et on va afficher la chaine qu'il faut
DoIncVolMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	AfficheMenuVol0						; et on va afficher la chaine qu'il faut

DecVolMenuReg1:										; Décrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecVolMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,7
		mov		MenuReg1,Work						; sinon, on le repasse à 7		
		rjmp	AfficheMenuVol0						; et on va afficher la chaine qu'il faut
DoDecVolMR1:
		dec		MenuReg1							; On décrémente le registre

AfficheMenuVol0:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 3)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,0x40							; On se place en début de seconde ligne
		call	DisplayPlaceCurseur

		mov		Work,MenuReg1						; On met le registre dans un registre immédiat

TestMenuVolumeBal:

		cpi		Work,0								; C'est 0 ?
		brne	TestMenuVolStart					; Nan...

		ldi		ZH,HIGH(MenuVolumeBalanceMessage*2)	; Oui, c'est 0
		ldi		ZL,LOW(MenuVolumeBalanceMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolStart:

		cpi		Work,1								; C'est 1 ?
		brne	TestMenuMuteLevel					; Nan...

		ldi		ZH,HIGH(MenuVolumeStartupMessage*2)	; Oui, c'est 1
		ldi		ZL,LOW(MenuVolumeStartupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuMuteLevel:

		cpi		Work,2								; C'est 2 ?
		brne	TestMenuVolDisplay					; Nan...

		ldi		ZH,HIGH(MenuVolumeMuteLevelMessage*2); Oui, c'est 2
		ldi		ZL,LOW(MenuVolumeMuteLevelMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolDisplay:

		cpi		Work,3								; C'est 3 ?
		brne	TestMenuVolMBBOff					; Nan...

		ldi		ZH,HIGH(MenuVolumeDisplayMessage*2)	; Oui, c'est 3
		ldi		ZL,LOW(MenuVolumeDisplayMessage*2)
		call	DisplayAfficheChaine				; Affiche la chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolMBBOff:

		cpi		Work,4								; C'est 4 ?
		brne	TestMenuVolMBBOn					; Nan...

		ldi		ZH,HIGH(MenuVolumeDelayOffMessage*2)
		ldi		ZL,LOW(MenuVolumeDelayOffMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolMBBOn:

		cpi		Work,5								; C'est 5 ?
		brne	TestMenuVolSpeedup					; Nan...

		ldi		ZH,HIGH(MenuVolumeDelayOnMessage*2)
		ldi		ZL,LOW(MenuVolumeDelayOnMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolSpeedup:

		cpi		Work,6								; C'est 6 ?
		brne	TestMenuVolEncoderStep				; Nan...

		ldi		ZH,HIGH(MenuVolSpeedupMessage*2)
		ldi		ZL,LOW(MenuVolSpeedupMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

TestMenuVolEncoderStep:

		ldi		ZH,HIGH(MenuVolEncoderStepMessage*2)
		ldi		ZL,LOW(MenuVolEncoderStepMessage*2)
		call	DisplayAfficheChaine				; Affiche la première chaine de setup
		call	DisplayArrow						; et les flèches de l'encodeur

		rjmp	LoopLevelV0							; et on continue la boucle

WhatVolumeMenuToEnter:

		mov		Work,MenuReg1						; Transfert en immédiat

MVTest0:cpi		Work,0								; si c'est 0
		brne	MVTest1
		rjmp	EnterMenuVolBalance					; on va triturer le menu de balance

MVTest1:cpi		Work,1								; si c'est 1
		brne	MVTest2
		rjmp	EnterMenuVolStart					; on va triturer le menu de StartupVolume

MVTest2:cpi		Work,2								; si c'est 2
		brne	MVTest3
		rjmp	EnterMenuMuteLevel					; on va triturer le menu de Mute Level

MVTest3:cpi		Work,3								; si c'est 3
		brne	MVTest4
		rjmp	EnterMenuVolDisplay					; on va triturer le menu de l'affichage du volume

MVTest4:cpi		Work,4								; si c'est 4
		brne	MVTest5
		rjmp	EnterMenuVolMBBOff					; on va triturer le menu du délai MBB

MVTest5:cpi		Work,5								; Comme pour 5, d'ailleurs
		brne	MVTest6
		rjmp	EnterMenuVolMBBOn					; on va triturer le menu du délai MBB

MVTest6:cpi		Work,6								; si c'est 6
		brne	MVTest7
		rjmp	EnterMenuVolSpeedup					; on va triturer le menu de Speedup de volume

MVTest7:cpi		Work,7								; si c'est 6
		brne	MVTest0
		rjmp	EnterMenuVolEncoderStep				; on va triturer le menu du pas d'encodeur


EnterMenuVolBalance:								; on va triturer le menu de balance

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolumeBal					; Sinon,on revient au bon endroit

		rcall	MenuBalance							; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur						; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		clr		Work
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolumeBal					; et on revient au bon endroit

EnterMenuVolStart:									; on va triturer le menu de StartupVolume

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolStart					; Sinon,on revient au bon endroit

		rcall	MenuStartVol						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,1
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolStart					; et on revient au bon endroit

EnterMenuMuteLevel:									; on va triturer le menu de Mute Level

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuMuteLevel					; Sinon,on revient au bon endroit

		rcall	MenuMuteLevel						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,2
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuMuteLevel					; et on revient au bon endroit

EnterMenuVolDisplay:								; on va triturer le menu de l'affichage du volume

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolDisplay					; Sinon,on revient au bon endroit

		rcall	MenuVolDisplay						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,3
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolDisplay					; et on revient au bon endroit

EnterMenuVolMBBOff:									; on va triturer le menu du délai MBB

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolMBBOff					; Sinon,on revient au bon endroit

		rcall	MenuVolMBBOff						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,4
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolMBBOff					; et on revient au bon endroit

EnterMenuVolMBBOn:									; on va triturer le menu du délai MBB

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolMBBOn					; Sinon,on revient au bon endroit

		rcall	MenuVolMBBOn						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur						; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,5
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolMBBOn					; et on revient au bon endroit

EnterMenuVolSpeedup:								; on va triturer le menu de speedup

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolSpeedup					; Sinon,on revient au bon endroit

		rcall	MenuVolSpeedup						; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,6
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolSpeedup					; et on revient au bon endroit

EnterMenuVolEncoderStep:							; on va triturer le menu du pas d'encodeur

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	TestMenuVolEncoderStep				; Sinon,on revient au bon endroit

		rcall	MenuVolEncoderStep					; On y va

; -- Rétablissement de l'affichage au retour

		ldi		Work,0								; Début de première ligne 
		call	DisplayPlaceCurseur					; 
		ldi		ZH,HIGH(MenuVolumeTopMessage*2)
		ldi		ZL,LOW(MenuVolumeTopMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		ldi		Work,7
		mov		MenuReg1,Work						; On remet la bonne valeur dans MenuReg1
		rjmp	TestMenuVolEncoderStep				; et on revient au bon endroit


ExitVolumeMenu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation ?
		rjmp	LoopLevelV0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitVolumeMenu:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitVolumeMenu			; des sorties de menu en cascade

		ret											; on se casse de ce menu

; =============================================
; == Edition de la balance                   ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            == 
; =============================================

MenuBalance:

WaitMenuBalance:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuBalance						; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; On sauvegarde l'ancienne valeur en cas d'annulation
		ldi		ZL,RAM_Tempo
		st		Z,BalanceReg

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(BalanceMessage*2)			; Affiche le message correspondant à la balance
		ldi		ZL,LOW(BalanceMessage*2)
		call	DisplayAfficheChaine

		call 	AfficheBalanceNoClear				; Affiche la valeur actuelle de la balance sur la seconde ligne

LoopBalance0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeBalanceMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitBalanceMenuNoSave				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopBalance0						; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopBalance0						; Non, on boucle

		rjmp	ExitBalanceMenu						; sinon on se prépar à sortir de cette page

ChangeBalanceMenu:									; On a touché l'encodeur -> Faut changer la balance

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeBalanceMenu						
		rcall	LanceClignotementLED

DoChangeBalanceMenu:
		call	AjusteBalance						; on y va donc,
		rjmp	LoopBalance0						; et on reboucle

ExitBalanceMenu:									; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitBalanceMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,BalanceReg					; La valeur de BalanceReg a été modifiée dans AjusteBalance,
		ldi		Work,EE_Balance						; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ret											; et voilou

ExitBalanceMenuNoSave: 								; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitBalanceMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		ld		BalanceReg,Z						; On récupère la valeur sauvegardée au début
	
		ldi		ZL,RAM_Balance						; Adresse de la valeur en RAM
		st		Z,BalanceReg						; et on met la valeur en RAM

		call	SetVolume							; On transmet ça aux relais de volume (avec prise en compte de la balance)

MenuBalWaitMBB:		
		sbrc	StatReg2,FlagMBB					; Attend la fin de la séquence de MBB
		rjmp	MenuBalWaitMBB						; Avant de passer à la suite

		ret											; et voualou

; =============================================
; == Edition du volume au démarrage			 ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            ==
; =============================================

MenuStartVol:

WaitMenuSTV:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuSTV							; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartVolume					; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuStartVolumeTopMessage*2); Affiche le message correspondant au comportement
		ldi		ZL,LOW(MenuStartVolumeTopMessage*2)
		call	DisplayAfficheChaine

		call	AfficheMenuVolStart					; et on affiche la valeur

LoopSTV0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeSTVMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour annuler ?
		rjmp	ExitSTVMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopSTV0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopSTV0							; Non, on boucle

		rjmp	ExitSTVMenu							; sinon on se prépar à sortir de cette page

ChangeSTVMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeSTVMenu						
		rcall	LanceClignotementLED

DoChangeSTVMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncSTVMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecSTVMenuReg1						; vers le bas ?
		rjmp	LoopSTV0							; Aucun des deux, alors cassos

IncSTVMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,2								; c'est le max ?
		brne	DoIncSTVMR1							; non, alors on peut incrémenter sans pb

		ldi		Work,0								; oui, alors on repasse au min
		mov		MenuReg1,Work
		rjmp	MenuActualiseSTV					; et on actualise

DoIncSTVMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseSTV					; et on modifie le paramètre

DecSTVMenuReg1:										; Décrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecSTVMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,2								; oui, alors on repasse au max
		mov		MenuReg1,Work
		rjmp	MenuActualiseSTV					; et on actualise

DoDecSTVMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseSTV					; et on modifier le paramètre

MenuActualiseSTV:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolStart					; on affiche la nouvelle valeur,
		rjmp	LoopSTV0							; et on reboucle

ExitSTVMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitSTVMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		mov		Work2,MenuReg1						; Et sauvegarde du paramètre en EEPROM
		ldi		Work,EE_StartVolume					; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_StartVolume
		st		Z,MenuReg1							; c'est fait

		mov		Work,MenuReg1						; Cependant, si on a choisi le preset de volume
		cpi		Work,1								; reste à choisir la valeur de ce preset
		breq	MenuVolumePreset					; C'est là

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ret											; sinon, on peut s'en aller

ExitSTVMenuNoSave: 									; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitSTVMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; et voualou

; ==============================================
; == Edition du preset de volume au démarrage ==
; ==                                          ==
; ==	- Encodeur pour changer la valeur     ==
; ==    - Menu pour valider et sortir         ==
; ==    - Standby/On pour annuler             == 
; ==============================================

MenuVolumePreset:

		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	MenuVolumePreset					; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; On sauvegarde la valeur du volume
		ldi		ZL,RAM_Tempo
		st		Z,VolReg

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_VolumePreset					; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1
		mov		VolReg,MenuReg1						; et on la place aussi dans le registre de volume

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPresetVolumeTopMessage*2); Affiche le message correspondant au comportement
		ldi		ZL,LOW(MenuPresetVolumeTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuPresetVolumeLowMessage*2); Affiche le message correspondant au comportement
		ldi		ZL,LOW(MenuPresetVolumeLowMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		sbrs	StatReg2,Flag6dB					; Est-ce que le volume en cours était augmenté de 6dB ?
		rjmp	MenuAfficheStartVol					; 	- Non -> On affiche tel quel

		ldi		Work,(VolumeMaxi-SixdBMore+1)		; On peut augmenter de 6dB ?
		cp		VolReg,Work
		brge	MenuSet6toMax						; 	 - Bénon
		ldi		Work,SixdBMore						; 	 - Béoui
		add		VolReg,Work							; 	   alors on ajoute
		rjmp	MenuAfficheStartVol					; et on peut afficher la nouvelle valeur

MenuSet6ToMax:
		ldi		Work,VolumeMaxi						; sinon on met le volume au maxi...
		mov		VolReg,Work

MenuAfficheStartVol:
		call	AfficheVolume						; On affiche la valeur
		call	SetVolume							; Et on met le volume à cette nouvelle valeur

LoopVoP0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVoPMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitVoPMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopVoP0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopVoP0							; Non, on boucle

		rjmp	ExitVoPMenu							; sinon on se prépar à sortir de cette page

ChangeVoPMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeVoPMenu						
		rcall	LanceClignotementLED

DoChangeVoPMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVoP								; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVoP								; vers le bas ?
		rjmp	LoopVoP0							; Aucun des deux, alors cassos

IncVoP:												; Incrémentation du paramètre
		mov		Work,VolReg							; transfert dans un registre immédiat
		cpi		Work,VolumeMaxi								; c'est le max ?
		brne	DoIncVoP							; non, alors on peut incrémenter sans pb
		rjmp	LoopVoP0							; oui, alors on ne fait rien

DoIncVoP:
		inc		VolReg								; On incrémente le registre
		rjmp	MenuActualiseVoP					; et on modifie le paramètre

DecVoP:												; Décrémentation du paramètre
		mov		Work,VolReg							; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecVoP							; non, alors on peut décrémenter sans pb
		rjmp	LoopVoP0							; oui, alors on ne fait rien

DoDecVoP:
		dec		VolReg								; On décrémente le registre
		rjmp	MenuActualiseVoP					; et on modifier le paramètre

MenuActualiseVoP:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheVolume						; on affiche la nouvelle valeur,
		call	SetVolume							; et on fait écouter ce que ça donne
		rjmp	LoopVoP0							; et on reboucle

ExitVoPMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitVoPMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		sbrs	StatReg2,Flag6dB					; Est-ce que ce volume était augmenté de 6dB pour une entrée asymétrique ? 
		rjmp	MenuWriteStartVolume				; 	- Non, alors on le stocke directement

		ldi		Work,SixdBMore						; 	- Oui, alors faut les enlever
		cp		VolReg,Work							;   	si on peut...
		brge	MenuSubstract6dBStartVol			;     	et là, on peut.
		clr		VolReg								; 		sinon on le met au min
		rjmp	MenuWriteStartVolume				; 		et on passe à la suite

MenuSubstract6dBStartVol:
		sub		VolReg,Work							; On retranche les 6dB

MenuWriteStartVolume:
		mov		Work2,VolReg						; Sauvegarde du paramètre en EEPROM
		ldi		Work,EE_VolumePreset				; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_VolumePreset
		st		Z,VolReg							; c'est fait

		ldi		ZL,RAM_Tempo						; Récupère la valeur du volume actuel
		ld		VolReg,Z
		call	SetVolume							; et on remet ça sur les relais

MenuVoPWaitMBB1:		
		sbrc	StatReg2,FlagMBB					; Attend la fin de la séquence de MBB
		rjmp	MenuVoPWaitMBB1						; Avant de passer à la suite

		ret											; et voilou

ExitVoPMenuNoSave: 									; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitVoPMenuNoSave

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo						; Récupère la valeur du volume actuel
		ld		VolReg,Z

		call	SetVolume							; et on remet ça sur les relais

MenuVoPWaitMBB2:		
		sbrc	StatReg2,FlagMBB					; Attend la fin de la séquence de MBB
		rjmp	MenuVoPWaitMBB2						; Avant de passer à la suite

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret

; ==========================================
; == Edition du volume de mute            ==
; ==                                      ==
; ==	- Encodeur pour changer la valeur ==
; ==    - Menu pour valider et sortir     ==
; ==    - Standby/On pour annuler         == 
; ==========================================

MenuMuteLevel:

WaitMenuVoML:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuVoML						; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; On sauvegarde la valeur du volume
		ldi		ZL,RAM_Tempo
		st		Z,VolReg

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_MuteLevel					; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1
		mov		VolReg,MenuReg1						; et on la place aussi dans le registre de volume

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMuteLevelTopMessage*2)	; Affiche le message correspondant au comportement
		ldi		ZL,LOW(MenuMuteLevelTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuMuteLevelLowMessage*2)	; Affiche le message correspondant au comportement
		ldi		ZL,LOW(MenuMuteLevelLowMessage*2)
		call	DisplayAfficheChaine
		call	DisplayArrow

		ldi		Work,MuteLevelOff					; 
		cp		VolReg,Work							; C'est un mute total ?
		breq	MenuVoMLAfficheOff					; Ben oui, alors on l'affiche

		sbrs	StatReg2,Flag6dB					; Est-ce que le volume en cours était augmenté de 6dB ?
		rjmp	MenuAfficheMuteLevel				; 	- Non -> On affiche tel quel

		ldi		Work,(VolumeMaxi-SixdBMore+1)		; On peut augmenter de 6dB ?
		cp		VolReg,Work
		brge	MenuSet6toMaxML						; 	 - Bénon
		ldi		Work,SixdBMore						; 	 - Béoui
		add		VolReg,Work							; 	   alors on ajoute
		rjmp	MenuAfficheMuteLevel				; et on peut afficher la nouvelle valeur

MenuSet6ToMaxML:
		ldi		Work,VolumeMaxi						; sinon on met le volume au maxi...
		mov		VolReg,Work

MenuAfficheMuteLevel:
		ldi		Work,MuteLevelOff					; Teste d'abord si on est en mute total
		cp		VolReg,Work							; 
		breq	MenuVoMLAfficheOff

		call	AfficheVolume						; On affiche la valeur
		call	SetVolume							; Et on met le volume à cette nouvelle valeur
		rjmp	LoopVoML
		
MenuVoMLAfficheOff:
		call	AfficheOff							; Affiche 'Off' sur le Display

	    MacroMuteOn									; Mute la sortie (Relais de mute au repos)
		sbr		StatReg1,EXP2(FlagMute)				; Signale qu'on est en mute (bit à 1)
		
LoopVoML:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVoMLMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitVoMLMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopVoML							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopVoML							; Non, on boucle

		rjmp	ExitVoMLMenu						; sinon on se prépar à sortir de cette page

ChangeVoMLMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeVoMLMenu						
		rcall	LanceClignotementLED

DoChangeVoMLMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVoML								; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVoML								; vers le bas ?
		rjmp	LoopVoML							; Aucun des deux, alors cassos

IncVoML:											; Incrémentation du paramètre
		ldi		Work,MuteLevelOff
		cpse	Work,VolReg
		rjmp	MenuVoMLTesteMax					; on teste normalement

		clr		VolReg								; Sinon on met le volume au minimum
		cbr		StatReg1,EXP2(FlagMute)				; On signale qu'on n'est plus en mute

	    MacroMuteOff								; Passe le relais de mute à 1 (La sortie devient active)
		rjmp	MenuActualiseVoML					; et on actualise...

MenuVoMLTesteMax:
		mov		Work,VolReg							; transfert dans un registre immédiat
		cpi		Work,VolumeMaxi								; c'est le max ?
		brne	DoIncVoML							; non, alors on peut incrémenter sans pb
		rjmp	LoopVoML							; oui, alors on ne fait rien

DoIncVoML:
		inc		VolReg								; On incrémente le registre
		rjmp	MenuActualiseVoML					; et on modifie le paramètre

DecVoML:											; Décrémentation du paramètre
		ldi		Work,MuteLevelOff					; Si on n'est pas 'Off'
		cpse	Work,VolReg							; 
		rjmp	MenuVoMLTestMin						; On teste comme d'hab
		rjmp	LoopVoML							; Sinon on ne peut pas décrémenter

MenuVoMLTestMin:
		mov		Work,VolReg			 				; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecVoML							; non, alors on peut décrémenter sans pb

		ldi		Work,MuteLevelOff					; Sinon, on passe en mute...
		mov		VolReg,Work
		sbr		StatReg1,EXP2(FlagMute)				; On signale qu'on est passé en mute
		MacroMuteOn									; Passe le relais de mute à 0 (Mute au repos)
		rjmp	MenuActualiseVoML					; et on actualise...

DoDecVoML:
		dec		VolReg								; On décrémente le registre
		rjmp	MenuActualiseVoML					; et on modifie le paramètre

MenuActualiseVoML:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		ldi		Work,MuteLevelOff					; Si la valeur n'est pas le 'Off'
		cp		VolReg,Work
		brne	MenuVoMLAfficheNormal				; On affiche normalement le volume

		call	AfficheOff							; Affiche 'Off' sur le Display
		rjmp	LoopVoML

MenuVoMLAfficheNormal:
		call	AfficheVolume						; on affiche la nouvelle valeur,
		call	SetVolume							; et on fait écouter ce que ça donne
		rjmp	LoopVoML							; et on reboucle

ExitVoMLMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitVoMLMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ldi		Work,MuteLevelOff					; Est-ce que la nouvelle  valeur, c'est le mute total ?
		cp		Work,VolReg
		breq	MenuWriteMuteLevel					; 	Oui -> On saute la phase des 6dB

		sbrs	StatReg2,Flag6dB					; 	Non, mais est-ce que ce volume était augmenté de 6dB pour une entrée asymétrique ? 
		rjmp	MenuWriteMuteLevel					; 	- Non, alors on le stocke directement

		ldi		Work,SixdBMore						; 	- Oui, alors faut les enlever
		cp		VolReg,Work							;   	si on peut...
		brge	MenuSubstract6dBMuteLevel			;     	et là, on peut.
		clr		VolReg								; 		sinon on le met au min
		rjmp	MenuWriteMuteLevel					; 		et on passe à la suite

MenuSubstract6dBMuteLevel:
		sub		VolReg,Work							; On retranche les 6dB

MenuWriteMuteLevel:
		mov		Work2,VolReg						; Sauvegarde du paramètre en EEPROM
		ldi		Work,EE_MuteLevel					; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_MuteLevel
		st		Z,VolReg							; c'est fait

		ldi		ZL,RAM_Tempo						; Récupère la valeur du volume actuel
		ld		VolReg,Z
		call	SetVolume							; et on remet ça sur les relais

MenuMLWaitMBB1:		
		sbrc	StatReg2,FlagMBB					; Attend la fin de la séquence de MBB
		rjmp	MenuMLWaitMBB1						; Avant de passer à la suite

		ret											; et voilou

ExitVoMLMenuNoSave: 								; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitVoMLMenuNoSave

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo						; Récupère la valeur du volume actuel
		ld		VolReg,Z

		call	SetVolume							; et on remet ça sur les relais

MenuMLWaitMBB2:		
		sbrc	StatReg2,FlagMBB					; Attend la fin de la séquence de MBB
		rjmp	MenuMLWaitMBB2						; Avant de passer à la suite

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret

; =============================================
; == Edition du mode d'affichage du volume   ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            ==
; =============================================

MenuVolDisplay:

WaitMenuVDM:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuVDM							; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_AffichageVolume				; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolumeTypeTopMessage*2)	; Affiche le message correspondant au Mode d'affichage
		ldi		ZL,LOW(MenuVolumeTypeTopMessage*2)
		call	DisplayAfficheChaine

		call	AfficheMenuVolType					; et on affiche la valeur

LoopVDM0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVDMMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitVDMMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopVDM0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopVDM0							; Non, on boucle

		rjmp	ExitVDMMenu							; sinon on se prépar à sortir de cette page

ChangeVDMMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeVDMMenu						
		rcall	LanceClignotementLED

DoChangeVDMMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVDMMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVDMMenuReg1						; vers le bas ?
		rjmp	LoopVDM0							; Aucun des deux, alors cassos

IncVDMMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,3								; c'est le max ?
		brne	DoIncVDMMR1							; non, alors on peut incrémenter sans pb

		ldi		Work,0								; oui, alors on repasse au min
		mov		MenuReg1,Work
		rjmp	MenuActualiseVDM					; et on actualise

DoIncVDMMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseVDM					; et on modifie le paramètre

DecVDMMenuReg1:										; Décrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecVDMMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,3								; oui, alors on repasse au max
		mov		MenuReg1,Work
		rjmp	MenuActualiseVDM					; et on actualise

DoDecVDMMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseVDM					; et on modifier le paramètre

MenuActualiseVDM:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolType					; on affiche la nouvelle valeur,
		rjmp	LoopVDM0							; et on reboucle

ExitVDMMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitVDMMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg1						; Et sauvegarde du paramètre en EEPROM
		ldi		Work,EE_AffichageVolume				; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_AffichageVolume
		st		Z,MenuReg1							; c'est fait

		ret											; et voilou

ExitVDMMenuNoSave: 									; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitVDMMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; et voualou

; =============================================
; == Edition du délai de Make Before Break   ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            == 
; =============================================

MenuVolMBBOff:

WaitMenuMBBOff:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuMBBOff						; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		st		Z,DelayPot							; On sauvegarde l'ancienne valeur en cas d'annulation
		mov		MenuReg1,DelayPot					; Transfère pour l'édition

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolumeDelayOffTopMessage*2); Affiche le message correspondant au MBB
		ldi		ZL,LOW(MenuVolumeDelayOffTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; Se place au début de la seconde ligne du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolumeDelayLowMessage*2); Affiche le message correspondant au MBB
		ldi		ZL,LOW(MenuVolumeDelayLowMessage*2)
		call	DisplayAfficheChaine

		call 	AfficheMenuVolMBBOff				; Affiche la valeur actuelle du délai sur la seconde ligne

LoopMBB0Off:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeMBBOffMenu					; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitMBBOffMenuNoSave				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopMBB0Off							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopMBB0Off							; Non, on boucle

		rjmp	ExitMBBOffMenu						; sinon on se prépar à sortir de cette page

ChangeMBBOffMenu:									; On a touché l'encodeur -> Faut changer le délai

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeMBBOffMenu						
		rcall	LanceClignotementLED

DoChangeMBBOffMenu:									; ATTENTION ici, l'incrémentation et la décrémentation sont inversés
													; car la valeur minimale correspond à un délai maximum et lycée de Versailles

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	DecMBBOffMenuReg1					; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	IncMBBOffMenuReg1						; vers le bas ?
		rjmp	LoopMBB0Off							; Aucun des deux, alors cassos

IncMBBOffMenuReg1:									; Incrémentation du délai
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,255							; c'est le max ?
		brne	DoIncMBBOffMR1						; non, alors on peut incrémenter sans pb

		rjmp	LoopMBB0Off							; Sinon, on ne fait rien

DoIncMBBOffMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseMBBOff					; et on modifie le délai

DecMBBOffMenuReg1:									; Décrémentation du délai
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecMBBOffMR1						; non, alors on peut décrémenter sans pb

		rjmp	LoopMBB0Off							; Sinon, on ne fait rien

DoDecMBBOffMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseMBBOff					; et on modifier le délai

MenuActualiseMBBOff:								; On modifie vraiment le délai

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolMBBOff				; on affiche la nouvelle valeur,
		rjmp	LoopMBB0Off							; et on reboucle

ExitMBBOffMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMBBOffMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		DelayPot,MenuReg1					; on sauve la valeur dans son registre

		mov		Work2,MenuReg1						; Dans l'EEPROM aussi
		ldi		Work,EE_DelaiVolume					; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_DelaiVolume
		st		Z,DelayPot							; c'est fait

		ret											; et voilou

ExitMBBOffMenuNoSave: 								; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitMBBOffMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		ld		DelayPot,Z							; On récupère la valeur sauvegardée au début
	
		ldi		ZL,RAM_DelaiVolume					; Adresse de la valeur en RAM
		st		Z,DelayPot							; et on met la valeur en RAM

		ret											; et voualou

; =============================================
; == Edition du délai de Make Before Break   ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            == 
; =============================================

MenuVolMBBOn:

WaitMenuMBBOn:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuMBBOn						; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_DelaiRecolleVol
		ld		MenuReg1,Z							; On récupère la valeur
		ldi		ZL,RAM_Tempo
		st		Z,MenuReg1							; On sauve ça en RAM temporaire

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolumeDelayOnTopMessage*2); Affiche le message correspondant au MBB
		ldi		ZL,LOW(MenuVolumeDelayOnTopMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; Se place au début de la seconde ligne du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolumeDelayLowMessage*2); Affiche le message correspondant au MBB
		ldi		ZL,LOW(MenuVolumeDelayLowMessage*2)
		call	DisplayAfficheChaine

		call 	AfficheMenuVolMBBOn					; Affiche la valeur actuelle du délai sur la seconde ligne

LoopMBB0On:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeMBBOnMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitMBBOnMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopMBB0On							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopMBB0On							; Non, on boucle

		rjmp	ExitMBBOnMenu						; sinon on se prépare à sortir de cette page

ChangeMBBOnMenu:									; On a touché l'encodeur -> Faut changer le délai

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeMBBOnMenu						
		rcall	LanceClignotementLED

DoChangeMBBOnMenu:									

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncMBBOnMenuReg1					; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecMBBOnMenuReg1					; vers le bas ?
		rjmp	LoopMBB0On							; Aucun des deux, alors cassos

IncMBBOnMenuReg1:									; Incrémentation du délai
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,255							; c'est le max ?
		brne	DoIncMBBOnMR1						; non, alors on peut incrémenter sans pb

		rjmp	LoopMBB0On							; Sinon, on ne fait rien

DoIncMBBOnMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseMBBOn					; et on modifie le délai

DecMBBOnMenuReg1:									; Décrémentation du délai
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecMBBOnMR1						; non, alors on peut décrémenter sans pb

		rjmp	LoopMBB0On							; Sinon, on ne fait rien

DoDecMBBOnMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseMBBOn					; et on modifier la valeur

MenuActualiseMBBOn:									; On modifie vraiment la valeur du délai

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolMBBOn					; on affiche la nouvelle valeur,
		rjmp	LoopMBB0On							; et on reboucle

ExitMBBOnMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitMBBOnMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg1						; On sauve dans l'EEPROM
		ldi		Work,EE_DelaiRecolleVol				; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_DelaiRecolleVol
		st		Z,MenuReg1							; c'est fait

		ret											; et voilou

ExitMBBOnMenuNoSave: 								; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitMBBOnMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_Tempo
		ld		MenuReg1,Z							; On récupère la valeur sauvegardée au début
	
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_DelaiRecolleVol				; Adresse de la valeur en RAM
		st		Z,MenuReg1							; et on met la valeur en RAM

		ret											; et voualou

; ====================================================
; == Affiche le comportement du volume au démarrage ==
; ====================================================

AfficheMenuVolStart:

		mov		Work1,MenuReg1						; Récupère l'indication du comportement

AfficheMenuVolStartNoRAM:							; Autre point d'entrée de la routine

		ldi		Work,0x40							; Début de la seconde ligne
		call	DisplayPlaceCurseur					; de l'afficheur

		cpi		Work1,0								; Volume au mini ?
		brne	MenuIsVolStartPreset				; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolStartMiniMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolStartMiniMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolStartPreset:

		cpi		Work1,1								; Preset de volume ?
		brne	MenuIsVolStartLast					; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolStartPresetMessage*2);	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolStartPresetMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow							; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolStartLast:

		ldi		ZH,HIGH(MenuVolStartLastMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolStartLastMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow							; et les flèches de l'encodeur
		ret											; et on s'en va

; ====================================================
; == Type d'affichage du volume (dB/Normal/Binaire) ==
; ====================================================

AfficheMenuVolType:

		mov		Work1,MenuReg1						; Récupère la valeur du paramètre dans un registre immédiat

		ldi		Work,0x40							; Début de la seconde ligne
		call	DisplayPlaceCurseur						; de l'afficheur

		cpi		Work1,0								; Volume au mini ?
		brne	MenuIsVolTypeDecimal				; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolTypeDBMessage*2)		;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolTypeDBMessage*2)		; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolTypeDecimal:

		cpi		Work1,1								; Preset de volume ?
		brne	MenuIsVolTypeBinary					; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolTypeDecMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolTypeDecMessage*2)		; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolTypeBinary:

		cpi		Work1,2								; Preset de volume ?
		brne	MenuIsVolTypeGraphic				; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolTypeBinaryMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolTypeBinaryMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		
MenuIsVolTypeGraphic:

		ldi		ZH,HIGH(MenuVolTypeGraphicMessage*2);	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolTypeGraphicMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		
		ret											; et on s'en va

		
; =======================================================================
; == Affiche la valeur du délai de MBB pour le potentiomètre de volume ==
; =======================================================================

AfficheMenuVolMBBOff:

		ldi		Work,0x4A							; On place le curseur sur le 9ème caractère
		call	DisplayPlaceCurseur					; de la seconde ligne

		mov		Work,MenuReg1						; Recopie la valeur
		com		Work								; Complément à $FF car la valeur sert de départ pour l'overflow (jusqu'à $FF)
		
; -- Comme le pas du timer de MBB est de 16µs, 
; -- il "suffit" de multiplier la valeur par 16 
; -- pour avoir la valeur du délai en µs
; -- Le registre Work1 va contenir les
; -- bits décalés dans le bit de carry

		clr		Work1
		
		lsl		Work								; Premier décalage -> Multiplication par 2 
		rol		Work1								; On décale aussi Work1 en y mettant le bit de carry qui peut venir du lsl précédent

		lsl		Work								; Second décalage -> Multiplication par 4  
		rol		Work1								; On décale aussi Work1 en y mettant le bit de carry qui peut venir du lsl précédent

		lsl		Work								; Troisième décalage -> Multiplication par 8 
		rol		Work1								; On décale aussi Work1 en y mettant le bit de carry qui peut venir du lsl précédent

		lsl		Work								; Quatrième décalage -> Multiplication par 16 
		rol		Work1								; On décale aussi Work1 en y mettant le bit de carry qui peut venir du lsl précédent

		rcall	BinaireToBCD16						; Transforme la valeur binaire 16 bits dans Work1:Work en nombre de µs

		mov		Work3,MSDVol						; Transfère le registre contenant les 2 premiers chiffres

		andi	Work3, 0b11110000					; ne garde que le nibble de gauche (le premier chiffre)
		swap	Work3								; le décale à droite (swappe les nibbles)

		cpi		Work3,0								; c'est un zéro ?
		breq	MBBChiffre2							; 	- Oui -> on ne l'affiche pas
		mov		Char,Work3							;  	- Nan -> Alors on l'affiche
		subi	Char,-48							; on le passe en ASCII (ajoute 48)
		call	DisplayWriteChar					; et affichage
		ldi		Char,'.'							; Comme il y a un premier chiffre, ce sont des milliers de µs
		call	DisplayWriteChar					; alors on va l'afficher en ms en mettant un "."

MBBChiffre2:
		mov		Work2,MSDVol						; Transfert dans un registre temporaire
		andi	Work2,0b00001111					; Récupère la valeur qui nous intéresse
		cpi		Work2,0								; C'est un zéro ?
		brne 	MBBAfficheChiffre2					; 	- Nan, alors on l'affiche

		cpi		Work3,0								; 	- Oui, mais est-ce que le chiffre précédent était lui aussi un zéro ?
		breq	MBBChiffre3							; 		- Oui -> On passe au chiffre suivant

MBBAfficheChiffre2:
		mov		Char,Work2							; Transfère le registre contenant les 2 premiers chiffres
		subi	Char,-48							; Passe en ASCII
		call	DisplayWriteChar
		
MBBChiffre3:
		mov		Work1,LSDVol						; On s'occupe des deux derniers chiffres
		andi	Work1,0b11110000					; selon le même principe
		swap	Work1

		cpi		Work1,0								; C'est un zéro ?
		brne	MBBAfficheChiffre3					; 	- Non -> on l'affiche 

		cpi		Work2,0								; Le chiffre précédent, c'est 0 ?
		brne	MBBAfficheChiffre3					; 	- Nan -> On l'affiche
		cpi		Work3,0								; 	- Oui -> Mais le chiffre avant, c'est aussi un zéro ?
		brne	MBBAfficheChiffre3					; 		- Nan -> On l'affiche
		rjmp	MBBAfficheChiffre4					;		- Oui -> Faut pas afficher
MBBAfficheChiffre3:
		mov		Char,Work1
		subi	Char,-48
		call	DisplayWriteChar

MBBAfficheChiffre4:
		mov		Char,LSDVol
		andi	Char,0b00001111
		subi	Char,-48
		call	DisplayWriteChar

		ldi		Char,32								; un blanc avant d'afficher les unités
		call	DisplayWriteChar

		mov		Char,MSDVol							; On regarde à nouveau si le premier chiffre n'est pas un zéro
		andi	Char,0b11110000
		swap	Char
		cpi		Char,0
		breq	MBBAfficheMicro						; Si c'est 0, on va afficher "µ"
		ldi		Char,'m'							; sinon, on affiche "m"
		rjmp	MBBAfficheSeconde					; puis le "s" de seconde

MBBAfficheMicro:
#if defined(CRYSTALFONTZ)
		ldi		Char,0xEA							; le code ascii de "µ" pour le CrystalFontz
#else
		ldi		Char,0xE4							; le code ascii de "µ"
#endif
MBBAfficheSeconde:									; et termine l'affichage par "µs" ou "ms"
		call	DisplayWriteChar
		ldi		Char,'s'
		call	DisplayWriteChar
		
		ldi		Char,32
		call	DisplayWriteChar
		call	DisplayWriteChar

		call	DisplayArrow						; et les flèches de l'encodeur

		ret											; et voilà			 
; ===================================================================================
; == Affiche la valeur du délai de MBB pour le potentiomètre de volume (Recollage) ==
; ===================================================================================

AfficheMenuVolMBBOn:

		ldi		Work,0x4A							; On place le curseur sur le 9ème caractère
		call	DisplayPlaceCurseur					; de la seconde ligne

		mov		Work1,MenuReg1						; Recopie la valeur

		call	Affiche255

		ldi		Char,32								; 
		call	DisplayWriteChar
#if defined(CRYSTALFONTZ)
		ldi		Char,0xEA							; le code ascii de "µ" pour le CrystalFontz
#else
		ldi		Char,0xE4							; le code ascii de "µ"
#endif
		call	DisplayWriteChar
		ldi		Char,'s'
		call	DisplayWriteChar
		ldi		Char,32								; 
		call	DisplayWriteChar
		call	DisplayWriteChar

		call	DisplayArrow						; et les flèches de l'encodeur

		ret

; =============================================
; == Edition du mode de speed up du volume   ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            ==
; =============================================

MenuVolSpeedup:

WaitMenuVSM:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuVSM							; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_Speedup						; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolSpeedupMessage*2)	; Affiche le message correspondant au Mode de speedup
		ldi		ZL,LOW(MenuVolSpeedupMessage*2)
		call	DisplayAfficheChaine

		call	AfficheMenuVolSpeed					; et on affiche la valeur

LoopVSM0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVSMMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitVSMMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopVSM0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopVSM0							; Non, on boucle

		rjmp	ExitVSMMenu							; sinon on se prépar à sortir de cette page

ChangeVSMMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeVSMMenu						
		rcall	LanceClignotementLED

DoChangeVSMMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVSMMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVSMMenuReg1						; vers le bas ?
		rjmp	LoopVSM0							; Aucun des deux, alors cassos

IncVSMMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,2								; c'est le max ?
		brne	DoIncVSMMR1							; non, alors on peut incrémenter sans pb

		ldi		Work,0								; oui, alors on repasse au min
		mov		MenuReg1,Work
		rjmp	MenuActualiseVSM					; et on actualise

DoIncVSMMR1:
		inc		MenuReg1							; On incrémente le registre
		rjmp	MenuActualiseVSM					; et on modifie le paramètre

DecVSMMenuReg1:										; Décrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le min ?
		brne	DoDecVSMMR1							; non, alors on peut décrémenter sans pb

		ldi		Work,2								; oui, alors on repasse au max
		mov		MenuReg1,Work
		rjmp	MenuActualiseVSM					; et on actualise

DoDecVSMMR1:
		dec		MenuReg1							; On décrémente le registre
		rjmp	MenuActualiseVSM					; et on modifier le paramètre

MenuActualiseVSM:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolSpeed					; on affiche la nouvelle valeur,
		rjmp	LoopVSM0							; et on reboucle

ExitVSMMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitVSMMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg1						; Et sauvegarde du paramètre en EEPROM
		ldi		Work,EE_SpeedUp						; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_SpeedUp
		st		Z,MenuReg1							; c'est fait

		ret											; et voilou

ExitVSMMenuNoSave: 									; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitVSMMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; et voualou

; ============================================
; == Affichage du type de speedup du volume ==
; ============================================

AfficheMenuVolSpeed:

		mov		Work1,MenuReg1						; Récupère la valeur du paramètre dans un registre immédiat

		ldi		Work,0x40							; Début de la seconde ligne
		call	DisplayPlaceCurseur					; de l'afficheur

		cpi		Work1,0								; Volume au mini ?
		brne	MenuIsVolSpeed1						; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolSpeedupNoneMessage*2);	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolSpeedupNoneMessage*2)				; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolSpeed1:

		cpi		Work1,1								; Un seul speedup ?
		brne	MenuIsVolSpeed2						; 	- Non -> next one ?

		ldi		ZH,HIGH(MenuVolSpeedupOneMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolSpeedupOneMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur
		ret											; et on s'en va

MenuIsVolSpeed2:


		ldi		ZH,HIGH(MenuVolSpeedupTwoMessage*2)	;	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolSpeedupTwoMessage*2)	; 
		call	DisplayAfficheChaine
		call	DisplayArrow							; et les flèches de l'encodeur
		ret											; et on s'en va


; =============================================
; == Edition du pas de l'encodeur du volume  ==
; ==                                         ==
; ==      Valeurs possibles : 1,2,4,8        ==
; ==                                         ==
; ==	- Encodeur pour changer la valeur    ==
; ==    - Menu pour valider et sortir        ==
; ==    - Standby/On pour annuler            ==
; =============================================

MenuVolEncoderStep:

WaitMenuVEC:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuVEC							; On attend le relachement du bouton de menu

; Bouton relâché, on continue

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_EncoderStep					; L'adresse de ce paramètre en RAM
		ld		MenuReg1,Z							; Récupère la valeur stockée en RAM dans MenuReg1

		ldi		Work,0								; Se place au début du Display
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuVolEncoderStepMessage*2); Affiche le message correspondant au pas mémorisé
		ldi		ZL,LOW(MenuVolEncoderStepMessage*2)
		call	DisplayAfficheChaine

		call	AfficheMenuVolEncodeurStep			; et on affiche la valeur

LoopVEC0:
		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeVECMenu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitVECMenuNoSave					; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu pour valider ?
		rjmp 	LoopVEC0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu toujours appuyé ?
		rjmp 	LoopVEC0							; Non, on boucle

		rjmp	ExitVECMenu							; sinon on se prépar à sortir de cette page

ChangeVECMenu:										; On a touché l'encodeur -> Faut changer le mode d'affichage

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	DoChangeVECMenu						
		rcall	LanceClignotementLED

DoChangeVECMenu:

		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncVECMenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecVECMenuReg1						; vers le bas ?
		rjmp	LoopVEC0							; Aucun des deux, alors cassos

IncVECMenuReg1:										; Incrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,8								; c'est le max ?
		brne	DoIncVECMR1							; non, alors on peut incrémenter sans pb

		rjmp	MenuActualiseVEC					; Sinon status quo

DoIncVECMR1:
		lsl		MenuReg1							; On incrémente le registre (multiplication par 2)
		rjmp	MenuActualiseVEC					; et on modifie le paramètre

DecVECMenuReg1:										; Décrémentation du paramètre
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,EncoderStepMin								; c'est le min ?
		brne	DoDecVECMR1							; non, alors on peut décrémenter sans pb

		rjmp	MenuActualiseVEC					; Sinon status quo

DoDecVECMR1:
		lsr		MenuReg1							; On décrémente le registre (division par 2)
		rjmp	MenuActualiseVEC					; et on modifie le paramètre

MenuActualiseVEC:									; On modifie vraiment le paramètre

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		call	AfficheMenuVolEncodeurStep			; on affiche la nouvelle valeur,
		rjmp	LoopVEC0							; et on reboucle

ExitVECMenu:										; On sort de la routine tout simplement
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitVECMenu
													 
		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		mov		Work2,MenuReg1						; Et sauvegarde du paramètre en EEPROM
		ldi		Work,EE_EncoderStep					; il faut juste la mettre en EEPROM
		call	WriteEEprom							; et au bon endroit svp

		ldi		ZH,RAM_Start						; et en RAM
		ldi		ZL,RAM_EncoderStep
		st		Z,MenuReg1							; c'est fait

		ret											; et voilou

ExitVECMenuNoSave: 									; On s'en va sans sauvegarder
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitVECMenuNoSave

		rcall	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret											; et voualou

; ==============================================
; == Affichage du nombre de pas de l'encodeur ==
; ==============================================

AfficheMenuVolEncodeurStep:

		ldi		Work,0x40							; Début de la seconde ligne
		call	DisplayPlaceCurseur					; de l'afficheur

		ldi		ZH,HIGH(MenuVolEncoderStepValueMessage*2);	- Oui, on l'affiche
		ldi		ZL,LOW(MenuVolEncoderStepValueMessage*2)				; 
		call	DisplayAfficheChaine
		call	DisplayArrow						; et les flèches de l'encodeur


		ldi		Work,0x50							; Se place à la position
		call	DisplayPlaceCurseur					; où on écrit le numéro de l'entrée
		mov		Char,MenuReg1						; Copie la valeur dans Char
		subi	Char,-48							; Ajoute 48 pour l'afficher en ASCII
		call	DisplayWriteChar					; et l'envoie sur le display
		
		ret											; épicétou
