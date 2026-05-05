; ===================================================
; == Routines pour l'apprentissage de la telco RC5 ==
; ===================================================

MenuRC5:

WaitMenuRC5:
		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	WaitMenuRC5							; On attend le relachement du bouton de menu

		ldi		Work,0								; on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuRC5Key2learnMessage*2)
		ldi		ZL,LOW(MenuRC5Key2learnMessage*2)
		call	DisplayAfficheChaine				; Et on affiche le message

		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur
		ldi		ZH,HIGH(MenuRC5SystemIDMessage*2)
		ldi		ZL,LOW(MenuRC5SystemIDMessage*2)
		call	DisplayAfficheChaine				; affiche le "message" de l'encodeur 
		call	DisplayArrow

		clr		MenuReg1

		rcall	MenuRC5AfficheCodeIR

; -- Pour cette routine en particulier, on rétablit l'interruption INT1
; -- pour détecter la transmission d'un ordre IR

		ldi		Work,0b00000010
		out		EIMSK,Work

LoopLevelR0:

		call 	LectureEncodeur						; Lecture de l'encodeur
		sbrs	StatReg1,FlagIncremente				; doit-on incrémenter
		sbrc	StatReg1,FlagDecremente				; ou décrémenter ?
		rjmp	ChangeRC5Menu						; l'un des deux...

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation ?
		rjmp	ExitRC5Menu							;   - Oui, alors on annule

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	LoopLevelR0							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	LoopLevelR0							; Non, on boucle

		rjmp	MenuRC5EnterLearn					; sinon on entre dans le menu de config qu'il faut
			
ChangeRC5Menu:
		sbrc	StatReg1,FlagIncremente				; regarde dans quel sens allait l'encodeur
		rjmp	IncRC5MenuReg1						; Vers le haut ?
		sbrc	StatReg1,FlagDecremente				; 
		rjmp	DecRC5MenuReg1						; vers le bas ?
		rjmp	LoopLevelR0							; Aucun des deux, alors cassos

IncRC5MenuReg1:										; Incrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,16								; c'est le dernier menu ?
		brne	DoIncRC5MR1							; non, alors on peut incrémenter sans pb

		clr		MenuReg1							; sinon, on le repasse à 0		
		ldi		ZH,HIGH(MenuRC5SystemIDMessage*2)
		ldi		ZL,LOW(MenuRC5SystemIDMessage*2)
		rjmp	AfficheMenuRC50						; et on va afficher la chaine qu'il faut

DoIncRC5MR1:
		inc		MenuReg1							; On incrémente le registre
		adiw	ZH:ZL,DisplaySize+2					; ainsi que l'adresse du message
		rjmp	AfficheMenuRC50						; et on va afficher la chaine qu'il faut

;		mov		Work,MenuReg1
;		cpi		Work,(MaxInput+7)					; il faut sauter les entrées non utilisées
;	    brlo	AfficheMenuRC50						; quand MenuReg1 est entre (MaxInput+7) et 10 
;		cpi		Work,11								; et c'est bon quand on est supérieur ou égal à 11
;		brsh	AfficheMenuRC50
;		rjmp	DoIncRC5MR1

DecRC5MenuReg1:										; Décrémentation du numéro de menu
		mov		Work,MenuReg1						; transfert dans un registre immédiat
		cpi		Work,0								; c'est le dernier menu ?
		brne	DoDecRC5MR1							; non, alors on peut décrémenter sans pb

		ldi		Work,16
		mov		MenuReg1,Work						; sinon, on le repasse à 15		
		ldi		ZH,HIGH(MenuRC5ClearAllMessage*2)
		ldi		ZL,LOW(MenuRC5ClearAllMessage*2)
		rjmp	AfficheMenuRC50						; et on va afficher la chaine qu'il faut

DoDecRC5MR1:
		dec		MenuReg1							; On décrémente le registre
		sbiw	ZH:ZL,DisplaySize+2
		rjmp	AfficheMenuRC50						; et on va afficher la chaine qu'il faut

;		mov		Work,MenuReg1
;		cpi		Work,11								; il faut sauter les entrées non utilisées
;		brsh	AfficheMenuRC50						; quand MenuReg1 est entre (MaxInput+7) et 10 
;		cpi		Work,(MaxInput+7)					; et c'est bon quand on est supérieur ou égal à 11
;	    brlo	AfficheMenuRC50
;		rjmp	DoDecRC5MR1

