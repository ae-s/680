;;; z80 emulator for 68k calculators

;;; Astrid Smith
;;; Project started: 2010-06-06
;;; GPL

;;; Registers used:
;;;
;;; A7 = sp
;;; A6 = address space base pointer
;;; A3 = instruction table base pointer
;;; A2 = pseudo return address (for emulation core, to emulate prefix
;;;      instructions properly)
;;;
;;; D0,D1 = scratch
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

	;; Macro to read a byte from main memory at register \1.  Puts
	;; the byte read in \2.
FETCHB	MACRO
	move.b	(\1.w,a6),\2
	ENDM

	;; Macro to write a byte in \1 to main memory at \2 (regs only)
PUTB	MACRO
	move.b	\1,(\2,a6)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
FETCHW	MACRO
	move.b	(\1.w,a6),\2
	rol.w	8,\2
	move.b	1(\1.w,a6),\2
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
PUTW	MACRO
	move.b	\1,(\2,a6)
	ENDM

	;; Macro to read an immediate byte into \2.
FETCHBI	MACRO
	addq.w	#1,d2
	move.b	-1(d2.w,a6),\2
	ENDM

	;; Macro to read an immediate word (unaligned) into \2.
FETCHWI	MACRO
	addq.w	2,d2
	move.b	-2(d2.w,a6),\2
	rol.w	8,d2
	move.b	-1(d2.w,a6),\2
	ENDM

	;; When you want to use the high reg of a pair, use this first
LOHI	MACRO
	ror	8,\1
	ENDM

	;; Then do your shit and finish with this
HILO	MACRO
	rol	8,\1
	ENDM

DONE	MACRO
	jmp	(a2)
	ENDM



_main:
	bsr	emu_setup
	rts

emu_setup:
	eor.l	a5,a5
	eor.l	a4,a4
	movea	emu_instr_table,a3
	movea	emu_fetch(pc),a2
	;; FIXME

refresh:			; screen refresh routine
	;; FIXME
	rts

emu_fetch:
	;; Will this even work?
	move.b	(a4)+,d0
	movea	(a3,d0),a5
	jmp	a5

