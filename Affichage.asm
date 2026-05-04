; =====================================================================
; == Toutes les routines d'affichage autre que celles de l'afficheur ==
; =====================================================================

; -----------------------------------
; -- Routine d'affichage du volume --
; -----------------------------------

AfficheVolume:

		sbrc	StatReg1,FlagBalance				; Si on était en train d'afficher la balance,
		call	AfficheEntreeApresBalance			; il faut réafficher l'entrée pour meubler la première ligne

		sbrc	StatReg1,FlagMenu					; Si on est en mode menu (Preset de volume)
		rjmp	SkipChaineVolume					; on n'affiche pas la première chaîne

		ldi		Work,0x40							; Curseur au début de la seconde ligne
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(VolumeMessage*2)
		ldi		ZL,LOW(VolumeMessage*2)
		rcall	DisplayAfficheChaine				; Affiche "Volume :"

SkipChaineVolume:
		ldi		Work,0x49							; Curseur au dixième caractère sur cette même ligne
		call	DisplayPlaceCurseur

		sbrc	StatReg1,FlagMenu					; Affichage "obligatoire" en dB si on est en mode menu
		rjmp	AffichedB

		ldi		ZH,RAM_Start						; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_AffichageVolume				; récupère la valeur de l'afiichage de volume
		ld		Work,Z								; et le met dans le registre

		cpi		Work,0								; Affiche en dB (la valeur est à 0) ?
		breq	AffichedB							; vivi, c'est ça
		rjmp	AfficheNormal						; non, c'est autre chose

; --- Affichage du volume en dB

AffichedB:
		ldi		Work1,127
		cp		VolReg,Work1						; Volume Maxi ?
		brsh	AfficheMaxdB						; oui, alors on affiche 0.00dB

		ldi		Char,'-'							; non, alors on est < 0dB,
		rcall	DisplayWriteChar					; donc faut afficher un signe moins...

; Comme le volume est par pas de 0.75dB, on multiplie par trois et on divise par 4 la valeur du volume binaire pour l'avoir en dB (0.75=3/4....)

		ldi		Work,127
		sub		Work,VolReg							; Complement à 127 de la valeur pour les dB -> La valeur du volume est maintenant dans Work

		mov		Work3,Work							; 3 additions -> Multiplication par 3
		add		Work3,Work							; On fait attention à ne pas écraser le bit de retenue à la fin, car on va le récupérer
		add		Work3,Work							; la valeur max est 3x126, soit moins de 512 (378 exactement) donc on n'a besoin que du bit de carry... 

		mov		Work2,Work3							; Conserve la valeur, on va en avoir besoin car les deux derniers bits vont être perdus durant le décalage à droite
		ror		Work3								; Première division par 2,sans oublier de shifter le bit de "Carry"
		lsr		Work3								; Seconde division par deux, plus besoin du carry, on contraire on met un zéro dans le bit 7

		andi	Work2,0b00000011					; on ne garde que les deux bits qui auraient été perdus lors du shift
		mov		LSDVol,Work3						; et le nombre "principal"

; Arrivés ici, on a le résultat de l'opération dans LSDVol et les décimales dans Work2

		rcall	BinaireToBCD						; transforme ça en un nombre à deux chiffres (MSDVol et LSDVol)

		ldi		Work,48								; On regarde si le chiffre des dizaines est un zéro
		cp		Work,MSDVol							
		breq	NoDiz								; Oui c'est un zéro (48 en ascii), alors pas la peine de l'afficher

		mov		Char,MSDVol							; sinon, on affiche
		rcall	DisplayWriteChar					; le chiffre des dizaines
		
NoDiz:
		mov		Char,LSDVol
		rcall	DisplayWriteChar					; Affiche le chiffre des unités

		ldi		Char,'.'							; Affiche le point décimal
		rcall	DisplayWriteChar

; -- On s'attaque maintenant aux décimales (contenues dans Work2)

		cpi		Work2,0								; Si on a zéro, c'est '00' qu'il faut afficher
		brne	NextTenth1							; c'est pas zéro

		ldi		Char,'0'							; Deux écritures de "0"
		rcall	DisplayWriteChar
		rcall	DisplayWriteChar
		rjmp	FinDB

