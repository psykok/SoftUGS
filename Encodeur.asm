; ***************************************************************
; ***** Décodage d'un encodeur mécanique a quadrature       *****
; ***** Les deux switches de l'encodeur sont sur le port B  *****
; ***** de l'ATmega, sur les 2 premiers bits (7 & 6)        *****
; ***************************************************************
; *** Je ne valide la nouvelle position que   ***
; *** si on a eu 2 fois l'info de changement  ***
; *** dans la même direction                  ***
; ***********************************************

LectureEncodeur:

        in      Work3,PinsEncodeur				; On lit la valeur de l'encodeur
        andi    Work3,MasqueEncodeur            ; et on ne retient que les 2 premiers bits
        cp      Work3,Last                      ; La valeur a-t-elle changé depuis la dernière fois ?
        breq    ExitLectureEncodeur             ; Non, alors on sort...

		call	IRClearIRSup					; Autre action que IR -> Efface le registre de speedup

		ldi		Count2,255						; Une petite attente
WaitES1:dec		Count2							; avant de retester l'encodeur
		brne	WaitES1							; pour éliminer les rebonds 

        in      Work2,PinsEncodeur              ; On relit la valeur de l'encodeur
        andi    Work2,MasqueEncodeur            ; et on ne retient que les 2 premiers bits
        cp      Work2,Last                      ; La valeur a-t-elle changé depuis la dernière fois ?
        breq    ExitLectureEncodeur             ; Non, alors on sort...
        cp      Work2,Work3                     ; La valeur a-t-elle changé depuis la lecture précédente
        brne    ExitLectureEncodeur             ; Oui, c'est donc qu'on a eu un rebond, et alors on sort..

; -- La valeur a vraiment changé --

		mov		Work,Last						; Copie l'ancienne position de l'encodeur dans un registre immédiat
		mov		Work1,Work2						; Copie la nouvelle position dans un autre registre pour la préserver

		lsr		Work1							; on se décale de 2 bits vers la droite
		lsr		Work1							; pour former la première partie du nibble

		add     Work,Work1                      ; On concatène les deux groupes de 2 bits pour obtenir un nibble

		swap	Work							; Swappe les nibbles de Work (seul le nibble de poids faible nous intéresse)

		mov		Last,Work2						; On stocke la nouvelle valeur de l'encodeur dans le registre Last

; -- Pour savoir ce qu'on fait ensuite, on convertit le nibble a l'aide de la RAM        

		ldi		ZH,RAM_Encodeur_H				; Adresse haute de la table de décodage
		mov		ZL,Work							; On charge "l'adresse" pour la RAM (entre 0 et 15)
		ld		Work,Z							; et on lit la valeur décodée dans la RAM

		ldi		ZH,RAM_Start					; Octet de poids fort de l'adresse de début en RAM 
		ldi		ZL,RAM_EncoderStep				; L'adresse du paramètre d'encodeur en RAM
        ld 	    Work2,Z			              	; On mémorise le pas de travail de l'encodeur
        
        cbr     StatReg1,EXP2(FlagDecremente)   ; Rien à faire pour l'instant
        cbr     StatReg1,EXP2(FlagIncremente)   ; On remet donc les Flags à zéro
        
        cpi     Work,2                          ; Décrémenter ?
        breq    Decrementation                  ; Décrémente
        
        cpi     Work,1                          ; Incrémenter ?
        breq    Incrementation                  ; Incrémente
        
; -- Si on arrive là, on a eu une erreur de lecture de l'encodeur, alors on remet tout à zéro et on s'en va

        clr		T_Inc							; Efface les registres temporaires
		clr		T_Dec							; 
		rjmp    ExitLectureEncodeur
      
; -- Décrémentation de la position --

Decrementation:
        inc     T_Dec                           ; Incrémente le registre temporaire  
		cp      T_Dec,Work2                     ; On est arrivé ?
		brne    ExitLectureEncodeur             ; Non --> on sort

		clr     T_Dec                           ; Oui, on est à zéro et on réinitialise le registre temporaire
        sbr     StatReg1,EXP2(FlagDecremente)   ; On signale qu'il s'agit réellement d'une décrémentation
        rjmp    ExitLectureEncodeur             ; et on s'en va
                
; -- Incrémentation de la position -- 

Incrementation:
        inc     T_Inc                           ; Incrémente le registre temporaire
		cp      T_Inc,Work2                     ; On est arrivé ?
		brne    ExitLectureEncodeur             ; Non -> On sort

		clr     T_Inc                           ; Oui, on est à zéro et on réinitialise le registre temporaire
        sbr     StatReg1,EXP2(FlagIncremente)   ; On signale qu'il s'agit réellement d'une incrémentation
                
ExitLectureEncodeur:
        ret                                     ; On sort de la routine

; ===========================================================
; == Mise en mémoire de la position initiale de l'encodeur ==
; ===========================================================

InitEncodeur:

        in      Work3,PinsEncodeur				; On lit la valeur de l'encodeur
        andi    Work3,MasqueEncodeur            ; et on ne retient que les 2 premiers bits

		mov		Last,Work3						; Mémorise la valeur

		clr		T_Dec							; initialisation des registres temporaires
		clr		T_Inc

		ret										; et voilou
		
