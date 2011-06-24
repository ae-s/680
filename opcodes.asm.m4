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
FETCHW	MACRO			;  ?/16
	move.w	\1,d1		;  4/2
	bsr	deref		;  ?/4
	;; XXX SPEED
	move.b	(a0)+,d2
	move.b	(a0),\2
	rol.w	#8,\2
	move.b	d2,\2
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

	;; Push the word in \1 (register) using stack register esp.
	;; Sadly, I can't trust the stack register to be aligned.
	;; Destroys d2.

	;;   (SP-2) <- \1_l
	;;   (SP-1) <- \1_h
	;;   SP <- SP - 2
PUSHW	MACRO
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
POPW	MACRO
	move.b	(esp)+,\1
	LOHI	\1		;slow
	move.b	(esp)+,\1	; high byte
	HILO	\1		;slow
	ENDM

	;; == Immediate Memory Macros ==

	;; Macro to read an immediate byte into \1.
FETCHBI	MACRO			; 8 cycles, 2 bytes
	move.b	(epc)+,\1	; 8/2
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
_align	SET	_align+$40	; opcode routine length
	bra.w	do_interrupt	; for interrupt routines
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
	move.l	\1,-(sp)	;12 cycles / 2 bytes
	movep.w	0(sp),\1	;16 cycles / 4 bytes
	swap	\1		; 4 cycles / 2 bytes
	movep.w	1(sp),\1	;16 cycles / 4 bytes
	addq	#4,sp		; 4 cycles / 2 bytes
	;; overhead:		 52 cycles /14 bytes
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
	st	f_tmp_src_b-flag_storage(a3) ;; why did I do this?
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


	;; This is run at the end of every instruction routine.
done:
	clr.w	d0		; 4 cycles / 2 bytes
	move.b	(epc)+,d0	; 8 cycles / 2 bytes
	move.b	d0,$4c00+32*(128/8)
	rol.w	#6,d0		;18 cycles / 2 bytes
	jmp	0(a5,d0.w)	;14 cycles / 4 bytes
	;; overhead:		 42 cycles /10 bytes


DONE	MACRO
	bra	done
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
	;; NOP
OPCODE(00,«»,4)

	;; LD	BC,immed.w
	;; Read a word and put it in BC
	;; No flags
OPCODE(01,«
	FETCHWI	ebc
	»,36,,12)

	;; LD	(BC),A
	;; (BC) <- A
	;; No flags
OPCODE(02,«
	PUTB	eaf,ebc
	»,14,,4)

	;; INC	BC
	;; BC <- BC+1
	;; No flags
OPCODE(03,«
	F_INC_W	ebc
	»,4,,2)

	;; INC	B
	;; B <- B+1
OPCODE(04,«
	LOHI	ebc
	F_INC_B	ebc
	HILO	ebc
	»)

	;; DEC	B
	;; B <- B-1
OPCODE(05,«
	LOHI	ebc
	F_DEC_B	ebc
	HILO	ebc
	»)
				;nok

	;; LD	B,immed.b
	;; Read a byte and put it in B
	;; B <- immed.b
	;; No flags
OPCODE(06,«
	LOHI	ebc
	FETCHBI	ebc
	HILO	ebc
	»,26,,10)
				;nok

	;; RLCA
	;; Rotate A left, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX flags
OPCODE(07,«
	rol.b	#1,eaf
	»,4,,2)
				;nok

	;; EX	AF,AF'
	;; No flags
	;; XXX AF
OPCODE(08,«
	swap	eaf
	»,4,,2)
				;nok

	;; ADD	HL,BC
	;; HL <- HL+BC
	;; Flags: H, C aff.; N=0
OPCODE(09,«
	F_ADD_W	ebc,ehl
	»)
				;nok

	;; LD	A,(BC)
	;; A <- (BC)
	;; No flags
OPCODE(0a,«
	FETCHB	ebc,eaf
	»,14,,4)

	;; DEC	BC
	;; BC <- BC-1
	;; No flags
OPCODE(0b,«
	F_DEC_W	ebc
	»,4,,2)
				;nok

	;; INC	C
	;; C <- C+1
	;; Flags: S,Z,H aff.; P=overflow, N=0
OPCODE(0c,«
	F_INC_B	ebc
	»)
				;nok

	;; DEC	C
	;; C <- C-1
	;; Flags: S,Z,H aff., P=overflow, N=1
OPCODE(0d,«
	F_DEC_B	ebc
	»)
				;nok

	;; LD	C,immed.b
	;; No flags
OPCODE(0e,«
	FETCHBI	ebc
	»,18,,6)
				;nok

	;; RRCA
	;; Rotate A right, carry bit gets top bit
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
OPCODE(0f,«
	ror.b	#1,eaf
	»)
				;nok

	;; DJNZ	immed.w
	;; Decrement B
	;;  and branch by immed.b
	;;  if B not zero
	;; No flags