NextTenth1:	

		cpi		Work2,1								; si on a 1, c'est "0.25"
		brne	NextTenth2							; c'est pas ça

		ldi		Char,'2'							; on écrit "25"
		rcall	DisplayWriteChar
		ldi		Char,'5'
		rcall	DisplayWriteChar
		rjmp	FinDB

NextTenth2:	

		cpi		Work2,2								; si on a 2, c'est "0.50"
		brne	NextTenth3							; c'est toujours pas ça

		ldi		Char,'5'							; on écrit "50"
		rcall	DisplayWriteChar
		ldi		Char,'0'
		rcall	DisplayWriteChar
		rjmp	FinDB

NextTenth3:											; arrivé ici, c'est sûrement 3, donc il faut écrire "0.75"

		ldi		Char,'7'							; on écrit "50"
		rcall	DisplayWriteChar
		ldi		Char,'5'
		rcall	DisplayWriteChar

FinDB:												; on écrit "dB " à la fin de la chaine
		ldi		Char,32
		rcall	DisplayWriteChar
		ldi		Char,'d'
		rcall	DisplayWriteChar
		ldi		Char,'B'
		rcall	DisplayWriteChar
		ldi		Char,32
		rcall	DisplayWriteChar

		rjmp	ExitAfficheVolume					; On a fini l'affichage en dB

AfficheMaxdB:
		ldi		ZH,HIGH(VolMaxdBMessage*2)
		ldi		ZL,LOW(VolMaxdBMessage*2)
		rcall	DisplayAfficheChaine				; Affiche " 0.00dB"
		rjmp	ExitAfficheVolume					; pas la peine d'aller plus loin...

; -- Affichage de la valeur décimale du volume (de 0 à 127)

AfficheNormal:										; Affichage du volume en pas (de 0 à 127)

		cpi		Work,1								; Affichage normal ?
		brne	AfficheBinaire						; non, c'est finalement l'affichage en binaire

		ldi		Char,32								; on commence par un blanc
		rcall	DisplayWriteChar

		mov		LSDVol,VolReg						; Transfère la valeur du volume dans LSDVol

		cpi		LSDVol,100							; cette valeur est-elle supérieure ou égale à 100 ?
		brlt	LastNormalDigits					; non, on n'a que 2 chiffres à afficher

		ldi		Char,'1'							; sinon, on affiche d'abord le 1 des centaines
		rcall	DisplayWriteChar				

		subi	LSDVol,100							; et on enlève la centaine qui gène...

LastNormalDigits:									; On s'occupe des derniers chiffres

		rcall	BinaireToBCD						; transforme ça en un nombre à deux chiffres (MSDVol et LSDVol)

		cpi		MSDVol,48							; le chiffre des dizaines est un zéro ?
		brne	AfficheDiz							; non, pas de pb on l'affiche

		mov		Work,VolReg							; Mais si c'est un "0", y a-t-il le chiffre des centaines devant ?

		cpi		Work,100
		brge	AfficheDiz							; Oui, alors on l'affiche, ce zéro
		rjmp	AfficheUnites						; sinon, on saute à l'affichage des unités

AfficheDiz:											; Affichage du chiffre des dizaines
		mov		Char,MSDVol
		rcall	DisplayWriteChar

AfficheUnites:										; Affichage du chiffre des unités
		mov		Char,LSDVol
		rcall	DisplayWriteChar
		rjmp	ExitAfficheVolume					; et on a fini par ici

; -- Affichage du volume en binaire

AfficheBinaire: 									; Si on arrive là, pas besoin de tests
		cpi		Work,2
		brne	AfficheGraphique

		mov		LSDVol,VolReg						; Transfère la valeur du volume dans un registre immédiat

		ldi		Char,32								; On commence par un blanc
		rcall	DisplayWriteChar

; Et c'est parti pour l'affichage de tous les bits

		ldi		Count1,7								; 7 bits à lire

