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
;;; A6 = address space base pointer
;;; A3 = instruction table base pointer
;;; A2 = pseudo return address (for emulation core, to emulate prefix
;;;      instructions properly)
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
	move.b	\1,(a6,\2)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
FETCHW	MACRO			; 32 cycles, 10 bytes
	move.b	1(a6,\1.w),\2	; 14/4
	ror.w	#8,\2		;  4/2
	move.b	(a6,\1.w),\2	; 14/4
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
	;; XXX ALIGNMENT
PUTW	MACRO			; 14 cycles, 4 bytes
	move.b	\1,(a6,\2)
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
_align	SET	_align+32
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

	;; Set flags appropriately for an ADD \1,\2
F_ADD_B	MACRO			; 14 bytes?
	;; preserve operands for flagging
	move.b	\1,tmp_src
	move.b	\2,tmp_dst
	moveq	#0,flag_n
	moveq	#1,tmp_byte
	;; XXX do I have to use SR instead?
	move	ccr,68k_ccr
	ENDM

	;; Set flags appropriately for a SUB \1,\2
F_SUB_B	MACRO			;14 bytes?
	;; preserve operands for flagging
	move.b	\1,tmp_src
	move.b	\2,tmp_dst
	moveq	#1,flag_n
	moveq	#1,tmp_byte
	;; XXX do I have to use SR instead?
	move	ccr,68k_ccr
	ENDM

	;; Set flags appropriately for a ADD \1,\2, both words
F_ADD_W	MACRO
	ENDM
	;; Set flags appropriately for a SUB \1,\2, both words
F_SUB_W	MACRO
	ENDM






_main:
	bsr	emu_setup
	rts

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

storage:
	;; 1 if tmp_???b is valid, 0 if tmp_???w is valid
tmp_byte:	ds.b	0

	;; byte operands
tmp_srcb:	ds.b	0
tmp_dstb:	ds.b	0

	;; word operands
tmp_srcw:	ds.w	0
tmp_dstw:	ds.w	0

flag_n:		ds.b	0
68k_ccr:	ds.w	0

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

emu_plain_op:
emu_op_00:
	;; NOP
	START
	DONE

emu_op_01:
	;; LD	BC,immed.w
	;; Read a word and put it in BC
	;; No flags
	START
	FETCHWI	d4
	DONE

emu_op_02:
	;; LD	(BC),A
	;; XXX Do this
	;; No flags
	START
	DONE

emu_op_03:
	;; INC	BC
	;; BC <- BC+1
	;; No flags
	START
	addq.w	#1,d4
	DONE

emu_op_04:
	;; INC	B
	;; B <- B+1
	;; No flags ?
	START
	add.w	#$0100,d4	; 8
	DONE			; 8
				;16 cycles

emu_op_05:
	;; DEC	B
	;; B <- B-1
	;; Flags: S,Z,H changed, P=oVerflow, N set, C left
	START
	sub.w	#$0100,d4
	DONE

emu_op_06:
	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; No flags
	START
	LOHI	d4
	FETCHBI	d4
	HILO	d4
	DONE

emu_op_07:
	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	START
	rol.b	#1,d3
	DONE

emu_op_08:
	;; EX	AF,AF'
	;; No flags
	START
	swap	d3
	DONE

emu_op_09:
	;; ADD	HL,BC
	;; HL <- HL+BC
	;; Flags: H, C aff.; N=0
	START
	add.w	d4,d6
	DONE

emu_op_0a:
	;; LD	A,(BC)
	;; A <- (BC)
	;; No flags
	START
	FETCHB	d4,d3
	DONE

emu_op_0b:
	;; DEC	BC
	;; BC <- BC-1
	;; No flags
	START
	subq.w	#1,d4
	DONE

emu_op_0c:
	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
	START
	addq.b	#1,d4
	DONE

emu_op_0d:
	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
	START
	subq.b	#1,d4
	DONE

