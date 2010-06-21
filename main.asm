;;; z80 emulator for 68k calculators

;;; Astrid Smith
;;; Project started: 2010-06-06
;;; GPL

;;; Yes, I use lots of big ascii art.  With this much code, you need
;;; something to catch your eye when scrolling through it.  I suppose
;;; I'll split it into different files later.

;;; Registers used:
;;;
;;; A7 = sp
;;; A6 = emulated PC XXX
;;; A5 = instruction table base pointer
;;; A4 = emulated SP XXX
;;; A3 = pointer to flag_storage
;;; A2 =
;;; A1 =
;;; A0 =
;;;
;;; D0 = current instruction, scratch for macros
;;; D1 = scratch for instructions
;;; D2 = undefined
;;;
;;;
;;; The following have their shadows in the top half of the register
;;; D3 = AF	A is in the low byte, F in the high byte (yeah ... speed)
;;; D4 = BC	B high, C low
;;; D5 = DE	D high, E low
;;; D6 = HL	H high, L low
;;;
;;; IY is used more often so it's easier to get at.  It can be slow
;;; but I don't really care to go to the effort to make it so.
;;; D7 = IX (hi), IY (low)

;;; Assemble with the following flags:
;;; a68k -l -n -g -t main.asm
;;; -n is important, it disables optimizations


;;; emulated I and R are both in RAM

	xdef	_ti89
;	xdef	_ti92plus
	xdef	__main
	xdef	_tigcc_native
	include "../tios.h"

	;; == Memory Macros ================================================

	;; Macro to read a byte from main memory at register \1.  Puts
	;; the byte read in \2.
FETCHB	MACRO
	move.w	\1,d1
	bsr	deref
	move.b	(a0),\2
	ENDM

	;; Macro to write a byte in \1 to main memory at \2
PUTB	MACRO
	move.w	\2,d1
	bsr	deref
	move.b	\1,(a0)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
	;;
	;; <debrouxl> It decrements sp by 2, but stores the result at
	;; sp, not at 1(sp). So you essentially get a "free" shift
	;; left by 8 bits. Much faster than lsl.w / rol.w #8, at
	;; least.
FETCHW	MACRO			;  ?/16
	move.w	\1,d1		;  4/2
	bsr	deref		;  ?/4
	move.b	(a0),-(sp)	; 18/4
	move.w	(sp)+,\2	;  8/2
	move.b	(a0),\2		; 14/4
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
PUTW	MACRO			; 
	move.w	\2,d1
	bsr	deref
	move.w	\1,d0
	move.b	d0,(a0)+
	LOHI	d0
	move.b	d0,(a0)
	ENDM

	;; Push the word in \1 (register) using stack register a4.
	;; Sadly, I can't trust the stack register to be aligned.
	;; Destroys d0.

	;;   (SP-2) <- \1_l
	;;   (SP-1) <- \1_h
	;;   SP <- SP - 2
PUSHW	MACRO
	move.w	\1,d0
	LOHI	d0		;slow
	move.b	d0,-(a4)	; high byte
	move.b	\1,-(a4)	; low byte
	ENDM

	;; Pop the word at the top of stack a4 into \1.
	;; Destroys d0.

	;;   \1_h <- (SP+1)
	;;   \1_l <- (SP)
	;;   SP <- SP + 2
POPW	MACRO
	move.b	(a4)+,\1
	LOHI	\1		;slow
	move.b	(a4)+,\1	; high byte
	HILO	\1		;slow
	ENDM

	;; == Immediate Memory Macros ==

	;; Macro to read an immediate byte into \1.
FETCHBI	MACRO			; 8 cycles, 2 bytes
	move.b	(a6)+,\1	; 8/2
	ENDM

	;; Macro to read an immediate word (unaligned) into \1.
FETCHWI	MACRO			; 28 cycles, 6 bytes
	;; See FETCHW for an explanation of this trick.
	move.b	(a6)+,-(sp)	; 12/2
	move.w	(sp)+,\1	;  8/2
	move.b	(a6)+,\1	;  8/2
	ENDM			; 28/6

	;; == Common Opcode Macros =========================================

	;; To align subroutines.
_align	SET	0

START	MACRO
	ORG	emu_plain_op+_align
_align	SET	_align+$20
	ENDM

	;; LOHI/HILO are hideously slow for instructions used often.
	;; Interleave registers instead:
	;;
	;; d4 = [B' B  C' C]
	;;
	;; Thus access to B is fast (swap d4) while access to BC is
	;; slow.

	;; When you want to use the high reg of a pair, use this first
LOHI	MACRO			; 22 cycles, 2 bytes
	ror.w	#8,\1		; 22/2
	ENDM

	;; Then do your shit and finish with this
HILO	MACRO			; 22 cycles, 2 bytes
	rol.w	#8,\1
	ENDM

	;; Rearrange a register: ABCD -> ACBD.
WORD	MACRO
	move.l	\1,-(a7)	;12 cycles / 2 bytes
	movep.w	0(a7),\1	;16 cycles / 4 bytes
	swap	\1		; 4 cycles / 2 bytes
	movep.w	1(a7),\1	;16 cycles / 4 bytes
	addq	#4,a7		; 4 cycles / 2 bytes
	;; overhead:		 52 cycles /14 bytes
	ENDM


	;; This is run at the end of every instruction routine.