emu_instr_table:
	dc.w	emu_op_00
	dc.w	emu_op_01
	dc.w	emu_op_02
	dc.w	emu_op_03
	dc.w	emu_op_04
	dc.w	emu_op_05
	dc.w	emu_op_06
	dc.w	emu_op_07
	dc.w	emu_op_08
	dc.w	emu_op_09
	dc.w	emu_op_0a
	dc.w	emu_op_0b
	dc.w	emu_op_0c
	dc.w	emu_op_0d
	dc.w	emu_op_0e
	dc.w	emu_op_0f
	dc.w	emu_op_10
	dc.w	emu_op_11
	dc.w	emu_op_12
	dc.w	emu_op_13
	dc.w	emu_op_14
	dc.w	emu_op_15
	dc.w	emu_op_16
	dc.w	emu_op_17
	dc.w	emu_op_18
	dc.w	emu_op_19
	dc.w	emu_op_1a
	dc.w	emu_op_1b
	dc.w	emu_op_1c
	dc.w	emu_op_1d
	dc.w	emu_op_1e
	dc.w	emu_op_1f
	dc.w	emu_op_20
	dc.w	emu_op_21
	dc.w	emu_op_22
	dc.w	emu_op_23
	dc.w	emu_op_24
	dc.w	emu_op_25
	dc.w	emu_op_26
	dc.w	emu_op_27
	dc.w	emu_op_28
	dc.w	emu_op_29
	dc.w	emu_op_2a
	dc.w	emu_op_2b
	dc.w	emu_op_2c
	dc.w	emu_op_2d
	dc.w	emu_op_2e
	dc.w	emu_op_2f
	dc.w	emu_op_30
	dc.w	emu_op_31
	dc.w	emu_op_32
	dc.w	emu_op_33
	dc.w	emu_op_34
	dc.w	emu_op_35
	dc.w	emu_op_36
	dc.w	emu_op_37
	dc.w	emu_op_38
	dc.w	emu_op_39
	dc.w	emu_op_3a
	dc.w	emu_op_3b
	dc.w	emu_op_3c
	dc.w	emu_op_3d
	dc.w	emu_op_3e
	dc.w	emu_op_3f
	dc.w	emu_op_40
	dc.w	emu_op_41
	dc.w	emu_op_42
	dc.w	emu_op_43
	dc.w	emu_op_44
	dc.w	emu_op_45
	dc.w	emu_op_46
	dc.w	emu_op_47
	dc.w	emu_op_48
	dc.w	emu_op_49
	dc.w	emu_op_4a
	dc.w	emu_op_4b
	dc.w	emu_op_4c
	dc.w	emu_op_4d
	dc.w	emu_op_4e
	dc.w	emu_op_4f
	dc.w	emu_op_50
	dc.w	emu_op_51
	dc.w	emu_op_52
	dc.w	emu_op_53
	dc.w	emu_op_54
	dc.w	emu_op_55
	dc.w	emu_op_56
	dc.w	emu_op_57
	dc.w	emu_op_58
	dc.w	emu_op_59
	dc.w	emu_op_5a
	dc.w	emu_op_5b
	dc.w	emu_op_5c
	dc.w	emu_op_5d
	dc.w	emu_op_5e
	dc.w	emu_op_5f
	dc.w	emu_op_60
	dc.w	emu_op_61
	dc.w	emu_op_62
	dc.w	emu_op_63
	dc.w	emu_op_64
	dc.w	emu_op_65
	dc.w	emu_op_66
	dc.w	emu_op_67
	dc.w	emu_op_68
	dc.w	emu_op_69
	dc.w	emu_op_6a
	dc.w	emu_op_6b
	dc.w	emu_op_6c
	dc.w	emu_op_6d
	dc.w	emu_op_6e
	dc.w	emu_op_6f
	dc.w	emu_op_70
	dc.w	emu_op_71
	dc.w	emu_op_72
	dc.w	emu_op_73
	dc.w	emu_op_74
	dc.w	emu_op_75
	dc.w	emu_op_76
	dc.w	emu_op_77
	dc.w	emu_op_78
	dc.w	emu_op_79
	dc.w	emu_op_7a
	dc.w	emu_op_7b
	dc.w	emu_op_7c
	dc.w	emu_op_7d
	dc.w	emu_op_7e
	dc.w	emu_op_7f
	dc.w	emu_op_80
	dc.w	emu_op_81
	dc.w	emu_op_82
	dc.w	emu_op_83
	dc.w	emu_op_84
	dc.w	emu_op_85
	dc.w	emu_op_86
	dc.w	emu_op_87
	dc.w	emu_op_88
	dc.w	emu_op_89
	dc.w	emu_op_8a
	dc.w	emu_op_8b
	dc.w	emu_op_8c
	dc.w	emu_op_8d
	dc.w	emu_op_8e
	dc.w	emu_op_8f
	dc.w	emu_op_90
	dc.w	emu_op_91
	dc.w	emu_op_92
	dc.w	emu_op_93
	dc.w	emu_op_94
	dc.w	emu_op_95
	dc.w	emu_op_96
	dc.w	emu_op_97
	dc.w	emu_op_98
	dc.w	emu_op_99
	dc.w	emu_op_9a
	dc.w	emu_op_9b
	dc.w	emu_op_9c
	dc.w	emu_op_9d
	dc.w	emu_op_9e
	dc.w	emu_op_9f
	dc.w	emu_op_a0
	dc.w	emu_op_a1
	dc.w	emu_op_a2
	dc.w	emu_op_a3
	dc.w	emu_op_a4
	dc.w	emu_op_a5
	dc.w	emu_op_a6
	dc.w	emu_op_a7
	dc.w	emu_op_a8
	dc.w	emu_op_a9
	dc.w	emu_op_aa
	dc.w	emu_op_ab
	dc.w	emu_op_ac
	dc.w	emu_op_ad
	dc.w	emu_op_ae
	dc.w	emu_op_af
	dc.w	emu_op_b0
	dc.w	emu_op_b1
	dc.w	emu_op_b2
	dc.w	emu_op_b3
	dc.w	emu_op_b4
	dc.w	emu_op_b5
	dc.w	emu_op_b6
	dc.w	emu_op_b7
	dc.w	emu_op_b8
	dc.w	emu_op_b9
	dc.w	emu_op_ba
	dc.w	emu_op_bb
	dc.w	emu_op_bc
	dc.w	emu_op_bd
	dc.w	emu_op_be
	dc.w	emu_op_bf
	dc.w	emu_op_c0
	dc.w	emu_op_c1
	dc.w	emu_op_c2
	dc.w	emu_op_c3
	dc.w	emu_op_c4
	dc.w	emu_op_c5
	dc.w	emu_op_c6
	dc.w	emu_op_c7
	dc.w	emu_op_c8
	dc.w	emu_op_c9
	dc.w	emu_op_ca
	dc.w	emu_op_cb
	dc.w	emu_op_cc
	dc.w	emu_op_cd
	dc.w	emu_op_ce
	dc.w	emu_op_cf
	dc.w	emu_op_d0
	dc.w	emu_op_d1
	dc.w	emu_op_d2
	dc.w	emu_op_d3
	dc.w	emu_op_d4
	dc.w	emu_op_d5
	dc.w	emu_op_d6
	dc.w	emu_op_d7
	dc.w	emu_op_d8
	dc.w	emu_op_d9
	dc.w	emu_op_da
	dc.w	emu_op_db
	dc.w	emu_op_dc
	dc.w	emu_op_dd
	dc.w	emu_op_de
	dc.w	emu_op_df
	dc.w	emu_op_e0
	dc.w	emu_op_e1
	dc.w	emu_op_e2
	dc.w	emu_op_e3
	dc.w	emu_op_e4
	dc.w	emu_op_e5
	dc.w	emu_op_e6
	dc.w	emu_op_e7
	dc.w	emu_op_e8
	dc.w	emu_op_e9
	dc.w	emu_op_ea
	dc.w	emu_op_eb
	dc.w	emu_op_ec
	dc.w	emu_op_ed
	dc.w	emu_op_ee
	dc.w	emu_op_ef
	dc.w	emu_op_f0
	dc.w	emu_op_f1
	dc.w	emu_op_f2
	dc.w	emu_op_f3
	dc.w	emu_op_f4
	dc.w	emu_op_f5
	dc.w	emu_op_f6
	dc.w	emu_op_f7
	dc.w	emu_op_f8
	dc.w	emu_op_f9
	dc.w	emu_op_fa
	dc.w	emu_op_fb
	dc.w	emu_op_fc
	dc.w	emu_op_fd
	dc.w	emu_op_fe
	dc.w	emu_op_ff
	

