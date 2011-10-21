;;; == -*- asm -*- =========================================================
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

	;; == Memory Macros ================================================

	;; Macro to read a byte from main memory at register \1.  Puts
	;; the byte read in \2.
FETCHB	MACRO			; 106 cycles, 8 bytes
	move.w	\1,d1
	jsr	deref
	move.b	(a0),\2
	ENDM

	;; Macro to write a byte in \1 to main memory at \2
PUTB	MACRO			; 106 cycles, 8 bytes
	move.w	\2,d1
	jsr	deref
	move.b	\1,(a0)
	ENDM

	;; Macro to read a word from main memory at register \1
	;; (unaligned).  Puts the word read in \2.
FETCHW	MACRO			; 140 cycles, 16 bytes
	move.w	\1,d1
	jsr	deref
	;; XXX SPEED
	move.b	(a0)+,d2
	move.b	(a0),\2
	rol.w	#8,\2
	move.b	d2,\2
	ENDM

	;; Macro to write a word in \1 to main memory at \2 (regs only)
PUTW	MACRO			; 140 cycles, 14 bytes
	move.w	\2,d1
	jsr	deref
	move.w	\1,d0
	move.b	d0,(a0)+
	LOHI	d0
	move.b	d0,(a0)
	ENDM

	;; Push the word in \1 (register) using stack register esp.
	;; Sadly, I can't trust the stack register to be aligned.
	;; Destroys d2.

	;;   (SP-2) <- \1_l
	;;   (SP-1) <- \1_h
	;;   SP <- SP - 2
PUSHW	MACRO			; 42 cycles, 8 bytes
	move.w	\1,d2
	LOHI	d2		;slow
	move.b	d2,-(esp)	; high byte
	move.b	\1,-(esp)	; low byte
	ENDM

	;; Pop the word at the top of stack esp into \1.
	;; Destroys d0.

	;;   \1_h <- (SP+1)
	;;   \1_l <- (SP)
	;;   SP <- SP + 2
POPW	MACRO			; 60 cycles, 8 bytes
	move.b	(esp)+,\1
	LOHI	\1
	move.b	(esp)+,\1	; high byte
	HILO	\1
	ENDM

	;; == Immediate Memory Macros ==

	;; Macro to read an immediate byte into \1.
FETCHBI	MACRO			; 8 cycles, 2 bytes
	move.b	(epc)+,\1
	ENDM

	;; Macro to read an immediate word (unaligned) into \1.
FETCHWI	MACRO			; 42 cycles, 8 bytes
	;; XXX SPEED
	move.b	(epc)+,d2
	move.b	(epc)+,\1
	rol.w	#8,\1
	move.b	d2,\1
	ENDM

	;; == Common Opcode Macros =========================================

	;; To align opcode routines.
_align	SET	0

START	MACRO
	ORG	emu_plain_op+_align
_align	SET	_align+$100	; opcode routine length
	jmp	do_interrupt	; for interrupt routines
	ENDM

START_DD	MACRO
	ORG	emu_plain_op+_align+$40
	ENDM

START_CB	MACRO
	ORG	emu_plain_op+_align+$42
	ENDM

START_DDCB	MACRO
	ORG	emu_plain_op+_align+$44
	ENDM

START_FD	MACRO
	ORG	emu_plain_op+_align+$46
	ENDM

START_FDCB	MACRO
	ORG	emu_plain_op+_align+$48
	ENDM

START_ED	MACRO
	ORG	emu_plain_op+_align+$4A
	ENDM

	;; LOHI/HILO are hideously slow for instructions used often.
	;; Consider interleaving registers instead:
	;;
	;; d4 = [B' B  C' C]
	;;
	;; Thus access to B is fast (swap d4) while access to BC is
	;; slow.

	;; When you want to use the high reg of a pair, use this first
LOHI	MACRO			; 22 cycles, 2 bytes
	ror.w	#8,\1
	ENDM

	;; Then do your shit and finish with this
HILO	MACRO			; 22 cycles, 2 bytes
	rol.w	#8,\1
	ENDM

	;; Rearrange a register: ABCD -> ACBD.
WORD	MACRO		  	; 52 cycles, 14 bytes
	move.l	\1,-(sp)
	movep.w	0(sp),\1
	swap	\1
	movep.w	1(sp),\1
	addq	#4,sp
	ENDM

	;; == Special Opcode Macros ========================================

	;; Do an ADD \1,\2
F_ADD_W	MACRO			; ? cycles, ? bytes
	;; XXX
	ENDM
	;; Do an SUB \1,\2
F_SUB_W	MACRO			; ? cycles, ? bytes
	;; XXX
	ENDM

	;; INC and DEC macros
F_INC_B	MACRO			; 108 cycles, 34 bytes
	move.b	#1,f_tmp_byte-flag_storage(a3)
	move.b	#1,f_tmp_src_b-flag_storage(a3)
	move.b	\1,f_tmp_dst_b-flag_storage(a3)
	addq	#1,\1
	moveq	#2,d0
	F_CLEAR	d0
	F_OVFL
	ENDM

F_DEC_B	MACRO			; 80 cycles, 26 bytes
	move.b	#1,f_tmp_byte-flag_storage(a3)
	st	f_tmp_src_b-flag_storage(a3) ;; why did I do this?
	move.b	\1,f_tmp_dst_b-flag_storage(a3)
	subq	#1,\1
	F_SET	#2
	ENDM

F_INC_W	MACRO			; 4 cycles, 2 bytes
	addq.w	#1,\1
	ENDM

F_DEC_W	MACRO			; 4 cycles, 2 bytes
	subq.w	#1,\1
	ENDM

	;; I might be able to unify rotation flags or maybe use a
	;; lookup table


	;; This is run at the end of every instruction routine.
done:
	clr.w	d0		; 4 cycles / 2 bytes
	move.b	(epc)+,d0	; 8 cycles / 2 bytes
	move.b	d0,$4c00+32*(128/8)
	rol.w	#6,d0		;18 cycles / 2 bytes
	jmp	0(a5,d0.w)	;14 cycles / 4 bytes
	;; overhead:		 42 cycles /10 bytes


DONE	MACRO
	clr.w	d0		; 4 cycles / 2 bytes
	move.b	(epc)+,d0	; 8 cycles / 2 bytes
	move.b	d0,$4c00+32*(128/8)
	rol.w	#6,d0		;18 cycles / 2 bytes
	jmp	0(a5,d0.w)	;14 cycles / 4 bytes
	ENDM

	;; Timing correction for more precise emulation
	;;
	;; \1 is number of tstates the current instruction should take
	;; \2 is number of cycles taken already
TIME	MACRO
	ENDM

	CNOP	0,32

emu_plain_op:			; Size(bytes) Time(cycles)
				; S0 T0

	;; I would like to thank the State of Washington for
	;; supporting the initial development of this file, by giving
	;; me a job doing nothing with no oversight for hours at a
	;; time.

	;; NOP
OPCODE(00,«»,4)

	;;
OP_DD(00,«»)

	;; RLC	B
OP_CB(00,«»)

	;;
OP_DDCB(00,«»)

	;;
OP_FD(00,«»)

	;;
OP_FDCB(00,«»)

	;;
OP_ED(00,«»)

	;; LD	BC,immed.w
	;; Read a word and put it in BC
	;; No flags
	;; 42 cycles
OPCODE(01,«
	FETCHWI	ebc
	»,36,,12)

OP_DD(01,«»)
OP_CB(01,«»)
OP_DDCB(01,«»)
OP_FD(01,«»)
OP_FDCB(01,«»)
OP_ED(01,«»)


	;; LD	(BC),A
	;; (BC) <- A
	;; No flags
	;; 106 cycles
OPCODE(02,«
	PUTB	eaf,ebc
	»,14,,4)

OP_DD(02,«»)
OP_CB(02,«»)
OP_DDCB(02,«»)
OP_FD(02,«»)
OP_FDCB(02,«»)
OP_ED(02,«»)

	;; INC	BC
	;; BC <- BC+1
	;; No flags
	;; 4 cycles
OPCODE(03,«
	F_INC_W	ebc
	»,4,,2)

OP_DD(03,«»)
OP_CB(03,«»)
OP_DDCB(03,«»)
OP_FD(03,«»)
OP_FDCB(03,«»)
OP_ED(03,«»)

	;; INC	B
	;; B <- B+1
	;; 152 cycles
OPCODE(04,«
	LOHI	ebc
	F_INC_B	ebc
	HILO	ebc
	»)

OP_DD(04,«»)
OP_CB(04,«»)
OP_DDCB(04,«»)
OP_FD(04,«»)
OP_FDCB(04,«»)
OP_ED(04,«»)

	;; DEC	B
	;; B <- B-1
	;; 124 cycles
OPCODE(05,«
	LOHI	ebc
	F_DEC_B	ebc
	HILO	ebc
	»)
				;nok

OP_DD(05,«»)
OP_CB(05,«»)
OP_DDCB(05,«»)
OP_FD(05,«»)
OP_FDCB(05,«»)
OP_ED(05,«»)

	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; B <- immed.b
	;; No flags
	;; 52 cycles
OPCODE(06,«
	LOHI	ebc
	FETCHBI	ebc
	HILO	ebc
	»,26,,10)
				;nok

OP_DD(06,«»)
OP_CB(06,«»)
OP_DDCB(06,«»)
OP_FD(06,«»)
OP_FDCB(06,«»)
OP_ED(06,«»)

	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX flags
	;; ? cycles
OPCODE(07,«
	rol.b	#1,eaf
	»,4,,2)
				;nok

OP_DD(07,«»)
OP_CB(07,«»)
OP_DDCB(07,«»)
OP_FD(07,«»)
OP_FDCB(07,«»)
OP_ED(07,«»)

	;; EX	AF,AF'
	;; No flags
	;; XXX AF
	;; 4 cycles, 2 bytes
OPCODE(08,«
	swap	eaf
	»,4,,2)
				;nok

OP_DD(08,«»)
OP_CB(08,«»)
OP_DDCB(08,«»)
OP_FD(08,«»)
OP_FDCB(08,«»)
OP_ED(08,«»)

	;; ADD	HL,BC
	;; HL <- HL+BC
	;; Flags: H, C aff.; N=0
	;; ? cycles
OPCODE(09,«
	F_ADD_W	ebc,ehl
	»)
				;nok

OP_DD(09,«»)
OP_CB(09,«»)
OP_DDCB(09,«»)
OP_FD(09,«»)
OP_FDCB(09,«»)
OP_ED(09,«»)

	;; LD	A,(BC)
	;; A <- (BC)
	;; No flags
	;; 106 cycles, 8 bytes
OPCODE(0a,«
	FETCHB	ebc,eaf
	»,14,,4)

OP_DD(0a,«»)
OP_CB(0a,«»)
OP_DDCB(0a,«»)
OP_FD(0a,«»)
OP_FDCB(0a,«»)
OP_ED(0a,«»)

	;; DEC	BC
	;; BC <- BC-1
	;; No flags
	;; 4 cycles, 2 bytes
OPCODE(0b,«
	F_DEC_W	ebc
	»,4,,2)
				;nok

OP_DD(0b,«»)
OP_CB(0b,«»)
OP_DDCB(0b,«»)
OP_FD(0b,«»)
OP_FDCB(0b,«»)
OP_ED(0b,«»)

	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
	;; 108 cycles, 34 bytes
OPCODE(0c,«
	F_INC_B	ebc
	»)
				;nok

OP_DD(0c,«»)
OP_CB(0c,«»)
OP_DDCB(0c,«»)
OP_FD(0c,«»)
OP_FDCB(0c,«»)
OP_ED(0c,«»)

	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
	;; 80 cycles, 26 bytes
OPCODE(0d,«
	F_DEC_B	ebc
	»)
				;nok

OP_DD(0d,«»)
OP_CB(0d,«»)
OP_DDCB(0d,«»)
OP_FD(0d,«»)
OP_FDCB(0d,«»)
OP_ED(0d,«»)

	;; LD	C,immed.b
	;; C <- immed.b
	;; No flags
	;; 8 cycles, 2 bytes
