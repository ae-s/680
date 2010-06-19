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
;;;
;;; D2 = emulated SP, PC	SP high, PC low - both virtual addresses
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
	xdef	_main
	xdef	_nostub
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
	move.b	d0,-1(a4)	; high byte
	move.b	\1,-2(a4)	; low byte
	subq	#2,a4
	ENDM

	;; Pop the word at the top of stack a4 into \1.
	;; Destroys d0.

	;;   \1_h <- (SP+1)
	;;   \1_l <- (SP)
	;;   SP <- SP + 2
POPW	MACRO
	move.b	(a4),\1
	LOHI	\1		;slow
	move.b	(a4),\1		; high byte
	HILO	\1		;slow
	addq.w	#2,a4
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


	;; calc84maniac suggests putting emu_fetch into this in order
	;; to save 8 cycles per instruction, at the expense of code
	;; size
	;;
	;; See if I can get rid of the eor
DONE	MACRO
	clr.w	d0		; 4 cycles
	move.b	(a4)+,d0	; 8 cycles
	rol.w	#5,d0		;16 cycles
	jmp	0(a5,d0)	;14 cycles
	;; overhead:		 42 cycles
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
	move.b	#-1,f_tmp_src_b-flag_storage(a3)
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

;;; one-off flag operations:
;;; CCF - invert CARRY
;;; CPL - H,N=1
;;; RLD
;;; 






_main:
	bsr	emu_setup
	rts

	include	"ports.asm"
	include "interrupts.asm"
	include	"flags.asm"

emu_setup:
	movea	emu_plain_op,a5
	lea	emu_fetch(pc),a2
	;; XXX finish
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
	adda.l	deref_table(pc,d0),a0
	rts

deref_table:
ref_0:	dc.l	0		; bank 0
ref_1:	dc.l	0		; bank 1
ref_2:	dc.l	0		; bank 2
ref_3:	dc.l	0		; bank 3

	;; Take a physical address in a0 and turn it into a virtual
	;; address in d0
	;; Destroys d0
underef:
	move.l	a0,d0
	sub.l	ref_0(pc,d0),d0
	bmi	underef_not0
	cmpi.l	#$4000,d0
	bmi	underef_thatsit
underef_not0:
	move.l	a0,d0
	sub.l	ref_1(pc,d0),d0
	bmi	underef_not1
	cmpi.l	#$4000,d0
	bmi	underef_thatsit
underef_not1:
	move.l	a0,d0
	sub.l	ref_2(pc,d0),d0
	bmi	underef_not2
	cmpi.l	#$4000,d0
	bmi	underef_thatsit
underef_not2:
	move.l	a0,d0
	sub.l	ref_3(pc,d0),d0
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

emu_fetch:
	;; Move this into DONE, saving 8 more cycles but using extra
	;; space.
	;;
	;; Likely impossible to get rid of the clr
	clr.w	d0		;  4 cycles
	move.b	(a4)+,d0	;  8 cycles
	rol.w	#5,d0		; 16 cycles   adjust to actual alignment
	jmp	0(a5,d0.w)	; 14 cycles
	;; overhead:		  42 cycles

