;;  N   =S
;;   Z  = Z
;;    V ~     P
;;     C=       C
;; 
;; =CCR= == z80==
;; XNZVC SZ5H3PNC
;; 00000 00000000
;; 00001 00000001
;; 00010 00000100
;; 00011 00000101
;; 00100 01000000
;; 00101 01000001
;; 00110 01000100
;; 00111 01000101
;; 01000 10000000
;; 01001 10000001
;; 01010 10000100
;; 01011 10000101
;; 01100 11000000
;; 01101 11000001
;; 01110 11000100
;; 01111 11000101
;; 10000 00000000
;; 10001 00000001
;; 10010 00000100
;; 10011 00000101
;; 10100 01000000
;; 10101 01000001
;; 10110 01000100
;; 10111 01000101
;; 11000 10000000
;; 11001 10000001
;; 11010 10000100
;; 11011 10000101
;; 11100 11000000
;; 11101 11000001
;; 11110 11000100
;; 11111 11000101

	;; Routine to set the given flags
	;;   Noted in \1 by a 1 bit
F_SET	MACRO
	or.b	\1,flag_byte
	or.b	\1,flag_valid
	ENDM

	;; Clear the given flags
	;;   Noted in \1 (must be a reg) by a 1 bit
F_CLEAR	MACRO
	or.b	\1,flag_valid
	not.b	\1
	and.b	\1,flag_byte
	ENDM

	;; Use this when an instruction uses the P/V bit as Parity.
	;; Sets or clears the bit explicitly.
	;;
	;; Byte for which parity is calculated must be in \1. (d1
	;; destroyed)
F_PAR	MACRO
	move.b	\1,d1			;  4  2
	lsr	#4,d1			;  6  2
	eor.b	\1,d1			;  4  2
	lsr	#2,d1			;  6  2
	eor.b	\1,d1			;  4  2
	lsr	#1,d1			;  6  2
	eor.b	\1,d1			;  4  2
	andi.b	#$01,d1			;  8  4
	;; odd parity is now in d1
	ori.b	#%00000100,flag_valid	; 20  6
	andi.b	#%11111011,flag_byte	; 20  6
	rol.b	#2,d1			;  6  2
	or.b	d1,flag_byte		;  8  4
	ENDM				; 86 cycles (!)
					;    36 bytes (make this a subroutine)


	;; Use this when an instruction uses the P/V bit as Overflow.
	;; Leaves the bit itself implicit; simply marks it dirty.
F_OVFL	MACRO
	andi.b	#%11111011
	ENDM

	;; Save the two operands from ADD \1,\2
F_ADD_SAVE	MACRO
	move.b	\1,f_tmp_src_b
	move.b	\2,f_tmp_dst_b
	movei.b	#$01,f_tmp_byte
	F_SET	#%
	ENDM

	;; Normalize and return carry bit (is loaded into Z bit)
	;; Destroys d1
F_NORM_C	MACRO
	move.b	flag_valid,d1
	andi.b	#%00000001,d1
	bne	FNC_ok		; Bit is valid
	move.b	f_host_ccr,d1
	andi.b	#%00000001,d1
	or.b	d1,flag_byte
	ori.b	#%00000001,flag_valid
FNC_ok:
	move.b	flag_byte,d1
	andi.b	#%00000001,d1
	ENDM


	;; Routine to turn 68k flags into z80 flags.
	;; Preconditions:
	;;   Flags to change are noted in d0 by a 1 bit
flags_normalize:
	move.b	f_host_ccr,d1
	andi.b	#%00011111,d1	; Maybe TI uses the reserved bits for
				; something ...
	movea	lut_ccr(pc),a1
	move.b	0(a1,d1),d1
	;; XXX do this
	rts

storage:
	;; 1 if tmp_???b is valid, 0 if tmp_???w is valid
f_tmp_byte:	ds.b	0
	;; 2 if P is 0, 3 if P is 1, 4 if P is Parity, 5 if P is oVerflow
f_tmp_p_type:	ds.b	0

	;; byte operands
f_tmp_src_b:	ds.b	0
f_tmp_dst_b:	ds.b	0
f_tmp_result_b:	ds.b	0

	EVEN
f_tmp_src_w:	ds.w	0
f_tmp_dst_w:	ds.w	0
f_tmp_result_w:	ds.w	0

flag_n:		ds.w	0

	;; 000XNZVC
	EVEN			; Compositing a word from two bytes ...
f_host_sr:	ds.b	0
f_host_ccr:	ds.b	0

	EVEN
flag_byte:	ds.b	0	; Byte of all flags
flag_valid:	ds.b	0	; Validity mask -- 1 if valid.

	;; LUT for the CCR -> F mapping
lut_ccr:
	dc.b	%00000000
	dc.b	%00000001
	dc.b	%00000100
	dc.b	%00000101
	dc.b	%01000000
	dc.b	%01000001
	dc.b	%01000100
	dc.b	%01000101
	dc.b	%10000000
	dc.b	%10000001
	dc.b	%10000100
	dc.b	%10000101
	dc.b	%11000000
	dc.b	%11000001
	dc.b	%11000100
	dc.b	%11000101
	dc.b	%00000000
	dc.b	%00000001
	dc.b	%00000100
	dc.b	%00000101
	dc.b	%01000000
	dc.b	%01000001
	dc.b	%01000100
	dc.b	%01000101
	dc.b	%10000000
	dc.b	%10000001
	dc.b	%10000100
	dc.b	%10000101
	dc.b	%11000000
	dc.b	%11000001
	dc.b	%11000100
	dc.b	%11000101

