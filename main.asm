;;; z80 emulator for 68k calculators

;;; Duncan Smith
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

	include "opcodes.asm"

emu_run:
	;; XXX: make this actually return
	DONE
	rts

emu_op_undo_cb:
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:
	rts

