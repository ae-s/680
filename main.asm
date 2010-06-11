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
;;; A6 = address space base pointer
;;; A5 =
;;; A4 =
;;; A3 = instruction table base pointer
;;; A2 = pseudo return address (for emulation core, to emulate prefix
;;;      instructions properly)
;;; A1 = scratch
;;; A0 = scratch
;;;
;;; D0 = current instruction
;;; D1 = scratch
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

;;; emulated I and R are both in RAM

	xdef	_ti89
;	xdef	_ti92plus
	xdef	_main
	xdef	_nostub
	include "../tios.h"

	;; == Memory Macros ================================================

	;; Macro to read a byte from main memory at register \1.  Puts
	;; the byte read in \2.
FETCHB	MACRO			; 14 cycles, 4 bytes
	move.b	0(a6,\1.w),\2
	ENDM

	;; Macro to write a byte in \1 to main memory at \2 (regs only)
PUTB	MACRO			; 14 cycles, 4 bytes
	move.b	\1,0(a6,\2)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
FETCHW	MACRO			; 32 cycles, 10 bytes
	move.b	1(a6,\1.w),\2	; 14/4
	ror.w	#8,\2		;  4/2
	move.b	0(a6,\1.w),\2	; 14/4
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
	;; XXX ALIGNMENT
PUTW	MACRO			; 14 cycles, 4 bytes
	move.b	\1,0(a6,\2)
	ENDM

	;; == Immediate Memory Macros ==

	;; Macro to read an immediate byte into \1.
FETCHBI	MACRO			; 18 cycles, 6 bytes
	addq.w	#1,d2		;  4/2
	move.b	-1(a6,d2.w),\1	; 14/4
	ENDM

	;; Macro to read an immediate word (unaligned) into \1.
FETCHWI	MACRO			; 36 cycles, 12 bytes
	addq.w	#2,d2		;  4/2
	move.b	-1(a6,d2.w),\1	; 14/4
	rol.w	#8,d2		;  4/2
	move.b	-2(a6,d2.w),\1	; 14/4
	ENDM

	;; == Common Opcode Macros =========================================

	;; Forces alignment
_align	SET	0

START	MACRO
	ORG	emu_plain_op+_align
_align	SET	_align+$20
	ENDM

	;; When you want to use the high reg of a pair, use this first
LOHI	MACRO			; 6 cycles, 2 bytes
	ror	#8,\1
	ENDM

	;; Then do your shit and finish with this
HILO	MACRO			; 6 cycles, 2 bytes
	rol	#8,\1
	ENDM

	;; calc84maniac suggests putting emu_fetch into this in order
	;; to save 8 cycles per instruction, at the expense of code
	;; size
DONE	MACRO			; 8 cycles, 2 bytes
	jmp	(a2)
	ENDM

	;; == Special Opcode Macros ========================================

	;; Do a SUB \2,\1
F_SUB_B	MACRO			;14 bytes?
	move.b	\1,f_tmp_src_b	; preserve operands for flagging
	move.b	\2,f_tmp_dst_b
	move.b	#1,flag_n
	move.b	#1,f_tmp_byte
	sub	\1,\2
	move	sr,f_host_ccr
	ENDM


	;; Do an ADD \1,\2
F_ADD_W	MACRO
	ENDM
	;; Do an SUB \1,\2
F_SUB_W	MACRO
	ENDM

	;; INC and DEC macros
F_INC_B	MACRO
	ENDM

F_DEC_B	MACRO
	ENDM

F_INC_W	MACRO
	ENDM

F_DEC_W	MACRO
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

	include	"flags.asm"

emu_setup:
	movea	emu_plain_op,a3
	movea	emu_fetch(pc),a2
	;; XXX finish

refresh:			; screen refresh routine
	;; XXX Do this
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
	;; See if I can get rid of the eor
	eor.w	d0,d0		; 4 cycles
	move.b	(a4)+,d0	; 8 cycles
	rol.w	#5,d0		; 4 cycles   adjust to actual alignment
	jmp	0(a3,d0)	;14 cycles
	;; overhead:		 30 cycles

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
	addq.w	#1,d4
	DONE

	START
emu_op_04:
	;; INC	B
	;; B <- B+1
	;; XXX FLAGS
	add.w	#$0100,d4	; 8
	DONE			; 8
				;16 cycles

	START