OPCODE(10,«
	LOHI	ebc
	subq.b	#1,ebc
	beq.s	local(end)	; slooooow
	FETCHBI	d1
	move.l	epc,a0
	bsr	underef
	add.w	d1,d0		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move.l	a0,epc
local(end):
	HILO	ebc
	»,,,32)
				;nok

	;; LD	DE,immed.w
	;; No flags
OPCODE(11,«
	FETCHWI	ede
	»)
				;nok

	;; LD	(DE),A
	;; No flags
OPCODE(12,«
	move.w	ede,d0
	rol.w	#8,d0
	FETCHB	d0,eaf
	»)
				;nok

	;; INC	DE
	;; No flags
OPCODE(13,«
	F_INC_W	ede
	»)
				;nok

	;; INC	D
	;; Flags: S,Z,H aff.; P=overflow, N=0
OPCODE(14,«
	LOHI	ede
	F_INC_B	ede
	HILO	ede
	»)
				;nok

	;; DEC	D
	;; Flags: S,Z,H aff.; P=overflow, N=1
OPCODE(15,«
	LOHI	ede
	F_DEC_B	ede
	HILO	ede
	»)
				;nok

	;; LD D,immed.b
	;; No flags
OPCODE(16,«
	LOHI	ede
	FETCHBI	ede
	HILO	ede
	»)
				;nok

	;; RLA
	;; Flags: P,N=0; C aff.
	;; XXX flags
OPCODE(17,«
	roxl.b	#1,eaf
	»)
				;nok

	;; JR	immed.b
	;; PC <- immed.b
	;; Branch relative by a signed immediate byte
	;; No flags