BoucleShiftBits:

		lsl		LSDVol								; On décale d'une position vers la droite pour ne tester que le bit 7
		ldi		Char,'1'							; Charge un 1 par défaut dans le registre de caractère
		sbrs	LSDVol,7							; Le bit 7 est-il à 1 ?
		ldi		Char,'0'							; 	-Non, alors on met un 0
		rcall	DisplayWriteChar						; On écrit le contenu de Char
		dec		Count1								; Combien de bits on a déjà affiché?
		brne	BoucleShiftBits						; On n'a pas tout affiché, alors on reboucle
													; Sinon, on a fini l'affichage et on se casse
		rjmp	ExitAfficheVolume

; -- Affichage en mode "pseudo-graphique"

AfficheGraphique:

		mov		Work,VolReg
		cpi		Work,8								; Volume inférieur à 8 ?
		brsh	AfficheBarIsMax		
		rjmp	ExitAfficheVolume

AfficheBarIsMax:
		cpi		Work,VolumeMaxi
		brne	AfficheMultipleBars
		rjmp	AfficheAllBars

AfficheMultipleBars:

; On a 12 caractères de 5 points de large de disponible,
; donc on va travailler entre 0 et 120 de valeur de volume
; On divise par 2 pour ramener ça à 0->60.
; Puis on divise par 5, le quotient nous donnant le nombre de caractères de 5 points
; et le reste représente le nombre de barres verticales à allumer

		subi	Work,7								; on va travailler entre 0 et 120
		mov		MenuReg1,Work						; On garde cette valeur dans MenuReg1
		lsr		Work								; Divise la valeur par deux
		
		call	AfficheDivideBy5					; Et par 5. Work2=Quotient, Work1=Reste

; -- Et on affiche tout ça

		cpi		Work2,0								; Quotient = 0 ?
		breq	AfficheBars							; vi, alors aucun bloc mais des barres

		ldi		Char,BlockChar	    				; Caractère "bloc"
		clr 	Count1								; pour compter le nombre de blocs
AfficheLoopBloc:
		ldi		Work,0x48							; Début de la zone d'affichage
		add		Work,Count1							; puis position du caractère
		call	DisplayPlaceCurseur
		call	DisplayWriteChar					; Affiche le bloc
		inc		Count1								; Passe au suivant
		cpse	Count1,Work2						; c'était le dernier ?
		rjmp	AfficheLoopBloc						; non, on boucle

AfficheBars:										; le dernier caractère est éventuellement composé de barres
		mov		Count1,Work1						; "Dessin" des barres par définition du caractère graphique
		ldi		Work3,0b00010000					; Le nombre de barres est égal au reste de la division
		clr		Char								; (entre 0 et 4)
DoAfficheBarsLoop:									; avec des 1/2 barres intermédiaires
		cpi		Count1,0							; Char contient les barres 
		breq	FinDoAfficheBarsLoop				; et Work3 les 1/2 barres
		mov		Char,Work3	
		lsr		Work3
		sbr		Work3,0b00010000
		dec		Count1
		rjmp	DoAfficheBarsLoop

FinDoAfficheBarsLoop:								; On va stocker ça en RAM
		ldi		ZH,RAM_Bar_H
		ldi		ZL,RAM_BAR_L
		clr		Count1

AfficheBarLoopRAM:		
		st		Z+,Char
		inc		Count1
		cpi		Count1,MiDots						; pour les 1/2 barres
		breq	AffichaBarChangeChar
		cpi		Count1,MaxDots
		brne	AfficheBarLoopRAM
		rjmp	AfficheBarLoadChar

AffichaBarChangeChar:								; si la valeur du volume est paire
		sbrc	MenuReg1,0							; on passe à la 1/2 barre 
		mov		Char,Work3
		rjmp	AfficheBarLoopRAM

AfficheBarLoadChar:
#if defined(VFD)
		clr		Char
		st		Z+,Char
#endif
		call	DisplayWriteBarGraph				; On écrit le caractère dans la mémoire graphique de l'afficheur
		clr		Char								; à l'adresse 0, donc Char vaut 0
		ldi		Work,0x48							; on se place au bon endroit
		add		Work,Work2
		call	DisplayPlaceCurseur
		call	DisplayWriteChar					; on écrit,
		rjmp	ExitAfficheVolume					; et c'est fini