emu_op_05:
	;; DEC	B
	;; B <- B-1
	;; Flags: S,Z,H changed, P=oVerflow, N set, C left
	;; XXX FLAGS
	sub.w	#$0100,d4
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
	;; XXX FLAGS
	add.w	d4,d6
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
	subq.w	#1,d4
	DONE

	START
emu_op_0c:
	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
	;; XXX FLAGS
	addq.b	#1,d4
	DONE

	START
emu_op_0d:
	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
	;; XXX FLAGS
	subq.b	#1,d4
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
emu_op_10:			; S14 T??
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	LOHI	d4
	subq.b	#1,d4
	beq	end_10	; slooooow
	FETCHBI	d1
	add.w	d1,d2
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
	move.b	0(a0,d5.w),d3
	DONE

	START
emu_op_13:
	;; INC	DE
	;; No flags
	addq.w	#1,d5
	DONE

	START
emu_op_14:
	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
	LOHI	d5
	addq.b	#1,d5
	HILO	d5
	DONE

	START
emu_op_15:
	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d5
	subq.b	#1,d5
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
	roxl.b	#1,d3
	DONE

	START
emu_op_18:
	;; JR
	;; Branch relative by a signed immediate byte
	;; No flags
	FETCHBI	d1
	add.w	d1,d2
	DONE

	START
emu_op_19:
	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
	add.w	d5,d6
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
	addq.b	#1,d5
	DONE

	START
emu_op_1d:
	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
	subq.b	#1,d5
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
	add.w	d1,d2
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
	addq.b	#1,d6
	HILO	d6
	DONE

	START
emu_op_25:
	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d6
	subq.b	#1,d6
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
	beq	end_28
	FETCHBI	d1
	add.w	d1,d2
end_28:
	DONE

	START
emu_op_29:
	;; ADD	HL,HL
	;; Flags: 
	add.w	d6,d6
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
	subq.w	#1,d6
	DONE

	START
emu_op_2c:
	;; INC	L
	addq.b	#1,d6
	DONE

	START
emu_op_2d:
	;; DEC	L
	subq.b	#1,d6
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
	not.b	d3
	DONE

	START
emu_op_30:
	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
	bsr	f_norm_c
	bne	end_30		; branch taken: carry set
	FETCHBI	d1
	add.w	d1,d2
end_30:
	DONE

	START
emu_op_31:
	;; LD	SP,immed.w
	swap	d2
	FETCHWI	d2
	swap	d2
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
	;; XXX This might be done by adding $100
	swap	d2
	addq.w	#1,d2
	swap	d2
	DONE

	START
emu_op_34:
	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
	FETCHB	d6,d1
	addq.b	#1,d1
	PUTB	d1,d6
	DONE

	START
emu_op_35:
	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
	FETCHB	d6,d1
	subq.b	#1,d1
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
	;; XXX DO THIS
	DONE

	START
emu_op_38:
	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
	bcc	end_38
	FETCHBI	d1
	add.w	d1,d2
end_38:
	DONE

	START
emu_op_39:
	;; ADD	HL,SP
	;; HL <- HL+SP
	swap	d2
	add.w	d6,d2
	swap	d2
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
	;; XXX this might be done by subtracting $100
	swap	d2
	subq.w	#1,d2
	swap	d2
	DONE

	START
emu_op_3c:
	;; INC	A
	addq.b	#1,d3
	DONE

	START
emu_op_3d:
	;; DEC	A
	subq.b	#1,d3
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
	;; XXX DO THIS
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
	LOHI	d4		; 4
	LOHI	d5		; 4
	move.b	d5,d4		; 4
	HILO	d4		; 4
	HILO	d5		; 4
	DONE
				;20 cycles

	START
emu_op_43:
	;; LD	B,E
	;; B <- E
	LOHI	d4		; 4
	move.b	d4,d5		; 4
	HILO	d4		; 4
	DONE
				; 12 cycles

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
	LOHI	d5
	move.b	d5,d1
	HILO	d5
	move.b	d1,d5
	DONE

	;; Is this faster or slower?

	andi.w	#$ff00,d5
	move.b	d5,d1
	lsr	#8,d1
	or.w	d1,d5
	DONE

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
F_ADD_B	MACRO			; 14 bytes?
	move.b	\1,f_tmp_src_b	; preserve operands for flag work
	move.b	\2,f_tmp_dst_b
	move.b	#0,flag_n
	move.b	#1,f_tmp_byte
	add	\1,\2
	move	sr,f_host_ccr
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
F_ADC_B	MACRO
	;; XXX
	ENDM

	START