OPCODE(0e,«
	FETCHBI	ebc
	»,18,,6)
				;nok

OP_DD(0e,«»)
OP_CB(0e,«»)
OP_DDCB(0e,«»)
OP_FD(0e,«»)
OP_FDCB(0e,«»)
OP_ED(0e,«»)

	;; RRCA
	;; Rotate A right, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
	;; ? cycles
OPCODE(0f,«
	ror.b	#1,eaf
	»)
				;nok

OP_DD(0f,«»)
OP_CB(0f,«»)
OP_DDCB(0f,«»)
OP_FD(0f,«»)
OP_FDCB(0f,«»)
OP_ED(0f,«»)

	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
	;; 24 bytes
	;; take: 22+4+ 8+8+4+8+22 = 76
	;; skip: 22+4+10+      22 = 58
OPCODE(10,«
	LOHI	ebc
	subq.b	#1,ebc
	beq.s	local(end)	; slooooow
	FETCHBI	d1
	ext.w	d1
	add.w	d1,epc
local(end):
	HILO	ebc
	»,,,32)
				;nok

OP_DD(10,«»)
OP_CB(10,«»)
OP_DDCB(10,«»)
OP_FD(10,«»)
OP_FDCB(10,«»)
OP_ED(10,«»)

	;; LD	DE,immed.w
	;; DE <- immed.w
	;; No flags
	;; 42 cycles, 8 bytes
OPCODE(11,«
	FETCHWI	ede
	»)
				;nok

OP_DD(11,«»)
OP_CB(11,«»)
OP_DDCB(11,«»)
OP_FD(11,«»)
OP_FDCB(11,«»)
OP_ED(11,«»)

	;; LD	(DE),A
	;; (DE) <- A
	;; No flags
	;; 106 cycles, 8 bytes
OPCODE(12,«
	PUTB	eaf,ede
	»)
				;nok

OP_DD(12,«»)
OP_CB(12,«»)
OP_DDCB(12,«»)
OP_FD(12,«»)
OP_FDCB(12,«»)
OP_ED(12,«»)

	;; INC	DE
	;; No flags
	;; 4 cycles, 2 bytes
OPCODE(13,«
	F_INC_W	ede
	»)
				;nok

OP_DD(13,«»)
OP_CB(13,«»)
OP_DDCB(13,«»)
OP_FD(13,«»)
OP_FDCB(13,«»)
OP_ED(13,«»)

	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
	;; 152 cycles
OPCODE(14,«
	LOHI	ede
	F_INC_B	ede
	HILO	ede
	»)
				;nok

OP_DD(14,«»)
OP_CB(14,«»)
OP_DDCB(14,«»)
OP_FD(14,«»)
OP_FDCB(14,«»)
OP_ED(14,«»)

	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
	;; 124 cycles
OPCODE(15,«
	LOHI	ede
	F_DEC_B	ede
	HILO	ede
	»)
				;nok

OP_DD(15,«»)
OP_CB(15,«»)
OP_DDCB(15,«»)
OP_FD(15,«»)
OP_FDCB(15,«»)
OP_ED(15,«»)

	;; LD	D,immed.b
	;; No flags
	;; 52 cycles
OPCODE(16,«
	LOHI	ede
	FETCHBI	ede
	HILO	ede
	»)
				;nok

OP_DD(16,«»)
OP_CB(16,«»)
OP_DDCB(16,«»)
OP_FD(16,«»)
OP_FDCB(16,«»)
OP_ED(16,«»)

	;; RLA
	;; Flags: P,N=0; C aff.
	;; XXX flags
	;; ? cycles
OPCODE(17,«
	roxl.b	#1,eaf
	»)
				;nok

OP_DD(17,«»)
OP_CB(17,«»)
OP_DDCB(17,«»)
OP_FD(17,«»)
OP_FDCB(17,«»)
OP_ED(17,«»)

	;; JR	immed.b
	;; PC <- immed.b
	;; Branch relative by a signed immediate byte
	;; No flags
	;; 20 cycles

	;; XXX
	;; Yes, I can avoid the underef/deref cycle.  To do so, put a
	;; sled of emulator trap instructions on either side of each
	;; 16k page.  When that trap is executed, undo the shortcut
	;; and redo it by the book.

OPCODE(18,«
	clr.w	d1
	FETCHBI	d1
	add.w	d1,epc
	»)
				;nok

OP_DD(18,«»)
OP_CB(18,«»)
OP_DDCB(18,«»)
OP_FD(18,«»)
OP_FDCB(18,«»)
OP_ED(18,«»)

	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
	;; ? cycles
OPCODE(19,«
	F_ADD_W	ede,ehl
	»)
				;nok

OP_DD(19,«»)
OP_CB(19,«»)
OP_DDCB(19,«»)
OP_FD(19,«»)
OP_FDCB(19,«»)
OP_ED(19,«»)

	;; LD	A,(DE)
	;; A <- (DE)
	;; No flags
	;; 106 cycles, 8 bytes
OPCODE(1a,«
	FETCHB	ede,eaf
	»)
				;nok

OP_DD(1a,«»)
OP_CB(1a,«»)
OP_DDCB(1a,«»)
OP_FD(1a,«»)
OP_FDCB(1a,«»)
OP_ED(1a,«»)

	;; DEC	DE
	;; No flags
	;; 4 cycles, 2 bytes
OPCODE(1b,«
	subq.w	#1,ede
	»)
				;nok

OP_DD(1b,«»)
OP_CB(1b,«»)
OP_DDCB(1b,«»)
OP_FD(1b,«»)
OP_FDCB(1b,«»)
OP_ED(1b,«»)

	;; INC	E
	;; Flags: S,Z,H aff.; P=overflow; N=0
	;; 108 cycles, 34 bytes
OPCODE(1c,«
	F_INC_B	ede
	»)
				;nok

OP_DD(1c,«»)
OP_CB(1c,«»)
OP_DDCB(1c,«»)
OP_FD(1c,«»)
OP_FDCB(1c,«»)
OP_ED(1c,«»)

	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
	;; 80 cycles, 26 bytes
OPCODE(1d,«
	F_DEC_B	ede
	»)
				;nok

OP_DD(1d,«»)
OP_CB(1d,«»)
OP_DDCB(1d,«»)
OP_FD(1d,«»)
OP_FDCB(1d,«»)
OP_ED(1d,«»)

	;; LD	E,immed.b
	;; No flags
	;; 8 cycles, 2 bytes
OPCODE(1e,«
	FETCHBI	ede
	»)
				;nok

OP_DD(1e,«»)
OP_CB(1e,«»)
OP_DDCB(1e,«»)
OP_FD(1e,«»)
OP_FDCB(1e,«»)
OP_ED(1e,«»)

	;; RRA
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
	;; ? cycles
OPCODE(1f,«
	roxr.b	#1,eaf
	»)
				;nok

OP_DD(1f,«»)
OP_CB(1f,«»)
OP_DDCB(1f,«»)
OP_FD(1f,«»)
OP_FDCB(1f,«»)
OP_ED(1f,«»)

	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	;; No flags
	;; 10 bytes
	;; take: 40+10+20(=JR immed.b) = 70
	;; skip: 40+12+12              = 64
OPCODE(20,«
	jsr	f_norm_z
	;; if the emulated Z flag is set, this will be clear
	beq	emu_op_18	; branch taken: Z reset -> eq (zero set)
	add.l	#1,epc		; skip over the immediate byte
	»)

OP_DD(20,«»)
OP_CB(20,«»)
OP_DDCB(20,«»)
OP_FD(20,«»)
OP_FDCB(20,«»)
OP_ED(20,«»)

	;; LD	HL,immed.w
	;; No flags
	;; 42 cycles
OPCODE(21,«
	FETCHWI	ehl
	»)
				;nok

OP_DD(21,«»)
OP_CB(21,«»)
OP_DDCB(21,«»)
OP_FD(21,«»)
OP_FDCB(21,«»)
OP_ED(21,«»)

	;; LD	immed.w,HL
	;; (address) <- HL
	;; No flags
	;; 182 cycles
OPCODE(22,«
	FETCHWI	d1
	PUTW	ehl,d1
	»)
				;nok

OP_DD(22,«»)
OP_CB(22,«»)
OP_DDCB(22,«»)
OP_FD(22,«»)
OP_FDCB(22,«»)
OP_ED(22,«»)

	;; INC	HL
	;; No flags
	;; 4 cycles
OPCODE(23,«
	addq.w	#1,ehl
	»)
				;nok

OP_DD(23,«»)
OP_CB(23,«»)
OP_DDCB(23,«»)
OP_FD(23,«»)
OP_FDCB(23,«»)
OP_ED(23,«»)

	;; INC	H
	;; Flags: S,Z,H aff.; P=overflow, N=0
	;; 152 cycles
OPCODE(24,«
	LOHI	ehl
	F_INC_B	ehl
	HILO	ehl
	»)
				;nok

OP_DD(24,«»)
OP_CB(24,«»)
OP_DDCB(24,«»)
OP_FD(24,«»)
OP_FDCB(24,«»)
OP_ED(24,«»)

	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
	;; 124 cycles
OPCODE(25,«
	LOHI	ehl
	F_DEC_B	ehl
	HILO	ehl
	»)
				;nok

OP_DD(25,«»)
OP_CB(25,«»)
OP_DDCB(25,«»)
OP_FD(25,«»)
OP_FDCB(25,«»)
OP_ED(25,«»)

	;; LD	H,immed.b
	;; No flags
	;; 52 cycles
OPCODE(26,«
	LOHI	ehl
	FETCHBI	ehl
	HILO	ehl
	»)
				;nok

OP_DD(26,«»)
OP_CB(26,«»)
OP_DDCB(26,«»)
OP_FD(26,«»)
OP_FDCB(26,«»)
OP_ED(26,«»)

	;; DAA
	;; Decrement, adjust accum
	;; http://www.z80.info/z80syntx.htm#DAA
	;; Flags: ummm, go find a manual.
	;; XXX
	;; ? cycles
OPCODE(27,«
	F_PAR	eaf
	»)
				;nok

OP_DD(27,«»)
OP_CB(27,«»)
OP_DDCB(27,«»)
OP_FD(27,«»)
OP_FDCB(27,«»)
OP_ED(27,«»)

	;; JR	Z,immed.b
	;; If zero
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
	;; ~130 cycles
OPCODE(28,«
	jsr	f_norm_z
	bne	emu_op_18
	add.l	#1,epc
	»)
				;nok

OP_DD(28,«»)
OP_CB(28,«»)
OP_DDCB(28,«»)
OP_FD(28,«»)
OP_FDCB(28,«»)
OP_ED(28,«»)

	;; ADD	HL,HL
	;; No flags
	;; ? cycles
OPCODE(29,«
	F_ADD_W	ehl,ehl
	»)
				;nok

OP_DD(29,«»)
OP_CB(29,«»)
OP_DDCB(29,«»)
OP_FD(29,«»)
OP_FDCB(29,«»)
OP_ED(29,«»)

	;; LD	HL,(immed.w)
	;; address is absolute
	;; 172 cycles
OPCODE(2a,«
	FETCHWI	d1
	FETCHW	d1,ehl
	»)
				;nok

OP_DD(2a,«»)
OP_CB(2a,«»)
OP_DDCB(2a,«»)
OP_FD(2a,«»)
OP_FDCB(2a,«»)
OP_ED(2a,«»)

	;; XXX TOO LONG
	;; DEC	HL
	;; ? cycles
OPCODE(2b,«
	F_DEC_W	ehl
	»)
				;nok

OP_DD(2b,«»)
OP_CB(2b,«»)
OP_DDCB(2b,«»)
OP_FD(2b,«»)
OP_FDCB(2b,«»)
OP_ED(2b,«»)

	;; INC	L
	;; 108 cycles
OPCODE(2c,«
	F_INC_B	ehl
	»)
				;nok