;;; http://z80.info/z80oplist.txt
emu_op_00:
	;; NOP = 4
	DONE

emu_op_01:
	;; LD	BC,immed.w = 10,14
	;; Read a word and put it in BC
	;; No flags
	FETCHWI	d4
	DONE

emu_op_02:
	;; LD	(BC),A
	;; XXX Do this
	;; No flags
	DONE

emu_op_03:
	;; INC	BC
	;; BC <- BC+1
	;; No flags
	addq.w	#1,d4
	DONE

emu_op_04:
	;; INC	B
	;; B <- B+1
	;; No flags
	LOHI	d4
	addq.b	#1,d4
	HILO	d4
	DONE

emu_op_05:
	;; DEC	B
	;; B <- B-1
	;; Flags: S,Z,H changed, P=oVerflow, N set, C left
	LOHI	d4
	subq.b	#1,d4
	HILO	d4
	DONE

emu_op_06:
	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; No flags
	;; XXX Check that this does not zero the top of the register
	LOHI	d4
	FETCHBI	d4
	HILO	d4
	DONE

emu_op_07:
	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	roxl.b	d3,1
	DONE

emu_op_08:
	;; EX	AF,AF'
	;; No flags
	swap	d3
	DONE

emu_op_09:
	;; ADD	HL,BC
	;; HL <- HL+BC
	;; Flags: H, C aff.; N=0
	add.w	d4,d6
	DONE

emu_op_0a:
	;; LD	A,(BC)
	;; A <- (BC)
	;; No flags
	FETCHB	d4
	move.b	d0,d3
	DONE

emu_op_0b:
	;; DEC	BC
	;; BC <- BC-1
	;; No flags
	subq.w	#1,d4
	DONE

emu_op_0c:
	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
	addq.b	#1,d4
	DONE

emu_op_0d:
	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
	subq.b	#1,d4
	DONE