AfficheAllBars:										; Rien que des blocs entiers, par paquets de 12
		clr		Count1
		ldi		Char,BlockChar   					; Le caractère bloc
AfficheAllBarsLoop:									; et on l'affiche à 12 positions successives
		mov		Work,Count1
		subi	Work,-0x48
		call	DisplayPlaceCurseur
		call	DisplayWriteChar
		inc		Count1
		cpi		Count1,12
		brne	AfficheAllBarsLoop
		rjmp	ExitAfficheVolume

ExitAfficheVolume:
		ret											; fin de sub

; --------------------------------------------
; --               Division par 5           --
; --                                        --
; -- On approxime ça par la suite récursive --
; --  y=x/4                                 --
; --  do i=1,n (n < 15)                     --
; --    y=x-y                               --
; --    y=y/4                               --
; --  enddo                                 --
; --                                        --
; -- et y contient x/5                      --
; -- Plus n est grand, plus c'est exact.    --
; -- Ici, la valeur de n est fixée à 3,     --
; -- ce qui calcule en réalité 51x/256      --
; -- et ça suffit largement à nos besoins   --
; --                                        --
; -- Work contient la valeur en entrée      --
; -- Work2 contient le quotient en sortie   --
; -- Work1 récupère le reste                --
; --                                        --
; --------------------------------------------

AfficheDivideBy5:
		mov		Work2,Work							; Copie Work dans Work2
		lsr		Work2								; Division
		lsr		Work2								; par 4
		ldi		Count1,3
AfficheLoopDiv5:
		mov		Work1,Work							; Calcule Work-Work2
		sub		Work1,Work2							; sans écraser Work
		mov		Work2,Work1							; avec résultat dans Work2
		lsr		Work2								; et on redivise
		lsr		Work2								; par 4
		dec		Count1
		brne	AfficheLoopDiv5

; -- Work 2 contient Work/5 et on va calculer le reste

		mov 	Work1,Work2							; Garde le résultat au chaud
		lsl		Work1								; Multiplie
		lsl		Work1								; par 4
		add		Work1,Work2							; et ajoute une fois, donc multiplication par 5
		sub		Work,Work1							; Work contient maintenant le reste de la division
		mov		Work1,Work							; qu'on copie dans Work1

		ret

; -----------------------------------------
; -- Affichage de l'intitulé des entrées --
; -----------------------------------------

AfficheEntree:

		call	DisplayEffacePremiereLigne			; Commence par effacer la première ligne de l'afficheur

		sbrc	StatReg1,FlagBalance				; Si on était en train d'afficher la balance,
		call	AfficheVolumeApresBalance			; il faut réafficher l'entrée pour meubler la première ligne

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_EntreeActive
		ld		Work1,Z								; récupère l'entrée à afficher dans le registre Work1

		ldi		Work,0
		call	DisplayPlaceCurseur

;		cpi		Work1,4								; Traitement à part si c'est le magnéto
;		breq	AfficheIntituleTape					; 

		sbrs	StatReg1,FlagAsym					; Regarde si l'entrée est sur XLR ou RCA
		rcall	WriteXLR							; C'est une XLR
		sbrc	StatReg1,FlagAsym
		rcall	WriteRCA							; C'est une RCA

		ldi		Char,32								; un blanc...
		rcall	DisplayWriteChar

		mov		Char,Work1							; Le n° de l'entrée
		subi	Char,-49							; on le passe en ascii
		rcall	DisplayWriteChar					; et on l'écrit

		ldi		Char,32								; Puis on inscrit " : "
		rcall	DisplayWriteChar
		ldi		Char,':'
		rcall	DisplayWriteChar
		ldi		Char,32
		rcall	DisplayWriteChar

		ldi		ZH,RAM_Start

		cpi 	Work1,0								; C'est l'entrée 1 ?
		brne	AfficheIn2							; 	- Nan, on teste la suivante
		ldi		ZL,RAM_TitreIn1						; 	- Oui, alors adresse EEPROM du début de l'intitulé
		rjmp	AfficheIntitule						; et on va afficher le titre