OP_DD(2c,«»)
OP_CB(2c,«»)
OP_DDCB(2c,«»)
OP_FD(2c,«»)
OP_FDCB(2c,«»)
OP_ED(2c,«»)

	;; DEC	L
	;; 80 cycles
OPCODE(2d,«
	F_DEC_B	ehl
	»)
				;nok

OP_DD(2d,«»)
OP_CB(2d,«»)
OP_DDCB(2d,«»)
OP_FD(2d,«»)
OP_FDCB(2d,«»)
OP_ED(2d,«»)

	;; LD	L,immed.b
	;; 8 cycles
OPCODE(2e,«
	FETCHBI	ehl
	»)
				;nok

OP_DD(2e,«»)
OP_CB(2e,«»)
OP_DDCB(2e,«»)
OP_FD(2e,«»)
OP_FDCB(2e,«»)
OP_ED(2e,«»)

	;; CPL
	;; A <- NOT A
	;; XXX flags
	;; ? cycles
OPCODE(2f,«
	not.b	eaf
	»)
				;nok

OP_DD(2f,«»)
OP_CB(2f,«»)
OP_DDCB(2f,«»)
OP_FD(2f,«»)
OP_FDCB(2f,«»)
OP_ED(2f,«»)

	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
	;; ? cycles
OPCODE(30,«
	jsr	f_norm_c
	beq	emu_op_18	; branch taken: carry clear
	add.l	#1,epc
	»)

OP_DD(30,«»)
OP_CB(30,«»)
OP_DDCB(30,«»)
OP_FD(30,«»)
OP_FDCB(30,«»)
OP_ED(30,«»)

	;; LD	SP,immed.w
	;; 140 cycles
OPCODE(31,«
	FETCHWI	d1
	jsr	deref
	movea.l	a0,esp
	»)
				;nok

OP_DD(31,«»)
OP_CB(31,«»)
OP_DDCB(31,«»)
OP_FD(31,«»)
OP_FDCB(31,«»)
OP_ED(31,«»)

	;; LD	(immed.w),A
	;; store indirect
	;; 170 cycles
OPCODE(32,«
	FETCHWI	d1
	rol.w	#8,d1
	PUTB	eaf,d1
	»)
				;nok

OP_DD(32,«»)
OP_CB(32,«»)
OP_DDCB(32,«»)
OP_FD(32,«»)
OP_FDCB(32,«»)
OP_ED(32,«»)

	;; INC	SP
	;; No flags
	;;
	;; FYI:  Do not have to deref because this will never cross a
	;; page boundary.  So sayeth BrandonW.
	;; 4 cycles
OPCODE(33,«
	addq.w	#1,esp
	»)
				;nok

OP_DD(33,«»)
OP_CB(33,«»)
OP_DDCB(33,«»)
OP_FD(33,«»)
OP_FDCB(33,«»)
OP_ED(33,«»)

	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
	;; 320 cycles
OPCODE(34,«
	FETCHB	ehl,d1
	F_INC_B	d1
	PUTB	d1,ehl
	»)
				;nok

OP_DD(34,«»)
OP_CB(34,«»)
OP_DDCB(34,«»)
OP_FD(34,«»)
OP_FDCB(34,«»)
OP_ED(34,«»)

	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
	;; 292 cycles
OPCODE(35,«
	FETCHB	ehl,d1
	F_DEC_B	d1
	PUTB	d1,ehl
	»)
				;nok

OP_DD(35,«»)
OP_CB(35,«»)
OP_DDCB(35,«»)
OP_FD(35,«»)
OP_FDCB(35,«»)
OP_ED(35,«»)

	;; LD	(HL),immed.b
	;; 114 cycles
OPCODE(36,«
	FETCHBI	d1
	PUTB	ehl,d1
	»)
				;nok

