|| -*- gas -*-

|| ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||  _ __ ___   ___ _ __ ___   ___  _ __ _   _   |||||||||||||||||||||||||||
|| | '_ ` _ \ / _ \ '_ ` _ \ / _ \| '__| | | |  \\\\\\\\\\\\\\\\\\\\\\\\\\\
|| | | | | | |  __/ | | | | | (_) | |  | |_| |  |||||||||||||||||||||||||||
|| |_| |_| |_|\___|_| |_| |_|\___/|_|   \__, |  ///////////////////////////
|| of the virtual type                  |___/   |||||||||||||||||||||||||||
|| =============================================JJJJJJJJJJJJJJJJJJJJJJJJJJJ

	|| Take a virtual address in d1 and dereference it.  Returns the
	|| host address in a0.  Destroys a0, d0.
deref:	| 76 cycles + 18 cycles for bsr
	| 20 bytes to inline, saves 34 cycles per call
	move.w	d1,d0
	andi.w	#0x3FFF,d0
	movea.w	d0,a0
	move.w	d1,d0
	andi.w	#0xC000,d0	| Can cut this out by pre-masking the table.
	rol.w	#4,d0
	adda.l	deref_table(pc,d0.w),a0	| TODO gas doesn't like this
	rts

.even
.bss
deref_table:
mem_page_0:	.long	0		| bank 0 / 0x0000
mem_page_1:	.long	0		| bank 1 / 0x4000
mem_page_2:	.long	0		| bank 2 / 0x8000
mem_page_3:	.long	0		| bank 3 / 0xc000

.xdef	mem_page_0
.xdef	mem_page_1
.xdef	mem_page_2
.xdef	mem_page_3

mem_page_loc_0:	.byte	0
mem_page_loc_1:	.byte	0
mem_page_loc_2:	.byte	0
mem_page_loc_3:	.byte	0

.xdef	mem_page_loc_0
.xdef	mem_page_loc_1
.xdef	mem_page_loc_2
.xdef	mem_page_loc_3

pages:	.long	0

.xdef pages

.text

	|| Take a physical address in a0 and turn it into a virtual
	|| address in d0
	|| Destroys d0, a1
| XXX AFAICS, a1 is currently a scratch address register, so you can load deref_table in it, and then save some space:
| But you may wish to use it for other purposes in the future, so you needn't integrate that immediately.

	|| Guessing this is 300 cycles.
underef:
	move.l	d2,-(a7)
	lea	deref_table(pc),a1
	move.l	a0,d0
	clr.w	d2
	sub.l	(a1)+,d0
	bmi.s	underef_not0
	cmpi.l	#0x4000,d0
	bmi.s	underef_thatsit
underef_not0:
	move.l	a0,d0
	move.w	#0x4000,d2
	sub.l	(a1)+,d0
	bmi.s	underef_not1
	cmpi.l	#0x4000,d0
	bmi.s	underef_thatsit
underef_not1:
	move.l	a0,d0
	move.w	#0x8000,d2
	sub.l	(a1)+,d0
	bmi.s	underef_not2
	cmpi.l	#0x4000,d0
	bmi.s	underef_thatsit
underef_not2:
	move.w	#0xc000,d2
	suba.l	(a1)+,a0
	|| if that fails too, well shit man!
	moveq	#0,d0
underef_thatsit:
	add.w	d2,d0
	move.l	(a7)+,d2
	rts