AfficheIn2:
		cpi 	Work1,1								; C'est l'entrée 2 ?
		brne	AfficheIn3							; 	- Nan, on teste la suivante
		ldi		ZL,RAM_TitreIn2						; 	- Oui, alors adresse EEPROM du début de l'intitulé
		rjmp	AfficheIntitule						; et on va afficher le titre

AfficheIn3:
		cpi 	Work1,2								; C'est l'entrée 3 ?
		brne	AfficheIn4							; 	- Nan, on teste la suivante
		ldi		ZL,RAM_TitreIn3						; 	- Oui, alors adresse EEPROM du début de l'intitulé
		rjmp	AfficheIntitule						; et on va afficher le titre

AfficheIn4:
		cpi 	Work1,3								; C'est l'entrée 4 ?
		brne	AfficheIn5							; 	- Nan, on teste la suivante
		ldi		ZL,RAM_TitreIn4						;   - Oui, alors adresse EEPROM du début de l'intitulé
		rjmp	AfficheIntitule						; et on va afficher le titre

AfficheIn5:											; Arrivé ici, c'est forcément l'entrée 5 (Tape ou Vinyle/Phillipe) ...
		ldi		ZL,RAM_TitreIn5
		
AfficheIntitule:
		ldi		Count1,NameSize						; 12 caractères au max

AfficheNextChar:
		ld		Char,Z+								; Récupère le caractère en RAM, et incrémente l'adresse RAM en prévision de la prochaine lecture
		rcall	DisplayWriteChar					; On écrit le caractère
		dec		Count1								; C'est le dernier caractère ?
		brne	AfficheNextChar						; 	- Non, alors on reboucle

ExitAfficheEntree:									;   - Oui, alors c'est fini
		ret											; Et c'est tout mon toutou

; ------------------------------------
; -- Affichage de l'entrée bypassée --
; ------------------------------------
#if defined(BYPASS)
AfficheBypass:

		call	DisplayEffacePremiereLigne			; Commence par effacer la première ligne de l'afficheur

		sbrc	StatReg1,FlagBalance				; Si on n'était pas en train d'afficher la balance,
		rjmp	AffBypSkipBal						; on poursuit normalemeny

		clr		Work								; sinon, on arrête le Timer 3 
		sts		TCCR3B,Work							; qui était en train de tourner
		cbr		StatReg1,EXP2(FlagBalance)			; et on nactive le flag d'affichage

AffBypSkipBal:

		ldi		Work,2
		call	DisplayPlaceCurseur					; Curseur LCD sur le 3ème caractère

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_TitreIn5						; Adresse RAM du début de l'intitulé
		ldi		Count1,16 							; 16 caractères au max

AfficheByNextChar:
		ld		Char,Z+								; Récupère le caractère en RAM, et incrémente l'adresse RAM en prévision de la prochaine lecture
		rcall	DisplayWriteChar					; On écrit le caractère
		dec		Count1								; C'est le dernier caractère ?
		brne	AfficheByNextChar						; 	- Non, alors on reboucle

		ldi		ZH,RAM_Start
		ldi		ZL,RAM_In_Bypass
		ld		Work1,Z								; récupère l'entrée bypassée à afficher dans le registre Work1

		ldi		Work,8								; Curseur en 9ème position
		call 	DisplayPlaceCurseur

		mov		Char,Work1							; Le n° de l'entrée
		subi	Char,-49							; est transformé en ASCII
		rcall	DisplayWriteChar						; et on l'écrit

		ldi		Work,0x40							; Curseur au début de la seconde ligne
		call	DisplayPlaceCurseur

		ldi		ZH,HIGH(Bypass2Message*2)
		ldi		ZL,LOW(Bypass2Message*2)
		rcall	DisplayAfficheChaine				; Affiche le message de la seconde ligne

		ret											; Et c'est tout mon toutou
#endif

; ---------------------------------------
; -- Routine d'affichage de la balance --
; ---------------------------------------

