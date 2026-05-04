; ======================================================================
; == Les routines pour les différents relais, hormis le relais d'alim ==
; ======================================================================

; ---------------------
; -- Change d'entrée --
; ---------------------

ChangeEntree:

; On cherche d'abord sur quel bouton on a appuyé,
; et en même temps, ça fait un peu de debouncing...

		sbic	PinsSwitches,SwitchIn1				; On a appuyé sur l'entrée 1 (actif à 0) ?
		rjmp 	TestIn2								; 	- Non, alors on va tester l'autre entrée
		ldi 	Work1,0								; 	- Oui, on mémorise le n° de l'entrée
		rjmp	WaitIn1SwitchRelease				; 	  et on passe à la suite

TestIn2:
		sbic	PinsSwitches,SwitchIn2				; On a appuyé sur l'entrée 2 (actif à 0) ?
		rjmp 	TestIn3								; 	- Non, alors on va tester l'entrée suivante
		ldi 	Work1,1								; 	- Oui, on mémorise le n° de l'entrée
		rjmp	WaitIn2SwitchRelease				; 	  et on passe à la suite

TestIn3:
		sbic	PinsSwitches,SwitchIn3				; On a appuyé sur l'entrée 3 (actif à 0) ?
		rjmp 	TestIn4								; 	- Non, alors on va tester l'entrée suivante
		ldi 	Work1,2								; 	- Oui, on mémorise le n° de l'entrée
		rjmp	WaitIn3SwitchRelease				; 	  et on passe à la suite

TestIn4:
		sbic	PinsSwitches,SwitchIn4				; On a appuyé sur l'entrée 4 (actif à 0) ?
		rjmp 	TestInTapeOrBypass					; 	- Non, alors on va tester le bouton suivant
		ldi 	Work1,3								; 	- Oui, on mémorise le n° de l'entrée
		rjmp	WaitIn4SwitchRelease				; 	  et on passe à la suite

TestInTapeOrBypass:
		sbic	PinsSwitches,SwitchTapeOrBypass		; On a appuyé sur l'entrée Tape/Bypass (actif à 0) ?
		ret											;	- Non, alors on se casse
		ldi 	Work1,4								; 	- Oui, on mémorise le n° de l'entrée
		rjmp	WaitInTapeOrBypassSwitchRelease

WaitIn1SwitchRelease:								; On attend le relâchement du bouton  de l'entrée 1 avant de passer à autre chose
		sbis	PinsSwitches,SwitchIn1
		rjmp	WaitIn1SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn2SwitchRelease:								; On attend le relâchement du bouton  de l'entrée 2 avant de passer à autre chose
		sbis	PinsSwitches,SwitchIn2
		rjmp	WaitIn2SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn3SwitchRelease:								; On attend le relâchement du bouton  de l'entrée 3 avant de passer à autre chose
		sbis	PinsSwitches,SwitchIn3
		rjmp	WaitIn3SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitIn4SwitchRelease:								; On attend le relâchement du bouton  de l'entrée 4 avant de passer à autre chose
		sbis	PinsSwitches,SwitchIn4
		rjmp	WaitIn4SwitchRelease
		rjmp	ChangeEntreeStopIdle

WaitInTapeOrBypassSwitchRelease:					; On attend le relâchement du bouton  de l'entrée Tape/Bypass avant de passer à autre chose
		sbis	PinsSwitches,SwitchTapeOrBypass
		rjmp	WaitInTapeOrBypassSwitchRelease
		rjmp	ChangeEntreeStopIdle

ChangeEntreeStopIdle:								; On a bien appuyé sur un bouton
        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle était en train de tourner,
		call	StopIdle							; alors on l'arrête
		call	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosité

		call	IRClearIRSup						; Autre action que IR -> Efface le registre de speedup

ChangeEntreeAfterSwitches:							; Si on arrive là, c'est qu'on a bien appuyé sur un bouton (et qu'on l'a relâché)
													; ou qu'on a reçu une commande RC5

; On va tout d'abord vérifier que l'entrée sélectionnée n'est pas l'entrée active,
; auquel cas pas besoin de s'embêter.

		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de l'entrée active (l'ancienne)
		ld		Work,Z								; et récupère la valeur

		cpse	Work,Work1							; Compare l'ancienne et la nouvelle
		rjmp	ChangeVraimentEntree				; Si ce n'est pas la même, on change vraiment...
		rjmp	ExitChangeEntree					; Si c'est la même -> Cassos, plus rien à faire ici

ChangeVraimentEntree:

