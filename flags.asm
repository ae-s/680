	;; Routine to set the given flags
	;;   Noted in \1 by a 1 bit
F_SET	MACRO			; 32 cycles, 8 bytes
	or.b	\1,flag_byte-flag_storage(a3)
	or.b	\1,flag_valid-flag_storage(a3)
	ENDM

	;; Clear the given flags
	;;   Noted in \1 (must be a reg) by a 1 bit
F_CLEAR	MACRO			; 36 cycles, 10 bytes
	or.b	\1,flag_valid-flag_storage(a3)
	not.b	\1
	and.b	\1,flag_byte-flag_storage(a3)
	ENDM

	;; Use this when an instruction uses the P/V bit as Parity.
	;; Sets or clears the bit explicitly.
	;;
	;; Byte for which parity is calculated must be in \1.  High
	;; byte of \1.w must be zero, using d0 is suggested. (a0,d1
	;; destroyed)

F_PAR	MACRO
	ori.b	#%00000100,flag_valid-flag_storage(a3)
	move.b	flag_byte(pc),d1
	andi.b	#%11111011,d1
	lea	lut_parity(pc),a0
	or.b	0(a0,\1.w),d1
	move.b	d1,flag_byte-flag_storage(a3)
	ENDM


	;; Use this when an instruction uses the P/V bit as Overflow.
	;; Leaves the bit itself implicit; simply marks it dirty.
F_OVFL	MACRO			; 20 cycles, 6 bytes
	andi.b	#%11111011,flag_valid-flag_storage(a3)
	ENDM

	;; Save the two operands from ADD \1,\2
F_ADD_SAVE	MACRO
	move.b	\1,f_tmp_src_b-flag_storage(a3)
	move.b	\2,f_tmp_dst_b-flag_storage(a3)
	move.b	#$01,f_tmp_byte-flag_storage(a3)
	F_SET	#%
	ENDM

	;; Normalize and return inverse of emulated Carry bit (loaded
	;; into host zero flag)

	;; Destroys d1
f_norm_c:
	move.b	flag_valid-flag_storage(a3),d1
; d1 is destroyed in all cases, so you can use lsr and the C bit (same speed, smaller)
	lsr.b	#1,d1
	bcs.s	FNC_ok		; Bit is valid
	move.b	(f_host_sr+1)-flag_storage(a3),d1
	andi.b	#%00000001,d1
	or.b	d1,flag_byte-flag_storage(a3)
	ori.b	#%00000001,flag_valid-flag_storage(a3)
FNC_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#%00000001,d1
	rts

	;; Normalize and return **INVERSE** of emulated Zero bit
	;; (loaded into host's zero flag)

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

	;; Normalize and return **INVERSE** of emulated Parity/oVerflow
	;; bit (loaded into host zero flag)

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
	move.b	lut_parity-flag_storage(a3,d1.w),d1
	move.b	(flag_byte),d0
	and.b	#%11110111,d0
	or.w	#%0000100000000000,d0
	or.b	d1,d0
	move.w	d0,flag_byte-flag_storage(a3)
	rts

	;; Routine to make both the Carry and Half-Carry flags valid.
	;; Trashes d0, d1.
f_calc_carries:
	;; XXX do this
	;; if f_tmp_byte == 0 {
	;;   return, shit is valid
	;; } else if f_tmp_byte == 2 {
	;;   // it's a word
	;;   add f_tmp_src_w to f_tmp_dst_w
	;;     low bytes only, create a carry and save
	;;     then high bytes, create a carry and output
	;;     then 3rd nibble, create a half-carry and output
	;; } else if f_tmp_byte == 3 {
	;;   // it's a byte
	;;   add f_tmp_src_b to f_tmp_dst_b
	;;     create a carry and output
	;;   add low nybbles only
	;;     create a half-carry and output
	;; }
	;; set f_tmp_byte = 0
	pushm	d2-d5		; how many registers do I need?
	move.b	f_tmp_byte(pc),d0
	bne	f_cc_dirty
	rts
f_cc_dirty:
	cmpi.b	#2,d0
	bne	f_cc_byte
	;; it's a word!
	move.w	f_tmp_src_w(pc),d2
	move.w	f_tmp_dst_w(pc),d3
	move.w	d3,d4
	add.w	d2,d3
	move	sr,d5
	andi.w	#1,d5
	rol	#8,d5
	andi.w	#$0fff,d2
	andi.w	#$0fff,d4
	add.w	d2,d4
	andi.l	#$1000,d4
	ori.w	#%00010001,d5
	or.w	d4,d5
	or.w	d5,flag_byte-flag_storage(a3)
	clr.b	f_tmp_byte-flag_storage(a3)
	popm	d2-d5
	rts
f_cc_byte:
	move.b	f_tmp_src_b(pc),d2
	move.b	f_tmp_dst_b(pc),d3
	move.b	d3,d4
	add.b	d2,d3
	move	sr,d5
	andi.b	#1,d5
	andi.b	#$0f,d2
	andi.b	#$0f,d4
	add.b	d2,d4
	andi.b	#$10,d4
	or.b	d4,d5
	or.b	d5,flag_byte-flag_storage(a3)
	clr.b	f_tmp_byte-flag_storage(a3)
	or.b	#%00010001,flag_valid-flag_storage(a3)
	popm	d2-d5
	rts

	;; Normalize and return inverse of emulated Sign bit (loaded
	;; into host zero flag).

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
flags_normalize:
	move.b	(f_host_sr+1)(pc),d1	;  8/4
	;; .w keeps d1 clean
	andi.w	#%00011111,d1			;  8/4

	;; doesn't this invalidate the previous contents of d1
	;; entirely?
	move.b	lut_ccr(pc,d1.w),d1 		; 10/4
	move.b	flag_valid(pc),d0
	not.b	d0
	and.b	d0,d1		; Mask out all the unwanted bits
	not.b	d0
	ori.b	#%11000101,d0	; These are the z80 flag register bits that can be derived from the 68k CCR.
	move.b	d0,flag_valid-flag_storage(a3)
	or.b	d1,flag_byte-flag_storage(a3)
	rts

	;; Routine to completely fill the flags register
flags_all:
	bsr	flags_normalize
	bsr	f_calc_carries
	rts

	EVEN
flag_storage:
	;; 0 if the flag is already valid
	;; 2 if tmp_???b is valid
	;; 3 if tmp_???w is valid
f_tmp_byte:	dc.b	0

	;; 2 if P is 0
	;; 3 if P is 1
	;; 4 if P is uncalculated Parity
	;; 5 if P is uncalculated oVerflow
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
f_host_sr:	dc.w	0
f_host_ccr:	dc.b	0	;XXX make overlap somehow?

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
	;;
	;; This table taken from another z80 emulator
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

	;; To save space I might be able to overlay the Parity table
	;; with the CCR table, or even interleave it in the opcodes.