emu_op_0e:
	;; LD	C,immed.b
	;; No flags
	START
	FETCHBI	d4
	DONE

emu_op_0f:
	;; RRCA
	;; Rotate A right, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	START
	ror.b	#1,d3
	DONE

emu_op_10:
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	START
	LOHI	d4
	subq.b	#1,d4
	beq	end	; slooooow
	FETCHBI	d1
	add.w	d1,d2
\end:
	HILO	d4
	DONE

emu_op_11:
	;; LD	DE,immed.w
	;; No flags
	START
	FETCHWI	d5
	DONE

emu_op_12:
	;; LD	(DE),A
	;; No flags
	START
	move.b	(a0,d5.w),d3
	DONE

emu_op_13:
	;; INC	DE
	;; No flags
	START
	addq.w	#1,d5
	DONE

emu_op_14:
	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
	START
	LOHI	d5
	addq.b	#1,d5
	HILO	d5
	DONE

emu_op_15:
	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
	START
	LOHI	d5
	subq.b	#1,d5
	HILO	d5
	DONE

emu_op_16:
	;; LD D,immed.b
	;; No flags
	START
	LOHI	d5
	FETCHBI	d5
	HILO	d5
	DONE

emu_op_17:
	;; RLA
	;; Flags: P,N=0; C aff.
	START
	roxl.b	#1,d3
	DONE

emu_op_18:
	;; JR
	;; Branch relative by a signed immediate byte
	;; No flags
	START
	FETCHBI	d1
	add.w	d1,d2
	DONE

emu_op_19:
	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
	START
	add.w	d5,d6
	DONE

emu_op_1a:
	;; LD	A,(DE)
	;; A <- (DE)
	;; No flags
	START
	FETCHB	d5,d3
	DONE

emu_op_1b:
	;; DEC	DE
	;; No flags
	START
	subq.w	#1,d5
	DONE

emu_op_1c:
	;; INC	E
	;; Flags: S,Z,H aff.; P=overflow; N=0
	START
	addq.b	#1,d5
	DONE

emu_op_1d:
	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
	START
	subq.b	#1,d5
	DONE

emu_op_1e:
	;; LD	E,immed.b
	;; No flags
	START
	FETCHBI	d5
	DONE

emu_op_1f:
	;; RRA
	;; Flags: H,N=0; C aff.
	START
	roxr.b	#1,d3
	DONE

emu_op_20:
	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	START
	beq	end
	FETCHBI	d1
	add.w	d1,d2
\end:
	DONE

emu_op_21:
	;; LD	HL,immed.w
	;; No flags
	START
	FETCHWI	d6
	DONE

emu_op_22:
	;; LD	immed.w,HL
	;; (address) <- HL
	;; No flags
	START
	FETCHWI	d1
	PUTW	d6,d1

emu_op_23:
	;; INC	HL
	;; No flags
	START
	addq.w	#1,d6
	DONE

emu_op_24:
	;; INC	H
	;; Flags: S,Z,H aff.; P=overflow, N=0
	START
	LOHI	d6
	addq.b	#1,d6
	HILO	d6
	DONE

emu_op_25:
	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
	START
	LOHI	d6
	subq.b	#1,d6
	HILO	d6
	DONE

emu_op_26:
	;; LD	H,immed.b
	;; No flags
	START
	LOHI	d6
	FETCHBI	d6
	HILO	d6
	DONE

emu_op_27:
	;; DAA
	;; Decrement, adjust accum
	;; http://www.z80.info/z80syntx.htm#DAA
	;; Flags: oh lord they're fucked up
	;; XXX DO THIS
	START

	DONE

emu_op_28:
	;; JR Z,immed.b
	;; If zero
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	START
	beq	end
	FETCHBI	d1
	add.w	d1,d2
\end:
	DONE

emu_op_29:
	;; ADD	HL,HL
	;; Flags: 
	START
	add.w	d6,d6
	DONE

emu_op_2a:
	;; LD	HL,(immed.w)
	;; address is absolute
	START
	FETCHWI	d1
	FETCHW	d1,d6
	DONE