;;; ========================================================================
;;; ========================================================================
;;;      ___   ___                    ======= ==============================
;;;  ___( _ ) / _ \   emulation core    ====================================
;;; |_  / _ \| | | |  emulation core     ===================================
;;;  / ( (_) | |_| |  emulation core      ==================================
;;; /___\___/ \___/   emulation core       =================================
;;;                                   ======= ==============================
;;; ========================================================================
;;; ========================================================================

;;; http://z80.info/z80oplist.txt

	CNOP	0,32

emu_plain_op:			; Size(bytes) Time(cycles)
	START
emu_op_00:			; S0 T0
	;; NOP
	DONE

	START
emu_op_01:			; S12 T36
	;; LD	BC,immed.w
	;; Read a word and put it in BC
	;; No flags
	FETCHWI	d4
	DONE

	START
emu_op_02:			; S4 T14
	;; LD	(BC),A
	;; No flags
	FETCHB	d4,d3
	DONE

	START
emu_op_03:			; S2 T4
	;; INC	BC
	;; BC <- BC+1
	;; No flags
	F_INC_W	d4
	DONE

	START
emu_op_04:
	;; INC	B
	;; B <- B+1
	LOHI	d4
	F_INC_B	d4
	HILO	d4
	DONE

	START
emu_op_05:
	;; DEC	B
	;; B <- B-1
	LOHI	d4
	F_DEC_B	d4
	HILO	d4
	DONE

	START
emu_op_06:			; S10 T26
	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; No flags
	LOHI	d4
	FETCHBI	d4
	HILO	d4
	DONE

	START
emu_op_07:			; S2 T4
	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX flags
	rol.b	#1,d3
	DONE

	START
emu_op_08:			; S2 T4
	;; EX	AF,AF'
	;; No flags
	swap	d3
	DONE

	START
emu_op_09:
	;; ADD	HL,BC
	;; HL <- HL+BC
	;; Flags: H, C aff.; N=0
	F_ADD_W	d4,d6
	DONE

	START
emu_op_0a:			; S4 T14
	;; LD	A,(BC)
	;; A <- (BC)
	;; No flags
	FETCHB	d4,d3
	DONE

	START
emu_op_0b:			; S2 T4
	;; DEC	BC
	;; BC <- BC-1
	;; No flags
	F_DEC_W	d4
	DONE

	START
emu_op_0c:
	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
	F_INC_B	d4
	DONE

	START
emu_op_0d:
	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
	F_DEC_B	d4
	DONE

	START
emu_op_0e:			; S6 T18
	;; LD	C,immed.b
	;; No flags
	FETCHBI	d4
	DONE

	START
emu_op_0f:
	;; RRCA
	;; Rotate A right, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
	ror.b	#1,d3
	DONE

	START
emu_op_10:			; S32
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	LOHI	d4
	subq.b	#1,d4
	beq	end_10	; slooooow
	FETCHBI	d1
	move	a6,a0
	bsr	underef
	add.w	d1,d0		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move	a0,a6
end_10:
	HILO	d4
	DONE

	START
emu_op_11:			; S
	;; LD	DE,immed.w
	;; No flags
	FETCHWI	d5
	DONE

	START
emu_op_12:
	;; LD	(DE),A
	;; No flags
	FETCHB	d5,d3
	DONE

	START
emu_op_13:
	;; INC	DE
	;; No flags
	F_INC_W	d5
	DONE

	START
emu_op_14:
	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
	LOHI	d5
	F_INC_B	d5
	HILO	d5
	DONE

	START
emu_op_15:
	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d5
	F_DEC_B	d5
	HILO	d5
	DONE

	START
emu_op_16:
	;; LD D,immed.b
	;; No flags
	LOHI	d5
	FETCHBI	d5
	HILO	d5
	DONE

	START
emu_op_17:
	;; RLA
	;; Flags: P,N=0; C aff.
	;; XXX flags
	roxl.b	#1,d3
	DONE

	START
emu_op_18:
	;; JR
	;; Branch relative by a signed immediate byte
	;; No flags
	FETCHBI	d1
	move	a6,a0
	bsr	underef
	add.w	d1,d0		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_19:
	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
	F_ADD_W	d5,d6
	DONE

	START
emu_op_1a:
	;; LD	A,(DE)
	;; A <- (DE)
	;; No flags
	FETCHB	d5,d3
	DONE

	START
emu_op_1b:
	;; DEC	DE
	;; No flags
	subq.w	#1,d5
	DONE

	START
emu_op_1c:
	;; INC	E
	;; Flags: S,Z,H aff.; P=overflow; N=0
	F_INC_B	d5
	DONE

	START
emu_op_1d:
	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
	F_DEC_B	d5
	DONE

	START
emu_op_1e:
	;; LD	E,immed.b
	;; No flags
	FETCHBI	d5
	DONE

	START
emu_op_1f:
	;; RRA
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
	roxr.b	#1,d3
	DONE

	START
emu_op_20:
	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	beq	end_20
	FETCHBI	d1
	add.w	d1,a6		; XXX deref?
end_20:
	DONE

	START
emu_op_21:
	;; LD	HL,immed.w
	;; No flags
	FETCHWI	d6
	DONE

	START
emu_op_22:
	;; LD	immed.w,HL
	;; (address) <- HL
	;; No flags
	FETCHWI	d1
	PUTW	d6,d1
	DONE

	START
emu_op_23:
	;; INC	HL
	;; No flags
	addq.w	#1,d6
	DONE

	START
emu_op_24:
	;; INC	H
	;; Flags: S,Z,H aff.; P=overflow, N=0
	LOHI	d6
	F_INC_B	d6
	HILO	d6
	DONE

	START
emu_op_25:
	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d6
	F_DEC_B	d6
	HILO	d6
	DONE

	START
emu_op_26:
	;; LD	H,immed.b
	;; No flags
	LOHI	d6
	FETCHBI	d6
	HILO	d6
	DONE

	START
emu_op_27:
	;; DAA
	;; Decrement, adjust accum
	;; http://www.z80.info/z80syntx.htm#DAA
	;; Flags: oh lord they're fucked up
	;; XXX DO THIS

	F_PAR	d3
	DONE

	START
emu_op_28:
	;; JR Z,immed.b
	;; If zero
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	bsr	f_norm_z
	bne	emu_op_18
	DONE

	START
emu_op_29:
	;; ADD	HL,HL
	;; No flags
	F_ADD_W	d6,d6
	DONE

	START
emu_op_2a:
	;; LD	HL,(immed.w)
	;; address is absolute
	FETCHWI	d1
	FETCHW	d1,d6
	DONE

	START
emu_op_2b:
	;; DEC	HL
	F_DEC_W	d6
	DONE

	START
emu_op_2c:
	;; INC	L
	F_INC_B	d6
	DONE

	START
emu_op_2d:
	;; DEC	L
	F_DEC_B	d6
	DONE

	START
emu_op_2e:
	;; LD	L,immed.b
	FETCHBI	d6
	DONE

	START
emu_op_2f:
	;; CPL
	;; A <- NOT A
	;; XXX flags
	not.b	d3
	DONE

	START
emu_op_30:
	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
	bsr	f_norm_c
	beq	emu_op_18	; branch taken: carry clear
	DONE

	START
emu_op_31:
	;; LD	SP,immed.w
	FETCHWI	d1
	bsr	deref
	movea	a0,a4
	DONE

	START
emu_op_32:
	;; LD	(immed.w),A
	;; store indirect
	FETCHWI	d1
	PUTB	d3,d1
	DONE

	START
emu_op_33:
	;; INC	SP
	;; No flags
	;;
	;; FYI:  Do not have to deref because this will never cross a
	;; page boundary.  So sayeth BrandonW.
	addq.w	#1,a4
	DONE

	START
emu_op_34:
	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
	FETCHB	d6,d1
	F_INC_B	d1
	PUTB	d1,d6
	DONE

	START
emu_op_35:
	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
	FETCHB	d6,d1
	F_DEC_B	d1
	PUTB	d1,d6
	DONE

	START
emu_op_36:
	;; LD	(HL),immed.b
	FETCHBI	d1
	PUTB	d6,d1
	DONE

	START
emu_op_37:
	;; SCF
	;; Set Carry Flag
	move.b	#%00111011,flag_valid-flag_storage(a3)
	move.b	#%00111011,17(a3)
	move.b	d3,d1
	ori.b	#%00000001,d1
	andi.b	#%00101001,d1
;	or.b	d1,flag_byte(a3)
	or.b	d1,16(a3)
	DONE

	START
emu_op_38:
	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
	bsr	f_norm_c
	bne	emu_op_18
	DONE

	START
emu_op_39:
	;; ADD	HL,SP
	;; HL <- HL+SP
	move	a4,a0
	bsr	underef
	F_ADD_W	d6,d0		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move	a0,a4
	DONE

	START
emu_op_3a:
	;; LD	A,(immed.w)
	FETCHWI	d1
	FETCHB	d1,d3
	DONE

	START
emu_op_3b:
	;; DEC	SP
	;; No flags
	subq.l	#1,a4
	DONE

	START
emu_op_3c:
	;; INC	A
	F_INC_B	d3
	DONE

	START
emu_op_3d:
	;; DEC	A
	F_DEC_B	d3
	DONE

	START
emu_op_3e:
	;; LD	A,immed.b
	FETCHBI	d3
	DONE

	START
emu_op_3f:
	;; CCF
	;; Toggle carry flag
	bsr	flags_normalize
	;; 	  SZ5H3PNC
;	eor.b	#%00010001,flag_byte-flag_storage(a3)
	eor.b	#%00010001,16(a3)
	DONE

	START
emu_op_40:
	;; LD	B,B
	;; SPEED
	LOHI	d4
	move.b	d4,d4
	HILO	d4
	DONE

	START
emu_op_41:
	;; LD	B,C
	;; SPEED
	move.b	d4,d1
	LOHI	d4
	move.b	d1,d4
	HILO	d4
	DONE

	START
emu_op_42:
	;; LD	B,D
	;; B <- D
	;; SPEED
	LOHI	d4
	LOHI	d5
	move.b	d5,d4
	HILO	d4
	HILO	d5
	DONE

	START
emu_op_43:
	;; LD	B,E
	;; B <- E
	LOHI	d4
	move.b	d4,d5		; 4
	HILO	d4
	DONE

	START
emu_op_44:
	;; LD	B,H
	;; B <- H
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

	START
emu_op_45:
	;; LD	B,L
	;; B <- L
	LOHI	d4
	move.b	d6,d4
	HILO	d4
	DONE

	START
emu_op_46:
	;; LD	B,(HL)
	;; B <- (HL)
	LOHI	d4
	FETCHB	d6,d4
	HILO	d4
	DONE

	START
emu_op_47:
	;; LD	B,A
	;; B <- A
	LOHI	d4
	move.b	d3,d4
	HILO	d4
	DONE

	START
emu_op_48:
	;; LD	C,B
	;; C <- B
	move.w	d4,d1		; 4
	lsr.w	#8,d1		; 6
	move.b	d1,d4		; 4
	DONE
				;14 cycles
	START
emu_op_49:
	;; LD	C,C
	DONE

	START
emu_op_4a:
	;; LD	C,D
	move.w	d5,d1
	lsr.w	#8,d1
	move.b	d1,d4
	DONE

	START
emu_op_4b:
	;; LD	C,E
	move.b	d4,d5
	DONE

	START
emu_op_4c:
	;; LD	C,H
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

	START
emu_op_4d:
	;; LD	C,L
	move.b	d4,d6
	DONE

	START
emu_op_4e:
	;; LD	C,(HL)
	;; C <- (HL)
	FETCHB	d6,d4
	DONE

	START
emu_op_4f:
	;; LD	C,A
	move.b	d3,d4
	DONE

	START
emu_op_50:
	;; LD	D,B
	LOHI	d4
	LOHI	d5
	move.b	d4,d5
	HILO	d4
	HILO	d5
	DONE

	START
emu_op_51:
	;; LD	D,C
	LOHI	d5
	move.b	d4,d5
	HILO	d5
	DONE

	START
emu_op_52:
	;; LD	D,D
	DONE

	START
emu_op_53:
	;; LD	D,E
	andi.w	#$00ff,d5
	move.b	d5,d1
	lsl	#8,d1
	or.w	d1,d5
	DONE

	START
emu_op_54:
	;; LD	D,H
	LOHI	d5		; 4
	LOHI	d6		; 4
	move.b	d6,d5		; 4
	HILO	d5		; 4
	HILO	d6		; 4
	DONE
				;20 cycles

	START
emu_op_55:
	;; LD	D,L
	LOHI	d5
	move.b	d6,d5
	HILO	d5
	DONE

	START
emu_op_56:
	;; LD	D,(HL)
	;; D <- (HL)
	LOHI	d5
	FETCHB	d6,d5
	HILO	d5
	DONE

	START
emu_op_57:
	;; LD	D,A
	LOHI	d5
	move.b	d3,d5
	HILO	d5
	DONE

	START
emu_op_58:
	;; LD	E,B
	LOHI	d4
	move.b	d4,d5
	HILO	d4
	DONE

	START
emu_op_59:
	;; LD	E,C
	move.b	d4,d5
	DONE

	START
emu_op_5a:
	;; LD	E,D
	andi.w	#$ff00,d5	; 8/4
	move.b	d5,d1		; 4/2
	lsr	#8,d1		;22/2
	or.w	d1,d5		; 4/2
	DONE
				;38/2

	START
emu_op_5b:
	;; LD	E,E
	DONE

	START
emu_op_5c:
	;; LD	E,H
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

	START
emu_op_5d:
	;; LD	E,L
	move.b	d5,d6
	DONE

	START
emu_op_5e:
	;; LD	E,(HL)
	FETCHB	d6,d1
	DONE

	START
emu_op_5f:
	;; LD	E,A
	move.b	d5,d3
	DONE

	START
emu_op_60:
	;; LD	H,B
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

	START
emu_op_61:
	;; LD	H,C
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

	START
emu_op_62:
	;; LD	H,D
	LOHI	d5
	LOHI	d6
	move.b	d5,d6
	HILO	d5
	HILO	d6
	DONE

	START
emu_op_63:
	;; LD	H,E
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

	START
emu_op_64:
	;; LD	H,H
	DONE

	START
emu_op_65:
	;; LD	H,L
	;; H <- L
	move.b	d6,d1
	LOHI	d6
	move.b	d1,d6
	HILO	d6
	DONE

	START
emu_op_66:
	;; LD	H,(HL)
	FETCHB	d6,d1
	LOHI	d6
	move.b	d1,d6
	HILO	d6
	DONE

	START
emu_op_67:
	;; LD	H,A
	LOHI	d6
	move.b	d3,d6
	HILO	d6
	DONE

	START
emu_op_68:
	;; LD	L,B
	LOHI	d4
	move.b	d4,d6
	HILO	d4
	DONE

	START
emu_op_69:
	;; LD	L,C
	move.b	d4,d6
	DONE

	START
emu_op_6a:
	;; LD	L,D
	LOHI	d5
	move.b	d5,d6
	HILO	d5
	DONE

	START
emu_op_6b:
	;; LD	L,E
	move.b	d5,d6
	DONE

	START
emu_op_6c:
	;; LD	L,H
	LOHI	d6
	move.b	d6,d1
	HILO	d6
	move.b	d1,d6
	DONE

	START
emu_op_6d:
	;; LD	L,L
	DONE

	START
emu_op_6e:
	;; LD	L,(HL)
	;; L <- (HL)
	FETCHB	d6,d6
	DONE

	START
emu_op_6f:
	;; LD	L,A
	move.b	d3,d6
	DONE

	START
emu_op_70:
	;; LD	(HL),B
	LOHI	d4
	PUTB	d6,d4
	HILO	d4
	DONE

	START
emu_op_71:
	;; LD	(HL),C
	PUTB	d6,d4
	DONE

	START
emu_op_72:
	;; LD	(HL),D
	LOHI	d5
	PUTB	d6,d5
	HILO	d5
	DONE

	START
emu_op_73:
	;; LD	(HL),E
	PUTB	d6,d5
	DONE

	START
emu_op_74:
	;; LD	(HL),H
	move.w	d6,d1
	HILO	d1
	PUTB	d1,d6
	DONE

	START
emu_op_75:
	;; LD	(HL),L
	move.b	d6,d1
	PUTB	d1,d6
	DONE

	START
emu_op_76:
	;; HALT
	;; XXX do this
	DONE

	START
emu_op_77:
	;; LD	(HL),A
	PUTB	d3,d6
	DONE

	START
emu_op_78:
	;; LD	A,B
	move.w	d4,d1
	LOHI	d1
	move.b	d1,d3
	DONE

	START
emu_op_79:
	;; LD	A,C
	move.b	d4,d3
	DONE

	START
emu_op_7a:
	;; LD	A,D
	move.w	d5,d1
	LOHI	d1
	move.b	d1,d3
	DONE

	START
emu_op_7b:
	;; LD	A,E
	move.b	d5,d3
	DONE

	START
emu_op_7c:
	;; LD	A,H
	move.w	d6,d1
	LOHI	d1
	move.b	d1,d3
	DONE

	START
emu_op_7d:
	;; LD	A,L
	move.b	d6,d3
	DONE

	START
emu_op_7e:
	;; LD	A,(HL)
	;; A <- (HL)
	FETCHB	d6,d3
	DONE

	START
emu_op_7f:
	;; LD	A,A
	DONE



	;; Do an ADD \2,\1
	;; XXX check this
	;; XXX make it shorter ... D:
F_ADD_B	MACRO			; 14 bytes?
	move.b	\1,f_tmp_src_b	; preserve operands for flag work
	move.b	\2,f_tmp_dst_b
	move.b	#1,(f_tmp_byte-flag_storage)(a3)
	add	\1,\2
	move	sr,(f_host_sr-flag_storage)(a3)
	move.w	#0202,(flag_byte-flag_storage)(a3)
	ENDM

	START
emu_op_80:
	;; ADD	A,B
	LOHI	d4
	F_ADD_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_81:
	;; ADD	A,C
	F_ADD_B	d4,d3
	DONE

	START
emu_op_82:
	;; ADD	A,D
	LOHI	d5
	F_ADD_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_83:
	;; ADD	A,E
	F_ADD_B	d5,d3
	DONE

	START
emu_op_84:
	;; ADD	A,H
	LOHI	d6
	F_ADD_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_85:
	;; ADD	A,L
	F_ADD_B	d6,d3
	DONE

	START
emu_op_86:
	;; ADD	A,(HL)
	FETCHB	d6,d1
	F_ADD_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_87:
	;; ADD	A,A
	F_ADD_B	d3,d3
	DONE



	;; Do an ADC \2,\1
F_ADC_B	MACRO			; S34
	;; XXX TOO BIG
	bsr	flags_normalize
	move.b	flag_byte(pc),d0
	andi.b	#1,d0
	add.b	\1,d0
	move.b	d0,(f_tmp_src_b-flag_storage)(a3)
	move.b	\2,(f_tmp_dst_b-flag_storage)(a3)
	add.b	d0,\2
	move	sr,(f_host_ccr-flag_storage)(a3)
	move.w	#$0202,(flag_byte-flag_storage)(a3)
	ENDM

	START
emu_op_88:
	;; ADC	A,B
	;; A <- A + B + (carry)
	LOHI	d4
	F_ADC_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_89:
	;; ADC	A,C
	;; A <- A + C + (carry)
	F_ADC_B	d4,d3
	DONE

	START
emu_op_8a:
	;; ADC	A,D
	LOHI	d5
	F_ADC_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_8b:
	;; ADC	A,E
	;; A <- A + E + carry
	F_ADC_B	d5,d3
	DONE

	START
emu_op_8c:
	;; ADC	A,H
	LOHI	d3
	F_ADC_B	d6,d3
	HILO	d3
	DONE

	START
emu_op_8d:
	;; ADC	A,L
	F_ADC_B	d6,d3
	DONE

	START
emu_op_8e:
	;; ADC	A,(HL)
	FETCHB	d6,d1
	F_ADC_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_8f:
	;; ADC	A,A
	F_ADC_B	d3,d3
	DONE





	;; Do a SUB \2,\1
	;; XXX CHECK
F_SUB_B	MACRO			; 22 bytes?
	;; XXX use lea and then d(an) if you have a spare register.
	;; preserve operands for flagging
	move.b	\1,(f_tmp_src_b-flag_storage)(a3)
	move.b	\2,(f_tmp_dst_b-flag_storage)(a3)
	move.b	#1,(f_tmp_byte-flag_storage)(a3)
	andi.b	#%00000010,(flag_valid-flag_storage)(a3)
	move.b	#%00000010,(flag_byte-flag_storage)(a3)
	sub	\1,\2
	move	sr,(f_host_sr-flag_storage)(a3)
	ENDM

	START
emu_op_90:
	;; SUB	A,B
	LOHI	d4
	F_SUB_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_91:
	;; SUB	A,C
	F_SUB_B	d4,d3
	DONE

	START
emu_op_92:
	;; SUB	A,D
	LOHI	d5
	F_SUB_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_93:
	;; SUB	A,E
	F_SUB_B	d5,d3
	DONE

	START
emu_op_94:
	;; SUB	A,H
	LOHI	d6
	F_SUB_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_95:
	;; SUB	A,L
	F_SUB_B	d6,d3

	START
emu_op_96:
	;; SUB	A,(HL)
	FETCHB	d6,d1
	F_SUB_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_97:
	;; SUB	A,A
	F_SUB_B	d3,d3
	DONE




	;; Do a SBC \2,\1
F_SBC_B	MACRO
	;; XXX TOO BIG
	bsr	flags_normalize
	move.b	flag_byte(pc),d0
	andi.b	#1,d0
	add.b	\1,d0
	move.b	d0,(f_tmp_src_b-flag_storage)(a3)
	move.b	\2,(f_tmp_dst_b-flag_storage)(a3)
	sub.b	d0,\2
	move	sr,(f_host_sr-flag_storage)(a3)
	move.w	#$0202,(flag_byte-flag_storage)(a3)

	ENDM

	START
emu_op_98:
	;; SBC	A,B
	LOHI	d4
	F_SBC_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_99:
	;; SBC	A,C
	F_SBC_B	d4,d3
	DONE

	START
emu_op_9a:
	;; SBC	A,D
	LOHI	d5
	F_SBC_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_9b:
	;; SBC	A,E
	F_SBC_B	d5,d3
	DONE

	START
emu_op_9c:
	;; SBC	A,H
	LOHI	d6
	F_SBC_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_9d:
	;; SBC	A,L
	F_SBC_B	d6,d3
	DONE

	START
emu_op_9e:
	;; SBC	A,(HL)
	FETCHB	d6,d1
	F_SBC_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_9f:
	;; SBC	A,A
	F_SBC_B	d3,d3
	DONE





F_AND_B	MACRO
	;; XXX
	ENDM

	START
emu_op_a0:
	;; AND	B
	LOHI	d4
	F_AND_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_a1:
	;; AND	C
	F_AND_B	d4,d3

	START
emu_op_a2:
	;; AND	D
	LOHI	d5
	F_AND_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_a3:
	;; AND	E
	F_AND_B	d5,d3
	DONE

	START
emu_op_a4:
	;; AND	H
	LOHI	d6
	F_AND_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_a5:
	;; AND	L
	F_AND_B	d6,d3
	DONE

	START
emu_op_a6:
	;; AND	(HL)
	FETCHB	d6,d1
	F_AND_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_a7:
	;; AND	A
	;; SPEED ... It's probably not necessary to run this faster.
	F_AND_B	d3,d3
	DONE





F_XOR_B	MACRO
	;; XXX
	ENDM

	START
emu_op_a8:
	;; XOR	B
	LOHI	d4
	F_XOR_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_a9:
	;; XOR	C
	F_XOR_B	d4,d3
	DONE

	START
emu_op_aa:
	;; XOR	D
	LOHI	d5
	F_XOR_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_ab:
	;; XOR	E
	F_XOR_B	d5,d3
	DONE

	START
emu_op_ac:
	;; XOR	H
	LOHI	d6
	F_XOR_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_ad:
	;; XOR	L
	F_XOR_B	d6,d3
	DONE

	START
emu_op_ae:
	;; XOR	(HL)
	FETCHB	d6,d1
	F_XOR_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_af:
	;; XOR	A
	F_XOR_B	d3,d3
	;; XXX
	DONE





F_OR_B	MACRO
	;; XXX
	ENDM

	START
emu_op_b0:
	;; OR	B
	LOHI	d4
	F_OR_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_b1:
	;; OR	C
	F_OR_B	d4,d3
	DONE

	START
emu_op_b2:
	;; OR	D
	LOHI	d5
	F_OR_B	d5,d3
	HILO	d5
	DONE

	START
emu_op_b3:
	;; OR	E
	F_OR_B	d5,d3
	DONE

	START
emu_op_b4:
	;; OR	H
	LOHI	d6
	F_OR_B	d6,d3
	HILO	d6
	DONE

	START
emu_op_b5:
	;; OR	L
	F_OR_B	d6,d3
	DONE

	START
emu_op_b6:
	;; OR	(HL)
	FETCHB	d6,d1
	F_OR_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_b7:
	;; OR	A
	F_OR_B	d3,d3
	DONE





	;; COMPARE instruction
F_CP_B	MACRO
	;; XXX
	ENDM

	START
emu_op_b8:
	;; CP	B
	move.b	d4,d1
	LOHI	d1
	F_CP_B	d1,d3
	DONE

	START
emu_op_b9:
	;; CP	C
	F_CP_B	d4,d3
	DONE

	START
emu_op_ba:
	;; CP	D
	move.b	d5,d1
	LOHI	d1
	F_CP_B	d1,d3
	DONE

	START
emu_op_bb:
	;; CP	E
	F_CP_B	d5,d3
	DONE

	START
emu_op_bc:
	;; CP	H
	move.b	d6,d1
	LOHI	d1
	F_CP_B	d1,d3
	DONE

	START
emu_op_bd:
	;; CP	L
	F_CP_B	d6,d3
	DONE

	START
emu_op_be:
	;; CP	(HL)
	FETCHB	d6,d1
	F_CP_B	d1,d3		; if F_CP_B uses d1, watch out for this
	;; no result to store
	DONE

	START
emu_op_bf:
	;; CP	A
	F_CP_B	d3,d3
	DONE

	START
emu_op_c0:
	;; RET	NZ
	;; if ~Z
	;;   PCl <- (SP)
	;;   PCh <- (SP+1)
	;;   SP <- (SP+2)
	bsr	f_norm_z
	;; SPEED inline RET
	beq	emu_op_c9	; RET
	DONE

	START
emu_op_c1:			; S10 T
	;; POP	BC
	;; Pops a word into BC
	POPW	d4
	DONE

	START
emu_op_c2:
	;; JP	NZ,immed.w
	;; if ~Z
	;;   PC <- immed.w
	bsr	f_norm_z
	bne	emu_op_c3
	DONE

	START
emu_op_c3:			; S12 T36
	;; JP	immed.w
	;; PC <- immed.w
	FETCHWI	d1
	bsr	deref
	movea	a0,a6
	DONE

	START
emu_op_c4:
	;; CALL	NZ,immed.w
	;; If ~Z, CALL immed.w
	bsr	f_norm_z
	bne	emu_op_cd
	DONE

	START
emu_op_c5:
	;; PUSH	BC
	PUSHW	d4
	DONE

	START
emu_op_c6:
	;; ADD	A,immed.b
	FETCHBI	d1
	F_ADD_B	d1,d3
	DONE

	START
emu_op_c7:
	;; RST	&0
	;;  == CALL 0
	;; XXX check
	;; XXX FIX D2
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$00,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_c8:
	;; RET	Z
	bsr	f_norm_z
	beq	emu_op_c9
	DONE

	START
emu_op_c9:
	;; RET
	;; PCl <- (SP)
	;; PCh <- (SP+1)	POPW
	;; SP <- (SP+2)
	POPW	d1
	bsr	deref
	movea	a0,a6
	DONE

	START
emu_op_ca:
	;; JP	Z,immed.w
	;; If Z, jump
	bsr	f_norm_z
	beq	emu_op_c3
	DONE

	START
emu_op_cb:			; prefix
	movea.w	emu_op_undo_cb(pc),a2

	START
emu_op_cc:
	;; CALL	Z,immed.w
	bsr	f_norm_z
	beq	emu_op_cd
	DONE

	START
emu_op_cd:
	;; CALL	immed.w
	;; (Like JSR on 68k)
	;;  (SP-1) <- PCh
	;;  (SP-2) <- PCl
	;;  SP <- SP - 2
	;;  PC <- address
	move	a6,a0
	bsr	underef		; d0 has PC
	PUSHW	d0
	FETCHWI	d0
	bra	emu_op_ca	; JP

	START
emu_op_ce:
	;; ADC	A,immed.b
	FETCHWI	d1
	F_ADC_B	d1,d3
	DONE

	START
emu_op_cf:
	;; RST	&08
	;;  == CALL 8
	move	a6,a0
	bsr	underef		; d0 has PC
	PUSHW	d0
	move.w	#$08,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_d0:
	;; RET	NC
	bsr	f_norm_c
	beq	emu_op_c9
	DONE

	START
emu_op_d1:
	;; POP	DE
	POPW	d5
	DONE

	START
emu_op_d2:
	;; JP	NC,immed.w
	bsr	f_norm_c
	beq	emu_op_c3
	DONE

	START
emu_op_d3:
	;; OUT	immed.b,A
	move.b	d3,d1
	FETCHBI	d0
	bsr	port_out
	DONE

	START
emu_op_d4:
	;; CALL	NC,immed.w
	bsr	f_norm_c
	beq	emu_op_cd
	DONE

	START
emu_op_d5:
	;; PUSH	DE
	PUSHW	d5
	DONE

	START
emu_op_d6:
	;; SUB	A,immed.b
	FETCHBI	d1
	F_SUB_B	d3,d1
	DONE

	START
emu_op_d7:
	;; RST	&10
	;;  == CALL 10
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$10,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_d8:
	;; RET	C
	bsr	f_norm_c
	bne	emu_op_c9
	DONE

	START
emu_op_d9:
	;; EXX
	swap	d4
	swap	d5
	swap	d6
	DONE

	START
emu_op_da:
	;; JP	C,immed.w
	bsr	f_norm_c
	bne	emu_op_c3
	DONE

	START
emu_op_db:
	;; IN	A,immed.b
	move.b	d3,d1
	FETCHBI	d0
	bsr	port_in
	DONE

	START
emu_op_dc:
	;; CALL	C,immed.w
	bsr	f_norm_c
	bne	emu_op_cd
	DONE

	START
emu_op_dd:			; prefix
	movea.w		emu_op_undo_dd(pc),a2

	START
emu_op_de:
	;; SBC	A,immed.b
	FETCHWI	d1
	F_SBC_B	d1,d3
	DONE

	START
emu_op_df:
	;; RST	&18
	;;  == CALL 18
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$18,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_e0:
	;; RET	PO
	;; If parity odd (P zero), return
	bsr	f_norm_pv
	beq	emu_op_c9
	DONE

	START
emu_op_e1:
	;; POP	HL
	POPW	d6
	DONE

	START
emu_op_e2:
	;; JP	PO,immed.w
	bsr	f_norm_pv
	beq	emu_op_c3
	DONE

	START
emu_op_e3:
	;; EX	(SP),HL
	;; Exchange
	POPW	d1
	PUSHW	d6
	move.w	d1,d6
	DONE

	START
emu_op_e4:
	;; CALL	PO,immed.w
	;; if parity odd (P=0), call
	bsr	f_norm_pv
	beq	emu_op_cd
	DONE

	START
emu_op_e5:
	;; PUSH	HL
	PUSHW	d6
	DONE

	START
emu_op_e6:
	;; AND	immed.b
	FETCHBI	d1
	F_AND_B	d1,d3
	DONE

	START
emu_op_e7:
	;; RST	&20
	;;  == CALL 20
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$20,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_e8:
	;; RET	PE
	;; If parity odd (P zero), return
	bsr	f_norm_pv
	bne	emu_op_c9
	DONE

	START
emu_op_e9:
	;; JP	(HL)
	FETCHB	d6,d1
	bsr	deref
	movea	a0,a6
	DONE

	START
emu_op_ea:
	;; JP	PE,immed.w
	bsr	f_norm_pv
	bne	emu_op_c3
	DONE

	START
emu_op_eb:
	;; EX	DE,HL
	exg.w	d5,d6
	DONE

	START
emu_op_ec:
	;; CALL	PE,immed.w
	;; If parity even (P=1), call
	bsr	f_norm_c
	bne	emu_op_cd
	DONE

	START
emu_op_ed:			; prefix
	movea.w	emu_op_undo_ed(pc),a2
	DONE

	START
emu_op_ee:
	;; XOR	immed.b
	FETCHBI	d1
	F_XOR_B	d1,d3
	DONE

	START
emu_op_ef:
	;; RST	&28
	;;  == CALL 28
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$28,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_f0:
	;; RET	P
	;; Return if Positive
	bsr	f_norm_sign
	beq	emu_op_c9	; RET
	DONE

	START
emu_op_f1:
	;; POP	AF
	;; SPEED this can be made faster ...
	POPW	d3
	move.w	d3,(flag_byte-flag_storage)(a3)
	move.b	#$ff,(flag_valid-flag_storage)(a3)
	DONE

	START
emu_op_f2:
	;; JP	P,immed.w
	bsr	f_norm_sign
	beq	emu_op_c3	; JP
	DONE

	START
emu_op_f3:
	;; DI
	bsr	ints_stop

	START
emu_op_f4:
	;; CALL	P,&0000
	;; Call if positive (S=0)
	bsr	f_norm_sign
	beq	emu_op_cd
	DONE

	START
emu_op_f5:
	;; PUSH	AF
	bsr	flags_normalize
	LOHI	d3
	move.b	flag_byte(pc),d3
	HILO	d3
	PUSHW	d3
	DONE

	START
emu_op_f6:
	;; OR	immed.b
	FETCHBI	d1
	F_OR_B	d1,d3
	DONE

	START
emu_op_f7:
	;; RST	&30
	;;  == CALL 30
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$08,d0
	bsr	deref
	move	a0,a6
	DONE

	START
emu_op_f8:
	;; RET	M
	;; Return if Sign == 1, minus
	bsr	f_norm_sign
	bne	emu_op_c9	; RET
	DONE

	START
emu_op_f9:
	;; LD	SP,HL
	;; SP <- HL
	move.w	d6,d1
	bsr	deref
	movea	a0,a4
	DONE

	START
emu_op_fa:
	;; JP	M,immed.w
	bsr	f_norm_sign
	bne	emu_op_c3	; JP
	DONE

	START
emu_op_fb:
	;; EI
	bsr	ints_start
	DONE

	START
emu_op_fc:
	;; CALL	M,immed.w
	;; Call if minus (S=1)
	bsr	f_norm_sign
	bne	emu_op_cd
	DONE

	START
emu_op_fd:			; prefix
	;; swap IY, HL
	movea.w	emu_op_undo_fd(pc),a2

	START
emu_op_fe:
	;; CP	immed.b
	FETCHBI	d1
	F_CP_B	d1,d3
	DONE

	START
emu_op_ff:
	;; RST	&38
	;;  == CALL 38
	move	a6,a0
	bsr	underef
	PUSHW	d0
	move.w	#$08,d0
	bsr	deref
	move	a0,a6
	DONE

emu_op_undo_cb:

	movea.w	emu_fetch(pc),a2
	
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:


