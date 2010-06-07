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

	;; == Memory Macros ================================================

	;; Macro to read a byte from main memory at register \1.  Puts
	;; the byte read in \2.
FETCHB	MACRO			; 14 cycles, 4 bytes
	move.b	(\1.w,a6),\2
	ENDM

	;; Macro to write a byte in \1 to main memory at \2 (regs only)
PUTB	MACRO			; 14 cycles, 4 bytes
	move.b	\1,(\2,a6)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
FETCHW	MACRO			; 32 cycles, 10 bytes
	move.b	1(\1.w,a6),\2	; 14/4
	ror.w	#8,\2		;  4/2
	move.b	(\1.w,a6),\2	; 14/4
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
	;; XXX ALIGNMENT
PUTW	MACRO			; 14 cycles, 4 bytes
	move.b	\1,(\2,a6)
	ENDM

	;; == Immediate Memory Macros ==

	;; Macro to read an immediate byte into \2.
FETCHBI	MACRO			; 18 cycles, 6 bytes
	addq.w	#1,d2		;  4/2
	move.b	-1(d2.w,a6),\2	; 14/4
	ENDM

	;; Macro to read an immediate word (unaligned) into \2.
FETCHWI	MACRO			; 36 cycles, 12 bytes
	addq.w	#2,d2		;  4/2
	move.b	-1(d2.w,a6),\2	; 14/4
	rol.w	#8,d2		;  4/2
	move.b	-2(d2.w,a6),\2	; 14/4
	ENDM

	;; == Common Opcode Macros =========================================

	;; When you want to use the high reg of a pair, use this first
LOHI	MACRO			; 6 cycles, 2 bytes
	ror	#8,\1
	ENDM

	;; Then do your shit and finish with this
HILO	MACRO			; 6 cycles, 2 bytes
	rol	#8,\1
	ENDM

DONE	MACRO			; 8 cycles, 2 bytes
	;; calc84maniac suggests putting emu_fetch into this in order
	;; to save 8 cycles per instruction, at the expense of code
	;; size
	jmp	(a2)
	ENDM

	;; == Special Opcode Macros ========================================

	;; Set flags appropriately for an ADD \1,\2
F_ADD_B	MACRO
	;; preserve operands for flagging
	move.b	\1,add_src
	move.b	\2,add_dst
	moveq	#0,flag_n
	;; XXX do I have to use SR instead?
	move	ccr,68k_ccr
	ENDM

	;; Set flags appropriately for a SUB \1,\2
F_SUB_B	MACRO
	ENDM


