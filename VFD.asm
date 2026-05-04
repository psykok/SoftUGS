; ===============================================
; === Routines de contrôle de l'affichage VFD ===
; ===============================================

; ---------------------------------------------
; --- Envoie une commande au VFD            ---
; --- La commande est dans le registre Work ---
; ---------------------------------------------

VFDSendCommand:

		cbi		PortCmdVFD,RS_VFD					; Envoie un zéro sur Register Select pour sélectionner le registre de commande
	    nop

		cbi		PortCmdVFD,RW_VFD					; Ecriture dans le VFD -> R/W à 0
	    nop

		sbi		PortCmdVFD,E_VFD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns

		sts		PortDataVFD,Work					; Envoie la commande sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		nop											; donc on attend un peu
			
		cbi		PortCmdVFD,E_VFD					; On repasse Enable à zéro

		ret											; et on a fini

; ----------------------------------------------
; --- Envoie un octet de données au VFD      ---
; --- Les données sont dans le registre Char ---
; ----------------------------------------------

VFDSendData:

		sbi		PortCmdVFD,RS_VFD					; Envoie un "un" sur Register Select pour sélectionner le registre de données
	    nop

		cbi		PortCmdVFD,RW_VFD					; Ecriture dans le VFD -> R/W à 0
		nop

		sbi		PortCmdVFD,E_VFD					; Active l'Enable
		nop											; Il faut que le Enable reste stable pendant au moins 500ns


		sts		PortDataVFD,Char					; Envoie les données sur le bus (c'est le port F, donc on emploie STS au lieu de OUT)
		nop											; donc on attend un peu
		
		cbi		PortCmdVFD,E_VFD					; On repasse Enable à zéro
		nop

		ret											; et on a fini

; ------------------------------------------------------------------------------------------
; --- Teste le Flag "Busy" du VFD                                                        ---
; --- et par la même occasion récupère le registre d'adresse (bits 6-0 du registre Work) ---
; ------------------------------------------------------------------------------------------

VFDTestBusyFlag:

		cbi		PortCmdVFD,RS_VFD					; 0 sur le Register Select pour sélectionner le registre de commande
		sbi		PortCmdVFD,RW_VFD					; 1 sur R/W pour passer en lecture sur le VFD
		sbi		PortCmdVFD,E_VFD					; Front montant d'enable

													; Les instructions suivantes, outre leur utilité propre, 
													; permettent d'assurer les temps de cycle d'enable (1200ns) sans pb

		clr		Work   	  							; On met 0 dans le registre de direction
		sts		DataDirVFD,Work						; pour passer le port de données du VFD en entrée
		out		PinsDataVFD,Work					; Met les broches d'entrée à 0 		
		in		Work,PinsDataVFD					; Récupère les données du VFD
		
		cbi		PortCmdVFD,E_VFD					; Front descendant d'Enable

		push	Work								; Sauvegarde le registre dans la pile
		ser		Work								; Repasse les broches en sortie
		sts		DataDirVFD,Work						; en mettant des 1 dans le registre de direction
		cbi		PortCmdVFD,RW_VFD					; Repasse R/W à 0
		pop		Work								; récupère le contenu du registre qui avait été sauvegardé

		sbrc	Work,7								; Le Busy Flag est il à 1 (l'afficheur est occupé) ?
		rjmp	VFDTestBusyFlag						; nan -> On reboucle et on attend

		ret											; oui -> On s'en va

; --------------------------------------
; -- Routine d'initialisation du VFD ---
; --------------------------------------

DisplayInit:

		ldi 	Work,0b00111011						; Function set : Interface 8 bits, 2 lignes, caractère 5x7
													; On met les deux derniers bits à 1 pour fixer la luminosité de l'afficheur 
													; au minimum dans le cas du Newhaven (ces bits n'ont pas d'importance dans le cas du Noritake)
		rcall	VFDSendCommand						; Et on envoie la commande
#if defined(NORITAKE)
		rcall	VFDSendCommand						; plusieurs fois pour assurer la synchro
		rcall	VFDSendCommand						; comme indiqué dans le datasheet
#endif
		ldi		Work,0b00000001						; Efface l'afficheur et remet le curseur au début
		rcall	VFDSendCommand

;!!!!!!
;	    rcall	VFDTestBusyFlag						; A tester pour des problèmes de tempo

		ldi		Count1,0x0F							; Une petite boucle de 3ms
VFD_R1:	ldi		Count2,0
VFD_R2:	dec		Count2
		brne	VFD_R2
		dec		Count1
		brne	VFD_R1

	    ldi		Work,0
		rcall	SetBrightness

		ldi		Work,0b00001100						; Display On, Cursor Off, Blink Off
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande

		ldi		Work,0b00000001						; Display Clear
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande (1.5ms)

		ldi		Work,0b00000110						; Incrémentation automatique du curseur, pas de shift du display
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande

		ret											; et c'est terminé pour l'initialisation

; -----------------------------------------------------------------------
; --- Ecrit un caractère utilisateur dans la RAM graphique du VFD     ---
; --- L'adresse en EEPROM du début du caractère est placée dans Work1 ---
; --- L'adresse du caractère en CGRam est dans le registre Work2      ---
; -----------------------------------------------------------------------

DisplayWriteCGRAM:

		clr		Count1
		out		EEARH,Count1
		ldi 	Count1,8							; 8 lignes à écrire

VFDBoucleCar:
		
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 à 1
		cbr		Work,0b10000000						; et le bit 7 à zéro
		rcall	VFDSendCommand						; Envoie l'instrucution au VFD
		rcall 	VFDTestBusyFlag						; et attend la fin de commande

        out     EEARL,Work1                     	; On charge "l'adresse" de la ligne de caractère pour l'EEPROM
        sbi     EECR,EERE                       	; On prépare l'EEPROM à la lecture
        in      Char,EEDR                     		; On lit la valeur stokée en EEPROM et on la met dans le registre Char

		rcall	VFDSendData							; On envoie la valeur à l'afficheur
		rcall 	VFDTestBusyFlag						; et on attend la fin de commande

		inc		Work1								; incrémente l'adresse de l'EEPROM pour la ligne suivante
		inc		Work2								; Incrémente l'adresse en CGRAM
		dec		Count1								; décrémente le compteur de ligne 
		brne	VFDBoucleCar						; C'est la dernière ligne du caractère ? 

		ret											; On a fini

; -----------------------------------------------------------------------------
; --- Pour écrire un caractère sur l'afficheur,
; --- Lui donner la position (rcall DisplayPlaceCurseur)
; --- puis envoyer le caractère (rcall DisplayWriteChar)
; ---
; --- Pour des écriture successives, comme le curseur bouge tout seul
; --- après chaque écriture, seul un appel à DisplayWriteChar est nécessaire
; -----------------------------------------------------------------------------

; -------------------------------------------------------
; --- Met le "curseur" à une certaine position        ---
; --- La position (adresse) est dans le registre Work ---
; -------------------------------------------------------

DisplayPlaceCurseur:

		sbr		Work,0b10000000						; Pour indiquer une adresse DDRAM, met le bit 7 à 1
		rcall	VFDSendCommand						; Envoie l'instrucution au VFD
		rcall 	VFDTestBusyFlag						; et attend la fin de commande

		ret											; et on a fini

; ------------------------------------------
; --- Ecrit un caractère sur l'afficheur --- 
; --- Le caractère est dans Char         ---
; ------------------------------------------

DisplayWriteChar:

;		rcall	VFDTesteChar
		rcall	VFDSendData							; On envoie la valeur à l'afficheur
		rcall 	VFDTestBusyFlag						; et on attend la fin de commande

		ret											; et on se casse

VFDTesteChar:

		cpi		Char,'g'
		brne	S1
		ldi		Char,0xE7
		ret
S1:		cpi		Char,'j'
		brne	S2
		ldi		Char,0xEA
		ret
S2:		cpi		Char,'p'
		brne	S3
		ldi		Char,0xF0
		ret
S3:		cpi		Char,'q'
		brne	S4
		ldi		Char,0xF1'
		ret
S4:		cpi		Char,'y'
		brne	S5
		ldi		Char,0xF9
		ret
S5:
		ret

; ------------------------------------
; --- Efface l'afficheur           ---
; --- Et remet le curseur au début ---
; ------------------------------------

DisplayClear:

		ldi 	Work,1								; Commande d'effacement
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande (1.5ms)


VFDHome:

		ldi		Work,0b00000010						; Return Home
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande (1.5ms)

		ret											; et cassos


; ----------------------------
; --- Affichage du curseur ---
; ----------------------------

DisplayCursorOn:

		ldi		Work,0b00001110						; Display On, Cursor On, Blink Off
		rcall 	VFDSendCommand						; et on envoie la commande
;		rcall 	VFDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; -----------------------------
; --- Effacement du curseur ---
; -----------------------------

DisplayCursorOff:

		ldi		Work,0b00001100						; Display On, Cursor Off, Blink Off
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; --------------------------------
; -- Curseur en bloc clignotant --
; --------------------------------

DisplayCursorBlock:
		ldi		Work,0b00001111						; Display On, Cursor On, Blink On
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande
		ret											; et bye

; ---------------------------------
; --- Extinction de l'afficheur ---
; ---------------------------------

DisplayOff:

		ldi		Work,0b00001000						; Display Off, Cursor Off, Blink Off
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande

		ret

; ---------------------------------
; --- Extinction de l'afficheur ---
; ---------------------------------

DisplayOn:

		ldi		Work,0b00001100						; Display Off, Cursor Off, Blink Off
		rcall 	VFDSendCommand						; et on envoie la commande
		rcall 	VFDTestBusyFlag						; Attend la fin de commande

		ret

; -------------------------------------------------------
; --- Affichage d'une chaine de caractères sur le VFD ---
; --- La chaine est dans la mémoire programme...      ---
; -------------------------------------------------------

DisplayAfficheChaine:

		push	Char								; Sauvegarde le registre caractère
		push	ZL									; Sauvegarde l'adresse de début de la chaîne
		push	ZH									; pour pouvoir s'en reservir à la sortie 

VFDNextChar:
		lpm		Char,Z+								; Charge le caractère à l'adresse contenue dans le registre char,
													; et on incrémente l'adresse mémoire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caractère de fin de chaîne ?
		breq	ExitVFDAfficheChaine				; 	- Oui, alors on sort
		cpi		Char,FinLigne						; 	- Non, mais est-ce un saut de ligne ?
		breq	VFDNewLine							;		- Oui, alors on saute à la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on écrit le caractère
		rjmp	VFDNextChar							; 		  et on passe au caractère suivant

VFDNewLine:
		ldi		Work,0x40							; Place le curseur au début de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	VFDNextChar							; et passe au caractère suivant

ExitVFDAfficheChaine:

		pop		ZH									; Récupère l'adresse de début de chaîne
		pop		ZL									; qu'on avait stockée au début
		pop 	Char								; Restaure le registre Char

		ret											; et on s'en va

; -------------------------------------------------------
; --- Affichage d'une chaine de caractères sur le VFD ---
; --- La chaine est en RAM...                         ---
; -------------------------------------------------------

DisplayAfficheChaineRAM:

		push	Char								; Sauvegarde le registre caractère
		push	ZL									; Sauvegarde l'adresse de début de la chaîne
		push	ZH									; pour pouvoir s'en reservir à la sortie 

VFDNextCharRAM:
		ld		Char,Z+								; Charge le caractère à l'adresse contenue dans le registre char,
													; et on incrémente l'adresse mémoire dans Z
		cpi		Char,FinChaine						; Est-ce que c'est un caractère de fin de chaîne ?
		breq	ExitVFDAfficheChaineRAM				; 	- Oui, alors on sort
		cpi		Char,FinLigne						; 	- Non, mais est-ce un saut de ligne ?
		breq	VFDNewLineRAM						;		- Oui, alors on saute à la ligne
		rcall	DisplayWriteChar					; 		- Non, alors on écrit le caractère
		rjmp	VFDNextCharRAM						; 		  et on passe au caractère suivant

VFDNewLineRAM:
		ldi		Work,0x40							; Place le curseur au début de la seconde ligne
		rcall 	DisplayPlaceCurseur						;
		rjmp	VFDNextCharRAM							; et passe au caractère suivant

ExitVFDAfficheChaineRAM:

		pop		ZH									; Récupère l'adresse de début de chaîne
		pop		ZL									; qu'on avait stockée au début
		pop 	Char								; Restaure le registre Char
		ret											; et on s'en va

; ---------------------------------------------------------------
; -- Effacement de la première ou seconde ligne de l'afficheur --
; ---------------------------------------------------------------

DisplayEffacePremiereLigne:

		clr		Work								; Curseur en début de première ligne
		rjmp	VFDEfface							; et efface la ligne

VFDEffaceSecondeLigne:								; Point d'entrée pour l'effacement de la seconde ligne

		ldi		Work,0x40							; se place en début de seconde ligne

VFDEfface:
		push	Work								; sauvegarde l'adresse du début de ligne
		rcall 	DisplayPlaceCurseur						; Place le curseur en début de ligne

		ldi		Char,32								; Un blanc pour l'effacement
		ldi		Count1,0
LoopLine:
		rcall 	DisplayWriteChar					; écrit le blanc
		inc		Count1
		cpi		Count1,DisplaySize					; fin de ligne ?
		brne	LoopLine							; nan

		pop		Work								; On récupère l'adresse du début de ligne
		call	DisplayPlaceCurseur					; Et on replace le curseur en début de ligne

		ret											; fin de routine

; -----------------------------------------
; -- Affiche les flèches pour l'encodeur --
; -----------------------------------------

DisplayArrow:

		ldi		Work,0x40							; Première position
		rcall	DisplayPlaceCurseur					; seconde ligne

		ldi		Char,5								; Flèche vers la gauche
		rcall	DisplayWriteChar

		ldi		Work,0x40							; Seconde ligne
		subi	Work,-(DisplaySize-1)
		rcall	DisplayPlaceCurseur						; dernière position

		ldi		Char,4								; Flèche vers la droite
		rcall	DisplayWriteChar		

		ret											; finito

; ------------------------------------------------
; -- Ecriture des caractères accentués en CGRAM --
; ------------------------------------------------

DisplayCGRamDefaut:

; -- Le "é" --

		ldi		Work1,EE_Eaigu						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Eaigu					; L'adresse en CGRAM pour l'afficheur (ici 1)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "è" --

		ldi		Work1,EE_Egrave						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Egrave					; L'adresse en CGRAM pour l'afficheur (ici 2)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "ë" --

		ldi		Work1,EE_Etrema						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Etrema					; L'adresse en CGRAM pour l'afficheur (ici 3)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

; -- La flèche vers la droite --

		ldi		Work1,EE_FDroite					; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_FDroite					; L'adresse en CGRAM pour l'afficheur (ici 4)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- La flèche vers la gauche --

		ldi		Work1,EE_FGauche					; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_FGauche					; L'adresse en CGRAM pour l'afficheur (ici 5)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le "à" --

		ldi		Work1,EE_Agrave						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Agrave					; L'adresse en CGRAM pour l'afficheur (ici 6)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur


; -- Le Smiley --

		ldi		Work1,EE_Smile						; L'adresse en EEPROM de la définition du caractère
		ldi 	Work2,CGRam_Smile					; L'adresse en CGRAM pour l'afficheur (ici 7)
		call	DisplayWriteCGRAM					; et on envoie le bins dans l'afficheur

		ret

; ------------------------------------------
; -- Fixe la luminosité de l'afficheur    --
; -- La valeur est dans Work              --
; --      0 : 25%                         --  
; --      1 : 50%                         --  
; --      2 : 75%                         --  
; --      3 : 100%                        --  
; -- La valeur qu'on passe à l'afficheur  --
; -- est inversée :                       -- 
; --      0 : 100%                        --  
; --      1 : 75%                         --  
; --      2 : 50%                         --  
; --      3 : 25%                         --  
; ------------------------------------------

SetBrightness:

		push	Work								; Sauvegarde Work (qui contient la luminosité)
#if defined(NORITAKE)
		ldi		Work,0b00111000						; C'est un "function set" dans le cas du Noritake
#endif

#if defined(NEWHAVEN)								; Dans le cas d'un VFD Newhaven, on met dans la valeur de la luminosité
		mov 	Char,Work							; dans les deux derniers bits (en les inversant)
		com		Char								; Inverse la valeur
		andi	Char,0b00000011						; et met à zéro les bits qu'il faut.(les 6 de poids fort)
	    ldi		Work,0b00111000						; On met la commande "function set" dans Work
		add		Work,Char							; Ajoute la luminosité
#endif

		rcall	VFDSendCommand						; et on envoie la commande

		pop		Work
#if defined(NORITAKE)								; Pour le Noritake, c'est un peu différent et il faut envoyer des données supplémentaires
		mov		Char,Work
		com 	Char								; prend l'inverse
		andi	Char,0b00000011						; et met à zéro les bits qu'il faut.
		call	VFDSendData
#endif
		ret											; finito

; ----------------------------------------------------------------------
; -- Passage de la luminosité de l'afficheur à la valeur de mode Idle -- 
; ----------------------------------------------------------------------

SetIdleBrightness:							

		ldi		ZH,RAM_Start							; On récupère la valeur de luminosité actuelle en RAM
		ldi		ZL,RAM_StartBrightness
		ld		Work1,Z

		ldi		ZH,RAM_Start							; On récupère la valeur de luminosité Idle en RAM
		ldi		ZL,RAM_IdleBrightness
		ld		Work2,Z

		cp		Work2,Work1								; On diminue seulement si la luminosité d'Idle
		brlo	BoucleIdleBrightness					; est inférieure à la luminosité en actif
		ret												; sinon on ne fait rien

BoucleIdleBrightness:
		mov		Work,Work1								; Transfère dans le bon registre
		rcall 	SetBrightness							; et envoie ça sur le potar numérique

		ldi		Work,VFDBrightDelay
WaitVFDIdle:
		rcall	Attendre								; Petite temporisation
		dec		Work
		brne	WaitVFDIdle

		ldi		Count1,WaitBrightEnd
		rcall	MyWait									; Petite temporisation

		dec		Work1									; Décrémente la luminosité
		cp		Work1,Work2								; et tant qu'on n'est pas arrivé à la luminosité d'idle,
		brne	BoucleIdleBrightness					; On la diminue				

		mov		Work,Work2								; Transfère dans le bon registre
		rcall 	SetBrightness							; et envoie ça sur le potar numérique

		ret

; ----------------------------------------------------------------- 
; -- Retour de la luminosité de l'afficheur à sa valeur nominale --
; ----------------------------------------------------------------- 

RestoreBrightness:

; Les deux lignes suivantes pour éviter le bug du réveil de l'afficheur..
		ldi 	Work,0b00000100
		sts		ETIMSK,Work							; réautorise les interruptions par overflow sur le timer 3

		sbi		PortLedOn,LedOn						; Eventuellement, rallumer la Led

		ldi		ZH,RAM_Start						; On récupère la caleur de luminosité normale en RAM
		ldi		ZL,RAM_StartBrightness
		ld		Work,Z

		rcall	SetBrightness

		ret

; -------------------------------------------------------
; -- Augmentation de la luminosité par une commande IR --
; -------------------------------------------------------

IncreaseBrightness:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de la luminosité en RAM
		ld		Work,Z								; Récupère la valeur stockée en RAM 

		cpi		Work,BrightnessMax					; On est au max ?
		breq	ExitADIncB							;   vi -> on s'en va

		inc		Work								; sinon, on augmente la luminosité

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartBrightness				; 
		st		Z,Work								;  

		rcall	SetBrightness						; de manière effective ;)

ExitADIncB:
		ret

; -----------------------------------------------------
; -- Diminution de la luminosité par une commande IR --
; -----------------------------------------------------

DecreaseBrightness:

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_StartBrightness				; L'adresse de la luminosité en RAM
		ld		Work,Z								; Récupère la valeur stockée en RAM 

		cpi		Work,0								; On est au min ?
		breq	ExitADDecB							;   vi -> on s'en va

		dec 	Work

		ldi		ZH,RAM_Start						; Et on restocke la nouvelle valeur en RAM 
		ldi		ZL,RAM_StartBrightness				; 
		st		Z,Work								;  

		rcall	SetBrightness						; de manière effective ;)