AfficheMenuRC50:									; affiche le menu correspondant au contenu de MenuReg1 (entre 0 et 1)

		cbr		StatReg1,EXP2(FlagIncremente)		; On commence par remettre à 0 les flags de l'encodeur
		cbr		StatReg1,EXP2(FlagDecremente)

		rjmp	MenuRC5DisplayCommand

;		ldi		Work,0x40
;		call	DisplayPlaceCurseur
;		call	DisplayAfficheChaine				; Affiche la première chaine de setup
;		call	DisplayArrow
;
;		rcall	MenuRC5AfficheCodeIR				; et on affiche le code
;
;		rjmp	LoopLevelR0							; et on continue la boucle

MenuRC5EnterLearn:

		call 	Attendre							; On attend un peu
		sbic	PinMenu,SwitchMenu					; Un vrai appui sur le bouton de menu ?
		rjmp	LoopLevelR0							; Sinon,on revient dans la boucle

		mov		Work,MenuReg1
		cpi		Work,16
		brne	MenuRC5DoLearn
		rjmp	MenuRC5ClearAll
MenuRC5DoLearn:
		call	MenuRC5LearnKey						; On va apprendre le nouveau code

		ldi		Work,0								; Au retour, on se place
		call	DisplayPlaceCurseur					; sur la première ligne de l'afficheur
		ldi		ZH,HIGH(MenuRC5Key2learnMessage*2)
		ldi		ZL,LOW(MenuRC5Key2learnMessage*2)
		call	DisplayAfficheChaine				; Et on affiche le message

MenuRC5DisplayCommand:
		mov		Work,MenuReg1						; Va falloir récupérer la bonne adresse du message
		ldi		ZH,HIGH(MenuRC5SystemIDMessage*2)
		ldi		ZL,LOW(MenuRC5SystemIDMessage*2)
		
MenuRC5TestAdresse:
		cpi		Work,0
		breq	MenuRC5FoundRightAdress

		dec		Work								; Décrémente le compteur
		adiw	ZH:ZL,DisplaySize+2					; Incrémente l'adresse
		rjmp	MenuRC5TestAdresse					; et va retester

MenuRC5FoundRightAdress:
	
		ldi		Work,0x40							; on se place
		call	DisplayPlaceCurseur					; sur la seconde ligne de l'afficheur

		call	DisplayAfficheChaine

		mov		Work,MenuReg1
		cpi		Work,16
		breq	MenuRC5SkipCodeDisplay
		call	MenuRC5AfficheCodeIR
MenuRC5SkipCodeDisplay:
		call	DisplayArrow
		rjmp	LoopLevelR0							; et on continue la boucle

ExitRC5Menu:
		call 	Attendre							; On attend pour le débounce
		sbic	PinSwitchMC,SwitchMC				; C'est un vrai appui sur le bouton d'annulation pour sortir ?
		rjmp	LoopLevelR0							; Non, fausse arlette et on replonge dans la boucle

WaitBeforeExitRC5Menu:
		sbis	PinSwitchMC,SwitchMC				; Petit test habituel pour ne pas effectuer
		rjmp	WaitBeforeExitRC5Menu				; des sorties de menu en cascade

		clr		Work
		out		EIMSK,Work							; On inhibe toutes les interruptions


		ret											; on se casse de ce menu

; ---------------------------------
; -- Apprentissage d'un code RC5 --
; ---------------------------------

MenuRC5LearnKey:

		sbis	PinMenu,SwitchMenu					; Avant de passer à la suite,
		rjmp	MenuRC5LearnKey						; On attend le relachement du bouton de menu

		ldi		Work,0
		call	DisplayPlaceCurseur					; début de première ligne
		mov		Work,MenuReg1						; De quelle fonction IR s'agit-il ?
		cpi		Work,0								; Du système ID ?
		breq	MenuRC5AffSID						;   vivi

		ldi		ZH,HIGH(MenuRC5PressKeyMessage*2)	;   nannan, c'est une commande "normale"
		ldi		ZL,LOW(MenuRC5PressKeyMessage*2)	;   donc message en conséquence,
		rjmp	MenuRC5AffKeyLearn					;   et on l'affiche
MenuRC5AffSID:
		ldi		ZH,HIGH(MenuRC5PressAnyKeyMessage*2); Message à part pour le systemID
		ldi		ZL,LOW(MenuRC5PressAnyKeyMessage*2)

MenuRC5AffKeyLearn:
		call	DisplayAfficheChaine