OPCODE(18,«
	clr.w	d1
	FETCHBI	d1
	move.l	epc,a0
	bsr	underef
	add.w	d0,d1		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; ADD	HL,DE
	;; HL <- HL+DE
	;; Flags: H,C aff,; N=0
OPCODE(19,«
	F_ADD_W	ede,ehl
	»)
				;nok

	;; LD	A,(DE)
	;; A <- (DE)
	;; No flags
OPCODE(1a,«
	FETCHB	ede,eaf
	»)
				;nok

	;; DEC	DE
	;; No flags
OPCODE(1b,«
	subq.w	#1,ede
	»)
				;nok

	;; INC	E
	;; Flags: S,Z,H aff.; P=overflow; N=0
OPCODE(1c,«
	F_INC_B	ede
	»)
				;nok

	;; DEC	E
	;; Flags: S,Z,H aff.; P=overflow, N=1
OPCODE(1d,«
	F_DEC_B	ede
	»)
				;nok

	;; LD	E,immed.b
	;; No flags
OPCODE(1e,«
	FETCHBI	ede
	»)
				;nok

	;; RRA
	;; Flags: H,N=0; C aff.
	;; XXX FLAGS
OPCODE(1f,«
	roxr.b	#1,eaf
	»)
				;nok

	;; JR	NZ,immed.b
	;; if ~Z,
	;;  PC <- PC+immed.b
	;; No flags
OPCODE(20,«
	bsr	f_norm_z
	;; if the emulated Z flag is set, this will be clear
	beq	emu_op_18	; branch taken: Z reset -> eq (zero set)
	add.l	#1,epc		; skip over the immediate byte
	»)

	;; LD	HL,immed.w
	;; No flags
OPCODE(21,«
	FETCHWI	ehl
	»)
				;nok

	;; LD	immed.w,HL
	;; (address) <- HL
	;; No flags
OPCODE(22,«
	FETCHWI	d1
	PUTW	ehl,d1
	»)
				;nok

	;; INC	HL
	;; No flags
OPCODE(23,«
	addq.w	#1,ehl
	»)
				;nok

	;; INC	H
	;; Flags: S,Z,H aff.; P=overflow, N=0
OPCODE(24,«
	LOHI	ehl
	F_INC_B	ehl
	HILO	ehl
	»)
				;nok

	;; DEC	H
	;; Flags: S,Z,H aff.; P=overflow, N=1
OPCODE(25,«
	LOHI	ehl
	F_DEC_B	ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,immed.b
	;; No flags
OPCODE(26,«
	LOHI	ehl
	FETCHBI	ehl
	HILO	ehl
	»)
				;nok

	;; DAA
	;; Decrement, adjust accum
	;; http://www.z80.info/z80syntx.htm#DAA
	;; Flags: oh lord they're fucked up
	;; XXX DO THIS
OPCODE(27,«
	F_PAR	eaf
	»)
				;nok

	;; JR Z,immed.b
	;; If zero
	;;  PC <- PC+immed.b
	;; SPEED can be made faster
	;; No flags
OPCODE(28,«
	bsr	f_norm_z
	bne	emu_op_18
	add.l	#1,epc
	»)
				;nok

	;; ADD	HL,HL
	;; No flags
OPCODE(29,«
	F_ADD_W	ehl,ehl
	»)
				;nok

	;; LD	HL,(immed.w)
	;; address is absolute
OPCODE(2a,«
	FETCHWI	d1
	FETCHW	d1,ehl
	»)
				;nok

	;; XXX TOO LONG
	;; DEC	HL
OPCODE(2b,«
	F_DEC_W	ehl
	»)
				;nok

	;; INC	L
OPCODE(2c,«
	F_INC_B	ehl
	»)
				;nok

	;; DEC	L
OPCODE(2d,«
	F_DEC_B	ehl
	»)
				;nok

	;; LD	L,immed.b
OPCODE(2e,«
	FETCHBI	ehl
	»)
				;nok

	;; CPL
	;; A <- NOT A
	;; XXX flags
OPCODE(2f,«
	not.b	eaf
	»)
				;nok

	;; JR	NC,immed.b
	;; If carry clear
	;;  PC <- PC+immed.b
OPCODE(30,«
	bsr	f_norm_c
	beq	emu_op_18	; branch taken: carry clear
	add.l	#1,epc
	»)

	;; LD	SP,immed.w
OPCODE(31,«
	FETCHWI	d1
	bsr	deref
	movea.l	a0,esp
	»)
				;nok

	;; LD	(immed.w),A
	;; store indirect
OPCODE(32,«
	FETCHWI	d1
	rol.w	#8,d1
	PUTB	eaf,d1
	»)
				;nok

	;; INC	SP
	;; No flags
	;;
	;; FYI:  Do not have to deref because this will never cross a
	;; page boundary.  So sayeth BrandonW.
OPCODE(33,«
	addq.w	#1,esp
	»)
				;nok

	;; INC	(HL)
	;; Increment byte
	;; SPEED can be made faster
OPCODE(34,«
	FETCHB	ehl,d1
	F_INC_B	d1
	PUTB	d1,ehl
	»)
				;nok

	;; DEC	(HL)
	;; Decrement byte
	;; SPEED can be made faster
OPCODE(35,«
	FETCHB	ehl,d1
	F_DEC_B	d1
	PUTB	d1,ehl
	»)
				;nok

	;; LD	(HL),immed.b
OPCODE(36,«
	FETCHBI	d1
	PUTB	ehl,d1
	»)
				;nok

	;; SCF
	;; Set Carry Flag
	;; XXX flags are more complicated than this :(
OPCODE(37,«
	ori.b	#%00111011,flag_valid-flag_storage(a3)
	move.b	eaf,d1
	ori.b	#%00000001,d1
	andi.b	#%11101101,d1
	or.b	d1,flag_byte-flag_storage(a3)
	»)
				;nok

	;; JR	C,immed.b
	;; If carry set
	;;  PC <- PC+immed.b
OPCODE(38,«
	bsr	f_norm_c
	bne	emu_op_18
	add.l	#1,epc
	»)

	;; ADD	HL,SP
	;; HL <- HL+SP
OPCODE(39,«
	move.l	esp,a0
	bsr	underef
	F_ADD_W	ehl,d0		; ??? Can I avoid underef/deref cycle?
	bsr	deref
	move.l	a0,esp
	»)
				;nok

	;; LD	A,(immed.w)
OPCODE(3a,«
	FETCHWI	d1
	FETCHB	d1,eaf
	»)
				;nok

	;; DEC	SP
	;; No flags
OPCODE(3b,«
	subq.l	#1,esp
	»)
				;nok

	;; INC	A
OPCODE(3c,«
	F_INC_B	eaf
	»)

	;; DEC	A
OPCODE(3d,«
	F_DEC_B	eaf
	»)
				;nok

	;; LD	A,immed.b
OPCODE(3e,«
	FETCHBI	eaf
	»)

	;; CCF
	;; Clear carry flag
	;; XXX fuck flags
OPCODE(3f,«
	bsr	flags_normalize
	;; 	  SZ5H3PNC
	ori.b	#%00000001,flag_valid-flag_storage(a3)
	andi.b	#%11111110,flag_byte-flag_storage(a3)
	»)
				;nok

	;; LD	B,B
	;; SPEED
OPCODE(40,«
	LOHI	ebc
	move.b	ebc,ebc
	HILO	ebc
	»)
				;nok

	;; LD	B,C
OPCODE(41,«
	move.w	ebc,d1
	LOHI	d1
	move.b	d1,ebc
	»)
				;nok

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

	;; LD	B,E
	;; B <- E
OPCODE(43,«
	LOHI	ebc
	move.b	ebc,ede		; 4
	HILO	ebc
	»)
				;nok

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

	;; LD	B,L
	;; B <- L
OPCODE(45,«
	LOHI	ebc
	move.b	ehl,ebc
	HILO	ebc
	»)
				;nok

	;; LD	B,(HL)
	;; B <- (HL)
OPCODE(46,«
	LOHI	ebc
	FETCHB	ehl,ebc
	HILO	ebc
	»)
				;nok

	;; LD	B,A
	;; B <- A
OPCODE(47,«
	LOHI	ebc
	move.b	eaf,ebc
	HILO	ebc
	»)
				;nok

	;; LD	C,B
	;; C <- B
OPCODE(48,«
	move.w	ebc,-(sp)
	move.b	(sp),ebc
	;; XXX emfasten?
	addq.l #2,sp
	»)
				;nok

	;; LD	C,C
OPCODE(49,«
	move.b	ebc,ebc
	»)
				;nok

	;; LD	C,D
OPCODE(4a,«
	move.w	ede,-(sp)
	move.b	(sp),ebc
	;; XXX emfasten?
	addq.l #2,sp
	»)
				;nok

	;; LD	C,E
OPCODE(4b,«
	move.b	ebc,ede
	»)
				;nok

	;; LD	C,H
OPCODE(4c,«
	LOHI	ehl
	move.b	ebc,ehl
	HILO	ehl
	»)
				;nok

	;; LD	C,L
OPCODE(4d,«
	move.b	ebc,ehl
	»)
				;nok

	;; LD	C,(HL)
	;; C <- (HL)
OPCODE(4e,«
	FETCHB	ehl,ebc
	»)
				;nok

	;; LD	C,A
OPCODE(4f,«
	move.b	eaf,ebc
	»)
				;nok

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

	;; LD	D,C
OPCODE(51,«
	LOHI	ede
	move.b	ebc,ede
	HILO	ede
	»)
				;nok

	;; LD	D,D
OPCODE(52,«
	»)
				;nok

	;; LD	D,E
OPCODE(53,«
	andi.w	#$00ff,ede
	move.b	ede,d1
	lsl	#8,d1
	or.w	d1,ede
	»)
				;nok

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

	;; LD	D,L
OPCODE(55,«
	LOHI	ede
	move.b	ehl,ede
	HILO	ede
	»)
				;nok

	;; LD	D,(HL)
	;; D <- (HL)
OPCODE(56,«
	LOHI	ede
	FETCHB	ehl,ede
	HILO	ede
	»)
				;nok

	;; LD	D,A
OPCODE(57,«
	LOHI	ede
	move.b	eaf,ede
	HILO	ede
	»)
				;nok

	;; LD	E,B
OPCODE(58,«
	LOHI	ebc
	move.b	ebc,ede
	HILO	ebc
	»)
				;nok

	;; LD	E,C
OPCODE(59,«
	move.b	ebc,ede
	»)
				;nok

	;; LD	E,D
OPCODE(5a,«
	andi.w	#$ff00,ede	; 8/4
	move.b	ede,d1		; 4/2
	lsr.w	#8,d1		;22/2
	or.w	d1,ede		; 4/2
	»,38,,2)
				;nok

	;; LD	E,E
OPCODE(5b,«
	move.b	ede,ede
	»)
				;nok

	;; LD	E,H
OPCODE(5c,«
	LOHI	ehl
	move.b	ede,ehl
	HILO	ehl
	»)
				;nok

	;; LD	E,L
OPCODE(5d,«
	move.b	ede,ehl
	»)
				;nok

	;; LD	E,(HL)
OPCODE(5e,«
	FETCHB	ehl,d1
	»)
				;nok

	;; LD	E,A
OPCODE(5f,«
	move.b	ede,eaf
	»)
				;nok

	;; LD	H,B
OPCODE(60,«
	LOHI	ebc
	LOHI	ehl
	move.b	ehl,ebc
	HILO	ebc
	HILO	ehl
	»)
				;nok

	;; LD	H,C
OPCODE(61,«
	LOHI	ehl
	move.b	ebc,ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,D
OPCODE(62,«
	LOHI	ede
	LOHI	ehl
	move.b	ede,ehl
	HILO	ede
	HILO	ehl
	»)
				;nok

	;; LD	H,E
OPCODE(63,«
	LOHI	ehl
	move.b	ede,ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,H
OPCODE(64,«
	LOHI	ehl
	move.b	ehl,ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,L
	;; H <- L
OPCODE(65,«
	move.b	ehl,d1
	LOHI	ehl
	move.b	d1,ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,(HL)
OPCODE(66,«
	FETCHB	ehl,d1
	LOHI	ehl
	move.b	d1,ehl
	HILO	ehl
	»)
				;nok

	;; LD	H,A
OPCODE(67,«
	LOHI	ehl
	move.b	eaf,ehl
	HILO	ehl
	»)
				;nok

	;; LD	L,B
OPCODE(68,«
	LOHI	ebc
	move.b	ebc,ehl
	HILO	ebc
	»)
				;nok

	;; LD	L,C
OPCODE(69,«
	move.b	ebc,ehl
	»)
				;nok

	;; LD	L,D
OPCODE(6a,«
	LOHI	ede
	move.b	ede,ehl
	HILO	ede
	»)
				;nok

	;; LD	L,E
OPCODE(6b,«
	move.b	ede,ehl
	»)
				;nok

	;; LD	L,H
OPCODE(6c,«
	move.b	ehl,d1
	LOHI	d1
	move.b	d1,ehl
	»)
				;nok

	;; LD	L,L
OPCODE(6d,«
	move.b	ehl,ehl
	»)
				;nok

	;; LD	L,(HL)
	;; L <- (HL)
OPCODE(6e,«
	FETCHB	ehl,ehl
	»)
				;nok

	;; LD	L,A
OPCODE(6f,«
	move.b	eaf,ehl
	»)
				;nok

	;; LD	(HL),B
OPCODE(70,«
	LOHI	ebc
	PUTB	ehl,ebc
	HILO	ebc
	»)
				;nok

	;; LD	(HL),C
OPCODE(71,«
	PUTB	ehl,ebc
	»)
				;nok

	;; LD	(HL),D
OPCODE(72,«
	LOHI	ede
	PUTB	ehl,ede
	HILO	ede
	»)
				;nok

	;; LD	(HL),E
OPCODE(73,«
	PUTB	ehl,ede
	»)
				;nok

	;; LD	(HL),H
OPCODE(74,«
	move.w	ehl,d1
	HILO	d1
	PUTB	d1,ehl
	»)
				;nok

	;; LD	(HL),L
OPCODE(75,«
	move.b	ehl,d1
	PUTB	d1,ehl
	»)
				;nok

	;; HALT
	;; XXX do this
OPCODE(76,«
	bra	emu_op_76
	»)
				;nok

	;; LD	(HL),A
OPCODE(77,«
	PUTB	eaf,ehl
	»)
				;nok

	;; LD	A,B
OPCODE(78,«
	move.w	ebc,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

	;; LD	A,C
OPCODE(79,«
	move.b	ebc,eaf
	»)
				;nok

	;; LD	A,D
OPCODE(7a,«
	move.w	ede,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

	;; LD	A,E
OPCODE(7b,«
	move.b	ede,eaf
	»)
				;nok

	;; LD	A,H
OPCODE(7c,«
	move.w	ehl,d1
	LOHI	d1
	move.b	d1,eaf
	»)
				;nok

	;; LD	A,L
OPCODE(7d,«
	move.b	ehl,eaf
	»)
				;nok

	;; LD	A,(HL)
	;; A <- (HL)
OPCODE(7e,«
	FETCHB	ehl,eaf
	»)

	;; LD	A,A
OPCODE(7f,«
	»)
				;nok



	;; Do an ADD \2,\1
F_ADD_B	MACRO			; 14 bytes?
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_add
	move.b	d1,\2
	ENDM

	;; ADD	A,B
OPCODE(80,«
	LOHI	ebc
	F_ADD_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; ADD	A,C
OPCODE(81,«
	F_ADD_B	ebc,eaf
	»)
				;nok

	;; ADD	A,D
OPCODE(82,«
	LOHI	ede
	F_ADD_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; ADD	A,E
OPCODE(83,«
	F_ADD_B	ede,eaf
	»)
				;nok

	;; ADD	A,H
OPCODE(84,«
	LOHI	ehl
	F_ADD_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; ADD	A,L
OPCODE(85,«
	F_ADD_B	ehl,eaf
	»)
				;nok

	;; ADD	A,(HL)
	;; XXX size?
OPCODE(86,«
	FETCHB	ehl,d2
	F_ADD_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; ADD	A,A
OPCODE(87,«
	F_ADD_B	eaf,eaf
	»)
				;nok



	;; Do an ADC \2,\1
F_ADC_B	MACRO			; S34
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_adc
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

	;; ADC	A,C
	;; A <- A + C + (carry)
OPCODE(89,«
	F_ADC_B	ebc,eaf
	»)
				;nok

	;; ADC	A,D
OPCODE(8a,«
	LOHI	ede
	F_ADC_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; ADC	A,E
	;; A <- A + E + carry
OPCODE(8b,«
	F_ADC_B	ede,eaf
	»)
				;nok

	;; ADC	A,H
OPCODE(8c,«
	LOHI	eaf
	F_ADC_B	ehl,eaf
	HILO	eaf
	»)
				;nok

	;; ADC	A,L
OPCODE(8d,«
	F_ADC_B	ehl,eaf
	»)
				;nok

	;; ADC	A,(HL)
OPCODE(8e,«
	FETCHB	ehl,d2
	F_ADC_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; ADC	A,A
OPCODE(8f,«
	F_ADC_B	eaf,eaf
	»)
				;nok





	;; Do a SUB \2,\1
F_SUB_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_sub
	move.b	d1,\2
	ENDM

	;; SUB	A,B
OPCODE(90,«
	LOHI	ebc
	F_SUB_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; SUB	A,C
OPCODE(91,«
	F_SUB_B	ebc,eaf
	»)
				;nok

	;; SUB	A,D
OPCODE(92,«
	LOHI	ede
	F_SUB_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; SUB	A,E
OPCODE(93,«
	F_SUB_B	ede,eaf
	»)
				;nok

	;; SUB	A,H
OPCODE(94,«
	LOHI	ehl
	F_SUB_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; SUB	A,L
OPCODE(95,«
	F_SUB_B	ehl,eaf
	»)

	;; SUB	A,(HL)
OPCODE(96,«
	FETCHB	ehl,d2
	F_SUB_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; SUB	A,A
OPCODE(97,«
	F_SUB_B	eaf,eaf
	»)
				;nok




	;; Do a SBC \2,\1
F_SBC_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_sbc
	move.b	d1,\2
	ENDM

	;; SBC	A,B
OPCODE(98,«
	LOHI	ebc
	F_SBC_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; SBC	A,C
OPCODE(99,«
	F_SBC_B	ebc,eaf
	»)
				;nok

	;; SBC	A,D
OPCODE(9a,«
	LOHI	ede
	F_SBC_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; SBC	A,E
OPCODE(9b,«
	F_SBC_B	ede,eaf
	»)
				;nok

	;; SBC	A,H
OPCODE(9c,«
	LOHI	ehl
	F_SBC_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; SBC	A,L
OPCODE(9d,«
	F_SBC_B	ehl,eaf
	»)
				;nok

	;; SBC	A,(HL)
OPCODE(9e,«
	FETCHB	ehl,d2
	F_SBC_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; SBC	A,A
OPCODE(9f,«
	F_SBC_B	eaf,eaf
	»)
				;nok





F_AND_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_and
	move.b	d1,\2
	ENDM

	;; AND	B
OPCODE(a0,«
	LOHI	ebc
	F_AND_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; AND	C
OPCODE(a1,«
	F_AND_B	ebc,eaf
	»)

	;; AND	D
OPCODE(a2,«
	LOHI	ede
	F_AND_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; AND	E
OPCODE(a3,«
	F_AND_B	ede,eaf
	»)
				;nok

	;; AND	H
OPCODE(a4,«
	LOHI	ehl
	F_AND_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; AND	L
OPCODE(a5,«
	F_AND_B	ehl,eaf
	»)
				;nok

	;; AND	(HL)
OPCODE(a6,«
	FETCHB	ehl,d2
	F_AND_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; AND	A
	;; SPEED ... It's probably not necessary to run this faster.
OPCODE(a7,«
	F_AND_B	eaf,eaf
	»)
				;nok





F_XOR_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_xor
	move.b	d1,\2
	ENDM

	;; XOR	B
OPCODE(a8,«
	LOHI	ebc
	F_XOR_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; XOR	C
OPCODE(a9,«
	F_XOR_B	ebc,eaf
	»)
				;nok

	;; XOR	D
OPCODE(aa,«
	LOHI	ede
	F_XOR_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; XOR	E
OPCODE(ab,«
	F_XOR_B	ede,eaf
	»)
				;nok

	;; XOR	H
OPCODE(ac,«
	LOHI	ehl
	F_XOR_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; XOR	L
OPCODE(ad,«
	F_XOR_B	ehl,eaf
	»)
				;nok

	;; XOR	(HL)
OPCODE(ae,«
	FETCHB	ehl,d2
	F_XOR_B	d2,eaf
	PUTB	d2,ehl
	»)
				;nok

	;; XOR	A
OPCODE(af,«
	F_XOR_B	eaf,eaf
	;; XXX
	»)
				;nok





F_OR_B	MACRO
	move.b	\2,d1
	move.b	\1,d0
	bsr	alu_or
	move.b	d1,\2
	ENDM

	;; OR	B
OPCODE(b0,«
	LOHI	ebc
	F_OR_B	ebc,eaf
	HILO	ebc
	»)
				;nok

	;; OR	C
OPCODE(b1,«
	F_OR_B	ebc,eaf
	»)
				;nok

	;; OR	D
OPCODE(b2,«
	LOHI	ede
	F_OR_B	ede,eaf
	HILO	ede
	»)
				;nok

	;; OR	E
OPCODE(b3,«
	F_OR_B	ede,eaf
	»)
				;nok

	;; OR	H
OPCODE(b4,«
	LOHI	ehl
	F_OR_B	ehl,eaf
	HILO	ehl
	»)
				;nok

	;; OR	L
OPCODE(b5,«
	F_OR_B	ehl,eaf
	»)
				;nok

	;; OR	(HL)
OPCODE(b6,«
	;; SPEED unnecessary move
	FETCHB	ehl,d2
	F_OR_B	d2,eaf
	»)
				;nok

OPCODE(b7,«
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
	bsr	alu_cp
	;; no result to save
	ENDM

	;; CP	B
OPCODE(b8,«
	move.w	ebc,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

	;; CP	C
OPCODE(b9,«
	F_CP_B	ebc,eaf
	»)
				;nok

	;; CP	D
OPCODE(ba,«
	move.w	ede,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

	;; CP	E
OPCODE(bb,«
	F_CP_B	ede,eaf
	»)
				;nok

	;; CP	H
OPCODE(bc,«
	move.w	ehl,d2
	LOHI	d2
	F_CP_B	d2,eaf
	»)
				;nok

	;; CP	L
OPCODE(bd,«
	F_CP_B	ehl,eaf
	»)
				;nok

	;; CP	(HL)
OPCODE(be,«
	FETCHB	ehl,d2
	F_CP_B	d2,eaf
	;; no result to store
	»)
				;nok

	;; CP	A
OPCODE(bf,«
	F_CP_B	eaf,eaf
	»)

	;; RET	NZ
	;; if ~Z
	;;   PCl <- (SP)
	;;   PCh <- (SP+1)
	;;   SP <- (SP+2)
OPCODE(c0,«
	bsr	f_norm_z
	;; SPEED inline RET
	beq	emu_op_c9	; RET
	»)
				;nok

	;; POP	BC
	;; Pops a word into BC
OPCODE(c1,«			; S10 T
	POPW	ebc
	»)
				;nok

	;; JP	NZ,immed.w
	;; if ~Z
	;;   PC <- immed.w
OPCODE(c2,«
	bsr	f_norm_z
	beq.s	emu_op_c3
	add.l	#2,epc
	»)
				;nok

	;; JP	immed.w
	;; PC <- immed.w
OPCODE(c3,«
	FETCHWI	d1
	bsr	deref
	movea.l	a0,epc
	»,36,,12)

	;; CALL	NZ,immed.w
	;; If ~Z, CALL immed.w
OPCODE(c4,«
	bsr	f_norm_z
	;; CALL (emu_op_cd) will run HOLD_INTS again. This doesn't
	;; matter with the current implementation because HOLD_INTS
	;; simply sets a bit.
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; PUSH	BC
OPCODE(c5,«
	PUSHW	ebc
	»)
				;nok

	;; ADD	A,immed.b
OPCODE(c6,«
	FETCHBI	d1
	F_ADD_B	d1,eaf
	»)
				;nok

	;; RST	&0
	;;  == CALL 0
	;; XXX check
OPCODE(c7,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$00,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	Z
OPCODE(c8,«
	bsr	f_norm_z
	bne.s	emu_op_c9
	»)
				;nok

	;; RET
	;; PCl <- (SP)
	;; PCh <- (SP+1)	POPW
	;; SP <- (SP+2)
OPCODE(c9,«
	POPW	d1
	bsr	deref
	movea.l	a0,epc
	»)
				;nok

	;; JP	Z,immed.w
	;; If Z, jump
OPCODE(ca,«
	bsr	f_norm_z
	bne	emu_op_c3
	add.l	#2,epc
	»)
				;nok
	;; prefix
OPCODE(cb,«
	movea.w	emu_op_undo_cb(pc),a2
	»)
	;; nok

	;; CALL	Z,immed.w
OPCODE(cc,«
	bsr	f_norm_z
	bne.s	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; CALL	immed.w
	;; (Like JSR on 68k)
	;;  (SP-1) <- PCh
	;;  (SP-2) <- PCl
	;;  SP <- SP - 2
	;;  PC <- address
OPCODE(cd,«
	move.l	epc,a0
	bsr	underef		; d0 has PC
	add.w	#2,d0
	PUSHW	d0
	bra	emu_op_c3	; JP
	»)

	;; ADC	A,immed.b
OPCODE(ce,«
	FETCHWI	d1
	F_ADC_B	d1,eaf
	»)
				;nok

	;; RST	&08
	;;  == CALL 8
OPCODE(cf,«
	move.l	epc,a0
	bsr	underef		; d0 has PC
	PUSHW	d0
	move.w	#$08,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	NC
OPCODE(d0,«
	bsr	f_norm_c
	beq	emu_op_c9
	»)
				;nok

	;; POP	DE
OPCODE(d1,«
	POPW	ede
	»)
				;nok

	;; JP	NC,immed.w
OPCODE(d2,«
	bsr	f_norm_c
	beq	emu_op_c3
	add.l	#2,epc
	»)

	;; OUT	immed.b,A
OPCODE(d3,«
	move.b	eaf,d1
	FETCHBI	d0
	bsr	port_out
	»)
				;nok

	;; CALL	NC,immed.w
OPCODE(d4,«
	bsr	f_norm_c
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; PUSH	DE
OPCODE(d5,«
	PUSHW	ede
	»)
				;nok

	;; SUB	A,immed.b
OPCODE(d6,«
	FETCHBI	d1
	F_SUB_B	eaf,d1
	»)
				;nok

	;; RST	&10
	;;  == CALL 10
OPCODE(d7,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$10,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	C
OPCODE(d8,«
	bsr	f_norm_c
	bne	emu_op_c9
	»)
				;nok

	;; EXX
OPCODE(d9,«
	swap	ebc
	swap	ede
	swap	ehl
	»)
				;nok

	;; JP	C,immed.w
OPCODE(da,«
	bsr	f_norm_c
	bne	emu_op_c3
	»)
				;nok

OPCODE(db,«
	;; IN	A,immed.b
	move.b	eaf,d1
	FETCHBI	d0
	bsr	port_in
	»)
				;nok

	;; CALL	C,immed.w
OPCODE(dc,«
	bsr	f_norm_c
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

OPCODE(dd,«			; prefix
	movea.w		emu_op_undo_dd(pc),a2
	»)

	;; SBC	A,immed.b
OPCODE(de,«
	FETCHWI	d1
	F_SBC_B	d1,eaf
	»)
				;nok

	;; RST	&18
	;;  == CALL 18
OPCODE(df,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$18,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	PO
	;; If parity odd (P zero), return
OPCODE(e0,«
	bsr	f_norm_pv
	beq	emu_op_c9
	»)
				;nok

	;; POP	HL
OPCODE(e1,«
	POPW	ehl
	»)
				;nok

	;; JP	PO,immed.w
OPCODE(e2,«
	bsr	f_norm_pv
	beq	emu_op_c3
	add.l	#2,epc
	»)
				;nok

	;; EX	(SP),HL
	;; Exchange
OPCODE(e3,«
	POPW	d1
	PUSHW	ehl
	move.w	d1,ehl
	»)
				;nok

	;; CALL	PO,immed.w
	;; if parity odd (P=0), call
OPCODE(e4,«
	bsr	f_norm_pv
	beq	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; PUSH	HL
OPCODE(e5,«
	PUSHW	ehl
	»)
				;nok

	;; AND	immed.b
OPCODE(e6,«
	FETCHBI	d1
	F_AND_B	d1,eaf
	»)
				;nok

	;; RST	&20
	;;  == CALL 20
OPCODE(e7,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$20,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	PE
	;; If parity odd (P zero), return
OPCODE(e8,«
	bsr	f_norm_pv
	bne	emu_op_c9
	»)
				;nok

	;; JP	(HL)
OPCODE(e9,«
	FETCHB	ehl,d1
	bsr	deref
	movea.l	a0,epc
	»)
				;nok

	;; JP	PE,immed.w
OPCODE(ea,«
	bsr	f_norm_pv
	bne	emu_op_c3
	add.l	#2,epc
	»)
				;nok

	;; EX	DE,HL
OPCODE(eb,«
	exg.w	ede,ehl
	»)
				;nok

	;; CALL	PE,immed.w
	;; If parity even (P=1), call
OPCODE(ec,«
	bsr	f_norm_c
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; XXX this probably ought to hold interrupts too
OPCODE(ed,«			; prefix
	movea.w	emu_op_undo_ed(pc),a2
	»)
				;nok

	;; XOR	immed.b
OPCODE(ee,«
	FETCHBI	d1
	F_XOR_B	d1,eaf
	»)
				;nok

	;; RST	&28
	;;  == CALL 28
OPCODE(ef,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$28,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	P
	;; Return if Positive
OPCODE(f0,«
	bsr	f_norm_sign
	beq	emu_op_c9	; RET
	»)
				;nok

	;; POP	AF
	;; SPEED this can be made faster ...
	;; XXX AF
OPCODE(f1,«
	POPW	eaf
	move.w	eaf,(flag_byte-flag_storage)(a3)
	move.b	#$ff,(flag_valid-flag_storage)(a3)
	»)
				;nok

	;; JP	P,immed.w
OPCODE(f2,«
	bsr	f_norm_sign
	beq	emu_op_c3	; JP
	add.l	#2,epc
	»)
				;nok

OPCODE(f3,«
	;; DI
	bsr	ints_stop
	»)

	;; CALL	P,&0000
	;; Call if positive (S=0)
OPCODE(f4,«
	bsr	f_norm_sign
	beq	emu_op_cd
	»)
				;nok

	;; PUSH	AF
OPCODE(f5,«
	bsr	flags_normalize
	LOHI	eaf
	move.b	flag_byte(pc),eaf
	;; XXX wrong, af is not normalized by flags_normalize?
	HILO	eaf
	PUSHW	eaf
	»)
				;nok

OPCODE(f6,«
	;; OR	immed.b
	FETCHBI	d1
	F_OR_B	d1,eaf
	»)
				;nok

	;; RST	&30
	;;  == CALL 30
OPCODE(f7,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$30,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok

	;; RET	M
	;; Return if Sign == 1, minus
OPCODE(f8,«
	bsr	f_norm_sign
	bne	emu_op_c9	; RET
	»)
				;nok

	;; LD	SP,HL
	;; SP <- HL
OPCODE(f9,«
	move.w	ehl,d1
	bsr	deref
	movea.l	a0,esp
	»)
				;nok

	;; JP	M,immed.w
OPCODE(fa,«
	bsr	f_norm_sign
	bne	emu_op_c3	; JP
	add.l	#2,epc
	»)
				;nok

	;; EI
OPCODE(fb,«
	bsr	ints_start
	»)
				;nok

	;; CALL	M,immed.w
	;; Call if minus (S=1)
OPCODE(fc,«
	bsr	f_norm_sign
	bne	emu_op_cd
	add.l	#2,epc
	»)
				;nok

	;; swap IY, HL
OPCODE(fd,«			; prefix
	movea.w	emu_op_undo_fd(pc),a2
	»)

	;; CP	immed.b
OPCODE(fe,«
	FETCHBI	d1
	F_CP_B	d1,eaf
	»)
				;nok

	;; RST	&38
	;;  == CALL 38
OPCODE(ff,«
	move.l	epc,a0
	bsr	underef
	PUSHW	d0
	move.w	#$38,d0
	bsr	deref
	move.l	a0,epc
	»)
				;nok