ExitADDecB:
		ret

; -----------------------------------------------------------------------
; --- Ecrit un caractère utilisateur dans la RAM graphique du VFD     ---
; --- à l'adresse 0 pour le BarGraph                                  ---
; --- La valeur est dans le registre Char                             ---
; -----------------------------------------------------------------------

DisplayWriteBarGraph:

		push	Work2								; Sauvegarde Work2

		ldi 	Count1,8							; 8 lignes à écrire
		ldi		Work2,0								; Adresse 0 en CGRAM

		ldi		ZH,RAM_Bar_H
		ldi		ZL,RAM_Bar_L

VFDBoucleCarBG:
		ld		Char,Z+
		mov		Work,Work2							; Copie l'adresse CGRAM dans Work
		sbr		Work,0b01000000						; Pour indiquer une adresse CGRAM, met le bit 6 à 1
		cbr		Work,0b10000000						; et le bit 7 à zéro
		rcall	VFDSendCommand						; Envoie l'instrucution au VFD
		rcall 	VFDTestBusyFlag						; et attend la fin de commande

		rcall	VFDSendData							; On envoie la valeur à l'afficheur
		rcall 	VFDTestBusyFlag						; et on attend la fin de commande

		inc		Work2								; Incrémente l'adresse en CGRAM
		dec		Count1								; décrémente le compteur de ligne 
		cpi		Count1,1							; Dernière ligne ?
		breq	VFDLastBG							; vi -> Traitement spécial
		cpi		Count1,0							; Derdesder ?	
		breq	ExitVFDWriteBG						;   Vi, on sort
		rjmp	VFDBoucleCarBG						;   Nan, on boucle 

VFDLastBG:
		clr		Char
		rjmp	VFDBoucleCarBG						; C'est la dernière ligne du caractère ? 

ExitVFDWriteBG:
		pop		Work2								; Restore Work2
		ldi		ZH,RAM_Start
		ret											; On a fini