emu_op_88:
	;; ADC	A,B
	;; A <- A + B + (carry)
	;; XXX fix this shit up
	LOHI	d4
	F_ADC_B	d4,d3
	HILO	d4
	DONE

	START
emu_op_89:
	;; ADC	A,C
	;; A <- A + C + (carry)
	;; XXX fix this shit up
	F_ADC_B	d4,d3
	DONE

	START
emu_op_8a:
	;; ADC	A,D
	;; XXX fix this shit up
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
	F_ADD_B	d1,d3
	PUTB	d1,d6
	DONE

	START
emu_op_8f:
	;; ADC	A,A
	F_ADD_B	d3,d3
	DONE

	START
emu_op_90:
	;; SUB	A,B
	LOHI	d4
	F_SUB_B	d4,d3
	add.b	d4,d3
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
	;; XXX
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
emu_op_c1:
	;; POP	BC

	START
emu_op_c2:
	;; JP	NZ,immed.w
	;; if ~Z
	;;   PC <- immed.w

	START
emu_op_c3:
	;; JP	immed.w
	;; PC <- immed.w

	START
emu_op_c4:
	;; CALL	NZ,immed.w
	;; If ~Z, CALL immed.w

	START
emu_op_c5:
	;; PUSH	BC

	START
emu_op_c6:
	;; ADD	A,immed.b

	START
emu_op_c7:
	;; RST	immed.b
	;;   CALL	0

	START
emu_op_c8:
	;; CALL	immed.w
	;;  (SP-1) <- PCh
	;;  (SP-2) <- PCl
	;;  SP <- SP - 2
	;;  PC <- address

	START
emu_op_c9:
	;; RET
	;; PCl <- (SP)
	;; PCh <- (SP+1)
	;; SP <- (SP+2)
	swap	d2
	FETCHB	d2,d1
	addq.b	#1,emu_sp
	FETCHB	d2,d1
	addq.b	#1,emu_sp
	swap	d2
	move.w	d1,d2
	DONE

	START
emu_op_ca:
	;; JP	Z,immed.w

	START
emu_op_cb:			; prefix

	movea.w	emu_op_undo_cb(pc),a2
	START
emu_op_cc:
	START
emu_op_cd:
	START
emu_op_ce:
	START
emu_op_cf:
	START
emu_op_d0:
	START
emu_op_d1:
	START
emu_op_d2:
	START
emu_op_d3:
	START
emu_op_d4:
	START
emu_op_d5:
	START
emu_op_d6:
	START
emu_op_d7:
	START
emu_op_d8:
	START
emu_op_d9:
	START
emu_op_da:
	START
emu_op_db:
	START
emu_op_dc:
	START
emu_op_dd:			; prefix
	;; swap IX, HL

	movea.w		emu_op_undo_dd(pc),a2
	
	START
emu_op_de:
	START
emu_op_df:
	START
emu_op_e0:
	START
emu_op_e1:
	START
emu_op_e2:
	START
emu_op_e3:
	START
emu_op_e4:
	START
emu_op_e5:
	START
emu_op_e6:
	START
emu_op_e7:
	START
emu_op_e8:
	START
emu_op_e9:
	START
emu_op_ea:
	START
emu_op_eb:
	;; EX	DE,HL
	exg.w	d5,d6
	DONE

	START
emu_op_ec:
	START
emu_op_ed:			; prefix

	movea.w	emu_op_undo_ed(pc),a2
	START
emu_op_ee:
	START
emu_op_ef:
	START
emu_op_f0:
	START
emu_op_f1:
	START
emu_op_f2:
	START
emu_op_f3:
	START
emu_op_f4:
	START
emu_op_f5:
	START
emu_op_f6:
	START
emu_op_f7:
	START
emu_op_f8:
	START
emu_op_f9:
	START
emu_op_fa:
	START
emu_op_fb:p
	;; EI

	START
emu_op_fc:
	START
emu_op_fd:			; prefix
	;; swap IY, HL

	movea.w	emu_op_undo_fd(pc),a2
	START
emu_op_fe:
	START
emu_op_ff:

emu_op_undo_cb:

	movea.w	emu_fetch(pc),a2
	
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:


