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

	;; Macro to read an immediate byte into \2.
FETCHBI	MACRO
	addq.w	1,d2
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
	move.b	(a4)+,d0
	jsr	d0(A3)

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
	;; NOP
	DONE

emu_op_01:
	;; LD	BC,immed.w
	;; Read a word and put it in BC
	;; XXX Check that this does not zero the top of the register
	;; XXX proof against alignment
	FETCHWI	d4
	DONE

emu_op_02:
	;; LD	BC,A
	;; Move A to BC, zero top of BC (effectively A -> C?)
	;; XXX Sign extend?
	movei.w	$0,d3
	move.b	d4,d3
	DONE

emu_op_03:
	;; INC	BC
	;; BC <- BC+1
	addq.w	1,d4
	DONE

emu_op_04:
	;; INC	B
	;; B <- B+1
	LOHI	d4
	addq.b	1,d4
	HILO	d4
	DONE

emu_op_05:
	;; DEC	B
	;; B <- B-1
	LOHI	d4
	subq.b	1,d4
	HILO	d4
	DONE

emu_op_06:
	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; XXX Check that this does not zero the top of the register
	LOHI	d4
	FETCHBI	d4
	HILO	d4
	DONE

emu_op_07:
	;; RLCA
	;; Rotate A left, carry bit gets top bit
	roxl.b	d3,1
	DONE

emu_op_08:
	;; EX	AF,AF'
	swap	d3
	DONE

emu_op_09:
	;; ADD	HL,BC
	;; HL <- HL+BC
	add.w	d4,d6
	DONE

emu_op_0a:
	;; LD	A,(BC)
	;; A <- (BC)
	FETCHB	d4
	move.b	d0,d3
	DONE

emu_op_0b:
	;; DEC	BC
	;; BC <- BC-1
	subq.w	1,d4
	DONE

emu_op_0c:
	;; INC	C
	;; C <- C+1
	addq.b	1,d4
	DONE

emu_op_0d:
	;; DEC	C
	;; C <- C-1
	subq.b	1,d4
	DONE

emu_op_0e:
	;; LD	C,immed.b
	FETCHBI	d4
	DONE

emu_op_0f:
	;; RRCA
	;; Rotate A right, carry bit gets top bit
	roxr.b	d3,1
	DONE

emu_op_10:
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	LOHI	d4
	subq.b	1,d4
	HILO	d4
	beq	emu_op_10_end	; slooooow
	FETCHBI	d0
	add.w	d0,d2
emu_op_10_end:
	DONE

emu_op_11:
	;; LD	DE,immed.w
	;; XXX proof against alignment
	FETCHWI	d5
	DONE

emu_op_12:
	;; LD	(DE),A
	move.b	(a0,d5.w),d3
	DONE

emu_op_13:
	;; INC	DE
	addq.w	1,d5
	DONE

emu_op_14:
	;; INC	D
	LOHI	d5
	addq.b	1,d5
	HILO	d5
	DONE

emu_op_15:
	;; DEC	D
	LOHI	d5
	subq.b	1,d5
	HILO	d5
	DONE

emu_op_16:
	;; LD D,immed.b
	LOHI	d5
	FETCHBI	d5
	HILO	d5
	DONE

emu_op_17:
	;; RLA
	rol.b	1,d3
	DONE

emu_op_18:
	;; JR
	;; Branch relative by a signed immediate byte
	FETCHBI	d0
	add.w	d0,d2
	DONE

emu_op_19:
	;; ADD	HL,DE
	;; HL <- HL+DE
	add.w	d5,d6
	DONE

emu_op_1a:
	;; LDAX	D
	;; A <- (DE)
	FETCHB	d5,d3
	DONE

emu_op_1b:
	;; DEC	DE
	subq.w	1,d5
	DONE

emu_op_1c:
	;; INC	E
	addq.b	1,d5
	DONE

emu_op_1d:
	;; DEC	E
	subq.b	1,d5
	DONE

emu_op_1e:
	;; LD	E,immed.b
	FETCHBI	d5
	DONE

emu_op_1f:
	;; RRA
	ror.b	d3
	DONE

emu_op_20:
	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	beq	emu_op_10_end	; slooooow
	FETCHBI	d0
	add.w	d0,d2
emu_op_10_end:
	DONE

emu_op_21:
	;; LD	HL,immed.w
	FETCHWI	d6
	DONE

emu_op_22:
	;; LD	immed.w,HL
	;; (address) <- HL
	FETCHWI	d0
	PUTW	d6,d0

emu_op_23:
	;; INC	HL
	addq.w	1,d6
	DONE

emu_op_24:
	;; INC	H
	LOHI	d6
	addq.b	1,d6
	HILO	d6
	DONE

emu_op_25:
	;; DEC	H
	LOHI	d6
	subq.b	1,d6
	HILO	d6
	DONE

emu_op_26:
	;; LD	H,immed.b
	LOHI	d6
	FETCHBI	d6
	HILO	d6
	DONE

emu_op_27:
	;; DAA
	;; Decrement, adjust accum
	;; http://www.z80.info/z80syntx.htm#DAA
	;; XXX DO THIS

	DONE

emu_op_28:
	
emu_op_29:
emu_op_2a:
emu_op_2b:
emu_op_2c:
emu_op_2d:
emu_op_2e:
emu_op_2f:
emu_op_30:
emu_op_31:
emu_op_32:
emu_op_33:
emu_op_34:
emu_op_35:
emu_op_36:
emu_op_37:
emu_op_38:
emu_op_39:
emu_op_3a:
emu_op_3b:
emu_op_3c:
emu_op_3d:
emu_op_3e:
emu_op_3f:
emu_op_40:
emu_op_41:
emu_op_42:
emu_op_43:
emu_op_44:
emu_op_45:
emu_op_46:
emu_op_47:
emu_op_48:
emu_op_49:
emu_op_4a:
emu_op_4b:
emu_op_4c:
emu_op_4d:
emu_op_4e:
emu_op_4f:
emu_op_50:
emu_op_51:
emu_op_52:
emu_op_53:
emu_op_54:
emu_op_55:
emu_op_56:
emu_op_57:
emu_op_58:
emu_op_59:
emu_op_5a:
emu_op_5b:
emu_op_5c:
emu_op_5d:
emu_op_5e:
emu_op_5f:
emu_op_60:
emu_op_61:
emu_op_62:
emu_op_63:
emu_op_64:
emu_op_65:
emu_op_66:
emu_op_67:
emu_op_68:
emu_op_69:
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

	
