;; -*- asm -*-

	;; Register naming
esp	EQUR	a4
epc	EQUR	a6
	
eaf	EQUR	d3
ebc	EQUR	d4
ede	EQUR	d5
ehl	EQUR	d6
eixy	EQUR	d7

SAVEREG	MACRO
	movem	d3-d7/a3-a6,-(sp)
	ENDM

RESTREG	MACRO
	movem	(sp)+,d3-d7/a3-a6
	ENDM

;; pushm	MACRO
;; 	movem	\1,-(sp)
;; 	ENDM

;; popm	MACRO
;; 	movem	(sp)+,\1
;; 	ENDM

;; push	MACRO
;; 	move.\0	\1,-(sp)
;; 	ENDM

;; pop	MACRO
;; 	move.\0	(sp)+,\1
;; 	ENDM