emu_op_2b:
	;; DEC	HL
	START
	subq.w	#1,d6
	DONE

emu_op_2c:
	;; INC	L
	START
	addq.b	#1,d6
	DONE

emu_op_2d:
	;; DEC	L
	START
	subq.b	#1,d6
	DONE

emu_op_2e:
	;; LD	L,immed.b
	START
	FETCHBI	d6
	DONE

emu_op_2f:
	;; CPL
	;; A <- NOT A
	START
	not.b	d3
	DONE

emu_op_30:
	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
	;; XXX finish
	START
	bcs	end
	FETCHBI	d1
	add.w	d1,d2
\end:
	DONE

emu_op_31:
	;; LD	SP,immed.w
	START
	swap	d2
	FETCHWI	d2
	swap	d2
	DONE

emu_op_32:
	;; LD	(immed.w),A
	;; store indirect
	START
	FETCHWI	d1
	PUTB	d3,d1
	DONE

emu_op_33:
	;; INC	SP
	;; XXX This might be done by adding $100
	START
	swap	d2
	addq.w	#1,d2
	swap	d2
	DONE

emu_op_34:
	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
	START
	FETCHB	d6,d1
	addq.b	#1,d1
	PUTB	d1,d6
	DONE

emu_op_35:
	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
	START
	FETCHB	d6,d1
	subq.b	#1,d1
	PUTB	d1,d6
	DONE

emu_op_36:
	;; LD	(HL),immed.b
	START
	FETCHBI	d1
	PUTB	d6,d1
	DONE

emu_op_37:
	;; SCF
	;; Set Carry Flag
	;; XXX DO THIS
	START
	DONE

emu_op_38:
	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
	START
	bcc	end
	FETCHBI	d1
	add.w	d1,d2
\end:
	DONE

emu_op_39:
	;; ADD	HL,SP
	;; HL <- HL+SP
	START
	swap	d2
	add.w	d6,d2
	swap	d2
	DONE

emu_op_3a:
	;; LD	A,(immed.w)
	START
	FETCHWI	d1
	FETCHB	d1,d3
	DONE

emu_op_3b:
	;; DEC	SP
	;; XXX this might be done by subtracting $100
	START
	swap	d2
	subq.w	#1,d2
	swap	d2
	DONE

emu_op_3c:
	;; INC	A
	START
	addq.b	#1,d3
	DONE

emu_op_3d:
	;; DEC	A
	START
	subq.b	#1,d3
	DONE

emu_op_3e:
	;; LD	A,immed.b
	START
	FETCHBI	d3
	DONE

emu_op_3f:
	;; CCF
	;; Toggle carry flag
	;; XXX DO THIS
	START
	DONE

emu_op_40:
	;; LD	B,B
	;; SPEED
	START
	LOHI	d4
	move.b	d4,d4
	HILO	d4
	DONE

emu_op_41:
	;; LD	B,C
	;; SPEED
	START
	move.b	d4,d1
	LOHI	d4
	move.b	d1,d4
	HILO	d4
	DONE

emu_op_42:
	;; LD	B,D
	;; B <- D
	START
	LOHI	d4		; 4
	LOHI	d5		; 4
	move.b	d5,d4		; 4
	HILO	d4		; 4
	HILO	d5		; 4
	DONE
				;20 cycles

emu_op_43:
	;; LD	B,E
	;; B <- E
	START
	LOHI	d4		; 4
	move.b	d4,d5		; 4
	HILO	d4		; 4
	DONE
				; 12 cycles

emu_op_44:
	;; LD	B,H
	;; B <- H
	START
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

emu_op_45:
	;; LD	B,L
	;; B <- L
	START
	LOHI	d4
	move.b	d6,d4
	HILO	d4
	DONE

emu_op_46:
	;; LD	B,(HL)
	;; B <- (HL)
	START
	LOHI	d4
	FETCHB	d6,d4
	HILO	d4
	DONE

