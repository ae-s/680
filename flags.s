||| -*- gas -*-
||| Code and variables to emulate z80 CPU flags

	|| Routine to set the given flags
	||   Noted in \mask by a 1 bit
.macro	F_SET	mask		| 32 cycles, 8 bytes
	or.b	\mask,flag_byte-flag_storage(a3)
	or.b	\mask,flag_valid-flag_storage(a3)
.endm

	|| Clear the given flags
	||   Noted in \mask (must be a reg) by a 1 bit
.macro	F_CLEAR	mask		| 36 cycles, 10 bytes
	or.b	\mask,flag_valid-flag_storage(a3)
	not.b	\mask
	and.b	\mask,flag_byte-flag_storage(a3)
.endm

	|| Use this when an instruction uses the P/V bit as Parity.
	|| Sets or clears the bit explicitly.
	||
	|| Byte for which parity is calculated must be in \byte.  High
	|| byte of \byte.w must be zero, using d0 is suggested. (a0,d1
	|| destroyed)

.macro	F_PAR	byte
	ori.b	#0b00000100,flag_valid-flag_storage(a3)
	move.b	flag_byte(pc),d1
	andi.b	#0b11111011,d1
	lea	lut_parity(pc),a0
	or.b	0(a0,\byte.w),d1
	move.b	d1,flag_byte-flag_storage(a3)
.endm


	|| Use this when an instruction uses the P/V bit as Overflow.
	|| Leaves the bit itself implicit| simply marks it dirty.
.macro	F_OVFL			| 20 cycles, 6 bytes
	andi.b	#0b11111011,flag_valid-flag_storage(a3)
.endm

	|| Save the two operands from ADD \1,\2
.macro	F_ADD_SAVE	src dst
	move.b	\src,f_tmp_src_b-flag_storage(a3)
	move.b	\dst,f_tmp_dst_b-flag_storage(a3)
	move.b	#0x01,f_tmp_byte-flag_storage(a3)
	F_SET	#0b
.endm



.text

	|| Normalize and return inverse of emulated Carry bit (loaded
	|| into host zero flag)

	|| Destroys d1
f_norm_c:
	move.b	flag_valid-flag_storage(a3),d1
| d1 is destroyed in all cases, so you can use lsr and the C bit (same speed, smaller)
	lsr.b	#1,d1
	bcs.s	FNC_ok		| Bit is valid
	move.b	(f_host_sr+1)-flag_storage(a3),d1
	andi.b	#0b00000001,d1
	or.b	d1,flag_byte-flag_storage(a3)
	ori.b	#0b00000001,flag_valid-flag_storage(a3)