emu_op_0e:
	;; LD	C,immed.b
	;; No flags
	FETCHBI	d4
	DONE

emu_op_0f:
	;; RRCA
	;; Rotate A right, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	roxr.b	d3,1
	DONE

emu_op_10:
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	LOHI	d4
	subq.b	#1,d4
	HILO	d4
	beq	emu_op_10_end	; slooooow
	FETCHBI	d0
	add.w	d0,d2
emu_op_10_end:
	DONE

emu_op_11:
	;; LD	DE,immed.w
	;; XXX proof against alignment
	;; No flags
	FETCHWI	d5
	DONE

emu_op_12:
	;; LD	(DE),A
	;; No flags
	move.b	(a0,d5.w),d3
	DONE

emu_op_13:
	;; INC	DE
	;; No flags
	addq.w	#1,d5
	DONE

emu_op_14:
	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
	LOHI	d5
	addq.b	#1,d5
	HILO	d5
	DONE

emu_op_15:
	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d5
	subq.b	#1,d5
	HILO	d5
	DONE

emu_op_16:
	;; LD D,immed.b
	;; No flags
	LOHI	d5
	FETCHBI	d5
	HILO	d5
	DONE

emu_op_17:
	;; RLA
	;; Flags: P,N=0; C aff.
	rol.b	1,d3
	DONE

emu_op_18:
	;; JR
	;; Branch relative by a signed immediate byte
	;; No flags
	FETCHBI	d0
	add.w	d0,d2
	DONE

emu_op_19:
	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
	add.w	d5,d6
	DONE

emu_op_1a:
	;; LD	A,(DE)
	;; A <- (DE)
	;; No flags
	FETCHB	d5,d3
	DONE

emu_op_1b:
	;; DEC	DE
	;; No flags
	subq.w	#1,d5
	DONE

emu_op_1c:
	;; INC	E
	;; Flags: S,Z,H aff.; P=overflow; N=0
	addq.b	#1,d5
	DONE

emu_op_1d:
	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
	subq.b	#1,d5
	DONE

emu_op_1e:
	;; LD	E,immed.b
	;; No flags
	FETCHBI	d5
	DONE

emu_op_1f:
	;; RRA
	;; Flags: H,N=0; C aff.
	ror.b	d3
	DONE

emu_op_20:
	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	beq	emu_op_10_end
	FETCHBI	d0
	add.w	d0,d2
emu_op_10_end:
	DONE

emu_op_21:
	;; LD	HL,immed.w
	;; No flags
	FETCHWI	d6
	DONE

emu_op_22:
	;; LD	immed.w,HL
	;; (address) <- HL
	;; No flags
	FETCHWI	d0
	PUTW	d6,d0

emu_op_23:
	;; INC	HL
	;; No flags
	addq.w	#1,d6
	DONE

emu_op_24:
	;; INC	H
	;; Flags: S,Z,H aff.; P=overflow, N=0
	LOHI	d6
	addq.b	#1,d6
	HILO	d6
	DONE

emu_op_25:
	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
	LOHI	d6
	subq.b	#1,d6
	HILO	d6
	DONE

emu_op_26:
	;; LD	H,immed.b
	;; No flags
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

	DONE

emu_op_28:
	;; JR Z,immed.b
	;; If zero
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	beq	emu_op_28_end
	FETCHBI	d0
	add.w	d0,d2
emu_op_28_end:
	DONE

emu_op_29:
	;; ADD	HL,HL
	;; Flags: 
	add.w	d6,d6
	DONE

emu_op_2a:
	;; LD	HL,(immed.w)
	;; address is absolute
	FETCHWI	d0
	FETCHW	d0,d6
	DONE

emu_op_2b:
	;; DEC	HL
	subq.w	#1,d6
	DONE

emu_op_2c:
	;; INC	L
	addq.b	#1,d6
	DONE

emu_op_2d:
	;; DEC	L
	subq.b	#1,d6
	DONE

emu_op_2e:
	;; LD	L,immed.b
	FETCHBI	d6
	DONE

emu_op_2f:
	;; CPL
	;; A <- NOT A
	not.b	d3
	DONE

emu_op_30:
	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
	bcs	emu_op_30_end
	FETCHBI	d0
	add.w	d0,d2