; On commence par arrêter le timer au cas où, muter la sortie et désactiver tous les relais

		ldi		Work,TimerStop						; On arrête le Timer 1
		out		TCCR1B,Work

		MacroMuteOn
		sbr		StatReg1,EXP2(FlagMute)				; Signale qu'on est en mute (bit à 1)
		call 	Attendre							; Attend un peu

		clr		Work								; On fait passer tous les relais d'entrée
		out		PortRelaisIn,Work					; au repos (on coupe tout)

		lds		Work,PortAutresRelais				; Récupère l'état des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'état initial
#if !defined (BYPASS)
		cbr		Work,EXP2(RelaisTape)				; On s'occupe de ce relais seulement si c'est pas celui de bypass 
#endif
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants à 0
		sts		PortAutresRelais,Work

; pour les besoins de triggering, on récupère l'ancienne entrée active

		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de l'entrée active (l'ancienne, maintenant)
		ld		Work,Z								; et récupère la valeur
		ldi		ZL,RAM_AncienneEntreeActive			; pour la mettre à sa place
		st		Z,Work

		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de l'entrée maintenant active
		st		Z,Work1	

		call	TriggerSource						; Envoie (ou non) un trigger sur les sources

; On s'occupe du timer 1 pour la seconde de délai du mute

		ldi		Work,UneDemiSecHi					; On charge dedans
		out		TCNT1H,Work							; une première demi-seconde
		ldi		Work,UneDemiSecLo					; pour avoir le délai entre l'activation 
		out 	TCNT1L,Work							; du relais de masse et le relais de signal

		sbr		StatReg2,EXP2(FlagWait)				; Met à 1 le flag d'attente 
													; C'est lui qui va nous servir à déterminer où on en est

		ldi		Work,TimerDiv						; Lance le Timer 1 en Ck/1024
		out 	TCCR1B,Work	

; On passe le volume à Zéro (atténuation maximale)
; pour éviter les plocs de commutation d'entrée

		in		Work,PortVolume						; Récupère l'état des relais mute et volume
		andi	Work,0b10000000						; et on met tous le volume à zéro (atténuation max) sans toucher au relais de mute	
		out		PortVolume,Work 					; On remet ce registre à disposition sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch
		cbi		PortLatchVolG,LE_VolG
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch
		cbi		PortLatchVolD,LE_VolD

; Pendant que le timer commence à tourner, on regarde si on a affaire à une entrée symétrique ou non,
; puis si il faut un trigger, et on fait coller le relais de masse de l'entrée

;		cpi		Work1,4								; L'entrée à activer, c'est celle de tape ?
;		breq	ExitChangeEntree					; Oui, alors plus rien à faire...
			
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur d'entrée symétrique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et récupère la valeur

		cpi		Work,0								; C'est une entrée symétrique ?
		breq	LookFor6dB							; 	- Oui (Valeur à 0), alors on ne touche pas au relais, et on passe à autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur à 1), on active le relais de dissymétrisation
		sbr		Work,EXP2(RelaisAsym)				;    (Au repos, on est en symétrique, donc il faut que le relais de Bal/unBal soit activé pour de l'asymétrique)
		sts		PortAutresRelais,Work				; Envoie ça sur le port des relais
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant à 1

LookFor6dB:
		call	Want6dBMore							; Regarde si il faut 6 dB en plus dans le cas d'une entrée asymétrique
	    call	InputVol							; Faut-il ajuster le volume pour cette entrée
					
; Activation des relais de masse

ActiveGND:											; Active le relais de masse pour l'entrée sélectionnée
		cpi 	Work1,0								; C'est l'entrée 1 ?
		brne	ActiveGND2							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn1			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND2:
		cpi 	Work1,1								; C'est l'entrée 2 ?
		brne	ActiveGND3							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn2			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND3:
		cpi 	Work1,2								; C'est l'entrée 3 ?
		brne	ActiveGND4							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisGNDIn3			; Oui, alors on met la masse en circuit
		rjmp	ExitChangeEntree					; et on va lancer le Timer 1

ActiveGND4:
		sbi		PortRelaisIn,RelaisGNDIn4			; Si on arrive là,pas d'autre chose à faire que de mettre la masse en circuit

ExitChangeEntree:
		call	AfficheEntree						; On affiche le nom de la nouvelle entrée
		call	StartIdle							; On relance le timer de "fout rien"
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; -------------------------------------------
; -- Mise en route des relais au démarrage --
; -------------------------------------------

StartRelays:

		ldi		ZH,RAM_Start						; Stocke en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de l'entrée active
		st		Z,Work1	

		cpi		Work1,4								; L'entrée à activer, c'est celle de tape ?
		breq	ExitStartRelays			 			; Oui, alors plus rien à faire...
			
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur d'entrée symétrique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et récupère la valeur

		cpi		Work,0								; C'est une entrée asymétrique ?
		breq	Start6dB							; 	- Non (Valeur à 0), alors on ne touche pas au relais, et on passe à autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur à 1), on active le relais de Bal/UnBal
		sbr		Work,EXP2(RelaisAsym)
		sts		PortAutresRelais,Work
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant à 1