AfficheBalance:

;		sbrc	StatReg1,FlagBalance				; Est-ce qu'on vient juste de paser en mode Balance ?
;		rjmp	AfficheBalanceNoClear				; 	- Non, on y était déjà, alors pas besoin d'effacer l'afficheur

		rcall	DisplayEffacePremiereLigne			;   - Oui alors il faut effacer l'afficheur

		ldi		Work,0								; Se place au début
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(BalanceMessage*2)			; Affiche le message correspondant à la balance
		ldi		ZL,LOW(BalanceMessage*2)
		call	DisplayAfficheChaine

		sbr		StatReg1,EXP2(FlagBalance)			; Mentionne le fait qu'on est en train d'afficher la balance

AfficheBalanceNoClear:

		mov		Work,BalanceReg
		cpi 	Work,0								; Balance au milieu ?
		brne	AfficheBalanceQuelconque			;	- Non -> Procédure normale
		rjmp	AfficheBalanceMilieu				;	- Oui -> On l'affiche

AfficheBalanceQuelconque:

; -- On convertit la valeur en décimal --

		mov		Work,BalanceReg						; Copie la valeur dans un registre temporaire
		andi	Work,MasqueBalance					; on ne garde que les 3 premiers bits

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
													; Ici, MSDVol ne sert à rien

; -- Maintenant, on va afficher la valeur, à gauche ou à droite

		ldi		Work,0x40							; Début	de seconde ligne
		rcall	DisplayPlaceCurseur
			
		mov		Work1,BalanceReg					; Récupère la valeur de la balance
		cbr		Work1,0b10000000					; Efface le bit de "signe"

		sbrs	BalanceReg,7
		rjmp	BarraDroite
		sbrc	BalanceReg,7
		rjmp	BarraGauche