emu_op_30_end:
	DONE

emu_op_31:
	;; LD	SP,immed.w
	swap	d2
	FETCHWI	d2
	swap	d2
	DONE

emu_op_32:
	;; LD	(immed.w),A
	;; store indirect
	FETCHWI	d0
	PUTB	d3,d0
	DONE

emu_op_33:
	;; INC	SP
	swap	d2
	addq.w	#1,d2
	swap	d2
	DONE

emu_op_34:
	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
	FETCHB	d6
	addq.b	#1,d0
	PUTB	d0,d6
	DONE

emu_op_35:
	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
	FETCHB	d6
	subq.b	#1,d0
	PUTB	d0,d6
	DONE

emu_op_36:
	;; LD	(HL),immed.b
	FETCHBI	d0
	PUTB	d6,d0
	DONE

emu_op_37:
	;; SCF
	;; Set Carry Flag
	;; XXX DO THIS
	DONE

emu_op_38:
	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
	bcc	emu_op_38_end
	FETCHBI	d0
	add.w	d0,d2
emu_op_38_end:
	DONE

emu_op_39:
	;; ADD	HL,SP
	;; HL <- HL+SP
	swap	d2
	add.w	d6,d2
	swap	d2
	DONE

emu_op_3a:
	;; LD	A,(immed.w)
	FETCHWI	d0
	FETCHB	d0,d3
	DONE

emu_op_3b:
	;; DEC	SP
	swap	d2
	subq.w	#1,d2
	swap	d2
	DONE

emu_op_3c:
	;; INC	A
	addq.b	#1,d3
	DONE

emu_op_3d:
	;; DEC	A
	subq.b	#1,d3
	DONE

emu_op_3e:
	;; LD	A,immed.b
	FETCHBI	d3
	DONE

emu_op_3f:
	;; CCF
	;; Toggle carry flag
	;; XXX DO THIS
	DONE

emu_op_40:
	;; LD	B,B
	;; SPEED
	LOHI	d4
	move.b	d4,d4
	HILO	d4
	DONE

emu_op_41:
	;; LD	B,C
	;; SPEED
	move.b	d4,d0
	LOHI	d4
	move.b	d0,d4
	HILO	d4
	DONE

emu_op_42:
	;; LD	B,D
	;; B <- D
	move.w	d5,d0
	andi.w	#ff00,d0
	andi.w	#00ff,d4
	or.w	d0,d4
	DONE

emu_op_43:
	;; LD	B,E
	;; B <- E
	move.b	d5,d0
	asl.w	#8,d0
	andi.w	#00ff,d4
	or.w	d0,d4
	DONE

emu_op_44:
	;; LD	B,H
	;; B <- H
	move.w	d6,d0
	andi.w	#ff00,d0
	andi.w	#00ff,d4
	or.w	d0,d4
	DONE

emu_op_45:
	;; LD	B,L
	;; B <- L
	move.b	d6,d0
	lsl.w	#8,d0
	or.w	d0,d4
	DONE

emu_op_46:
	;; LD	B,(HL)
	;; B <- (HL)
	HILO	d4
	FETCHB	d6,d4
	LOHI	d4
	DONE

emu_op_47:
	;; LD	B,A
	;; B <- A
	HILO	d4
	move.b	d3,d4
	LOHI	d4
	DONE

emu_op_48:
	;; LD	C,B
	;; C <- B
	move.w	d4,d0
	lsr.w	#8,d0
	move.b	d0,d4
	DONE

emu_op_49:
	;; LD	C,C
	move.b	d4,d4
	DONE

emu_op_4a:
	;; LD	C,D
	move.w	d5,d0
	lsr.w	#8,d0
	move.b	d0,d4
	DONE

emu_op_4b:
	;; LD	C,E
	move.b	d4,d5
	DONE

emu_op_4c:
	;; LD	C,H
	move.b	d4,d0
	asl	#8,d0
	and.w	#$00ff,d6
	or.w	d0,d6
	DONE

emu_op_4d:
	;; LD	C,L
	move.b	d4,d6
	DONE

emu_op_4e:
	;; LD	C,(HL)
	;; C <- (HL)
	FETCHB	d6,d4
	DONE

emu_op_4f:
	;; LD	C,A
	move.b	d3,d4
	DONE