MenuRC5WaitKey:
		sbrc	StatReg2,FlagIRRec					; On attend une réception IR
		rjmp	MenuRC5LearnIR

		sbis	PinSwitchMC,SwitchMC				; Un appui sur le bouton d'annulation pour sortir ?
		rjmp	ExitRC5LearnKeyNoSave				; Oui, alors on y va

		sbic	PinMenu,SwitchMenu					; Un appui sur Menu ?
		rjmp 	MenuRC5WaitKey							; Non, on boucle

		call	Attendre							; On attend un peu...
		sbic	PinMenu,SwitchMenu					; Menu  toujours appuyé ?
		rjmp 	MenuRC5WaitKey						; Non, on boucle

		rjmp	ExitRC5LearnKeySave					; oui, alors on va sauver

MenuRC5LearnIR:
		call	IRDetect							; On va voir ce qu'on a reçu

		cpi		SystemIR,255
		breq	MenuRC5ReturnFromLearn				; Erreur de transmission

		lds		Work,TCCR3B							; si le timer 3 ne tourne pas
		andi	Work,0b00000111						; on lance le clignotement de la LED On
		cpi		Work,0								; car on a modifié la valeur qui était stockée
		brne	MenuRC5TesteCommande						
		call	LanceClignotementLED

MenuRC5TesteCommande:
		mov		Work,MenuReg1
		cpi		Work,0								; Est-ce qu'il s'agit de l'édition du SystemID ?
		breq	MenuRC5SystemID

		andi	CommandeIR,0x3F						; Enlève le bit de Toggle

		ldi		Work,0
		cpse	MenuReg1,Work						; On ne fait pas le test pour le SystemID (pas déjà utilisé par définition)

		call	MenuRC5TesteAlreadyUsed				; Vérifie que la commande n'est pas déjà utilisée

		cpi		Work3,255							; Au retour, si c'est pas bon, Work3 contient 255
		breq	MenuRC5ReturnFromLearn				; et dans ce cas on n'affiche pas la commande

		ldi		Work,0x4F
		call	DisplayPlaceCurseur
		mov		Work3,CommandeIR					; Tranfert de la commande pour affichage
		call	AfficheIR
		rjmp	MenuRC5ReturnFromLearn				; et on passe à la fin

MenuRC5SystemID:									; Cas particulier pour le SystemID

		ldi		Work,0x4F
		call	DisplayPlaceCurseur
		mov		Work3,SystemIR						; Tranfert de l'ID pour affichage
		call	AfficheIR
		
MenuRC5ReturnFromLearn:

		cbr		StatReg2,EXP2(FlagIRRec)			; On repasse le flag de réception à 0 
		ldi		Work,0b00000010						; Et on rétablit l'interruption IR
		out		EIMSK,Work							; Qui avait été désactivée dans la routine d'interruption

		rjmp	MenuRC5WaitKey


ExitRC5LearnKeyNoSave:								; On se sauve sans sauver
		sbis	PinSwitchMC,SwitchMC				; On attend le relâchement du bouton d'annulation
		rjmp	ExitRC5LearnKeyNoSave

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

		ret
ExitRC5LearnKeySave:								; Sortie en sauvegardant la commande
		sbis	PinMenu,SwitchMenu					; On attend le relâchement du bouton de menu
		rjmp	ExitRC5LearnKeySave

		call	ArreteClignotementLED				; Au cazoù, on rallume la LED de On/StandBy

; -- Sauve en RAM --

		ldi		ZH,RAM_Start						; Adresse Ram du début
		ldi		ZL,RAM_IRSytemID					; de la zone de stockage des commandes RC5
		add		ZL,MenuReg1							; et on pointe au bon endroit
		st		Z,Work3								; on stocke la valeur qui nous intéresse
		
; -- Sauve en EEPROM --

		ldi		Work,EE_IRSytemID					; Adresse de début en EEPROM
		add		Work,MenuReg1						; Shifte pour pointer au bon endroit
		mov		Work2,Work3							; la valeur à sauvegarder
		call	WriteEEprom							; et on se casse

		ldi		Work,SaveLong						; Fixe le temps d'affichage du prochain message
		call	AfficheSaving						; Affiche le message de sauvegarde

		ret

; --------------------------------------------------------
; -- Effacement de tous les codes RC5 enregistrés       --
; --------------------------------------------------------

MenuRC5ClearAll:
		sbis	PinMenu,SwitchMenu
		rjmp	MenuRC5ClearAll

		ldi		Work,0
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuRC5ClearAllMessage*2)
		ldi		ZL,LOW(MenuRC5ClearAllMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuEEPromSure*2)
		ldi		ZL,LOW(MenuEEPromSure*2)
		call	DisplayAfficheChaine

