
SAVEREG	MACRO
	movem	d3-d7/a3-a6,-(sp)
	ENDM

RESTREG	MACRO
	movem	(sp)+,d3-d7/a3-a6
	ENDM