emu_op_50:
	;; LD	D,B
	andi.w	#$00ff,d5
	move.w	d4,d0
	andi.w	#$ff00,d0
	or.w	d0,d5
	DONE

emu_op_51:
	;; LD	D,C
	andi.w	#$00ff,d5
	move.b	d4,d0
	lsl	#8,d0
	or.w	d0,d5
	DONE

emu_op_52:
	;; LD	D,D
	DONE

emu_op_53:
	;; LD	D,E
	andi.w	#$00ff,d5
	move.b	d5,d0
	lsl	#8,d0
	or.w	d0,d5
	DONE

emu_op_54:
	;; LD	D,H
	andi.w	#$00ff,d5
	move.w	d6,d0
	andi.w	#$ff00,d0
	or.w	d0,d5
	DONE

emu_op_55:
	;; LD	D,L
	andi.w	#$00ff,d5
	move.b	d6,d0
	lsl	#8,d0
	or.w	d0,d5
	DONE

emu_op_56:
	;; LD	D,(HL)
	;; D <- (HL)
	FETCHB	d6,d0
	andi.w	#$00ff,d5
	lsl	#8,d0
	or.w	d0,d5
	DONE

emu_op_57:
	;; LD	D,A
	LOHI	d5
	move.b	d3,d5
	HILO	d5
	DONE

emu_op_58:
	;; LD	E,B
	LOHI	d4
	move.b	d4,d5
	HILO	d4
	DONE

emu_op_59:
	;; LD	E,C
	move.b	d4,d5
	DONE

emu_op_5a:
	;; LD	E,D
	LOHI	d5
	move.b	d5,d0
	HILO	d5
	move.b	d0,d5
	DONE

emu_op_5b:
	;; LD	E,E
	DONE

emu_op_5c:
	;; LD	E,H
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

emu_op_5d:
	;; LD	E,L
	move.b	d5,d6
	DONE

emu_op_5e:
	;; LD	E,(HL)
	FETCHB	d6,d0
	DONE

emu_op_5f:
	;; LD	E,A
	move.b	d5,d3
	DONE

emu_op_60:
	;; LD	H,B
	move.w	d4,d0
	and.w	#$ff00,d0
	and.w	#$00ff,d3
	or.w	d0,d3
	DONE

emu_op_61:
	;; LD	H,C
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

emu_op_62:
	;; LD	H,D
	move.w	d5,d0
	and.w	#$ff00,d0
	and.w	#$00ff,d3
	or.w	d0,d3
	DONE

emu_op_63:
	;; LD	H,E
	LOHI	d6
	move.b	d5,d6
	HILO	d6
	DONE

emu_op_64:
	;; LD	H,H
	DONE

emu_op_65:
	;; LD	H,L
	;; H <- L
	move.b	d6,d0
	LOHI	d6
	move.b	d0,d6
	HILO	d6
	DONE

emu_op_66:
	;; LD	H,(HL)
	FETCHB	d6,d0
	LOHI	d6
	move.b	d0,d6
	HILO	d6
	DONE

emu_op_67:
	;; LD	H,A
	LOHI	d6
	move.b	d3,d6
	HILO	d6
	DONE

emu_op_68:
	;; LD	L,B
	LOHI	d4
	move.b	d4,d6
	HILO	d4
	DONE

emu_op_69:
	;; LD	L,C
	move.b	d4,d6
	DONE

emu_op_6a:
emu_op_6b:
emu_op_6c:
emu_op_6d:
emu_op_6e:
emu_op_6f:
emu_op_70:
emu_op_71:
emu_op_72:
emu_op_73:
emu_op_74:
emu_op_75:
emu_op_76:
emu_op_77:
emu_op_78:
emu_op_79:
emu_op_7a:
emu_op_7b:
emu_op_7c:
emu_op_7d:
emu_op_7e:
emu_op_7f:
emu_op_80:
emu_op_81:
emu_op_82:
emu_op_83:
emu_op_84:
emu_op_85:
emu_op_86:
emu_op_87:
emu_op_88:
emu_op_89:
emu_op_8a:
emu_op_8b:
emu_op_8c:
emu_op_8d:
emu_op_8e:
emu_op_8f:
emu_op_90:
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


