|| -*- gas -*-

	|| Register naming
.equiv	esp,	a4
	|| a5 is pointer to base of opcode jump table
.equiv	epc,	a6

	|| d0 is scratch generally used in macros
	|| d1 is scratch generally used outside macros
	|| d2 is scratch and up for grabs
.equiv	eaf,	d3
.equiv	ebc,	d4
.equiv	ede,	d5
.equiv	ehl,	d6
.equiv	eixy,	d7

.macro	SAVEREG
	movem.l	d3-d7/a3-a6,-(sp)
.endm

.macro	RESTREG
	movem.l	(sp)+,d3-d7/a3-a6
.endm

	|| Size of the ‘jmp	do_interrupt’ in every invocation of
	|| START.
.set	INT_OFFSET,	4
