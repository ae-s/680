;; -*- asm -*-

	;; Register naming
esp	EQUR	a4
	;; a5 is pointer to base of opcode jump table
epc	EQUR	a6

	;; d0 is scratch generally used in macros
	;; d1 is scratch generally used outside macros
	;; d2 is scratch and up for grabs
eaf	EQUR	d3
ebc	EQUR	d4
ede	EQUR	d5
ehl	EQUR	d6
eixy	EQUR	d7

SAVEREG	MACRO
	movem.l	d3-d7/a3-a6,-(sp)
	ENDM

RESTREG	MACRO
	movem.l	(sp)+,d3-d7/a3-a6
	ENDM