OP_DD(36,«»)
OP_CB(36,«»)
OP_DDCB(36,«»)
OP_FD(36,«»)
OP_FDCB(36,«»)
OP_ED(36,«»)

	;; SCF
	;; Set Carry Flag
	;; XXX flags are more complicated than this :(
	;; ? cycles
OPCODE(37,«
	ori.b	#%00111011,flag_valid-flag_storage(a3)
	move.b	eaf,d1
	ori.b	#%00000001,d1
	andi.b	#%11101101,d1
	or.b	d1,flag_byte-flag_storage(a3)
	»)
				;nok

OP_DD(37,«»)
OP_CB(37,«»)
OP_DDCB(37,«»)
OP_FD(37,«»)
OP_FDCB(37,«»)
OP_ED(37,«»)

	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
	;; ? cycles
OPCODE(38,«
	jsr	f_norm_c
	bne	emu_op_18
	add.l	#1,epc
	»)

OP_DD(38,«»)
OP_CB(38,«»)
OP_DDCB(38,«»)
OP_FD(38,«»)
OP_FDCB(38,«»)
OP_ED(38,«»)

	;; ADD	HL,SP
	;; HL <- HL+SP
OPCODE(39,«
	move.l	esp,a0
	jsr	underef
	F_ADD_W	d0,ehl
	»)
				;nok

OP_DD(39,«»)
OP_CB(39,«»)
OP_DDCB(39,«»)
OP_FD(39,«»)
OP_FDCB(39,«»)
OP_ED(39,«»)

	;; LD	A,(immed.w)
OPCODE(3a,«
	FETCHWI	d1
	FETCHB	d1,eaf
	»)
				;nok

OP_DD(3a,«»)
OP_CB(3a,«»)
OP_DDCB(3a,«»)
OP_FD(3a,«»)
OP_FDCB(3a,«»)
OP_ED(3a,«»)

	;; DEC	SP
	;; No flags
OPCODE(3b,«
	subq.l	#1,esp
	»)
				;nok

OP_DD(3b,«»)
OP_CB(3b,«»)
OP_DDCB(3b,«»)
OP_FD(3b,«»)
OP_FDCB(3b,«»)
OP_ED(3b,«»)

	;; INC	A
OPCODE(3c,«
	F_INC_B	eaf
	»)

OP_DD(3c,«»)
OP_CB(3c,«»)
OP_DDCB(3c,«»)
OP_FD(3c,«»)
OP_FDCB(3c,«»)
OP_ED(3c,«»)

	;; DEC	A
OPCODE(3d,«
	F_DEC_B	eaf
	»)
				;nok

OP_DD(3d,«»)
OP_CB(3d,«»)
OP_DDCB(3d,«»)
OP_FD(3d,«»)
OP_FDCB(3d,«»)
OP_ED(3d,«»)

	;; LD	A,immed.b
OPCODE(3e,«
	FETCHBI	eaf
	»)

	;; CCF
	;; Clear carry flag
	;; XXX fuck flags

OP_DD(3e,«»)
OP_CB(3e,«»)
OP_DDCB(3e,«»)
OP_FD(3e,«»)
OP_FDCB(3e,«»)
OP_ED(3e,«»)

OPCODE(3f,«
	jsr	flags_normalize
	;; 	  SZ5H3PNC
	ori.b	#%00000001,flag_valid-flag_storage(a3)
	andi.b	#%11111110,flag_byte-flag_storage(a3)
	»)
				;nok

OP_DD(3f,«»)
OP_CB(3f,«»)
OP_DDCB(3f,«»)
OP_FD(3f,«»)
OP_FDCB(3f,«»)
OP_ED(3f,«»)

	;; LD	B,B
	;; SPEED
OPCODE(40,«
	LOHI	ebc
	move.b	ebc,ebc
	HILO	ebc
	»)
				;nok

OP_DD(40,«»)
OP_CB(40,«»)
OP_DDCB(40,«»)
OP_FD(40,«»)
OP_FDCB(40,«»)
OP_ED(40,«»)

	;; LD	B,C
OPCODE(41,«
	move.w	ebc,d1
	LOHI	d1
	move.b	d1,ebc
	»)
				;nok

OP_DD(41,«»)
OP_CB(41,«»)
OP_DDCB(41,«»)
OP_FD(41,«»)
OP_FDCB(41,«»)
OP_ED(41,«»)

	;; LD	B,D
	;; B <- D
	;; SPEED
OPCODE(42,«
	LOHI	ebc
	LOHI	ede
	move.b	ede,ebc
	HILO	ebc
	HILO	ede
	»)
				;nok

OP_DD(42,«»)
OP_CB(42,«»)
OP_DDCB(42,«»)
OP_FD(42,«»)
OP_FDCB(42,«»)
OP_ED(42,«»)

	;; LD	B,E
	;; B <- E
OPCODE(43,«
	LOHI	ebc
	move.b	ebc,ede		; 4
	HILO	ebc
	»)
				;nok

OP_DD(43,«»)
OP_CB(43,«»)
OP_DDCB(43,«»)
OP_FD(43,«»)
OP_FDCB(43,«»)
OP_ED(43,«»)

	;; LD	B,H
	;; B <- H
	;; SPEED
OPCODE(44,«
	LOHI	ebc
	LOHI	ehl
	move.b	ehl,ebc
	HILO	ebc
	HILO	ehl
	»)
				;nok

OP_DD(44,«»)
OP_CB(44,«»)
OP_DDCB(44,«»)
OP_FD(44,«»)
OP_FDCB(44,«»)
OP_ED(44,«»)

	;; LD	B,L
	;; B <- L
OPCODE(45,«
	LOHI	ebc
	move.b	ehl,ebc
	HILO	ebc
	»)
				;nok

OP_DD(45,«»)
OP_CB(45,«»)
OP_DDCB(45,«»)
OP_FD(45,«»)
OP_FDCB(45,«»)
OP_ED(45,«»)

	;; LD	B,(HL)
	;; B <- (HL)
OPCODE(46,«
	LOHI	ebc
	FETCHB	ehl,ebc
	HILO	ebc
	»)
				;nok

OP_DD(46,«»)
OP_CB(46,«»)
OP_DDCB(46,«»)
OP_FD(46,«»)
OP_FDCB(46,«»)
OP_ED(46,«»)

	;; LD	B,A
	;; B <- A
OPCODE(47,«
	LOHI	ebc
	move.b	eaf,ebc
	HILO	ebc
	»)
				;nok

OP_DD(47,«»)
OP_CB(47,«»)
OP_DDCB(47,«»)
OP_FD(47,«»)
OP_FDCB(47,«»)
OP_ED(47,«»)

	;; LD	C,B
	;; C <- B
OPCODE(48,«
	move.w	ebc,-(sp)
	move.b	(sp),ebc
	;; XXX emfasten?
	addq.l #2,sp
	»)
				;nok

OP_DD(48,«»)
OP_CB(48,«»)
OP_DDCB(48,«»)
OP_FD(48,«»)
OP_FDCB(48,«»)
OP_ED(48,«»)

	;; LD	C,C
OPCODE(49,«
	move.b	ebc,ebc
	»)
				;nok

OP_DD(49,«»)
OP_CB(49,«»)
OP_DDCB(49,«»)
OP_FD(49,«»)
OP_FDCB(49,«»)
OP_ED(49,«»)

	;; LD	C,D
OPCODE(4a,«
	move.w	ede,-(sp)
	move.b	(sp),ebc
	;; XXX emfasten?
	addq.l #2,sp
	»)
				;nok

OP_DD(4a,«»)
OP_CB(4a,«»)
OP_DDCB(4a,«»)
OP_FD(4a,«»)
OP_FDCB(4a,«»)
OP_ED(4a,«»)

	;; LD	C,E
OPCODE(4b,«
	move.b	ebc,ede
	»)
				;nok

OP_DD(4b,«»)
OP_CB(4b,«»)
OP_DDCB(4b,«»)
OP_FD(4b,«»)
OP_FDCB(4b,«»)
OP_ED(4b,«»)

	;; LD	C,H
OPCODE(4c,«
	LOHI	ehl
	move.b	ebc,ehl
	HILO	ehl
	»)
				;nok

OP_DD(4c,«»)
OP_CB(4c,«»)
OP_DDCB(4c,«»)
OP_FD(4c,«»)
OP_FDCB(4c,«»)
OP_ED(4c,«»)

	;; LD	C,L
OPCODE(4d,«
	move.b	ebc,ehl
	»)
				;nok

OP_DD(4d,«»)
OP_CB(4d,«»)
OP_DDCB(4d,«»)
OP_FD(4d,«»)
OP_FDCB(4d,«»)
OP_ED(4d,«»)

	;; LD	C,(HL)
	;; C <- (HL)
OPCODE(4e,«
	FETCHB	ehl,ebc
	»)
				;nok

OP_DD(4e,«»)
OP_CB(4e,«»)
OP_DDCB(4e,«»)
OP_FD(4e,«»)
OP_FDCB(4e,«»)
OP_ED(4e,«»)

	;; LD	C,A
OPCODE(4f,«
	move.b	eaf,ebc
	»)
				;nok

OP_DD(4f,«»)
OP_CB(4f,«»)
OP_DDCB(4f,«»)
OP_FD(4f,«»)
OP_FDCB(4f,«»)
OP_ED(4f,«»)

; faster (slightly bigger) if we abuse sp again, something along the lines of (UNTESTED)
; move.w ebc,-(sp)   ; 8, 2
; move.w ede,-(sp)   ; 8, 2
; move.b 2(sp),(sp) ; 16, 4
; move.w (sp)+,ede   ; 8, 2
; addq.l #2,sp      ; 8, 2
	;; LD	D,B
OPCODE(50,«
	LOHI	ebc
	LOHI	ede
	move.b	ebc,ede
	HILO	ebc
	HILO	ede
	»)
				;nok

OP_DD(50,«»)
OP_CB(50,«»)
OP_DDCB(50,«»)
OP_FD(50,«»)
OP_FDCB(50,«»)
OP_ED(50,«»)

	;; LD	D,C
OPCODE(51,«
	LOHI	ede
	move.b	ebc,ede
	HILO	ede
	»)
				;nok

OP_DD(51,«»)
OP_CB(51,«»)
OP_DDCB(51,«»)
OP_FD(51,«»)
OP_FDCB(51,«»)
OP_ED(51,«»)

	;; LD	D,D
OPCODE(52,«
	»)
				;nok

OP_DD(52,«»)
OP_CB(52,«»)
OP_DDCB(52,«»)
OP_FD(52,«»)
OP_FDCB(52,«»)
OP_ED(52,«»)

	;; LD	D,E
OPCODE(53,«
	andi.w	#$00ff,ede
	move.b	ede,d1
	lsl	#8,d1
	or.w	d1,ede
	»)
				;nok

OP_DD(53,«»)
OP_CB(53,«»)
OP_DDCB(53,«»)
OP_FD(53,«»)
OP_FDCB(53,«»)
OP_ED(53,«»)

	;; LD	D,H
OPCODE(54,«
	LOHI	ede		; 4
	LOHI	ehl		; 4
	move.b	ehl,ede		; 4
	HILO	ede		; 4
	HILO	ehl		; 4
	»,20)
				;nok
				;20 cycles

OP_DD(54,«»)
OP_CB(54,«»)
OP_DDCB(54,«»)
OP_FD(54,«»)
OP_FDCB(54,«»)
OP_ED(54,«»)

	;; LD	D,L
OPCODE(55,«
	LOHI	ede
	move.b	ehl,ede
	HILO	ede
	»)
				;nok

OP_DD(55,«»)
OP_CB(55,«»)
OP_DDCB(55,«»)
OP_FD(55,«»)
OP_FDCB(55,«»)
OP_ED(55,«»)

	;; LD	D,(HL)
	;; D <- (HL)
OPCODE(56,«
	LOHI	ede
	FETCHB	ehl,ede
	HILO	ede
	»)
				;nok

OP_DD(56,«»)
OP_CB(56,«»)
OP_DDCB(56,«»)
OP_FD(56,«»)
OP_FDCB(56,«»)
OP_ED(56,«»)

	;; LD	D,A
OPCODE(57,«
	LOHI	ede
	move.b	eaf,ede
	HILO	ede
	»)
				;nok

OP_DD(57,«»)
OP_CB(57,«»)
OP_DDCB(57,«»)
OP_FD(57,«»)
OP_FDCB(57,«»)
OP_ED(57,«»)

	;; LD	E,B
OPCODE(58,«
	LOHI	ebc
	move.b	ebc,ede
	HILO	ebc
	»)
				;nok

OP_DD(58,«»)
OP_CB(58,«»)
OP_DDCB(58,«»)
OP_FD(58,«»)
OP_FDCB(58,«»)
OP_ED(58,«»)

	;; LD	E,C
OPCODE(59,«
	move.b	ebc,ede
	»)
				;nok

OP_DD(59,«»)
OP_CB(59,«»)
OP_DDCB(59,«»)
OP_FD(59,«»)
OP_FDCB(59,«»)
OP_ED(59,«»)

	;; LD	E,D
OPCODE(5a,«
	andi.w	#$ff00,ede	; 8/4
	move.b	ede,d1		; 4/2
	lsr.w	#8,d1		;22/2
	or.w	d1,ede		; 4/2
	»,38,,2)
				;nok

OP_DD(5a,«»)
OP_CB(5a,«»)
OP_DDCB(5a,«»)
OP_FD(5a,«»)
OP_FDCB(5a,«»)
OP_ED(5a,«»)

	;; LD	E,E
OPCODE(5b,«
	move.b	ede,ede
	»)
				;nok

OP_DD(5b,«»)
OP_CB(5b,«»)
OP_DDCB(5b,«»)
OP_FD(5b,«»)
OP_FDCB(5b,«»)
OP_ED(5b,«»)

	;; LD	E,H
OPCODE(5c,«
	LOHI	ehl
	move.b	ede,ehl
	HILO	ehl
	»)
				;nok

OP_DD(5c,«»)
OP_CB(5c,«»)
OP_DDCB(5c,«»)
OP_FD(5c,«»)
OP_FDCB(5c,«»)
OP_ED(5c,«»)

	;; LD	E,L
OPCODE(5d,«
	move.b	ede,ehl
	»)
				;nok

OP_DD(5d,«»)
OP_CB(5d,«»)
OP_DDCB(5d,«»)
OP_FD(5d,«»)
OP_FDCB(5d,«»)
OP_ED(5d,«»)

	;; LD	E,(HL)
OPCODE(5e,«
	FETCHB	ehl,d1
	»)
				;nok

OP_DD(5e,«»)
OP_CB(5e,«»)
OP_DDCB(5e,«»)
OP_FD(5e,«»)
OP_FDCB(5e,«»)
OP_ED(5e,«»)

	;; LD	E,A
OPCODE(5f,«
	move.b	ede,eaf
	»)
				;nok

OP_DD(5f,«»)
OP_CB(5f,«»)
OP_DDCB(5f,«»)
OP_FD(5f,«»)
OP_FDCB(5f,«»)
OP_ED(5f,«»)

	;; LD	H,B
OPCODE(60,«
	LOHI	ebc
	LOHI	ehl
	move.b	ehl,ebc
	HILO	ebc
	HILO	ehl
	»)
				;nok

OP_DD(60,«»)
OP_CB(60,«»)
OP_DDCB(60,«»)
OP_FD(60,«»)
OP_FDCB(60,«»)
OP_ED(60,«»)

	;; LD	H,C
OPCODE(61,«
	LOHI	ehl
	move.b	ebc,ehl
	HILO	ehl
	»)
				;nok

OP_DD(61,«»)
OP_CB(61,«»)
OP_DDCB(61,«»)
OP_FD(61,«»)
OP_FDCB(61,«»)
OP_ED(61,«»)

	;; LD	H,D
OPCODE(62,«
	LOHI	ede
	LOHI	ehl
	move.b	ede,ehl
	HILO	ede
	HILO	ehl
	»)
				;nok

OP_DD(62,«»)
OP_CB(62,«»)
OP_DDCB(62,«»)
OP_FD(62,«»)
OP_FDCB(62,«»)
OP_ED(62,«»)

	;; LD	H,E
OPCODE(63,«
	LOHI	ehl
	move.b	ede,ehl
	HILO	ehl
	»)
				;nok

OP_DD(63,«»)
OP_CB(63,«»)
OP_DDCB(63,«»)
OP_FD(63,«»)
OP_FDCB(63,«»)
OP_ED(63,«»)

	;; LD	H,H
OPCODE(64,«
	LOHI	ehl
	move.b	ehl,ehl
	HILO	ehl
	»)
				;nok

OP_DD(64,«»)
OP_CB(64,«»)
OP_DDCB(64,«»)
OP_FD(64,«»)
OP_FDCB(64,«»)
OP_ED(64,«»)

	;; LD	H,L
	;; H <- L
OPCODE(65,«
	move.b	ehl,d1
	LOHI	ehl
	move.b	d1,ehl
	HILO	ehl
	»)
				;nok

OP_DD(65,«»)
OP_CB(65,«»)
OP_DDCB(65,«»)
OP_FD(65,«»)
OP_FDCB(65,«»)
OP_ED(65,«»)

	;; LD	H,(HL)
OPCODE(66,«
	FETCHB	ehl,d1
	LOHI	ehl
	move.b	d1,ehl
	HILO	ehl
	»)
				;nok

OP_DD(66,«»)
OP_CB(66,«»)
OP_DDCB(66,«»)
OP_FD(66,«»)
OP_FDCB(66,«»)
OP_ED(66,«»)

	;; LD	H,A
OPCODE(67,«
	LOHI	ehl
	move.b	eaf,ehl
	HILO	ehl
	»)
				;nok

OP_DD(67,«»)
OP_CB(67,«»)
OP_DDCB(67,«»)
OP_FD(67,«»)
OP_FDCB(67,«»)
OP_ED(67,«»)

	;; LD	L,B
OPCODE(68,«
	LOHI	ebc
	move.b	ebc,ehl
	HILO	ebc
	»)
				;nok

OP_DD(68,«»)
OP_CB(68,«»)
OP_DDCB(68,«»)
OP_FD(68,«»)
OP_FDCB(68,«»)
OP_ED(68,«»)

	;; LD	L,C
OPCODE(69,«
	move.b	ebc,ehl
	»)
				;nok

OP_DD(69,«»)
OP_CB(69,«»)
OP_DDCB(69,«»)
OP_FD(69,«»)
OP_FDCB(69,«»)
OP_ED(69,«»)

	;; LD	L,D
OPCODE(6a,«
	LOHI	ede
	move.b	ede,ehl
	HILO	ede
	»)
				;nok

OP_DD(6a,«»)
OP_CB(6a,«»)
OP_DDCB(6a,«»)
OP_FD(6a,«»)
OP_FDCB(6a,«»)
OP_ED(6a,«»)

	;; LD	L,E
OPCODE(6b,«
	move.b	ede,ehl
	»)
				;nok

OP_DD(6b,«»)
OP_CB(6b,«»)
OP_DDCB(6b,«»)
OP_FD(6b,«»)
OP_FDCB(6b,«»)
OP_ED(6b,«»)

	;; LD	L,H
OPCODE(6c,«
	move.b	ehl,d1
	LOHI	d1
	move.b	d1,ehl
	»)
				;nok

OP_DD(6c,«»)
OP_CB(6c,«»)
OP_DDCB(6c,«»)
OP_FD(6c,«»)
OP_FDCB(6c,«»)
OP_ED(6c,«»)

	;; LD	L,L
OPCODE(6d,«
	move.b	ehl,ehl
	»)
				;nok

OP_DD(6d,«»)
OP_CB(6d,«»)
OP_DDCB(6d,«»)
OP_FD(6d,«»)
OP_FDCB(6d,«»)
OP_ED(6d,«»)

	;; LD	L,(HL)
	;; L <- (HL)
OPCODE(6e,«
	FETCHB	ehl,ehl
	»)
				;nok

OP_DD(6e,«»)
OP_CB(6e,«»)
OP_DDCB(6e,«»)
OP_FD(6e,«»)
OP_FDCB(6e,«»)
OP_ED(6e,«»)

	;; LD	L,A
OPCODE(6f,«
	move.b	eaf,ehl
	»)
				;nok

OP_DD(6f,«»)
OP_CB(6f,«»)
OP_DDCB(6f,«»)
OP_FD(6f,«»)
OP_FDCB(6f,«»)
OP_ED(6f,«»)

	;; LD	(HL),B
OPCODE(70,«
	LOHI	ebc
	PUTB	ehl,ebc
	HILO	ebc
	»)
				;nok

OP_DD(70,«»)
OP_CB(70,«»)
OP_DDCB(70,«»)
OP_FD(70,«»)
OP_FDCB(70,«»)
OP_ED(70,«»)

	;; LD	(HL),C
OPCODE(71,«
	PUTB	ehl,ebc
	»)
				;nok

OP_DD(71,«»)
OP_CB(71,«»)
OP_DDCB(71,«»)
OP_FD(71,«»)
OP_FDCB(71,«»)
OP_ED(71,«»)

	;; LD	(HL),D
OPCODE(72,«
	LOHI	ede
	PUTB	ehl,ede
	HILO	ede
	»)
				;nok

OP_DD(72,«»)
OP_CB(72,«»)
OP_DDCB(72,«»)
OP_FD(72,«»)
OP_FDCB(72,«»)
OP_ED(72,«»)

	;; LD	(HL),E
OPCODE(73,«
	PUTB	ehl,ede
	»)
				;nok

OP_DD(73,«»)
OP_CB(73,«»)
OP_DDCB(73,«»)
OP_FD(73,«»)
OP_FDCB(73,«»)
OP_ED(73,«»)

	;; LD	(HL),H
OPCODE(74,«
	move.w	ehl,d1
	HILO	d1
	PUTB	d1,ehl
	»)
				;nok

OP_DD(74,«»)
OP_CB(74,«»)
OP_DDCB(74,«»)
OP_FD(74,«»)
OP_FDCB(74,«»)
OP_ED(74,«»)

	;; LD	(HL),L
OPCODE(75,«
	move.b	ehl,d1
	PUTB	d1,ehl
	»)
				;nok

OP_DD(75,«»)
OP_CB(75,«»)
OP_DDCB(75,«»)
OP_FD(75,«»)
OP_FDCB(75,«»)
OP_ED(75,«»)

	;; HALT
	;; XXX do this
OPCODE(76,«
	bra	emu_op_76
	»)
				;nok

OP_DD(76,«»)
OP_CB(76,«»)
OP_DDCB(76,«»)
OP_FD(76,«»)
OP_FDCB(76,«»)
OP_ED(76,«»)

	;; LD	(HL),A
OPCODE(77,«
	PUTB	eaf,ehl
	»)
				;nok

OP_DD(77,«»)
OP_CB(77,«»)
OP_DDCB(77,«»)
OP_FD(77,«»)
OP_FDCB(77,«»)
OP_ED(77,«»)

	;; LD	A,B
OPCODE(78,«
	move.w	ebc,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

OP_DD(78,«»)
OP_CB(78,«»)
OP_DDCB(78,«»)
OP_FD(78,«»)
OP_FDCB(78,«»)
OP_ED(78,«»)

	;; LD	A,C
OPCODE(79,«
	move.b	ebc,eaf
	»)
				;nok

OP_DD(79,«»)
OP_CB(79,«»)
OP_DDCB(79,«»)
OP_FD(79,«»)
OP_FDCB(79,«»)
OP_ED(79,«»)

	;; LD	A,D
OPCODE(7a,«
	move.w	ede,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

OP_DD(7a,«»)
OP_CB(7a,«»)
OP_DDCB(7a,«»)
OP_FD(7a,«»)
OP_FDCB(7a,«»)
OP_ED(7a,«»)

	;; LD	A,E
OPCODE(7b,«
	move.b	ede,eaf
	»)
				;nok

OP_DD(7b,«»)
OP_CB(7b,«»)
OP_DDCB(7b,«»)
OP_FD(7b,«»)
OP_FDCB(7b,«»)
OP_ED(7b,«»)

	;; LD	A,H
OPCODE(7c,«
	move.w	ehl,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

OP_DD(7c,«»)
OP_CB(7c,«»)
OP_DDCB(7c,«»)
OP_FD(7c,«»)
OP_FDCB(7c,«»)
OP_ED(7c,«»)

	;; LD	A,L
OPCODE(7d,«
	move.b	ehl,eaf
	»)
				;nok

OP_DD(7d,«»)
OP_CB(7d,«»)
OP_DDCB(7d,«»)
OP_FD(7d,«»)
OP_FDCB(7d,«»)
OP_ED(7d,«»)

	;; LD	A,(HL)
	;; A <- (HL)
OPCODE(7e,«
	FETCHB	ehl,eaf
	»)

OP_DD(7e,«»)
OP_CB(7e,«»)
OP_DDCB(7e,«»)
OP_FD(7e,«»)
OP_FDCB(7e,«»)
OP_ED(7e,«»)

	;; LD	A,A
OPCODE(7f,«
	»)
				;nok

OP_DD(7f,«»)
OP_CB(7f,«»)
OP_DDCB(7f,«»)
OP_FD(7f,«»)
OP_FDCB(7f,«»)
OP_ED(7f,«»)



	;; Do an ADD \2,\1
F_ADD_B	MACRO			; 14 bytes?
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_add
	move.b	d1,\2
	ENDM

	;; ADD	A,B
OPCODE(80,«
	LOHI	ebc
	F_ADD_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(80,«»)
OP_CB(80,«»)
OP_DDCB(80,«»)
OP_FD(80,«»)
OP_FDCB(80,«»)
OP_ED(80,«»)

	;; ADD	A,C
OPCODE(81,«
	F_ADD_B	ebc,eaf
	»)
				;nok

OP_DD(81,«»)
OP_CB(81,«»)
OP_DDCB(81,«»)
OP_FD(81,«»)
OP_FDCB(81,«»)
OP_ED(81,«»)

	;; ADD	A,D
OPCODE(82,«
	LOHI	ede
	F_ADD_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(82,«»)
OP_CB(82,«»)
OP_DDCB(82,«»)
OP_FD(82,«»)
OP_FDCB(82,«»)
OP_ED(82,«»)

	;; ADD	A,E
OPCODE(83,«
	F_ADD_B	ede,eaf
	»)
				;nok

OP_DD(83,«»)
OP_CB(83,«»)
OP_DDCB(83,«»)
OP_FD(83,«»)
OP_FDCB(83,«»)
OP_ED(83,«»)

	;; ADD	A,H
OPCODE(84,«
	LOHI	ehl
	F_ADD_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(84,«»)
OP_CB(84,«»)
OP_DDCB(84,«»)
OP_FD(84,«»)
OP_FDCB(84,«»)
OP_ED(84,«»)

	;; ADD	A,L
OPCODE(85,«
	F_ADD_B	ehl,eaf
	»)
				;nok

OP_DD(85,«»)
OP_CB(85,«»)
OP_DDCB(85,«»)
OP_FD(85,«»)
OP_FDCB(85,«»)
OP_ED(85,«»)

	;; ADD	A,(HL)
	;; XXX size?
OPCODE(86,«
	FETCHB	ehl,d2
	F_ADD_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(86,«»)
OP_CB(86,«»)
OP_DDCB(86,«»)
OP_FD(86,«»)
OP_FDCB(86,«»)
OP_ED(86,«»)

	;; ADD	A,A
OPCODE(87,«
	F_ADD_B	eaf,eaf
	»)
				;nok

OP_DD(87,«»)
OP_CB(87,«»)
OP_DDCB(87,«»)
OP_FD(87,«»)
OP_FDCB(87,«»)
OP_ED(87,«»)



	;; Do an ADC \2,\1
F_ADC_B	MACRO			; S34
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_adc
	move.b	d1,\2
	ENDM

	;; ADC	A,B
	;; A <- A + B + (carry)
OPCODE(88,«
	LOHI	ebc
	F_ADC_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(88,«»)
OP_CB(88,«»)
OP_DDCB(88,«»)
OP_FD(88,«»)
OP_FDCB(88,«»)
OP_ED(88,«»)

	;; ADC	A,C
	;; A <- A + C + (carry)
OPCODE(89,«
	F_ADC_B	ebc,eaf
	»)
				;nok

OP_DD(89,«»)
OP_CB(89,«»)
OP_DDCB(89,«»)
OP_FD(89,«»)
OP_FDCB(89,«»)
OP_ED(89,«»)

	;; ADC	A,D
OPCODE(8a,«
	LOHI	ede
	F_ADC_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(8a,«»)
OP_CB(8a,«»)
OP_DDCB(8a,«»)
OP_FD(8a,«»)
OP_FDCB(8a,«»)
OP_ED(8a,«»)

	;; ADC	A,E
	;; A <- A + E + carry
OPCODE(8b,«
	F_ADC_B	ede,eaf
	»)
				;nok

OP_DD(8b,«»)
OP_CB(8b,«»)
OP_DDCB(8b,«»)
OP_FD(8b,«»)
OP_FDCB(8b,«»)
OP_ED(8b,«»)

	;; ADC	A,H
OPCODE(8c,«
	LOHI	eaf
	F_ADC_B	ehl,eaf
	HILO	eaf
	»)
				;nok

OP_DD(8c,«»)
OP_CB(8c,«»)
OP_DDCB(8c,«»)
OP_FD(8c,«»)
OP_FDCB(8c,«»)
OP_ED(8c,«»)

	;; ADC	A,L
OPCODE(8d,«
	F_ADC_B	ehl,eaf
	»)
				;nok

OP_DD(8d,«»)
OP_CB(8d,«»)
OP_DDCB(8d,«»)
OP_FD(8d,«»)
OP_FDCB(8d,«»)
OP_ED(8d,«»)

	;; ADC	A,(HL)
OPCODE(8e,«
	FETCHB	ehl,d2
	F_ADC_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(8e,«»)
OP_CB(8e,«»)
OP_DDCB(8e,«»)
OP_FD(8e,«»)
OP_FDCB(8e,«»)
OP_ED(8e,«»)

	;; ADC	A,A
OPCODE(8f,«
	F_ADC_B	eaf,eaf
	»)
				;nok

OP_DD(8f,«»)
OP_CB(8f,«»)
OP_DDCB(8f,«»)
OP_FD(8f,«»)
OP_FDCB(8f,«»)
OP_ED(8f,«»)





	;; Do a SUB \2,\1
F_SUB_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_sub
	move.b	d1,\2
	ENDM

	;; SUB	A,B
OPCODE(90,«
	LOHI	ebc
	F_SUB_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(90,«»)
OP_CB(90,«»)
OP_DDCB(90,«»)
OP_FD(90,«»)
OP_FDCB(90,«»)
OP_ED(90,«»)

	;; SUB	A,C
OPCODE(91,«
	F_SUB_B	ebc,eaf
	»)
				;nok

OP_DD(91,«»)
OP_CB(91,«»)
OP_DDCB(91,«»)
OP_FD(91,«»)
OP_FDCB(91,«»)
OP_ED(91,«»)

	;; SUB	A,D
OPCODE(92,«
	LOHI	ede
	F_SUB_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(92,«»)
OP_CB(92,«»)
OP_DDCB(92,«»)
OP_FD(92,«»)
OP_FDCB(92,«»)
OP_ED(92,«»)

	;; SUB	A,E
OPCODE(93,«
	F_SUB_B	ede,eaf
	»)
				;nok

OP_DD(93,«»)
OP_CB(93,«»)
OP_DDCB(93,«»)
OP_FD(93,«»)
OP_FDCB(93,«»)
OP_ED(93,«»)

	;; SUB	A,H
OPCODE(94,«
	LOHI	ehl
	F_SUB_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(94,«»)
OP_CB(94,«»)
OP_DDCB(94,«»)
OP_FD(94,«»)
OP_FDCB(94,«»)
OP_ED(94,«»)

	;; SUB	A,L
OPCODE(95,«
	F_SUB_B	ehl,eaf
	»)

OP_DD(95,«»)
OP_CB(95,«»)
OP_DDCB(95,«»)
OP_FD(95,«»)
OP_FDCB(95,«»)
OP_ED(95,«»)

	;; SUB	A,(HL)
OPCODE(96,«
	FETCHB	ehl,d2
	F_SUB_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(96,«»)
OP_CB(96,«»)
OP_DDCB(96,«»)
OP_FD(96,«»)
OP_FDCB(96,«»)
OP_ED(96,«»)

	;; SUB	A,A
OPCODE(97,«
	F_SUB_B	eaf,eaf
	»)
				;nok

OP_DD(97,«»)
OP_CB(97,«»)
OP_DDCB(97,«»)
OP_FD(97,«»)
OP_FDCB(97,«»)
OP_ED(97,«»)




	;; Do a SBC \2,\1
F_SBC_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_sbc
	move.b	d1,\2
	ENDM

	;; SBC	A,B
OPCODE(98,«
	LOHI	ebc
	F_SBC_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(98,«»)
OP_CB(98,«»)
OP_DDCB(98,«»)
OP_FD(98,«»)
OP_FDCB(98,«»)
OP_ED(98,«»)

	;; SBC	A,C
OPCODE(99,«
	F_SBC_B	ebc,eaf
	»)
				;nok

OP_DD(99,«»)
OP_CB(99,«»)
OP_DDCB(99,«»)
OP_FD(99,«»)
OP_FDCB(99,«»)
OP_ED(99,«»)

	;; SBC	A,D
OPCODE(9a,«
	LOHI	ede
	F_SBC_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(9a,«»)
OP_CB(9a,«»)
OP_DDCB(9a,«»)
OP_FD(9a,«»)
OP_FDCB(9a,«»)
OP_ED(9a,«»)

	;; SBC	A,E
OPCODE(9b,«
	F_SBC_B	ede,eaf
	»)
				;nok

OP_DD(9b,«»)
OP_CB(9b,«»)
OP_DDCB(9b,«»)
OP_FD(9b,«»)
OP_FDCB(9b,«»)
OP_ED(9b,«»)

	;; SBC	A,H
OPCODE(9c,«
	LOHI	ehl
	F_SBC_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(9c,«»)
OP_CB(9c,«»)
OP_DDCB(9c,«»)
OP_FD(9c,«»)
OP_FDCB(9c,«»)
OP_ED(9c,«»)

	;; SBC	A,L
OPCODE(9d,«
	F_SBC_B	ehl,eaf
	»)
				;nok

OP_DD(9d,«»)
OP_CB(9d,«»)
OP_DDCB(9d,«»)
OP_FD(9d,«»)
OP_FDCB(9d,«»)
OP_ED(9d,«»)

	;; SBC	A,(HL)
OPCODE(9e,«
	FETCHB	ehl,d2
	F_SBC_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(9e,«»)
OP_CB(9e,«»)
OP_DDCB(9e,«»)
OP_FD(9e,«»)
OP_FDCB(9e,«»)
OP_ED(9e,«»)

	;; SBC	A,A
OPCODE(9f,«
	F_SBC_B	eaf,eaf
	»)
				;nok





F_AND_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_and
	move.b	d1,\2
	ENDM

OP_DD(9f,«»)
OP_CB(9f,«»)
OP_DDCB(9f,«»)
OP_FD(9f,«»)
OP_FDCB(9f,«»)
OP_ED(9f,«»)

	;; AND	B
OPCODE(a0,«
	LOHI	ebc
	F_AND_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(a0,«»)
OP_CB(a0,«»)
OP_DDCB(a0,«»)
OP_FD(a0,«»)
OP_FDCB(a0,«»)
OP_ED(a0,«»)

	;; AND	C
OPCODE(a1,«
	F_AND_B	ebc,eaf
	»)

OP_DD(a1,«»)
OP_CB(a1,«»)
OP_DDCB(a1,«»)
OP_FD(a1,«»)
OP_FDCB(a1,«»)
OP_ED(a1,«»)

	;; AND	D
OPCODE(a2,«
	LOHI	ede
	F_AND_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(a2,«»)
OP_CB(a2,«»)
OP_DDCB(a2,«»)
OP_FD(a2,«»)
OP_FDCB(a2,«»)
OP_ED(a2,«»)

	;; AND	E
OPCODE(a3,«
	F_AND_B	ede,eaf
	»)
				;nok

OP_DD(a3,«»)
OP_CB(a3,«»)
OP_DDCB(a3,«»)
OP_FD(a3,«»)
OP_FDCB(a3,«»)
OP_ED(a3,«»)

	;; AND	H
OPCODE(a4,«
	LOHI	ehl
	F_AND_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(a4,«»)
OP_CB(a4,«»)
OP_DDCB(a4,«»)
OP_FD(a4,«»)
OP_FDCB(a4,«»)
OP_ED(a4,«»)

	;; AND	L
OPCODE(a5,«
	F_AND_B	ehl,eaf
	»)
				;nok

OP_DD(a5,«»)
OP_CB(a5,«»)
OP_DDCB(a5,«»)
OP_FD(a5,«»)
OP_FDCB(a5,«»)
OP_ED(a5,«»)

	;; AND	(HL)
OPCODE(a6,«
	FETCHB	ehl,d2
	F_AND_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(a6,«»)
OP_CB(a6,«»)
OP_DDCB(a6,«»)
OP_FD(a6,«»)
OP_FDCB(a6,«»)
OP_ED(a6,«»)

	;; AND	A
	;; SPEED ... It's probably not necessary to run this faster.
OPCODE(a7,«
	F_AND_B	eaf,eaf
	»)
				;nok





F_XOR_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_xor
	move.b	d1,\2
	ENDM

OP_DD(a7,«»)
OP_CB(a7,«»)
OP_DDCB(a7,«»)
OP_FD(a7,«»)
OP_FDCB(a7,«»)
OP_ED(a7,«»)

	;; XOR	B
OPCODE(a8,«
	LOHI	ebc
	F_XOR_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(a8,«»)
OP_CB(a8,«»)
OP_DDCB(a8,«»)
OP_FD(a8,«»)
OP_FDCB(a8,«»)
OP_ED(a8,«»)

	;; XOR	C
OPCODE(a9,«
	F_XOR_B	ebc,eaf
	»)
				;nok

OP_DD(a9,«»)
OP_CB(a9,«»)
OP_DDCB(a9,«»)
OP_FD(a9,«»)
OP_FDCB(a9,«»)
OP_ED(a9,«»)

	;; XOR	D
OPCODE(aa,«
	LOHI	ede
	F_XOR_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(aa,«»)
OP_CB(aa,«»)
OP_DDCB(aa,«»)
OP_FD(aa,«»)
OP_FDCB(aa,«»)
OP_ED(aa,«»)

	;; XOR	E
OPCODE(ab,«
	F_XOR_B	ede,eaf
	»)
				;nok

OP_DD(ab,«»)
OP_CB(ab,«»)
OP_DDCB(ab,«»)
OP_FD(ab,«»)
OP_FDCB(ab,«»)
OP_ED(ab,«»)

	;; XOR	H
OPCODE(ac,«
	LOHI	ehl
	F_XOR_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(ac,«»)
OP_CB(ac,«»)
OP_DDCB(ac,«»)
OP_FD(ac,«»)
OP_FDCB(ac,«»)
OP_ED(ac,«»)

	;; XOR	L
OPCODE(ad,«
	F_XOR_B	ehl,eaf
	»)
				;nok

OP_DD(ad,«»)
OP_CB(ad,«»)
OP_DDCB(ad,«»)
OP_FD(ad,«»)
OP_FDCB(ad,«»)
OP_ED(ad,«»)

	;; XOR	(HL)
OPCODE(ae,«
	FETCHB	ehl,d2
	F_XOR_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

OP_DD(ae,«»)
OP_CB(ae,«»)
OP_DDCB(ae,«»)
OP_FD(ae,«»)
OP_FDCB(ae,«»)
OP_ED(ae,«»)

	;; XOR	A
OPCODE(af,«
	F_XOR_B	eaf,eaf
	;; XXX
	»)
				;nok





F_OR_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_or
	move.b	d1,\2
	ENDM

OP_DD(af,«»)
OP_CB(af,«»)
OP_DDCB(af,«»)
OP_FD(af,«»)
OP_FDCB(af,«»)
OP_ED(af,«»)

	;; OR	B
OPCODE(b0,«
	LOHI	ebc
	F_OR_B	ebc,eaf
	HILO	ebc
	»)
				;nok

OP_DD(b0,«»)
OP_CB(b0,«»)
OP_DDCB(b0,«»)
OP_FD(b0,«»)
OP_FDCB(b0,«»)
OP_ED(b0,«»)

	;; OR	C
OPCODE(b1,«
	F_OR_B	ebc,eaf
	»)
				;nok

OP_DD(b1,«»)
OP_CB(b1,«»)
OP_DDCB(b1,«»)
OP_FD(b1,«»)
OP_FDCB(b1,«»)
OP_ED(b1,«»)

	;; OR	D
OPCODE(b2,«
	LOHI	ede
	F_OR_B	ede,eaf
	HILO	ede
	»)
				;nok

OP_DD(b2,«»)
OP_CB(b2,«»)
OP_DDCB(b2,«»)
OP_FD(b2,«»)
OP_FDCB(b2,«»)
OP_ED(b2,«»)

	;; OR	E
OPCODE(b3,«
	F_OR_B	ede,eaf
	»)
				;nok

OP_DD(b3,«»)
OP_CB(b3,«»)
OP_DDCB(b3,«»)
OP_FD(b3,«»)
OP_FDCB(b3,«»)
OP_ED(b3,«»)

	;; OR	H
OPCODE(b4,«
	LOHI	ehl
	F_OR_B	ehl,eaf
	HILO	ehl
	»)
				;nok

OP_DD(b4,«»)
OP_CB(b4,«»)
OP_DDCB(b4,«»)
OP_FD(b4,«»)
OP_FDCB(b4,«»)
OP_ED(b4,«»)

	;; OR	L
OPCODE(b5,«
	F_OR_B	ehl,eaf
	»)
				;nok

OP_DD(b5,«»)
OP_CB(b5,«»)
OP_DDCB(b5,«»)
OP_FD(b5,«»)
OP_FDCB(b5,«»)
OP_ED(b5,«»)

	;; OR	(HL)
OPCODE(b6,«
	;; SPEED unnecessary move
	FETCHB	ehl,d2
	F_OR_B	d2,eaf
	»)
				;nok

OPCODE(b7,«
OP_DD(b6,«»)
OP_CB(b6,«»)
OP_DDCB(b6,«»)
OP_FD(b6,«»)
OP_FDCB(b6,«»)
OP_ED(b6,«»)

	;; OR	A
	F_OR_B	eaf,eaf
	»)
				;nok





	;; COMPARE instruction
	;; Tests the argument against A
F_CP_B	MACRO
	;; XXX deal with \2 or \1 being d1 or d0
	move.b	\2,d1
	move.b	\1,d0
	jsr	alu_cp
	;; no result to save
	ENDM

OP_DD(b7,«»)
OP_CB(b7,«»)
OP_DDCB(b7,«»)
OP_FD(b7,«»)
OP_FDCB(b7,«»)
OP_ED(b7,«»)

	;; CP	B
OPCODE(b8,«
	move.w	ebc,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

OP_DD(b8,«»)
OP_CB(b8,«»)
OP_DDCB(b8,«»)
OP_FD(b8,«»)
OP_FDCB(b8,«»)
OP_ED(b8,«»)

	;; CP	C
OPCODE(b9,«
	F_CP_B	ebc,eaf
	»)
				;nok

OP_DD(b9,«»)
OP_CB(b9,«»)
OP_DDCB(b9,«»)
OP_FD(b9,«»)
OP_FDCB(b9,«»)
OP_ED(b9,«»)

	;; CP	D
OPCODE(ba,«
	move.w	ede,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

OP_DD(ba,«»)
OP_CB(ba,«»)
OP_DDCB(ba,«»)
OP_FD(ba,«»)
OP_FDCB(ba,«»)
OP_ED(ba,«»)

	;; CP	E
OPCODE(bb,«
	F_CP_B	ede,eaf
	»)
				;nok

OP_DD(bb,«»)
OP_CB(bb,«»)
OP_DDCB(bb,«»)
OP_FD(bb,«»)
OP_FDCB(bb,«»)
OP_ED(bb,«»)

	;; CP	H
OPCODE(bc,«
	move.w	ehl,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

OP_DD(bc,«»)
OP_CB(bc,«»)
OP_DDCB(bc,«»)
OP_FD(bc,«»)
OP_FDCB(bc,«»)
OP_ED(bc,«»)

	;; CP	L
OPCODE(bd,«
	F_CP_B	ehl,eaf
	»)
				;nok

OP_DD(bd,«»)
OP_CB(bd,«»)
OP_DDCB(bd,«»)
OP_FD(bd,«»)
OP_FDCB(bd,«»)
OP_ED(bd,«»)

	;; CP	(HL)
OPCODE(be,«
	FETCHB	ehl,d2
	F_CP_B	d2,eaf
	;; no result to store
	»)
				;nok

OP_DD(be,«»)
OP_CB(be,«»)
OP_DDCB(be,«»)
OP_FD(be,«»)
OP_FDCB(be,«»)
OP_ED(be,«»)

	;; CP	A
OPCODE(bf,«
	F_CP_B	eaf,eaf
	»)

OP_DD(bf,«»)
OP_CB(bf,«»)
OP_DDCB(bf,«»)
OP_FD(bf,«»)
OP_FDCB(bf,«»)
OP_ED(bf,«»)

	;; RET	NZ
	;; if ~Z
	;;   PCl <- (SP)
	;;   PCh <- (SP+1)
	;;   SP <- (SP+2)
OPCODE(c0,«
	jsr	f_norm_z
	;; SPEED inline RET
	beq	emu_op_c9	; RET
	»)
				;nok

OP_DD(c0,«»)
OP_CB(c0,«»)
OP_DDCB(c0,«»)
OP_FD(c0,«»)
OP_FDCB(c0,«»)
OP_ED(c0,«»)

	;; POP	BC
	;; Pops a word into BC
OPCODE(c1,«			; S10 T
	POPW	ebc
	»)
				;nok

OP_DD(c1,«»)
OP_CB(c1,«»)
OP_DDCB(c1,«»)
OP_FD(c1,«»)
OP_FDCB(c1,«»)
OP_ED(c1,«»)

	;; JP	NZ,immed.w
	;; if ~Z
	;;   PC <- immed.w
OPCODE(c2,«
	jsr	f_norm_z
	beq.s	emu_op_c3
	add.l	#2,epc
	»)
				;nok

OP_DD(c2,«»)
OP_CB(c2,«»)
OP_DDCB(c2,«»)
OP_FD(c2,«»)
OP_FDCB(c2,«»)
OP_ED(c2,«»)

	;; JP	immed.w
	;; PC <- immed.w
OPCODE(c3,«
	FETCHWI	d1
	jsr	deref
	movea.l	a0,epc
	»,36,,12)

OP_DD(c3,«»)
OP_CB(c3,«»)
OP_DDCB(c3,«»)
OP_FD(c3,«»)
OP_FDCB(c3,«»)
OP_ED(c3,«»)

	;; CALL	NZ,immed.w
	;; If ~Z, CALL immed.w
OPCODE(c4,«
	jsr	f_norm_z
	;; CALL (emu_op_cd) will run HOLD_INTS again. This doesn't
	;; matter with the current implementation because HOLD_INTS
	;; simply sets a bit.
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(c4,«»)
OP_CB(c4,«»)
OP_DDCB(c4,«»)
OP_FD(c4,«»)
OP_FDCB(c4,«»)
OP_ED(c4,«»)

	;; PUSH	BC
OPCODE(c5,«
	PUSHW	ebc
	»)
				;nok

OP_DD(c5,«»)
OP_CB(c5,«»)
OP_DDCB(c5,«»)
OP_FD(c5,«»)
OP_FDCB(c5,«»)
OP_ED(c5,«»)

	;; ADD	A,immed.b
OPCODE(c6,«
	FETCHBI	d1
	F_ADD_B	d1,eaf
	»)
				;nok

OP_DD(c6,«»)
OP_CB(c6,«»)
OP_DDCB(c6,«»)
OP_FD(c6,«»)
OP_FDCB(c6,«»)
OP_ED(c6,«»)

	;; RST	&0
	;;  == CALL 0
	;; XXX check
OPCODE(c7,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$00,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(c7,«»)
OP_CB(c7,«»)
OP_DDCB(c7,«»)
OP_FD(c7,«»)
OP_FDCB(c7,«»)
OP_ED(c7,«»)

	;; RET	Z
OPCODE(c8,«
	jsr	f_norm_z
	bne.s	emu_op_c9
	»)
				;nok

OP_DD(c8,«»)
OP_CB(c8,«»)
OP_DDCB(c8,«»)
OP_FD(c8,«»)
OP_FDCB(c8,«»)
OP_ED(c8,«»)

	;; RET
	;; PCl <- (SP)
	;; PCh <- (SP+1)	POPW
	;; SP <- (SP+2)
OPCODE(c9,«
	POPW	d1
	jsr	deref
	movea.l	a0,epc
	»)
				;nok

OP_DD(c9,«»)
OP_CB(c9,«»)
OP_DDCB(c9,«»)
OP_FD(c9,«»)
OP_FDCB(c9,«»)
OP_ED(c9,«»)

	;; JP	Z,immed.w
	;; If Z, jump
OPCODE(ca,«
	jsr	f_norm_z
	bne	emu_op_c3
	add.l	#2,epc
	»)
				;nok
OP_DD(ca,«»)
OP_CB(ca,«»)
OP_DDCB(ca,«»)
OP_FD(ca,«»)
OP_FDCB(ca,«»)
OP_ED(ca,«»)

	;; prefix
OPCODE(cb,«
	movea.w	emu_op_undo_cb(pc),a2
	»)
				;nok

OP_DD(cb,«»)
OP_CB(cb,«»)
OP_DDCB(cb,«»)
OP_FD(cb,«»)
OP_FDCB(cb,«»)
OP_ED(cb,«»)

	;; CALL	Z,immed.w
OPCODE(cc,«
	jsr	f_norm_z
	bne.s	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(cc,«»)
OP_CB(cc,«»)
OP_DDCB(cc,«»)
OP_FD(cc,«»)
OP_FDCB(cc,«»)
OP_ED(cc,«»)

	;; CALL	immed.w
	;; (Like JSR on 68k)
	;;  (SP-1) <- PCh
	;;  (SP-2) <- PCl
	;;  SP <- SP - 2
	;;  PC <- address
OPCODE(cd,«
	move.l	epc,a0
	jsr	underef		; d0 has PC
	add.w	#2,d0
	PUSHW	d0
	bra	emu_op_c3	; JP
	»)

OP_DD(cd,«»)
OP_CB(cd,«»)
OP_DDCB(cd,«»)
OP_FD(cd,«»)
OP_FDCB(cd,«»)
OP_ED(cd,«»)

	;; ADC	A,immed.b
OPCODE(ce,«
	FETCHWI	d1
	F_ADC_B	d1,eaf
	»)
				;nok

OP_DD(ce,«»)
OP_CB(ce,«»)
OP_DDCB(ce,«»)
OP_FD(ce,«»)
OP_FDCB(ce,«»)
OP_ED(ce,«»)

	;; RST	&08
	;;  == CALL 8
OPCODE(cf,«
	move.l	epc,a0
	jsr	underef		; d0 has PC
	PUSHW	d0
	move.w	#$08,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(cf,«»)
OP_CB(cf,«»)
OP_DDCB(cf,«»)
OP_FD(cf,«»)
OP_FDCB(cf,«»)
OP_ED(cf,«»)

	;; RET	NC
OPCODE(d0,«
	jsr	f_norm_c
	beq	emu_op_c9
	»)
				;nok

OP_DD(d0,«»)
OP_CB(d0,«»)
OP_DDCB(d0,«»)
OP_FD(d0,«»)
OP_FDCB(d0,«»)
OP_ED(d0,«»)

	;; POP	DE
OPCODE(d1,«
	POPW	ede
	»)
				;nok

OP_DD(d1,«»)
OP_CB(d1,«»)
OP_DDCB(d1,«»)
OP_FD(d1,«»)
OP_FDCB(d1,«»)
OP_ED(d1,«»)

	;; JP	NC,immed.w
OPCODE(d2,«
	jsr	f_norm_c
	beq	emu_op_c3
	add.l	#2,epc
	»)

OP_DD(d2,«»)
OP_CB(d2,«»)
OP_DDCB(d2,«»)
OP_FD(d2,«»)
OP_FDCB(d2,«»)
OP_ED(d2,«»)

	;; OUT	immed.b,A
OPCODE(d3,«
	move.b	eaf,d1
	FETCHBI	d0
	jsr	port_out
	»)
				;nok

OP_DD(d3,«»)
OP_CB(d3,«»)
OP_DDCB(d3,«»)
OP_FD(d3,«»)
OP_FDCB(d3,«»)
OP_ED(d3,«»)

	;; CALL	NC,immed.w
OPCODE(d4,«
	jsr	f_norm_c
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(d4,«»)
OP_CB(d4,«»)
OP_DDCB(d4,«»)
OP_FD(d4,«»)
OP_FDCB(d4,«»)
OP_ED(d4,«»)

	;; PUSH	DE
OPCODE(d5,«
	PUSHW	ede
	»)
				;nok

OP_DD(d5,«»)
OP_CB(d5,«»)
OP_DDCB(d5,«»)
OP_FD(d5,«»)
OP_FDCB(d5,«»)
OP_ED(d5,«»)

	;; SUB	A,immed.b
OPCODE(d6,«
	FETCHBI	d1
	F_SUB_B	eaf,d1
	»)
				;nok

OP_DD(d6,«»)
OP_CB(d6,«»)
OP_DDCB(d6,«»)
OP_FD(d6,«»)
OP_FDCB(d6,«»)
OP_ED(d6,«»)

	;; RST	&10
	;;  == CALL 10
OPCODE(d7,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$10,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(d7,«»)
OP_CB(d7,«»)
OP_DDCB(d7,«»)
OP_FD(d7,«»)
OP_FDCB(d7,«»)
OP_ED(d7,«»)

	;; RET	C
OPCODE(d8,«
	jsr	f_norm_c
	bne	emu_op_c9
	»)
				;nok

OP_DD(d8,«»)
OP_CB(d8,«»)
OP_DDCB(d8,«»)
OP_FD(d8,«»)
OP_FDCB(d8,«»)
OP_ED(d8,«»)

	;; EXX
OPCODE(d9,«
	swap	ebc
	swap	ede
	swap	ehl
	»)
				;nok

OP_DD(d9,«»)
OP_CB(d9,«»)
OP_DDCB(d9,«»)
OP_FD(d9,«»)
OP_FDCB(d9,«»)
OP_ED(d9,«»)

	;; JP	C,immed.w
OPCODE(da,«
	jsr	f_norm_c
	bne	emu_op_c3
	»)
				;nok

OP_DD(da,«»)
OP_CB(da,«»)
OP_DDCB(da,«»)
OP_FD(da,«»)
OP_FDCB(da,«»)
OP_ED(da,«»)

	;; IN	A,immed.b
OPCODE(db,«
	move.b	eaf,d1
	FETCHBI	d0
	jsr	port_in
	»)
				;nok

OP_DD(db,«»)
OP_CB(db,«»)
OP_DDCB(db,«»)
OP_FD(db,«»)
OP_FDCB(db,«»)
OP_ED(db,«»)

	;; CALL	C,immed.w
OPCODE(dc,«
	jsr	f_norm_c
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OPCODE(dd,«			; prefix
	movea.w		emu_op_undo_dd(pc),a2
	»)

OP_DD(dc,«»)
OP_CB(dc,«»)
OP_DDCB(dc,«»)
OP_FD(dc,«»)
OP_FDCB(dc,«»)
OP_ED(dc,«»)

	;; SBC	A,immed.b
OPCODE(de,«
	FETCHWI	d1
	F_SBC_B	d1,eaf
	»)
				;nok

OP_DD(dd,«»)
OP_CB(dd,«»)
OP_DDCB(dd,«»)
OP_FD(dd,«»)
OP_FDCB(dd,«»)
OP_ED(dd,«»)

	;; RST	&18
	;;  == CALL 18
OPCODE(df,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$18,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(de,«»)
OP_CB(de,«»)
OP_DDCB(de,«»)
OP_FD(de,«»)
OP_FDCB(de,«»)
OP_ED(de,«»)

	;; RET	PO
	;; If parity odd (P zero), return
OPCODE(e0,«
	jsr	f_norm_pv
	beq	emu_op_c9
	»)
				;nok

OP_DD(df,«»)
OP_CB(df,«»)
OP_DDCB(df,«»)
OP_FD(df,«»)
OP_FDCB(df,«»)
OP_ED(df,«»)

	;; POP	HL
OPCODE(e1,«
	POPW	ehl
	»)
				;nok

OP_DD(e0,«»)
OP_CB(e0,«»)
OP_DDCB(e0,«»)
OP_FD(e0,«»)
OP_FDCB(e0,«»)
OP_ED(e0,«»)

	;; JP	PO,immed.w
OPCODE(e2,«
	jsr	f_norm_pv
	beq	emu_op_c3
	add.l	#2,epc
	»)
				;nok

OP_DD(e1,«»)
OP_CB(e1,«»)
OP_DDCB(e1,«»)
OP_FD(e1,«»)
OP_FDCB(e1,«»)
OP_ED(e1,«»)

	;; EX	(SP),HL
	;; Exchange
OPCODE(e3,«
	POPW	d1
	PUSHW	ehl
	move.w	d1,ehl
	»)
				;nok

OP_DD(e2,«»)
OP_CB(e2,«»)
OP_DDCB(e2,«»)
OP_FD(e2,«»)
OP_FDCB(e2,«»)
OP_ED(e2,«»)

	;; CALL	PO,immed.w
	;; if parity odd (P=0), call
OPCODE(e4,«
	jsr	f_norm_pv
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(e3,«»)
OP_CB(e3,«»)
OP_DDCB(e3,«»)
OP_FD(e3,«»)
OP_FDCB(e3,«»)
OP_ED(e3,«»)

	;; PUSH	HL
OPCODE(e5,«
	PUSHW	ehl
	»)
				;nok

OP_DD(e4,«»)
OP_CB(e4,«»)
OP_DDCB(e4,«»)
OP_FD(e4,«»)
OP_FDCB(e4,«»)
OP_ED(e4,«»)

	;; AND	immed.b
OPCODE(e6,«
	FETCHBI	d1
	F_AND_B	d1,eaf
	»)
				;nok

OP_DD(e5,«»)
OP_CB(e5,«»)
OP_DDCB(e5,«»)
OP_FD(e5,«»)
OP_FDCB(e5,«»)
OP_ED(e5,«»)

	;; RST	&20
	;;  == CALL 20
OPCODE(e7,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$20,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(e6,«»)
OP_CB(e6,«»)
OP_DDCB(e6,«»)
OP_FD(e6,«»)
OP_FDCB(e6,«»)
OP_ED(e6,«»)

	;; RET	PE
	;; If parity odd (P zero), return
OPCODE(e8,«
	jsr	f_norm_pv
	bne	emu_op_c9
	»)
				;nok

OP_DD(e7,«»)
OP_CB(e7,«»)
OP_DDCB(e7,«»)
OP_FD(e7,«»)
OP_FDCB(e7,«»)
OP_ED(e7,«»)

	;; JP	(HL)
OPCODE(e9,«
	FETCHB	ehl,d1
	jsr	deref
	movea.l	a0,epc
	»)
				;nok

OP_DD(e8,«»)
OP_CB(e8,«»)
OP_DDCB(e8,«»)
OP_FD(e8,«»)
OP_FDCB(e8,«»)
OP_ED(e8,«»)

	;; JP	PE,immed.w
OPCODE(ea,«
	jsr	f_norm_pv
	bne	emu_op_c3
	add.l	#2,epc
	»)
				;nok

OP_DD(e9,«»)
OP_CB(e9,«»)
OP_DDCB(e9,«»)
OP_FD(e9,«»)
OP_FDCB(e9,«»)
OP_ED(e9,«»)

	;; EX	DE,HL
OPCODE(eb,«
	exg.w	ede,ehl
	»)
				;nok

OP_DD(ea,«»)
OP_CB(ea,«»)
OP_DDCB(ea,«»)
OP_FD(ea,«»)
OP_FDCB(ea,«»)
OP_ED(ea,«»)

	;; CALL	PE,immed.w
	;; If parity even (P=1), call
OPCODE(ec,«
	jsr	f_norm_c
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(eb,«»)
OP_CB(eb,«»)
OP_DDCB(eb,«»)
OP_FD(eb,«»)
OP_FDCB(eb,«»)
OP_ED(eb,«»)

	;; XXX this probably ought to hold interrupts too
OPCODE(ed,«			; prefix
	movea.w	emu_op_undo_ed(pc),a2
	»)
				;nok

OP_DD(ec,«»)
OP_CB(ec,«»)
OP_DDCB(ec,«»)
OP_FD(ec,«»)
OP_FDCB(ec,«»)
OP_ED(ec,«»)

	;; XOR	immed.b
OPCODE(ee,«
	FETCHBI	d1
	F_XOR_B	d1,eaf
	»)
				;nok

OP_DD(ed,«»)
OP_CB(ed,«»)
OP_DDCB(ed,«»)
OP_FD(ed,«»)
OP_FDCB(ed,«»)
OP_ED(ed,«»)

	;; RST	&28
	;;  == CALL 28
OPCODE(ef,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$28,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(ee,«»)
OP_CB(ee,«»)
OP_DDCB(ee,«»)
OP_FD(ee,«»)
OP_FDCB(ee,«»)
OP_ED(ee,«»)

	;; RET	P
	;; Return if Positive
OPCODE(f0,«
	jsr	f_norm_sign
	beq	emu_op_c9	; RET
	»)
				;nok

OP_DD(ef,«»)
OP_CB(ef,«»)
OP_DDCB(ef,«»)
OP_FD(ef,«»)
OP_FDCB(ef,«»)
OP_ED(ef,«»)

	;; POP	AF
	;; SPEED this can be made faster ...
	;; XXX AF
OPCODE(f1,«
	POPW	eaf
	move.w	eaf,(flag_byte-flag_storage)(a3)
	move.b	#$ff,(flag_valid-flag_storage)(a3)
	»)
				;nok

OP_DD(f0,«»)
OP_CB(f0,«»)
OP_DDCB(f0,«»)
OP_FD(f0,«»)
OP_FDCB(f0,«»)
OP_ED(f0,«»)

	;; JP	P,immed.w
OPCODE(f2,«
	jsr	f_norm_sign
	beq	emu_op_c3	; JP
	add.l	#2,epc
	»)
				;nok

OPCODE(f3,«
OP_DD(f1,«»)
OP_CB(f1,«»)
OP_DDCB(f1,«»)
OP_FD(f1,«»)
OP_FDCB(f1,«»)
OP_ED(f1,«»)

	;; DI
	jsr	ints_stop
	»)

OP_DD(f2,«»)
OP_CB(f2,«»)
OP_DDCB(f2,«»)
OP_FD(f2,«»)
OP_FDCB(f2,«»)
OP_ED(f2,«»)

	;; CALL	P,&0000
	;; Call if positive (S=0)
OPCODE(f4,«
	jsr	f_norm_sign
	beq	emu_op_cd
	»)
				;nok

OP_DD(f3,«»)
OP_CB(f3,«»)
OP_DDCB(f3,«»)
OP_FD(f3,«»)
OP_FDCB(f3,«»)
OP_ED(f3,«»)

	;; PUSH	AF
OPCODE(f5,«
	jsr	flags_normalize
	LOHI	eaf
	move.b	flag_byte(pc),eaf
	;; XXX wrong, af is not normalized by flags_normalize?
	HILO	eaf
	PUSHW	eaf
	»)
				;nok

OP_DD(f5,«»)
OP_CB(f5,«»)
OP_DDCB(f5,«»)
OP_FD(f5,«»)
OP_FDCB(f5,«»)
OP_ED(f5,«»)

	;; OR	immed.b
OPCODE(f6,«
	FETCHBI	d1
	F_OR_B	d1,eaf
	»)
				;nok

OP_DD(f6,«»)
OP_CB(f6,«»)
OP_DDCB(f6,«»)
OP_FD(f6,«»)
OP_FDCB(f6,«»)
OP_ED(f6,«»)

	;; RST	&30
	;;  == CALL 30
OPCODE(f7,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$30,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(f7,«»)
OP_CB(f7,«»)
OP_DDCB(f7,«»)
OP_FD(f7,«»)
OP_FDCB(f7,«»)
OP_ED(f7,«»)

	;; RET	M
	;; Return if Sign == 1, minus
OPCODE(f8,«
	jsr	f_norm_sign
	bne	emu_op_c9	; RET
	»)
				;nok

OP_DD(f8,«»)
OP_CB(f8,«»)
OP_DDCB(f8,«»)
OP_FD(f8,«»)
OP_FDCB(f8,«»)
OP_ED(f8,«»)

	;; LD	SP,HL
	;; SP <- HL
OPCODE(f9,«
	move.w	ehl,d1
	jsr	deref
	movea.l	a0,esp
	»)
				;nok

OP_DD(f9,«»)
OP_CB(f9,«»)
OP_DDCB(f9,«»)
OP_FD(f9,«»)
OP_FDCB(f9,«»)
OP_ED(f9,«»)

	;; JP	M,immed.w
OPCODE(fa,«
	jsr	f_norm_sign
	bne	emu_op_c3	; JP
	add.l	#2,epc
	»)
				;nok

OP_DD(fa,«»)
OP_CB(fa,«»)
OP_DDCB(fa,«»)
OP_FD(fa,«»)
OP_FDCB(fa,«»)
OP_ED(fa,«»)

	;; EI
OPCODE(fb,«
	jsr	ints_start
	»)
				;nok

OP_DD(fb,«»)
OP_CB(fb,«»)
OP_DDCB(fb,«»)
OP_FD(fb,«»)
OP_FDCB(fb,«»)
OP_ED(fb,«»)

	;; CALL	M,immed.w
	;; Call if minus (S=1)
OPCODE(fc,«
	jsr	f_norm_sign
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OP_DD(fc,«»)
OP_CB(fc,«»)
OP_DDCB(fc,«»)
OP_FD(fc,«»)
OP_FDCB(fc,«»)
OP_ED(fc,«»)

	;; swap IY, HL
OPCODE(fd,«			; prefix
	movea.w	emu_op_undo_fd(pc),a2
	»)

OP_DD(fd,«»)
OP_CB(fd,«»)
OP_DDCB(fd,«»)
OP_FD(fd,«»)
OP_FDCB(fd,«»)
OP_ED(fd,«»)

	;; CP	immed.b
OPCODE(fe,«
	FETCHBI	d1
	F_CP_B	d1,eaf
	»)
				;nok

OP_DD(fe,«»)
OP_CB(fe,«»)
OP_DDCB(fe,«»)
OP_FD(fe,«»)
OP_FDCB(fe,«»)
OP_ED(fe,«»)

	;; RST	&38
	;;  == CALL 38
OPCODE(ff,«
	move.l	epc,a0
	jsr	underef
	PUSHW	d0
	move.w	#$38,d0
	jsr	deref
	move.l	a0,epc
	»)
				;nok

OP_DD(ff,«»)
OP_CB(ff,«»)
OP_DDCB(ff,«»)
OP_FD(ff,«»)
OP_FDCB(ff,«»)
OP_ED(ff,«»)