DONE	MACRO
	clr.w	d0		; 4 cycles / 2 bytes
	move.b	(a4)+,d0	; 8 cycles / 2 bytes
	rol.w	#5,d0		;16 cycles / 2 bytes
	jmp	0(a5,d0.w)	;14 cycles / 4 bytes
	;; overhead:		 42 cycles /10 bytes
	ENDM

	;; == Special Opcode Macros ========================================

	;; Do an ADD \1,\2
F_ADD_W	MACRO
	ENDM
	;; Do an SUB \1,\2
F_SUB_W	MACRO
	ENDM

	;; INC and DEC macros
F_INC_B	MACRO
	move.b	#1,f_tmp_byte-flag_storage(a3)
	move.b	#1,f_tmp_src_b-flag_storage(a3)
	move.b	\1,f_tmp_dst_b-flag_storage(a3)
	addq	#1,\1
	moveq	#2,d0
	F_CLEAR	d0
	F_OVFL
	ENDM

F_DEC_B	MACRO
	move.b	#1,f_tmp_byte-flag_storage(a3)
	st	f_tmp_src_b-flag_storage(a3)
	move.b	\1,f_tmp_dst_b-flag_storage(a3)
	subq	#1,\1
	F_SET	#2
	ENDM

F_INC_W	MACRO
	addq.w	#1,\1
	ENDM

F_DEC_W	MACRO
	subq.w	#1,\1
	ENDM

	;; I might be able to unify rotation flags or maybe use a
	;; lookup table



__main:
	movem.l d0-d7/a0-a6,-(sp)
	bsr	emu_setup
	bsr	emu_run
	movem.l (sp)+,d0-d7/a0-a6
	rts

	include	"ports.asm"
	include "interrupts.asm"
	include	"flags.asm"

emu_setup:
	movea	emu_plain_op,a5
	lea	emu_run(pc),a2

	;; Allocate memory pages; for now I assume this succeeds
	move.l	#$4000,-(a7)
	ROM_CALL	malloc
	move.l	a0,ref_0

	move.l	#$4000,-(a7)
	ROM_CALL	malloc
	move.l	a0,ref_1

	move.l	#$4000,-(a7)
	ROM_CALL	malloc
	move.l	a0,ref_2

	move.l	#$4000,-(a7)
	ROM_CALL	malloc
	move.l	a0,ref_3

	rts


;; ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;;  _ __ ___   ___ _ __ ___   ___  _ __ _   _   |||||||||||||||||||||||||||
;; | '_ ` _ \ / _ \ '_ ` _ \ / _ \| '__| | | |  \\\\\\\\\\\\\\\\\\\\\\\\\\\
;; | | | | | |  __/ | | | | | (_) | |  | |_| |  |||||||||||||||||||||||||||
;; |_| |_| |_|\___|_| |_| |_|\___/|_|   \__, |  ///////////////////////////
;; of the virtual type                  |___/   |||||||||||||||||||||||||||
;; =============================================JJJJJJJJJJJJJJJJJJJJJJJJJJJ

	;; Take a virtual address in d1 and dereference it.  Returns the
	;; host address in a0.  Destroys a0, d0.
deref:
	move.w	d1,d0
	andi.w	#$3FFF,d0
	movea.w	d0,a0
	move.w	d1,d0
	andi.w	#$C000,d0	; Can cut this out by pre-masking the table.
	rol.w	#2,d0
	adda.l	deref_table(pc,d0.w),a0
	rts

deref_table:
ref_0:	dc.l	0		; bank 0
ref_1:	dc.l	0		; bank 1
ref_2:	dc.l	0		; bank 2
ref_3:	dc.l	0		; bank 3

	;; Take a physical address in a0 and turn it into a virtual
	;; address in d0
	;; Destroys d0
; XXX AFAICS, a1 is currently a scratch address register, so you can load deref_table in it, and then save some space:
; But you may wish to use it for other purposes in the future, so you needn't integrate that immediately.
underef:
	lea	deref_table(pc),a1
	move.l	a0,d0
	sub.l	(a1)+,d0
	bmi.s	underef_not0
	cmpi.l	#$4000,d0
	bmi.s	underef_thatsit
underef_not0:
	move.l	a0,d0
	sub.l	(a1)+,d0
	bmi.s	underef_not1
	cmpi.l	#$4000,d0
	bmi.s	underef_thatsit
underef_not1:
	move.l	a0,d0
	sub.l	(a1)+,d0
	bmi.s	underef_not2
	cmpi.l	#$4000,d0
	bmi.s	underef_thatsit
underef_not2:
	suba.l	(a1)+,a0
	;; if that fails too, well shit man!
underef_thatsit:
	rts


;; =========================================================================
;; instruction   instruction   instruction  ================================
;;      _ _                 _       _       ================================
;;   __| (_)___ _ __   __ _| |_ ___| |__    ================================
;;  / _` | / __| '_ \ / _` | __/ __| '_ \   ================================
;; | (_| | \__ \ |_) | (_| | || (__| | | |  ================================
;;  \__,_|_|___/ .__/ \__,_|\__\___|_| |_|  ================================
;;             |_|                         =================================
;; ==========       ========================================================
;; =========================================================================

emu_run:
	;; XXX: make this actually return
	DONE
	rts

	include "opcodes.asm"


emu_op_undo_cb:
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:
	rts