emu_op_47:
	;; LD	B,A
	;; B <- A
	START
	LOHI	d4
	move.b	d3,d4
	HILO	d4
	DONE

emu_op_48:
	;; LD	C,B
	;; C <- B
	START
	move.w	d4,d1		; 4
	lsr.w	#8,d1		; 6
	move.b	d1,d4		; 4
	DONE
				;14 cycles
emu_op_49:
	;; LD	C,C
	START
	DONE

emu_op_4a:
	;; LD	C,D
	START
	move.w	d5,d1
	lsr.w	#8,d1
	move.b	d1,d4
	DONE

emu_op_4b:
	;; LD	C,E
	START
	move.b	d4,d5
	DONE

emu_op_4c:
	;; LD	C,H
	START
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

emu_op_4d:
	;; LD	C,L
	START
	move.b	d4,d6
	DONE

emu_op_4e:
	;; LD	C,(HL)
	;; C <- (HL)
	START
	FETCHB	d6,d4
	DONE

emu_op_4f:
	;; LD	C,A
	START
	move.b	d3,d4
	DONE

emu_op_50:
	;; LD	D,B
	START
	LOHI	d4
	LOHI	d5
	move.b	d4,d5
	HILO	d4
	HILO	d5
	DONE

emu_op_51:
	;; LD	D,C
	START
	LOHI	d5
	move.b	d4,d5
	HILO	d5
	DONE

emu_op_52:
	;; LD	D,D
	START
	DONE

emu_op_53:
	;; LD	D,E
	START
	andi.w	#$00ff,d5
	move.b	d5,d1
	lsl	#8,d1
	or.w	d1,d5
	DONE

emu_op_54:
	;; LD	D,H
	START
	LOHI	d5		; 4
	LOHI	d6		; 4
	move.b	d6,d5		; 4
	HILO	d5		; 4
	HILO	d6		; 4
	DONE
				;20 cycles

emu_op_55:
	;; LD	D,L
	START
	LOHI	d5
	move.b	d6,d5
	HILO	d5
	DONE

emu_op_56:
	;; LD	D,(HL)
	;; D <- (HL)
	START
	LOHI	d5
	FETCHB	d6,d5
	HILO	d5
	DONE

emu_op_57:
	;; LD	D,A
	START
	LOHI	d5
	move.b	d3,d5
	HILO	d5
	DONE

emu_op_58:
	;; LD	E,B
	START
	LOHI	d4
	move.b	d4,d5
	HILO	d4
	DONE

emu_op_59:
	;; LD	E,C
	START
	move.b	d4,d5
	DONE

emu_op_5a:
	;; LD	E,D
	START
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

emu_op_5b:
	;; LD	E,E
	START
	DONE

emu_op_5c:
	;; LD	E,H
	START
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

emu_op_5d:
	;; LD	E,L
	START
	move.b	d5,d6
	DONE

emu_op_5e:
	;; LD	E,(HL)
	START
	FETCHB	d6,d1
	DONE

emu_op_5f:
	;; LD	E,A
	START
	move.b	d5,d3
	DONE

emu_op_60:
	;; LD	H,B
	START
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

emu_op_61:
	;; LD	H,C
	START
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

emu_op_62:
	;; LD	H,D
	START
	LOHI	d5
	LOHI	d6
	move.b	d5,d6
	HILO	d5
	HILO	d6
	DONE

emu_op_63:
	;; LD	H,E
	START
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

emu_op_64:
	;; LD	H,H
	START
	DONE

emu_op_65:
	;; LD	H,L
	;; H <- L
	START
	move.b	d6,d1
	LOHI	d6
	move.b	d1,d6
	HILO	d6
	DONE

emu_op_66:
	;; LD	H,(HL)
	START
	FETCHB	d6,d1
	LOHI	d6
	move.b	d1,d6
	HILO	d6
	DONE