BarraDroite:

		ldi		ZH,HIGH(BalanceDroiteMessage*2)		; Affiche le message correspondant à la balance sur la seconde ligne
		ldi		ZL,LOW(BalanceDroiteMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x42
		call	DisplayPlaceCurseur
		rjmp	AfficheValeurBalance

BarraGauche:
		ldi		ZH,HIGH(BalanceGaucheMessage*2)		; Affiche le message correspondant à la balance sur la seconde ligne
		ldi		ZL,LOW(BalanceGaucheMessage*2)
		call	DisplayAfficheChaine

		ldi		Work,0x4C
		call	DisplayPlaceCurseur

AfficheValeurBalance:
		mov		Char,LSDVol				
		call	DisplayWriteChar					; Affiche le chiffre des unités

		ldi		Char,'.'							; Affiche le point décimal
		call	DisplayWriteChar

; -- On s'attaque maintenant aux décimales (contenues dans Work2)

		cpi		Work2,0								; Si on a zéro, c'est '00' qu'il faut afficher
		brne	NextTenthBal1						; c'est pas zéro

		ldi		Char,'0'							; Deux écritures de "0"
		call	DisplayWriteChar
		call	DisplayWriteChar
		rjmp	BalFinDB

NextTenthBal1:	

		cpi		Work2,1								; si on a 1, c'est "0.25"
		brne	NextTenthBal2						; c'est pas ça

		ldi		Char,'2'							; on écrit "25"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar
		rjmp	BalFinDB

NextTenthBal2:	

		cpi		Work2,2								; si on a 2, c'est "0.50"
		brne	NextTenthBal3						; c'est toujours pas ça

		ldi		Char,'5'							; on écrit "50"
		call	DisplayWriteChar
		ldi		Char,'0'
		call	DisplayWriteChar
		rjmp	BalFinDB

NextTenthBal3:										; arrivé ici, c'est sûrement 3, donc il faut écrire "0.75"

		ldi		Char,'7'							; on écrit "50"
		call	DisplayWriteChar
		ldi		Char,'5'
		call	DisplayWriteChar

BalFinDB:											; Termine en écrivant 'dB'

		ldi		Char,'d'
		call	DisplayWriteChar
		ldi		Char,'B'
		call	DisplayWriteChar
		rjmp	ExitAfficheBalance					; Et mission accomplie

; -- Affichage de la valeur centrale de la balance

AfficheBalanceMilieu:

		ldi		Work,0x40
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(BalanceCenterMessage*2)		; Affiche le message correspondant à la balance sur la seconde ligne
		ldi		ZL,LOW(BalanceCenterMessage*2)
		call	DisplayAfficheChaine

ExitAfficheBalance:									; Mais avant de partir, 
													; il faut lancer le Timer 3 pendant 5 secondes pour la persistance rétinienne
		sbrc	StatReg1,FlagMenu					; ...Mais seulement si on n'est pas en mode menu...
		ret

		clr		Work
		sts		TCCR3B,Work							; Arrête le timer 3

		ldi		Work,CinqSecHi
		sts		TCNT3H,Work
		ldi		Work,CinqSecLo
		sts		TCNT3L,Work
		ldi		Work,TimerDiv						; et relance le timer en CK1024
		sts		TCCR3B,Work				

		ret

; ---------------------------------------------------------------------
; -- Fin de l'affichage de la balance car on veut modifier le volume --
; ---------------------------------------------------------------------

AfficheEntreeApresBalance:

		clr		Work
		sts		TCCR3B,Work							; Arrête le timer 3 qui était en train de tourner

		cbr		StatReg1,EXP2(FlagBalance)			; Inactive le flag d'affichage

		call	AfficheEntree						; Affiche l'entrée active

		ret											; et c'est fini

; -----------------------------------------------------------------------------
; -- Fin de l'affichage de la balance car on veut modifier l'entrée courante --
; -----------------------------------------------------------------------------

AfficheVolumeApresBalance:

		clr		Work
		sts		TCCR3B,Work							; Arrête le timer 3 qui était en train de tourner

		cbr		StatReg1,EXP2(FlagBalance)			; Inactive le flag d'affichage

		call	AfficheVolume						; Affiche le volume

		ret											; et c'est fini

; --------------------------------
; -- Afiiche le message de Mute --
; --------------------------------

AfficheMute:

		ldi		ZH,RAM_Start						; Récupère le message
		ldi		ZL,RAM_Mute_M

		call 	DisplayAfficheChaineRAM				; et l'affiche

		ret											; et oualà

; -------------------
; -- Affiche 'XLR' --
; -------------------

WriteXLR:
		ldi		Char,'X'
		rcall	DisplayWriteChar
		ldi		Char,'L'
		rcall	DisplayWriteChar
		ldi		Char,'R'
		rcall	DisplayWriteChar
		ret											; C'est tout

; -------------------
; -- Affiche 'RCA' --
; -------------------

WriteRCA:
		ldi		Char,'R'
		rcall	DisplayWriteChar
		ldi		Char,'C'
		rcall	DisplayWriteChar
		ldi		Char,'A'
		rcall	DisplayWriteChar
		ret											; C'est tout

; -------------------
; -- Affiche 'Yes' --
; -------------------

WriteYes:
		ldi		Char,'Y'
		rcall	DisplayWriteChar
		ldi		Char,'e'
		rcall	DisplayWriteChar
		ldi		Char,'s'
		rcall	DisplayWriteChar
		ret											; C'est tout

; -------------------
; -- Affiche 'No ' --
; -------------------

WriteNo:
		ldi		Char,'N'
		rcall	DisplayWriteChar
		ldi		Char,'o'
		rcall	DisplayWriteChar
		ldi		Char,32
		rcall	DisplayWriteChar
		ret											; C'est tout

; ==================================
; == Affiche "Off" pour le volume ==
; ==================================

AfficheOff:
		ldi		Work,0x49							; Curseur au dixième caractère sur cette même ligne
		call	DisplayPlaceCurseur

		ldi		Char,'O'
		call 	DisplayWriteChar
		ldi		Char,'f'
		call 	DisplayWriteChar
		call 	DisplayWriteChar
		ldi		Char,32
		call 	DisplayWriteChar
		call 	DisplayWriteChar
		call 	DisplayWriteChar
		call 	DisplayWriteChar
		call 	DisplayWriteChar
		call 	DisplayWriteChar

		ret

; ====================================================
; == Affichage du message de sauvegarde des données ==
; ====================================================

AfficheSaving:
		push	Work

		ldi		Work,0								; Message de sauvegarde sur la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSavingMessage*2)
		ldi		ZL,LOW(MenuSavingMessage*2)
		call	DisplayAfficheChaine

		pop		Work