Start6dB:
		call	Want6dBMore							; 6dB de plus pour une entrée asymétrique ?
		call 	InputVolNew							; Un ajustement particulier du volume ?

; Activation des relais de masse

StartActiveGND:										; Active le relais de masse pour l'entrée sélectionnée
		cpi 	Work1,0								; C'est l'entrée 1 ?
		brne	StartActiveGND2						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn1				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en désactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND2:
		cpi 	Work1,1								; C'est l'entrée 2 ?
		brne	StartActiveGND3						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn2				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en désactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND3:
		cpi 	Work1,2								; C'est l'entrée 3 ?
		brne	StartActiveGND4						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn3				; Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					; en désactivant les autres relais de masse
		rjmp	ExitStartRelays						; et on va lancer le Timer 1

StartActiveGND4:
		ldi		Work,RelaisOnlyGNDIn4				; Si on arrive là,pas d'autre chose à faire que de mettre la masse en circuit
		out		PortRelaisIn,Work					; pour l'entrée 4

ExitStartRelays:
#if defined(BYPASS)
		lds		Work,PortAutresRelais				; Récupère l'état des autres relais
		sbr		Work,EXP2(RelaisBypass)				; et active le relais de bypass
		sts		PortAutresRelais,Work				; (Bypass désactivé quand le relais est activé)
#endif
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; ------------------------------------
; -- Fait coller le relais d'entrée --
; ------------------------------------

ActiveRelaisEntree:

;		call	TriggerSource						; Envoie (ou non) un trigger

		ldi		ZH,RAM_Start
#if defined(BYPASS)
		sbrc	StatReg2,FlagBypass					; Récupère soit l'entrée à activer
		ldi		ZL,RAM_In_Bypass					; soit l'entrée de bypass
		sbrs	StatReg2,FlagBypass					; suivant l'état du flag
		ldi		ZL,RAM_EntreeActive
#else
		ldi		ZL,RAM_EntreeActive
#endif
		ld		Work,Z								; récupère l'entrée à activer

		cpi 	Work,0								; C'est l'entrée 1 ?
		brne	ActiveIn2							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput1			; Oui, alors on met l'entrée en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn2:
		cpi 	Work,1								; C'est l'entrée 2 ?
		brne	ActiveIn3							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput2			; Oui, alors on met l'entrée en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn3:
		cpi 	Work,2								; C'est l'entrée 3 ?
		brne	ActiveIn4							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput3			; Oui, alors on met l'entrée en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveIn4:
		cpi 	Work,3								; C'est l'entrée 4 ?
		brne	ActiveTape							; Nan, on teste la suivante
		sbi		PortRelaisIn,RelaisInput4			; Oui, alors on met l'entrée en circuit
		rjmp	ExitActiveRelaisEntree				; et on s'en va...

ActiveTape:
#if !defined(BYPASS)
		lds		Work,PortAutresRelais				; Si on arrive là,pas d'autre chose à faire que de mettre l'entrée 4 en circuit
		sbr		Work,EXP2(RelaisTape)
		sts		PortAutresRelais,Work
#endif
ExitActiveRelaisEntree:
		ret											; et c'est finito

; ------------------------------------
; -- Gestion des triggers de source --
; ------------------------------------