;; =========================================================================
;;
;;      _ _                 _       _     
;;   __| (_)___ _ __   __ _| |_ ___| |__  
;;  / _` | / __| '_ \ / _` | __/ __| '_ \ 
;; | (_| | \__ \ |_) | (_| | || (__| | | |
;;  \__,_|_|___/ .__/ \__,_|\__\___|_| |_|
;;             |_|                        
;; 
;; =========================================================================



_main:
	bsr	emu_setup
	rts

emu_setup:
	eor.l	a5,a5
	eor.l	a4,a4
	movea	emu_instr_table,a3
	movea	emu_fetch(pc),a2
	;; XXX finish

refresh:			; screen refresh routine
	;; XXX Do this
	rts

emu_fetch:
	;; Will this even work?
	eor.w	d0,d0		; 4 cycles
	move.b	(a4)+,d0	; 8 cycles
	asl	#1,d0		; 6 cycles
	movea	(a3,d0.w),a5	;14 cycles
	jmp	(a5)		; 8 cycles
	; Total:  		 40 cycles

emu_alt_fetch:
	;; Allows me to get rid of the jump table and save cycles at
	;; the same time, but requires spacing instruction routines
	;; evenly
	eor.w	d0,d0		; 4 cycles
	move.b	(a4)+,d0	; 8 cycles
	asl	#5,d0		; 6 cycles
	jmp	(a3,d0)		;14 cycles
	;; overhead:		 32 cycles

storage:
add_src:	dc.b	0
add_dst:	dc.b	0
flag_n:		dc.b	0
68k_ccr:	dc.w	0

;;; ========================================================================
;;; ========================================================================
;;;      ___   ___                    ======= ==============================
;;;  ___( _ ) / _ \   emulation core    ====================================
;;; |_  / _ \| | | |  emulation core     ===================================
;;;  / / (_) | |_| |  emulation core      ==================================
;;; /___\___/ \___/   emulation core       =================================
;;;                                   ======= ==============================
;;; ========================================================================
;;; ========================================================================


emu_instr_table:
	dc.w	emu_op_00-emu_instr_table
	dc.w	emu_op_01-emu_instr_table
	dc.w	emu_op_02-emu_instr_table
	dc.w	emu_op_03-emu_instr_table
	dc.w	emu_op_04-emu_instr_table
	dc.w	emu_op_05-emu_instr_table
	dc.w	emu_op_06-emu_instr_table
	dc.w	emu_op_07-emu_instr_table
	dc.w	emu_op_08-emu_instr_table
	dc.w	emu_op_09-emu_instr_table
	dc.w	emu_op_0a-emu_instr_table
	dc.w	emu_op_0b-emu_instr_table
	dc.w	emu_op_0c-emu_instr_table
	dc.w	emu_op_0d-emu_instr_table
	dc.w	emu_op_0e-emu_instr_table
	dc.w	emu_op_0f-emu_instr_table
	dc.w	emu_op_10-emu_instr_table
	dc.w	emu_op_11-emu_instr_table
	dc.w	emu_op_12-emu_instr_table
	dc.w	emu_op_13-emu_instr_table
	dc.w	emu_op_14-emu_instr_table
	dc.w	emu_op_15-emu_instr_table
	dc.w	emu_op_16-emu_instr_table
	dc.w	emu_op_17-emu_instr_table
	dc.w	emu_op_18-emu_instr_table
	dc.w	emu_op_19-emu_instr_table
	dc.w	emu_op_1a-emu_instr_table
	dc.w	emu_op_1b-emu_instr_table
	dc.w	emu_op_1c-emu_instr_table
	dc.w	emu_op_1d-emu_instr_table
	dc.w	emu_op_1e-emu_instr_table
	dc.w	emu_op_1f-emu_instr_table
	dc.w	emu_op_20-emu_instr_table
	dc.w	emu_op_21-emu_instr_table
	dc.w	emu_op_22-emu_instr_table
	dc.w	emu_op_23-emu_instr_table
	dc.w	emu_op_24-emu_instr_table
	dc.w	emu_op_25-emu_instr_table
	dc.w	emu_op_26-emu_instr_table
	dc.w	emu_op_27-emu_instr_table
	dc.w	emu_op_28-emu_instr_table
	dc.w	emu_op_29-emu_instr_table
	dc.w	emu_op_2a-emu_instr_table
	dc.w	emu_op_2b-emu_instr_table
	dc.w	emu_op_2c-emu_instr_table
	dc.w	emu_op_2d-emu_instr_table
	dc.w	emu_op_2e-emu_instr_table
	dc.w	emu_op_2f-emu_instr_table
	dc.w	emu_op_30-emu_instr_table
	dc.w	emu_op_31-emu_instr_table
	dc.w	emu_op_32-emu_instr_table
	dc.w	emu_op_33-emu_instr_table
	dc.w	emu_op_34-emu_instr_table
	dc.w	emu_op_35-emu_instr_table
	dc.w	emu_op_36-emu_instr_table
	dc.w	emu_op_37-emu_instr_table
	dc.w	emu_op_38-emu_instr_table
	dc.w	emu_op_39-emu_instr_table
	dc.w	emu_op_3a-emu_instr_table
	dc.w	emu_op_3b-emu_instr_table
	dc.w	emu_op_3c-emu_instr_table
	dc.w	emu_op_3d-emu_instr_table
	dc.w	emu_op_3e-emu_instr_table
	dc.w	emu_op_3f-emu_instr_table
	dc.w	emu_op_40-emu_instr_table
	dc.w	emu_op_41-emu_instr_table
	dc.w	emu_op_42-emu_instr_table
	dc.w	emu_op_43-emu_instr_table
	dc.w	emu_op_44-emu_instr_table
	dc.w	emu_op_45-emu_instr_table
	dc.w	emu_op_46-emu_instr_table
	dc.w	emu_op_47-emu_instr_table
	dc.w	emu_op_48-emu_instr_table
	dc.w	emu_op_49-emu_instr_table
	dc.w	emu_op_4a-emu_instr_table
	dc.w	emu_op_4b-emu_instr_table
	dc.w	emu_op_4c-emu_instr_table
	dc.w	emu_op_4d-emu_instr_table
	dc.w	emu_op_4e-emu_instr_table
	dc.w	emu_op_4f-emu_instr_table
	dc.w	emu_op_50-emu_instr_table
	dc.w	emu_op_51-emu_instr_table
	dc.w	emu_op_52-emu_instr_table
	dc.w	emu_op_53-emu_instr_table
	dc.w	emu_op_54-emu_instr_table
	dc.w	emu_op_55-emu_instr_table
	dc.w	emu_op_56-emu_instr_table
	dc.w	emu_op_57-emu_instr_table
	dc.w	emu_op_58-emu_instr_table
	dc.w	emu_op_59-emu_instr_table
	dc.w	emu_op_5a-emu_instr_table
	dc.w	emu_op_5b-emu_instr_table
	dc.w	emu_op_5c-emu_instr_table
	dc.w	emu_op_5d-emu_instr_table
	dc.w	emu_op_5e-emu_instr_table
	dc.w	emu_op_5f-emu_instr_table
	dc.w	emu_op_60-emu_instr_table
	dc.w	emu_op_61-emu_instr_table
	dc.w	emu_op_62-emu_instr_table
	dc.w	emu_op_63-emu_instr_table
	dc.w	emu_op_64-emu_instr_table
	dc.w	emu_op_65-emu_instr_table
	dc.w	emu_op_66-emu_instr_table
	dc.w	emu_op_67-emu_instr_table
	dc.w	emu_op_68-emu_instr_table
	dc.w	emu_op_69-emu_instr_table
	dc.w	emu_op_6a-emu_instr_table
	dc.w	emu_op_6b-emu_instr_table
	dc.w	emu_op_6c-emu_instr_table
	dc.w	emu_op_6d-emu_instr_table
	dc.w	emu_op_6e-emu_instr_table
	dc.w	emu_op_6f-emu_instr_table
	dc.w	emu_op_70-emu_instr_table
	dc.w	emu_op_71-emu_instr_table
	dc.w	emu_op_72-emu_instr_table
	dc.w	emu_op_73-emu_instr_table
	dc.w	emu_op_74-emu_instr_table
	dc.w	emu_op_75-emu_instr_table
	dc.w	emu_op_76-emu_instr_table
	dc.w	emu_op_77-emu_instr_table
	dc.w	emu_op_78-emu_instr_table
	dc.w	emu_op_79-emu_instr_table
	dc.w	emu_op_7a-emu_instr_table
	dc.w	emu_op_7b-emu_instr_table
	dc.w	emu_op_7c-emu_instr_table
	dc.w	emu_op_7d-emu_instr_table
	dc.w	emu_op_7e-emu_instr_table
	dc.w	emu_op_7f-emu_instr_table
	dc.w	emu_op_80-emu_instr_table
	dc.w	emu_op_81-emu_instr_table
	dc.w	emu_op_82-emu_instr_table
	dc.w	emu_op_83-emu_instr_table
	dc.w	emu_op_84-emu_instr_table
	dc.w	emu_op_85-emu_instr_table
	dc.w	emu_op_86-emu_instr_table
	dc.w	emu_op_87-emu_instr_table
	dc.w	emu_op_88-emu_instr_table
	dc.w	emu_op_89-emu_instr_table
	dc.w	emu_op_8a-emu_instr_table
	dc.w	emu_op_8b-emu_instr_table
	dc.w	emu_op_8c-emu_instr_table
	dc.w	emu_op_8d-emu_instr_table
	dc.w	emu_op_8e-emu_instr_table
	dc.w	emu_op_8f-emu_instr_table
	dc.w	emu_op_90-emu_instr_table
	dc.w	emu_op_91-emu_instr_table
	dc.w	emu_op_92-emu_instr_table
	dc.w	emu_op_93-emu_instr_table
	dc.w	emu_op_94-emu_instr_table
	dc.w	emu_op_95-emu_instr_table
	dc.w	emu_op_96-emu_instr_table
	dc.w	emu_op_97-emu_instr_table
	dc.w	emu_op_98-emu_instr_table
	dc.w	emu_op_99-emu_instr_table
	dc.w	emu_op_9a-emu_instr_table
	dc.w	emu_op_9b-emu_instr_table
	dc.w	emu_op_9c-emu_instr_table
	dc.w	emu_op_9d-emu_instr_table
	dc.w	emu_op_9e-emu_instr_table
	dc.w	emu_op_9f-emu_instr_table
	dc.w	emu_op_a0-emu_instr_table
	dc.w	emu_op_a1-emu_instr_table
	dc.w	emu_op_a2-emu_instr_table
	dc.w	emu_op_a3-emu_instr_table
	dc.w	emu_op_a4-emu_instr_table
	dc.w	emu_op_a5-emu_instr_table
	dc.w	emu_op_a6-emu_instr_table
	dc.w	emu_op_a7-emu_instr_table
	dc.w	emu_op_a8-emu_instr_table
	dc.w	emu_op_a9-emu_instr_table
	dc.w	emu_op_aa-emu_instr_table
	dc.w	emu_op_ab-emu_instr_table
	dc.w	emu_op_ac-emu_instr_table
	dc.w	emu_op_ad-emu_instr_table
	dc.w	emu_op_ae-emu_instr_table
	dc.w	emu_op_af-emu_instr_table
	dc.w	emu_op_b0-emu_instr_table
	dc.w	emu_op_b1-emu_instr_table
	dc.w	emu_op_b2-emu_instr_table
	dc.w	emu_op_b3-emu_instr_table
	dc.w	emu_op_b4-emu_instr_table
	dc.w	emu_op_b5-emu_instr_table
	dc.w	emu_op_b6-emu_instr_table
	dc.w	emu_op_b7-emu_instr_table
	dc.w	emu_op_b8-emu_instr_table
	dc.w	emu_op_b9-emu_instr_table
	dc.w	emu_op_ba-emu_instr_table
	dc.w	emu_op_bb-emu_instr_table
	dc.w	emu_op_bc-emu_instr_table
	dc.w	emu_op_bd-emu_instr_table
	dc.w	emu_op_be-emu_instr_table
	dc.w	emu_op_bf-emu_instr_table
	dc.w	emu_op_c0-emu_instr_table
	dc.w	emu_op_c1-emu_instr_table
	dc.w	emu_op_c2-emu_instr_table
	dc.w	emu_op_c3-emu_instr_table
	dc.w	emu_op_c4-emu_instr_table
	dc.w	emu_op_c5-emu_instr_table
	dc.w	emu_op_c6-emu_instr_table
	dc.w	emu_op_c7-emu_instr_table
	dc.w	emu_op_c8-emu_instr_table
	dc.w	emu_op_c9-emu_instr_table
	dc.w	emu_op_ca-emu_instr_table
	dc.w	emu_op_cb-emu_instr_table
	dc.w	emu_op_cc-emu_instr_table
	dc.w	emu_op_cd-emu_instr_table
	dc.w	emu_op_ce-emu_instr_table
	dc.w	emu_op_cf-emu_instr_table
	dc.w	emu_op_d0-emu_instr_table
	dc.w	emu_op_d1-emu_instr_table
	dc.w	emu_op_d2-emu_instr_table
	dc.w	emu_op_d3-emu_instr_table
	dc.w	emu_op_d4-emu_instr_table
	dc.w	emu_op_d5-emu_instr_table
	dc.w	emu_op_d6-emu_instr_table
	dc.w	emu_op_d7-emu_instr_table
	dc.w	emu_op_d8-emu_instr_table
	dc.w	emu_op_d9-emu_instr_table
	dc.w	emu_op_da-emu_instr_table
	dc.w	emu_op_db-emu_instr_table
	dc.w	emu_op_dc-emu_instr_table
	dc.w	emu_op_dd-emu_instr_table
	dc.w	emu_op_de-emu_instr_table
	dc.w	emu_op_df-emu_instr_table
	dc.w	emu_op_e0-emu_instr_table
	dc.w	emu_op_e1-emu_instr_table
	dc.w	emu_op_e2-emu_instr_table
	dc.w	emu_op_e3-emu_instr_table
	dc.w	emu_op_e4-emu_instr_table
	dc.w	emu_op_e5-emu_instr_table
	dc.w	emu_op_e6-emu_instr_table
	dc.w	emu_op_e7-emu_instr_table
	dc.w	emu_op_e8-emu_instr_table
	dc.w	emu_op_e9-emu_instr_table
	dc.w	emu_op_ea-emu_instr_table
	dc.w	emu_op_eb-emu_instr_table
	dc.w	emu_op_ec-emu_instr_table
	dc.w	emu_op_ed-emu_instr_table
	dc.w	emu_op_ee-emu_instr_table
	dc.w	emu_op_ef-emu_instr_table
	dc.w	emu_op_f0-emu_instr_table
	dc.w	emu_op_f1-emu_instr_table
	dc.w	emu_op_f2-emu_instr_table
	dc.w	emu_op_f3-emu_instr_table
	dc.w	emu_op_f4-emu_instr_table
	dc.w	emu_op_f5-emu_instr_table
	dc.w	emu_op_f6-emu_instr_table
	dc.w	emu_op_f7-emu_instr_table
	dc.w	emu_op_f8-emu_instr_table
	dc.w	emu_op_f9-emu_instr_table
	dc.w	emu_op_fa-emu_instr_table
	dc.w	emu_op_fb-emu_instr_table
	dc.w	emu_op_fc-emu_instr_table
	dc.w	emu_op_fd-emu_instr_table
	dc.w	emu_op_fe-emu_instr_table
	dc.w	emu_op_ff-emu_instr_table


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
	;; No flags ?
	add.w	#$0100,d4	; 8
	DONE			; 8
				;16 cycles

emu_op_05:
	;; DEC	B
	;; B <- B-1
	;; Flags: S,Z,H changed, P=oVerflow, N set, C left
	sub.w	#$0100,d4
	DONE

emu_op_06:
	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; No flags
	LOHI	d4
	FETCHBI	d4
	HILO	d4
	DONE

emu_op_07:
	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	rol.b	d3,1
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
	ror.b	d3,1
	DONE

emu_op_10:
	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	LOHI	d4
	subq.b	#1,d4
	beq	emu_op_10_end	; slooooow
	FETCHBI	d0
	add.w	d0,d2
emu_op_10_end:
	HILO	d4
	DONE

emu_op_11:
	;; LD	DE,immed.w
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
	roxl.b	1,d3
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
	roxr.b	d3
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
	;; XXX This might be done by adding $100
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
	;; XXX this might be done by subtracting $100
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
	LOHI	d4		; 4
	LOHI	d5		; 4
	move.b	d5,d4		; 4
	HILO	d4		; 4
	HILO	d5		; 4
	DONE			; 8
				;28 cycles

emu_op_43:
	;; LD	B,E
	;; B <- E
	LOHI	d4		; 4
	move.b	d4,d5		; 4
	HILO	d4		; 4
	DONE 			; 8
				; 20 cycles

emu_op_44:
	;; LD	B,H
	;; B <- H
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

emu_op_45:
	;; LD	B,L
	;; B <- L
	LOHI	d4
	move.b	d6,d4
	HILO	d4
	DONE

emu_op_46:
	;; LD	B,(HL)
	;; B <- (HL)
	LOHI	d4
	FETCHB	d6,d4
	HILO	d4
	DONE

emu_op_47:
	;; LD	B,A
	;; B <- A
	LOHI	d4
	move.b	d3,d4
	HILO	d4
	DONE

emu_op_48:
	;; LD	C,B
	;; C <- B
	move.w	d4,d0		; 4
	lsr.w	#8,d0		; 6
	move.b	d0,d4		; 4
	DONE			; 8
				;22 cycles
emu_op_49:
	;; LD	C,C
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
	LOHI	d6
	move.b	d4,d6
	HILO	d6
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
	LOHI	d4
	LOHI	d5
	move.b	d4,d5
	HILO	d4
	HILO	d5
	DONE

emu_op_51:
	;; LD	D,C
	LOHI	d5
	move.b	d4,d5
	HILO	d5
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
	LOHI	d5		; 4
	LOHI	d6		; 4
	move.b	d6,d5		; 4
	HILO	d5		; 4
	HILO	d6		; 4
	DONE			; 8
				;28 cycles

emu_op_55:
	;; LD	D,L
	LOHI	d5
	move.b	d6,d5
	HILO	d5
	DONE

emu_op_56:
	;; LD	D,(HL)
	;; D <- (HL)
	LOHI	d5
	FETCHB	d6,d5
	HILO	d5
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

	;; Is this faster or slower?

	andi.w	#$ff00,d5
	move.b	d5,d0
	lsr	#8,d0
	or.w	d0,d5
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
	LOHI	d4
	LOHI	d6
	move.b	d6,d4
	HILO	d4
	HILO	d6
	DONE

emu_op_61:
	;; LD	H,C
	LOHI	d6
	move.b	d4,d6
	HILO	d6
	DONE

emu_op_62:
	;; LD	H,D
	LOHI	d5
	LOHI	d6
	move.b	d5,d6
	HILO	d5
	HILO	d6
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
	;; LD	L,D
	LOHI	d5
	move.b	d5,d6
	HILO	d5
	DONE

emu_op_6b:
	;; LD	L,E
	move.b	d5,d6
	DONE

emu_op_6c:
	;; LD	L,H
	LOHI	d6
	move.b	d6,d0
	HILO	d6
	move.b	d0,d6
	DONE

emu_op_6d:
	;; LD	L,L
	DONE

emu_op_6e:
	;; LD	L,(HL)
	;; L <- (HL)
	FETCHB	d6,d6
	DONE

emu_op_6f:
	;; LD	L,A
	move.b	d3,d6
	DONE

emu_op_70:
	;; LD	(HL),B
	LOHI	d4
	PUTB	d6,d4
	HILO	d4
	DONE

emu_op_71:
	;; LD	(HL),C
	PUTB	d6,d4
	DONE

emu_op_72:
	;; LD	(HL),D
	LOHI	d5
	PUTB	d6,d5
	HILO	d5
	DONE

emu_op_73:
	;; LD	(HL),E
	PUTB	d6,d5
	DONE

emu_op_74:
	;; LD	(HL),H
	move.w	d6,d0
	HILO	d0
	PUTB	d0,d6
	DONE

emu_op_75:
	;; LD	(HL),L
	move.b	d6,d0
	PUTB	d0,d6
	DONE

emu_op_76:
	;; HALT
	;; XXX do this
	DONE

emu_op_77:
	;; LD	(HL),A
	PUTB	d3,d6
	DONE

emu_op_78:
	;; LD	A,B
	move.w	d4,d0
	LOHI	d0
	move.b	d0,d3
	DONE

emu_op_79:
	;; LD	A,C
	move.b	d4,d3
	DONE

emu_op_7a:
	;; LD	A,D
	move.w	d5,d0
	LOHI	d0
	move.b	d0,d3
	DONE

emu_op_7b:
	;; LD	A,E
	move.b	d5,d3
	DONE

emu_op_7c:
	;; LD	A,H
	move.w	d6,d0
	LOHI	d0
	move.b	d0,d3
	DONE

emu_op_7d:
	;; LD	A,L
	move.b	d6,d3
	DONE

emu_op_7e:
	;; LD	A,(HL)
	;; A <- (HL)
	FETCHB	d6,d3
	DONE

emu_op_7f:
	;; LD	A,A
	DONE

emu_op_80:
	;; ADD	A,B
	LOHI	d4
	F_ADD_B	d4,d3
	add.b	d4,d3
	HILO	d4
	DONE

emu_op_81:
	;; ADD	A,C
	F_ADD_B	d4,d3
	add.b	d4,d3
	DONE

emu_op_82:
	;; ADD	A,D
	LOHI	d5
	F_ADD_B	d5,d3
	add.b	d5,d3
	HILO	d5
	DONE

emu_op_83:
	;; ADD	A,E
	F_ADD_B	d5,d3
	add.b	d5,d3
	DONE

emu_op_84:
	;; ADD	A,H
	LOHI	d6
	F_ADD_B	d6,d3
	add.b	d6,d3
	HILO	d6
	DONE

emu_op_85:
	;; ADD	A,L
	F_ADD_B	d6,d3
	add.b	d6,d3
	DONE

emu_op_86:
	;; ADD	A,(HL)

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