emu_op_67:
	;; LD	H,A
	START
	LOHI	d6
	move.b	d3,d6
	HILO	d6
	DONE

emu_op_68:
	;; LD	L,B
	START
	LOHI	d4
	move.b	d4,d6
	HILO	d4
	DONE

emu_op_69:
	;; LD	L,C
	START
	move.b	d4,d6
	DONE

emu_op_6a:
	;; LD	L,D
	START
	LOHI	d5
	move.b	d5,d6
	HILO	d5
	DONE

emu_op_6b:
	;; LD	L,E
	START
	move.b	d5,d6
	DONE

emu_op_6c:
	;; LD	L,H
	START
	LOHI	d6
	move.b	d6,d1
	HILO	d6
	move.b	d1,d6
	DONE

emu_op_6d:
	;; LD	L,L
	START
	DONE

emu_op_6e:
	;; LD	L,(HL)
	;; L <- (HL)
	START
	FETCHB	d6,d6
	DONE

emu_op_6f:
	;; LD	L,A
	START
	move.b	d3,d6
	DONE

emu_op_70:
	;; LD	(HL),B
	START
	LOHI	d4
	PUTB	d6,d4
	HILO	d4
	DONE

emu_op_71:
	;; LD	(HL),C
	START
	PUTB	d6,d4
	DONE

emu_op_72:
	;; LD	(HL),D
	START
	LOHI	d5
	PUTB	d6,d5
	HILO	d5
	DONE

emu_op_73:
	;; LD	(HL),E
	START
	PUTB	d6,d5
	DONE

emu_op_74:
	;; LD	(HL),H
	START
	move.w	d6,d1
	HILO	d1
	PUTB	d1,d6
	DONE

emu_op_75:
	;; LD	(HL),L
	START
	move.b	d6,d1
	PUTB	d1,d6
	DONE

emu_op_76:
	;; HALT
	;; XXX do this
	START
	DONE

emu_op_77:
	;; LD	(HL),A
	START
	PUTB	d3,d6
	DONE

emu_op_78:
	;; LD	A,B
	START
	move.w	d4,d1
	LOHI	d1
	move.b	d1,d3
	DONE

emu_op_79:
	;; LD	A,C
	START
	move.b	d4,d3
	DONE

emu_op_7a:
	;; LD	A,D
	START
	move.w	d5,d1
	LOHI	d1
	move.b	d1,d3
	DONE

emu_op_7b:
	;; LD	A,E
	START
	move.b	d5,d3
	DONE

emu_op_7c:
	;; LD	A,H
	START
	move.w	d6,d1
	LOHI	d1
	move.b	d1,d3
	DONE

emu_op_7d:
	;; LD	A,L
	START
	move.b	d6,d3
	DONE

emu_op_7e:
	;; LD	A,(HL)
	;; A <- (HL)
	START
	FETCHB	d6,d3
	DONE

emu_op_7f:
	;; LD	A,A
	START
	DONE

emu_op_80:
	;; ADD	A,B
	START
	LOHI	d4
	F_ADD_B	d4,d3
	add.b	d4,d3
	HILO	d4
	DONE

emu_op_81:
	;; ADD	A,C
	START
	F_ADD_B	d4,d3
	add.b	d4,d3
	DONE

emu_op_82:
	;; ADD	A,D
	START
	LOHI	d5
	F_ADD_B	d5,d3
	add.b	d5,d3
	HILO	d5
	DONE

emu_op_83:
	;; ADD	A,E
	START
	F_ADD_B	d5,d3
	add.b	d5,d3
	DONE

emu_op_84:
	;; ADD	A,H
	START
	LOHI	d6
	F_ADD_B	d6,d3
	add.b	d6,d3
	HILO	d6
	DONE

emu_op_85:
	;; ADD	A,L
	START
	F_ADD_B	d6,d3
	add.b	d6,d3
	DONE

emu_op_86:
	;; ADD	A,(HL)
	START
	FETCHB	d6,d1
	F_ADD_B	d1,d3
	add.b	d1,d3
	DONE