MenuRC5ClearWait:
		sbis	PinSwitchMC,SwitchMC
		rjmp	MenuRC5ClearCancel

		sbic	PinMenu,SwitchMenu
		rjmp	MenuRC5ClearWait

		call	Attendre
		sbic	PinMenu,SwitchMenu
		rjmp	MenuRC5ClearWait

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_IRSytemID
		ldi		Work1,EE_IRSytemID

MenuRC5ClearLoop:
		ldi		Work2,0xFF
		st		Z+,Work2

		mov		Work,Work1
		call	WriteEEprom

		inc		Work1
		cpi		Work1,EE_Stop_IR
		brne	MenuRC5ClearLoop

		ldi		Work,SaveLong
		call	AfficheSaving

		ldi		Work,0
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuRC5Key2learnMessage*2)
		ldi		ZL,LOW(MenuRC5Key2learnMessage*2)
		call	DisplayAfficheChaine
		rjmp	MenuRC5DisplayCommand

MenuRC5ClearCancel:
		sbis	PinSwitchMC,SwitchMC
		rjmp	MenuRC5ClearCancel

		ldi		Work,0
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuRC5Key2learnMessage*2)
		ldi		ZL,LOW(MenuRC5Key2learnMessage*2)
		call	DisplayAfficheChaine
		rjmp	MenuRC5DisplayCommand

; --------------------------------------------------------
; -- Affichage du code RC5 pour une commande donnée     --
; -- La commande est repérée par le contenu de MenuReg1 --
; --------------------------------------------------------

MenuRC5AfficheCodeIR:

		push	ZL									; On sauvegarde les registres 
		push	ZH									; d'adresse de la chaîne affichée

		ldi		Work,0x4F							; Endroit où afficher le code
		call	DisplayPlaceCurseur
		ldi		Char,' '							; mais on efface avec 3 blancs
		call	DisplayWriteChar
		call	DisplayWriteChar
		call	DisplayWriteChar
		ldi		Work,0x4F							; Et on replace le curseur
		call	DisplayPlaceCurseur

		ldi		ZH,RAM_Start						; Adresse Ram du début
		ldi		ZL,RAM_IRSytemID					; de la zone de stockage des commandes RC5
		add		ZL,MenuReg1							; et on pointe au bon endroit
		ld		Work3,Z								; on récupère la valeur qui nous intéresse
		call	AfficheIR							; et on affiche le code

		pop		ZH									; On récupère l'adresse
		pop		ZL									; qui était stockée

		ret

; ---------------------------------------------------------
; -- Teste si un nouveau code RC5 n'est pas déjà utilisé --
; ---------------------------------------------------------

MenuRC5TesteAlreadyUsed:

		ldi		ZH,RAM_Start						; Adresse Ram du début
		ldi		ZL,RAM_IRSytemID+1					; de la zone de stockage des commandes RC5
		ldi		Work,0								; mais on ne teste pas le SystemID

RC5TestLoop:
		clr		Work3
		inc		Work								; Incrémentation du compteur de commandes
		cpi		Work,16								; C'est la dernière ?
		breq	ExitRC5Test							; 	-  Oui, alors on sort

		ld		Work1,Z+							; Non, ce n'est pas la dernière, alors on récupère la commande stockée
		cp		MenuReg1,Work						; Mais est-ce la commande en cours ?
		breq	RC5TestLoop							; Oui, alors pas besoin de la tester

		cp		CommandeIR,Work1					; C'est le même code ?
		brne	RC5TestLoop							; 	- Non, alors on boucle

		ldi		Work,0								; Message d'avertissement sur la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuRC5DuplicateMessage*2)
		ldi		ZL,LOW(MenuRC5DuplicateMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x4F
		call	DisplayPlaceCurseur

		ldi		Work3,255
		call	AfficheIR
		ldi		Work,Savelong

MenuRC5TestWait:
		call	Attendre
		dec 	Work
		brne	MenuRC5TestWait

		ldi		Work,0
		call	DisplayPlaceCurseur					; début de première ligne
		ldi		ZH,HIGH(MenuRC5PressKeyMessage*2)
		ldi		ZL,LOW(MenuRC5PressKeyMessage*2)
		call	DisplayAfficheChaine

		call	MenuRC5AfficheCodeIR

		ldi		Work3,255		
ExitRC5Test:
		ret
			