SaveWait:
		call	Attendre
		dec 	Work
		brne	SaveWait

		ret											; et on se barre

; ====================================================
; == Affichage du message de sauvegarde du libellé  ==
; ====================================================

AfficheSavingName:
		push	Work

		ldi		Work,0								; Message de sauvegarde sur la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSaveName*2)
		ldi		ZL,LOW(MenuSaveName*2)
		call	DisplayAfficheChaine

		pop		Work

SaveWaitName:
		call	Attendre
		dec 	Work
		brne	SaveWaitName

		ret											; et on se barre

; ======================================================
; == Affichage du message de sauvegarde d'un message  ==
; ======================================================

AfficheSavingMessage:
		push	Work

		ldi		Work,0								; Message de sauvegarde sur la première ligne
		call	DisplayPlaceCurseur
		ldi		ZH,HIGH(MenuSaveMessage*2)
		ldi		ZL,LOW(MenuSaveMessage*2)
		call	DisplayAfficheChaine

		pop		Work

SaveWaitMess:
		call	Attendre
		dec 	Work
		brne	SaveWaitMess

		ret											; et on se barre

; ===============================
; == Affichage du code IR reçu ==
; ===============================

AfficheIR:

		cpi		Work3,255
		brne	AfficheIRNormal

		ldi		Char,'*'
		call	DisplayWriteChar
		call	DisplayWriteChar
		call	DisplayWriteChar
		ret

AfficheIRNormal:
		cpi		Work3,100
		brge	TestCent

		ldi		Char,' '
		call	DisplayWriteChar
		rjmp	SDC

TestCent:
		cpi		Work3,200
		brlo	Slt200

		ldi		Char,'2'
		call	DisplayWriteChar
		subi	Work3,200
		rjmp	SDC

Slt200:	cpi		Work3,100
		brlo	SDC

		ldi		Char,'1'
		call	DisplayWriteChar
		subi	Work3,100

SDC:	
		mov		LSDVol,Work3
		call	BinaireToBCD

		mov		Char,MSDVol
		call	DisplayWriteChar
		mov		Char,LSDVol
		call	DisplayWriteChar

		ret	

; ===========================================
; == Affichage d'une valeur entre 0 et 255 ==
; == La valeur à afficher est dans Work1   ==
; ===========================================

Affiche255:
		cpi		Work1,200							; C'est plus de 200 ?
		brlo	IsBC100								; 	- Nan, mais c'est plus de 100 ?

		ldi		Char,'2'							; 	- Oui, alors on affiche le "2"
		call	DisplayWriteChar
		subi	Work1,200							; On enlève 200 pour la suite
		rjmp	BCDiz								; à laquelle on va

IsBC100:
		cpi		Work1,100							; C'est moins de 100 ?
		brlo	BCDiz								; 	- Bé oui -> Zyva

		ldi		Char,'1'							; 	- Bénon, alors on écrit "1"
		call	DisplayWriteChar
		subi	Work1,100							; 	  et on enlève la centaine

BCDiz:
		mov 	LSDVol,Work1						; On s'occupe des 2 derniers chiffres
		call	BinaireToBCD
			
		cpi		MSDVol,48							; Le chiffre des dizaines est un 0 ?
		brne	BCWriteDiz							; non -> On l'affiche

		mov		Work1,MenuReg1						; OK, c'est un "0"
		cpi		Work1,100							; mais le chiffre des centaines, c'était un zéro ?
		brlo	BCWriteUnits						; Oui, alors on n'afiiche pas ce zéro non plus

BCWriteDiz:
		mov		Char,MSDVol
		call	DisplayWriteChar

BCWriteUnits:										; et on affiche les unités
		mov		Char,LSDVol
		call	DisplayWriteChar

		ret