TriggerSource:

	    push	Work1								; Sauvegarde ce registre (il contient le n° de l'entrée choisie)

		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_AncienneEntreeActive			; le numéro de l'ancienne entrée active
		ld		Work1,Z								; et récupère la valeur
		cpi		Work1,4								; Si c'était l'entrée tape (valeur=4)
		breq	TrigOn								; pas besoin de trigger l'extinction
		
		ldi		ZL,RAM_TrigIn1						; Sinon,adresse en RAM du début des triggers
		add		ZL,Work1							; Offset pour pointer au bon endroit
		ld 		Work,Z								; et met ça dans Work
		
		cpi		Work,0								; pas de trigger ?
		breq	TrigOn								; non, alors on passe à la suite
													; sinon, on envoie un trigger pour éteindre l'ancien truc

		subi	Work1,-3							; On ajoute 3 à l'adresse (Trig Inp1 =3, Trig Inp 2=4, etc...)

		sbrs	StatReg1,FlagMute					; Attention à ne pas désactiver le mute
		sbr		Work1,EXP2(RelaisMute)				; en transférant l'adresse
		sbrc	StatReg1,FlagMute					; (Le mute et les HC238/HC151 partagent le même port)
		cbr		Work1,EXP2(RelaisMute)

		out		PortAdresTrig,Work1					; Met l'adresse de l'entrée sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbis	PinTriggerIn,LectureTrigIn			; Si le truc était éteint, (Lecture sur le HC151)
		rjmp	TrigOn								; Pas besoin de l'éteindre
		sbi		PortTriggers,LatchTrigOut			; Sinon, envoie un pulse de latch sur le 74HC238 de la télécommande
		call	Attendre							; Le temps que l'impulsion fasse effet
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro

TrigOn:												; Autre point d'entrée de la routine
		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de la nouvelle entrée active
		ld		Work1,Z								; et récupère la valeur
		cpi		Work1,4								; Si c'est l'entrée tape (valeur=4)
		breq	ExitTrigger							; on ne va pas plus loin.

		ldi		ZL,RAM_TrigIn1						; Adresse en RAM du début des triggers
		add		ZL,Work1							; On ajoute le numéro de l'entrée (0--3) à l'adresse pour pointer au bon endroit
		ld		Work,Z								; et charge le comportement du trigger

		cpi 	Work,0								; Pas de trigger ?
		breq	ExitTrigger							; non, alors on passe à la suite

		subi	Work1,-3							; On ajoute 3 à l'adresse (Trig Inp1 =3, Trig Inp 2=4, etc...)

		sbrs	StatReg1,FlagMute					; Attention à ne pas désactiver le mute
		sbr		Work1,EXP2(RelaisMute)				; en transférant l'adresse
		sbrc	StatReg1,FlagMute					; (Le mute et les HC238/HC151 partagent le même port)
		cbr		Work1,EXP2(RelaisMute)

		out		PortAdresTrig,Work1					; Met l'adresse de l'entrée sur le "bus"
		nop											; Petite attente de 500ns
		nop											; pour que tout soit stable
		sbic	PinTriggerIn,LectureTrigIn			; Si le truc était déjà allumé,
		rjmp	ExitTrigger							; Pas besoin de le refaire...
		sbi		PortTriggers,LatchTrigOut			; Sinon, on envoie un pulse de latch sur le 74HC238 de la télécommande
		call	Attendre							; Le temps que l'impulsion fasse effet
		cbi		PortTriggers,LatchTrigOut			; et toutes les sorties du HC238 retombent à zéro

ExitTrigger:
		pop		Work1								; restaure le registre pour retourner dans de bonnes conditions
		ret 										; et c'est fini

; --------------------------------------------------------------------------------------------
; -- On va regarder si il faut ajouter 6dB au volume (dans le cas d'une entrée asymétrique) --
; --------------------------------------------------------------------------------------------

Want6dBMore:

		sbrs	StatReg2,Flag6dB					; Avait-on ajouté 6dB ?
		rjmp	No6dB								; 	- Non, on passe à la suite

		ldi		Work,SixdBMore						; 	- Oui, alors faut les enlever
		cp		VolReg,Work							; 	  si on peut...
		brge	Substract6dB						;     et là, on peut.
		clr		VolReg								; sinon on le met au min
		rjmp	No6dB								; et on passe à la suite

Substract6dB:
		sub		VolReg,Work							; On retranche les 6dB							
No6dB:
		cbr		StatReg2,EXP2(Flag6dB)				; Met le flag correspondant à 0 dans le registre d'état
													; et on va maintenant regarder pour la nouvelle entrée... 
		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work,Z								; récupère l'entrée active

		ldi		ZL,RAM_BalIn1						; C'est une entrée unbalanced ?
		add		ZL,Work								; Pointe sur la bonne entrée
		ld		Work2,Z

		cpi		Work2,0								; Entrée en RCA ?
		breq	ExitWant6dBMore						;   - Non -> va jouer plus loin

		ldi		ZL,RAM_In1_6dB						; 	- Oui -> Cette entrée, il lui faut 6dB en plus ?
		add		ZL,Work
		ld		Work2,Z

		cpi		Work2,0								; 6dB de plus ?
		breq	ExitWant6dBMore						; 	- Non -> La suite
		sbr		StatReg2,EXP2(Flag6dB)				; 	- Béoui -> On met le flag à 1

		ldi		Work,(VolumeMaxi-SixdBMore+1)		; On peut augmenter de 6dB ?
		cp		VolReg,Work
		brge	Set6toMax							; 	 - Bénon
		ldi		Work,SixdBMore						; 	 - Béoui
		add		VolReg,Work							; 	   alors on ajoute
		rjmp	ExitWant6dBMore						; et ouala

Set6ToMax:
		ldi		Work,VolumeMaxi						; sinon on met le volume au maxi...
		mov		VolReg,Work

ExitWant6dBMore:
		ret											; et c'est fini

; ---------------------------------------------------------------------------------------
; -- On va regarder de quelle valeur il faut modifier le volume individuel de l'entrée --
; ---------------------------------------------------------------------------------------

InputVol:

; On commence par remettre le volume à la bonne valeur en annulant ce qui avait été fait avant
 
		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_AncienneEntreeActive			; le numéro de l'ancienne entrée active
		ld		Work,Z								; et récupère la valeur

		ldi		ZL,RAM_ModVol_In1					; Quelle vamleur de modif de volume avait-on ?
		add		ZL,Work								; Pointe sur la bonne entrée
		ld		Work2,Z

		cpi		Work2,0								; Si c'était zéro
		breq	InputVolNew							; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'était une valeur négative (bit 7 à 1) 
	    rjmp	InputVolWasMore						; ou positive (bit 7 à 0)
		rjmp	InputVolWasLess

InputVolWasMore:
		cp		VolReg,Work2						; Avant de soustraire la valeur, on vérifie qu'on peut bien l'enlever
		brlo	OldVol2Min							; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	InputVolNew

OldVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	InputVolNew							; et on passe au volume de la nouvelle entrée

InputVolWasLess:									; On avait enlevé du volume
		cbr		Work2,0b10000000					; on met le bit 7 à 0
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	OldVol2Max							; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranchée
		rjmp	InputVolNew							; et on passe au nouveau volume

OldVol2Max:
		ldi		Work,VolumeMaxi						; sinon on met au maxi
		mov		VolReg,Work							; et on passe à la suite


InputVolNew:
		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de la nouvelle entrée active
		ld		Work,Z								; et récupère la valeur

		ldi		ZL,RAM_ModVol_In1					; Quelle valeur de modif de volume veut-on ?
		add		ZL,Work								; Pointe sur la bonne entrée
		ld		Work2,Z

InputVolNewNoRam:
		cpi		Work2,0								; Si c'est zéro
		breq	ExitInputVol						; on ne change rien

		sbrs	Work2,7								; Sinon, on teste si c'est une valeur négative (bit 7 à 1) 
	    rjmp	InputVolIsMore						; ou positive (bit 7 à 0)

InputVolIsLess:
		cbr		Work2,0b10000000					; on met le bit 7 à 0
		cp		VolReg,Work2						; Avant de soustraire la valeur, on vérifie qu'on peut bien l'enlever
		brlo	NewVol2Min							; sinon, on met le volume au mini

		sub		VolReg,Work2						; On peut bien soustraire
		rjmp	ExitInputVol

NewVol2Min:
		clr		VolReg								; Volume au mini
		rjmp	ExitInputVol						; et on passe au volume de la nouvelle entrée

InputVolIsMore:										; On veut ajouter du volume
		ldi		Work,VolumeMaxi						; On regarde si on peut rajouter 
		sub		Work,Work2							; la valeur de modif sans overflow
		cp		VolReg,Work
		brsh	NewVol2Max							; sinon, on met le volume au maxi

		add		VolReg,Work2						; On rajoute la valeur qu'on avait retranchée
		rjmp	ExitInputVol						; et on passe au nouveau volume

NewVol2Max:
		ldi		Work,VolumeMaxi						; on taquine les taquets
		mov		VolReg,Work

ExitInputVol:
		ret											; et c'est fini

; ================================================
; == Mise en route et arrêt du bypass de l'UGS
; ================================================
#if defined(BYPASS)
BypassOnOff:

		sbic	PinsSwitches,SwitchTapeOrBypass		; C'est bien un appui sur le bouton ?  (actif à 0) ?
		ret											;	- Non, alors on se casse

WaitBypassSwitchRelease:							; On attend le relâchement du bouton  de l'entrée Tape/Bypass avant de passer à autre chose
		sbis	PinsSwitches,SwitchTapeOrBypass
		rjmp	WaitBypassSwitchRelease
		rjmp	BypassStopIdle

BypassStopIdle:										; On a bien appuyé sur le bouton
        sbrc	StatReg1,FlagIdle					; Si le timer d'Idle était en train de tourner,
		call	StopIdle							; alors on l'arrête
		call	RestoreBrightness					; Sinon, on remet l'afficheur en pleine luminosité

		call	IRClearIRSup		 				; Autre action que IR -> Efface le registre de speedup
			
BypassAfterSwitches:								; Si on arrive là, c'est qu'on a bien appuyé sur le bouton (et qu'on l'a relâché)
													; ou qu'on a reçu une commande RC5
; On commence par arrêter le timer au cas où

		ldi		Work,TimerStop						; On arrête le Timer 1
		out		TCCR1B,Work

; On vérifie qu'il y a bien une entrée à Bypasser...

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_In_Bypass
		ld		Work,Z								; récupère ce numéro
		cpi		Work,4								; et si c'est pas 4, 
		brne	ConfirmBypassOnOff					; ben on s'y jette vraiment

; Sinon on affiche pendant 2 secondes un message comme quoi on peut pas, et tout et tout...

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(NoBypassMessageL1*2)		; Affiche la première ligne du message
		ldi		ZL,LOW(NoBypassMessageL1*2)
		call	DisplayAfficheChaine

		ldi		Work,0x40							; Se place au début
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(NoBypassMessageL2*2)		; de la seconde ligne du message
		ldi		ZL,LOW(NoBypassMessageL2*2)
		call	DisplayAfficheChaine

		sbr		StatReg1,EXP2(FlagBalance)			; Le process est exactement le même que pendant l'affichage de balance,
													; alors on en profite
		clr		Work
		sts		TCCR3B,Work							; Arrête le timer 3

		ldi		Work,DeuxSecHi
		sts		TCNT3H,Work
		ldi		Work,DeuxSecLo
		sts		TCNT3L,Work
		ldi		Work,TimerDiv						; et relance le timer en CK1024
		sts		TCCR3B,Work				

		rjmp	ExitBypass							; et on s'en va, au timer de finir le boulot

ConfirmBypassOnOff:

; Mute de la sortie 

		MacroMuteOn
		sbr		StatReg1,EXP2(FlagMute)				; Signale qu'on est en mute (bit à 1)

; On s'occupe du timer 1 pour la seconde de délai du mute

		ldi		Work,UneDemiSecHi					; On charge dedans
		out		TCNT1H,Work							; une première demi-seconde
		ldi		Work,UneDemiSecLo					; pour avoir le délai entre l'activation 
		out 	TCNT1L,Work							; du relais de masse et le relais de signal

		sbr		StatReg2,EXP2(FlagWait)				; Met à 1 le flag d'attente 
													; C'est lui qui va nous servir à déterminer où on en est

		ldi		Work,TimerDiv						; Lance le Timer 1 en Ck/1024
		out 	TCCR1B,Work	

		sbrs	StatReg2,FlagBypass					; était-on déjà en bypass ?
	    rjmp	Bypass2On							; non, alors on passe en Bypass

; -- Ici, on passe du bypass vers le mode de fontionnement normal

Bypass2Off:
	    cbr		StatReg2,EXP2(FlagBypass)			; Désactive le Flag de Bypass

		ldi		Work,RelaisAllGND					; On active tous les relais de masse des entrées
		out		PortRelaisIn,Work					; Et ça désactive en même temps les relais d'entrée

		lds		Work,PortAutresRelais				; Récupère l'état des autres relais sur le port du relais bypass
		sbr		Work,EXP2(RelaisBypass)				; Et désactive le relais de bypass (bypass inactif quand le relais est "on")
		sts		PortAutresRelais,Work				; et transmet ça au port concerné

		call 	Attendre							; Attend un peu

		lds		Work,PortAutresRelais				; Récupère l'état des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'état initial
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants à 0
		sts		PortAutresRelais,Work

; On passe le volume à Zéro (atténuation maximale)
; pour éviter les plocs de commutation d'entrée

		in		Work,PortVolume						; Récupère l'état des relais mute et volume
		andi	Work,0b10000000						; et on met tous le volume à zéro (atténuation max) sans toucher au relais de mute	
		out		PortVolume,Work 					; On remet ce registre à disposition sur le port de volume
		sbi		PortLatchVolG,LE_VolG				; Une impulsion pour le latch de gauche
		cbi		PortLatchVolG,LE_VolG
		sbi		PortLatchVolD,LE_VolD				; Une impulsion pour le latch de droite, on n'est pas sectaire
		cbi		PortLatchVolD,LE_VolD

; Pendant que le timer commence à tourner, on regarde si on a affaire à une entrée symétrique ou non,

		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_EntreeActive					; le numéro de l'entrée qui était activée précédemment
		ld		Work1,Z								; et récupère la valeur
		rjmp	FinishBypass						; Passe au Bal/Unbal et relais de masse

; -- Ici, on passe en mode bypass

Bypass2On:

	    sbr		StatReg2,EXP2(FlagBypass)			; Active le Flag de Bypass

		call 	Attendre							; Attend un peu

;		clr		Work								; On fait passer tous les relais d'entrée
;		out		PortRelaisIn,Work					; au repos (on coupe tout)

		lds		Work,PortAutresRelais				; Récupère l'état des autres relais
		cbr		Work,EXP2(RelaisAsym)				; Et les met dans l'état initial
		cbr		StatReg1,EXP2(FlagAsym)				; Passe les flags correspondants à 0
		sts		PortAutresRelais,Work

		ldi		ZH,RAM_Start						; Récupère en RAM
		ldi		ZL,RAM_In_Bypass					; le numéro de l'entrée à bypasser
		ld		Work1,Z								; et récupère la valeur

FinishBypass:
 		ldi		ZL,RAM_BalIn1 						; Récupère en RAM l'indicateur d'entrée symétrique
		add		ZL,Work1							; Shifte pour pointer au bon endroit dans la RAM
		ld		Work,Z								; et récupère la valeur

		cpi		Work,0								; C'est une entrée symétrique ?
		breq	BPActiveGND							; 	- Oui (Valeur à 0), alors on ne touche pas au relais, et on passe à autre chose

		lds		Work,PortAutresRelais				; 	- Sinon (Valeur à 1), on active le relais de dissymétrisation
		sbr		Work,EXP2(RelaisAsym)				;    (Au repos, on est en symétrique, donc il faut que le relais de Bal/unBal soit activé pour de l'asymétrique)
		sts		PortAutresRelais,Work				; Envoie ça sur le port des relais
		sbr		StatReg1,EXP2(FlagAsym)				; Passe le flag correspondant à 1

; Activation du relais de masse

BPActiveGND:										; Active le relais de masse pour l'entrée sélectionnée
		cpi 	Work1,0								; C'est l'entrée 1 ?
		brne	BPActiveGND2						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn1				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en désactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND2:
		cpi 	Work1,1								; C'est l'entrée 2 ?
		brne	BPActiveGND3						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn2				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en désactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND3:
		cpi 	Work1,2								; C'est l'entrée 3 ?
		brne	BPActiveGND4						; Nan, on teste la suivante
		ldi		Work,RelaisOnlyGNDIn3				;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work					;    en désactivant les autres relais de masse
		rjmp	ExitBypassOnOff						; et on va lancer le Timer 1

BPActiveGND4:
		ldi		Work,RelaisOnlyGNDIn4				; Si on arrive là,pas d'autre chose à faire que de mettre la masse de l'entrée 4 en circuit
		out		PortRelaisIn,Work					; en désactivant les autres relais de masse

ExitBypassOnOff:
		sbrc	StatReg2,FlagBypass					; Si on vient de passer en mode bypass
		rjmp	ExitBypassOn						; On affiche spécialement cet état de fait

		call	AfficheEntree						; sinon, on affiche le nom de l'ancienne entrée
		rjmp	ExitBypass							; et on se casse

ExitBypassOn:
		call 	AfficheBypass						; Affiche le message de Bypass
		
ExitBypass:
		call	StartIdle							; On relance le timer de "fout rien"
		ret											; et c'est tout pour l'instant. Suite et Fin dans TimerRelay...

; =======================================================================
; == Petite routine pour l'activation du bypass à la mise sous tension ==
; =======================================================================

StartOrByeBypass :

; -- On commence par lire en EEPROM le n° de l'entrée à bypasser

		sbic	EECR,EEWE
		rjmp	StartOrByeBypass
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_In_Bypass				; Ce qu'on cherche à atteindre en EEPROM
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Prépare l'EEPROM à la lecture
		in		Work2,EEDR						; lit la valeur en EEPROM et la met dans le registre Work2
	
; -- On regarde si par hasard il faut vraiment bypasser (n° < 4)

		cpi		Work2,4
		brne	BypassSym						; Vi, il faut bien un bypass (n° < 4), alors on y va

; -- Sinon, on active juste le relais de masse de l'entrée préférée, pour éviter les ronflettes

StartOnlyGndPref:
		sbic	EECR,EEWE
		rjmp	StartOnlyGndPref
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_StartInput				; Ce qu'on cherche à atteindre en EEPROM
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Prépare l'EEPROM à la lecture
		in		Work2,EEDR						; lit la valeur en EEPROM et la met dans le registre Work2

; -- Avant de se lancer, on va désactiver le relais de bypass.

		lds		Work,PortAutresRelais			; Récupère l'état des autres relais
		sbr		Work,EXP2(RelaisBypass)			; et désactive le relais de bypass
		sts		PortAutresRelais,Work			; (Bypass désactivé quand le relais est activé)

; -- Au tour de l'entrée par défaut, maintenant

		cpi		Work2,0							; C'est l'entrée 1 ?
		brne	SOnGnd2							;   nan, c'est-y la 2 ?
		ldi		Work,RelaisOnlyGNDIn1			;   vi, c'est la 1, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie ça sur le port des relais
		ret										;   et zou, finito
SOnGnd2:
		cpi		Work2,1							; C'est l'entrée 2 ?
		brne	SOnGnd3							;   nan, c'est-y la 3 ?
		ldi		Work,RelaisOnlyGNDIn2			;   vi, c'est la 2, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie ça sur le port des relais
		ret										;   et zou, finished

SOnGnd3:
		cpi		Work2,2							; C'est l'entrée 3 ?
		brne	SOnGnd4							;   nan, c'est-y la 4 ?
		ldi		Work,RelaisOnlyGNDIn3			;   vi, c'est la 2, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie ça sur le port des relais
		ret										;   et zou, finished

SOnGnd4:
		ldi		Work,RelaisOnlyGNDIn4			;   Arrivé là, c'est forcément la 4, alors on charge la config de relais a des couettes
		out		PortRelaisIn,Work				;   on envoie ça sur le port des relais
		ret										;   et zou, finished
	
; -- On regarde si cette entrée est symétrique ou non

BypassSym:
		sbic	EECR,EEWE
		rjmp	BypassSym
        clr     Work
        out     EEARH,Work
		ldi		Work1,EE_BalIn1					; Ce qu'on cherche à atteindre en EEPROM
		add		Work1,Work2						; Petite addition pour pointer sur la bonne adresse
		out		EEARL,Work1						; 
	    sbi		EECR,EERE						; Prépare l'EEPROM à la lecture
		in		Work1,EEDR						; lit la valeur en EEPROM et la met dans le registre Work1

		cpi		Work1,0							; L'entrée est-elle assymétrique ?
		breq	SBTest1							; 	- Non (Valeur à 0), alors on ne touche pas au relais, et on passe à l'entrée à activer

		lds		Work,PortAutresRelais			; 	- Sinon (Valeur à 1), on active le relais de Bal/UnBal
		sbr		Work,EXP2(RelaisAsym)
		sts		PortAutresRelais,Work
		
SBTest1:
		cpi		Work2,0							; c'est l'entrée 1 ?
		brne	SBTest2							;  - Non -> Est-ce la 2 ?
		ldi		Work,RelaisOnlyGNDIn1			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en désactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput1		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest2:
		cpi		Work2,1							; c'est l'entrée 2 ?
		brne	SBTest3							;  - Non -> Est-ce la 3 ?
		ldi		Work,RelaisOnlyGNDIn2			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en désactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput2		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest3:
		cpi		Work2,2							; c'est l'entrée 3 ?
		brne	SBTest4							;  - Non -> Est-ce la 4 ?
		ldi		Work,RelaisOnlyGNDIn3			;  - Oui, alors on met la masse en circuit
		out		PortRelaisIn,Work				;    en désactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput3		;    et on active le relais signal
		rjmp 	ActionStartBypass				;  et on se barre pour activer le relais de bypass (relais au repos)

SBTest4:										; Ce ne peut donc être que l'entrée 4,
		ldi		Work,RelaisOnlyGNDIn4			; Alors on met la masse en circuit
		out		PortRelaisIn,Work				; en désactivant les autres relais de masse
		sbi		PortRelaisIn,RelaisInput4		; et on active le relais signal

ActionStartBypass:								; On met le relais de bypass au repos, ce qui met le bypass en circuit
		lds		Work,PortAutresRelais			; Récupère l'état des autres relais
		cbr		Work,EXP2(RelaisBypass)			; et désactive le relais de bypass
		sts		PortAutresRelais,Work			; (Bypass activé quand le relais est désactivé)

#endif