FNC_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#0b00000001,d1
	rts

	|| Normalize and return **INVERSE** of emulated Zero bit
	|| (loaded into host's zero flag)

	|| Destroys d1
f_norm_z:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#0b01000000,d1
	bne.s	FNZ_ok		| Bit is valid
	bsr	flags_normalize
FNZ_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#0b01000000,d1
	rts

	|| Normalize and return **INVERSE** of emulated Parity/oVerflow
	|| bit (loaded into host zero flag)

	|| Destroys d1
f_norm_pv:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#0b00000100,d1
	bne.s	FNPV_ok		| Bit is already valid
	bsr	flags_normalize
FNPV_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#0b00000100,d1
	rts

	|| Calculate the P/V bit as Parity, for the byte in
	|| d1. Destroys d0,d1.
f_calc_parity:
	andi.w	#0xff,d1
	move.b	lut_parity-flag_storage(a3,d1.w),d1
	move.b	(flag_byte),d0
	and.b	#0b11110111,d0
	or.w	#0b0000100000000000,d0
	or.b	d1,d0
	move.w	d0,flag_byte-flag_storage(a3)
	rts

	|| Routine to make both the Carry and Half-Carry flags valid.
	|| Trashes d0, d1.
f_calc_carries:
	|| XXX do this
	|| if f_tmp_byte == 0 {
	||   return, shit is valid
	|| } else if f_tmp_byte == 2 {
	||   // it's a word
	||   add f_tmp_src_w to f_tmp_dst_w
	||     low bytes only, create a carry and save
	||     then high bytes, create a carry and output
	||     then 3rd nibble, create a half-carry and output
	|| } else if f_tmp_byte == 3 {
	||   // it's a byte
	||   add f_tmp_src_b to f_tmp_dst_b
	||     create a carry and output
	||   add low nybbles only
	||     create a half-carry and output
	|| }
	|| set f_tmp_byte = 0
	pushm	d2-d5		| how many registers do I need?
	move.b	f_tmp_byte(pc),d0
	bne	f_cc_dirty
	rts
f_cc_dirty:
	cmpi.b	#2,d0
	bne	f_cc_byte
	|| it's a word!
	move.w	f_tmp_src_w(pc),d2
	move.w	f_tmp_dst_w(pc),d3
	move.w	d3,d4
	add.w	d2,d3
	move	sr,d5
	andi.w	#1,d5
	rol	#8,d5
	andi.w	#0x0fff,d2
	andi.w	#0x0fff,d4
	add.w	d2,d4
	andi.l	#0x1000,d4
	ori.w	#0b00010001,d5
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
	andi.b	#0x0f,d2
	andi.b	#0x0f,d4
	add.b	d2,d4
	andi.b	#0x10,d4
	or.b	d4,d5
	or.b	d5,flag_byte-flag_storage(a3)
	clr.b	f_tmp_byte-flag_storage(a3)
	or.b	#0b00010001,flag_valid-flag_storage(a3)
	popm	d2-d5
	rts

	|| Normalize and return inverse of emulated Sign bit (loaded
	|| into host zero flag).

	|| Destroys d1
f_norm_sign:
	move.b	flag_valid-flag_storage(a3),d1
	andi.b	#0b01000000,d1
	bne.s	FNsign_ok	| Bit is already valid
	bsr	flags_normalize
FNsign_ok:
	move.b	flag_byte-flag_storage(a3),d1
	andi.b	#0b01000000,d1
	rts

	|| Routine to turn 68k flags into z80 flags.
flags_normalize:
	move.b	(f_host_sr+1)(pc),d1	|  8/4
	|| .w keeps d1 clean
	andi.w	#0b00011111,d1			|  8/4

	|| doesn't this invalidate the previous contents of d1
	|| entirely?
	move.b	lut_ccr(pc,d1.w),d1 		| 10/4
	move.b	flag_valid(pc),d0
	not.b	d0
	and.b	d0,d1		| Mask out all the unwanted bits
	not.b	d0
	ori.b	#0b11000101,d0	| These are the z80 flag register bits that can be derived from the 68k CCR.
	move.b	d0,flag_valid-flag_storage(a3)
	or.b	d1,flag_byte-flag_storage(a3)
	rts

	|| Routine to completely fill the flags register
flags_all:
	bsr	flags_normalize
	bsr	f_calc_carries
	rts



.data
flag_storage:
	|| 0 if the flag is already valid in flag_byte
	|| 2 if f_tmp_???_b is valid
	|| 3 if f_tmp_???_w is valid
f_tmp_byte:	.byte	0

	|| 2 if P is 0
	|| 3 if P is 1
	|| 4 if P is uncalculated Parity
	|| 5 if P is uncalculated oVerflow
f_tmp_p_type:	.byte	0

	|| byte operands
f_tmp_src_b:	.byte	0
f_tmp_dst_b:	.byte	0
f_tmp_result_b:	.byte	0

.even
f_tmp_src_w:	.word	0
f_tmp_dst_w:	.word	0
f_tmp_result_w:	.word	0

	|| 000XNZVC
.even
	|| DO NOT REARRANGE THESE
f_host_sr:	.word	0
f_host_ccr:	.byte	0	|XXX make overlap somehow?

.even
	|| DO NOT REARRANGE THESE.
flag_byte:	.byte	0	| Byte of all flags
flag_valid:	.byte	0	| Validity mask -- 1 if valid.


	|| LUT for the CCR -> F mapping
lut_ccr:
				||  N   =S
				||   Z  = Z
				||    V ~     P
				||     C=       C
				||
				|| =CCR= == z80==
				|| XNZVC SZ5H3PNC
	.byte	0b00000000	|| 00000 00000000
	.byte	0b00000001	|| 00001 00000001
	.byte	0b00000100	|| 00010 00000100
	.byte	0b00000101	|| 00011 00000101
	.byte	0b01000000	|| 00100 01000000
	.byte	0b01000001	|| 00101 01000001
	.byte	0b01000100	|| 00110 01000100
	.byte	0b01000101	|| 00111 01000101
	.byte	0b10000000	|| 01000 10000000
	.byte	0b10000001	|| 01001 10000001
	.byte	0b10000100	|| 01010 10000100
	.byte	0b10000101	|| 01011 10000101
	.byte	0b11000000	|| 01100 11000000
	.byte	0b11000001	|| 01101 11000001
	.byte	0b11000100	|| 01110 11000100
	.byte	0b11000101	|| 01111 11000101
	.byte	0b00000000	|| 10000 00000000
	.byte	0b00000001	|| 10001 00000001
	.byte	0b00000100	|| 10010 00000100
	.byte	0b00000101	|| 10011 00000101
	.byte	0b01000000	|| 10100 01000000
	.byte	0b01000001	|| 10101 01000001
	.byte	0b01000100	|| 10110 01000100
	.byte	0b01000101	|| 10111 01000101
	.byte	0b10000000	|| 11000 10000000
	.byte	0b10000001	|| 11001 10000001
	.byte	0b10000100	|| 11010 10000100
	.byte	0b10000101	|| 11011 10000101
	.byte	0b11000000	|| 11100 11000000
	.byte	0b11000001	|| 11101 11000001
	.byte	0b11000100	|| 11110 11000100
	.byte	0b11000101	|| 11111 11000101

	|| 256-byte LUT for the Parity bit.
	|| Keep this last so all storage references require only one
	|| extension word.
	||
	|| This table taken from another z80 emulator
lut_parity:
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	0,4,4,0,4,0,0,4,4,0,0,4,0,4,4,0
	.byte	4,0,0,4,0,4,4,0,0,4,4,0,4,0,0,4

	|| To save space I might be able to overlay the Parity table
	|| with the CCR table, or even interleave it in the opcodes.


