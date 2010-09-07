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
