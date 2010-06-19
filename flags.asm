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
	;; Byte for which parity is calculated must be in \1.  High
	;; byte of \1.w must be zero, using d0 is suggested. (a0,d1
	;; destroyed)

F_PAR	MACRO
	ori.b	#%00000100,(flag_valid).w	; ??/4
	move.b	(flag_byte).w,d1		; ??/2
	andi.b	#%11111011,d1			; ??/4
	lea	(lut_parity).w,a0
	or.b	0(a0,\1.w),d1			; ??/4
	move.b	d1,(flag_byte).w		; ??/2
	ENDM				;xxx cycles (!)


	;; Use this when an instruction uses the P/V bit as Overflow.
	;; Leaves the bit itself implicit; simply marks it dirty.
F_OVFL	MACRO
	andi.b	#%11111011
	ENDM

	;; Save the two operands from ADD \1,\2
F_ADD_SAVE	MACRO
	move.b	\1,(f_tmp_src_b).w
	move.b	\2,(f_tmp_dst_b).w
	move.b	#$01,(f_tmp_byte).w
	F_SET	#%
	ENDM

	;; Normalize and return carry bit (is loaded into Z bit)
	;; Destroys d1
f_norm_c:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#%00000001,d1
	bne.s	FNC_ok		; Bit is valid
	move.b	f_host_ccr-flag_storage(a3),d1
	andi.b	#%00000001,d1
;; XXX see above comment for using lea and then d(an) if you have a spare register.
	or.b	d1,flag_byte-flag_storage(a3)
	ori.b	#%00000001,flag_valid
FNC_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#%00000001,d1
	rts

	;; Normalize and return zero bit (loaded into Z bit)
	;; Destroys d1
f_norm_z:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#%01000000,d1
	bne.s	FNZ_ok		; Bit is valid
	bsr	flags_normalize
FNZ_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#%01000000,d1
	rts

	;; Normalize and return Parity/oVerflow bit (loaded into Z
	;; bit)
	;; Destroys d1
f_norm_pv:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#%00000100,d1
	bne.s	FNPV_ok		; Bit is already valid
	bsr	flags_normalize
FNPV_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#%00000100,d1
	rts

	;; Calculate the P/V bit as Parity, for the byte in
	;; d1. Destroys d0,d1.
f_calc_parity:
	andi.w	#$ff,d1
	move.b	lut_parity-flag_storage(a3,d1),d1
	move.w	flag_byte(pc),d0
	and.b	#%11110111,d0
	or.w	#%0000100000000000,d0
	or.b	d1,d0
	move.w	d0,flag_byte-flag_storage(a3)
	rts

	;; Normalize and return Sign bit (loaded into Z bit).
	;; Destroys d1
f_norm_sign:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#%01000000,d1
	bne.s	FNsign_ok	; Bit is already valid
	bsr	flags_normalize
FNsign_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#%01000000,d1
	rts

	;; Routine to turn 68k flags into z80 flags.
	;; Preconditions:
	;;   Flags to change are noted in d0 by a 1 bit
flags_normalize:
	move.b	f_host_ccr-flag_storage(a3),d1	;  8/4
	;; .w keeps d1 clean
	andi.w	#%00011111,d1			;  8/4
	move.b	lut_ccr(pc,d1.w),d1 		; 10/4
	;; XXX do this
	rts

flag_storage:
	;; Numbers in comments are offsets from flag_storage, so use
	;; offset(a3) to address.
	;; 1 if tmp_???b is valid, 0 if tmp_???w is valid
f_tmp_byte:	dc.b	0
	;; 2 if P is 0, 3 if P is 1, 4 if P is Parity, 5 if P is oVerflow
f_tmp_p_type:	dc.b	0

	;; byte operands
f_tmp_src_b:	dc.b	0
f_tmp_dst_b:	dc.b	0
f_tmp_result_b:	dc.b	0

	EVEN
f_tmp_src_w:	dc.w	0
f_tmp_dst_w:	dc.w	0
f_tmp_result_w:	dc.w	0

	;; 000XNZVC
	EVEN
	;; DO NOT REARRANGE THESE
f_host_sr:	dc.b	0
f_host_ccr:	dc.b	0

	EVEN
	;; DO NOT REARRANGE THESE.
flag_byte:	dc.b	0	; Byte of all flags
flag_valid:	dc.b	0	; Validity mask -- 1 if valid.


	;; LUT for the CCR -> F mapping
lut_ccr:
				;;  N   =S
				;;   Z  = Z
				;;    V ~     P
				;;     C=       C
				;;
				;; =CCR= == z80==
				;; XNZVC SZ5H3PNC
	dc.b	%00000000	;; 00000 00000000
	dc.b	%00000001	;; 00001 00000001
	dc.b	%00000100	;; 00010 00000100
	dc.b	%00000101	;; 00011 00000101
	dc.b	%01000000	;; 00100 01000000
	dc.b	%01000001	;; 00101 01000001
	dc.b	%01000100	;; 00110 01000100
	dc.b	%01000101	;; 00111 01000101
	dc.b	%10000000	;; 01000 10000000
	dc.b	%10000001	;; 01001 10000001
	dc.b	%10000100	;; 01010 10000100
	dc.b	%10000101	;; 01011 10000101
	dc.b	%11000000	;; 01100 11000000
	dc.b	%11000001	;; 01101 11000001
	dc.b	%11000100	;; 01110 11000100
	dc.b	%11000101	;; 01111 11000101
	dc.b	%00000000	;; 10000 00000000
	dc.b	%00000001	;; 10001 00000001
	dc.b	%00000100	;; 10010 00000100
	dc.b	%00000101	;; 10011 00000101
	dc.b	%01000000	;; 10100 01000000
	dc.b	%01000001	;; 10101 01000001
	dc.b	%01000100	;; 10110 01000100
	dc.b	%01000101	;; 10111 01000101
	dc.b	%10000000	;; 11000 10000000
	dc.b	%10000001	;; 11001 10000001
	dc.b	%10000100	;; 11010 10000100
	dc.b	%10000101	;; 11011 10000101
	dc.b	%11000000	;; 11100 11000000
	dc.b	%11000001	;; 11101 11000001
	dc.b	%11000100	;; 11110 11000100
	dc.b	%11000101	;; 11111 11000101

	;; 256-byte LUT for the Parity bit.
	;; Keep this last so all storage references require only one
	;; extension word.
lut_parity:
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	dc.b	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4