emu_op_87:
	;; ADD	A,A
	START
	F_ADD_B	d3,d3
	add.b	d3,d3
	DONE

emu_op_88:
	;; ADC	A,B
	;; A <- A + B + (carry)
	;; XXX fix this shit up
	START
	LOHI	d4
	addx.b	d4,d3
	HILO	d4
	DONE

emu_op_89:
	;; ADC	A,C
	;; A <- A + C + (carry)
	;; XXX fix this shit up
	START
	addx.b	d4,d3
	DONE

emu_op_8a:
	;; ADC	A,D
	;; XXX fix this shit up
	START
	LOHI	d5
	addx.b	d5,d3
	HILO	d5
	DONE

emu_op_8b:
	;; ADC	A,E
emu_op_8c:
	;; ADC	A,H
emu_op_8d:
	;; ADC	A,L
emu_op_8e:
	;; ADC	A,(HL)
emu_op_8f:
	;; ADC	A,A
emu_op_90:
	;; SUB	A,B
	
emu_op_91:
emu_op_92:
emu_op_93:
emu_op_94:
emu_op_95:
emu_op_96:
emu_op_97:
emu_op_98:
emu_op_99:
emu_op_9a:
emu_op_9b:
emu_op_9c:
emu_op_9d:
emu_op_9e:
emu_op_9f:
emu_op_a0:
emu_op_a1:
emu_op_a2:
emu_op_a3:
emu_op_a4:
emu_op_a5:
emu_op_a6:
emu_op_a7:
emu_op_a8:
emu_op_a9:
emu_op_aa:
emu_op_ab:
emu_op_ac:
emu_op_ad:
emu_op_ae:
emu_op_af:
emu_op_b0:
emu_op_b1:
emu_op_b2:
emu_op_b3:
emu_op_b4:
emu_op_b5:
emu_op_b6:
emu_op_b7:
emu_op_b8:
emu_op_b9:
emu_op_ba:
emu_op_bb:
emu_op_bc:
emu_op_bd:
emu_op_be:
emu_op_bf:
emu_op_c0:
emu_op_c1:
emu_op_c2:
emu_op_c3:
emu_op_c4:
emu_op_c5:
emu_op_c6:
emu_op_c7:
emu_op_c8:
emu_op_c9:
emu_op_ca:
emu_op_cb:			; prefix

	movea.w	emu_op_undo_cb(pc),a2
emu_op_cc:
emu_op_cd:
emu_op_ce:
emu_op_cf:
emu_op_d0:
emu_op_d1:
emu_op_d2:
emu_op_d3:
emu_op_d4:
emu_op_d5:
emu_op_d6:
emu_op_d7:
emu_op_d8:
emu_op_d9:
emu_op_da:
emu_op_db:
emu_op_dc:
emu_op_dd:			; prefix
	;; swap IX, HL

	movea.w	emu_op_undo_dd(pc),a2
emu_op_de:
emu_op_df:
emu_op_e0:
emu_op_e1:
emu_op_e2:
emu_op_e3:
emu_op_e4:
emu_op_e5:
emu_op_e6:
emu_op_e7:
emu_op_e8:
emu_op_e9:
emu_op_ea:
emu_op_eb:
emu_op_ec:
emu_op_ed:			; prefix

	movea.w	emu_op_undo_ed(pc),a2
emu_op_ee:
emu_op_ef:
emu_op_f0:
emu_op_f1:
emu_op_f2:
emu_op_f3:
emu_op_f4:
emu_op_f5:
emu_op_f6:
emu_op_f7:
emu_op_f8:
emu_op_f9:
emu_op_fa:
emu_op_fb:
emu_op_fc:
emu_op_fd:			; prefix
	;; swap IY, HL

	movea.w	emu_op_undo_fd(pc),a2
emu_op_fe:
emu_op_ff:

emu_op_undo_cb:

	movea.w	emu_fetch(pc),a2
	
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:


