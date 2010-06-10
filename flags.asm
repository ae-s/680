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

flags_set:
	;; Routine to set the given flags
	;;   Noted in d0 by a 1 bit
	or.b	d0,flag_byte
	or.b	d0,flag_valid
	rts

flags_clear:
	;; Clear the given flags
	;;   Noted in d0 by a 1 bit
	or.b	d0,flag_valid
	not.b	d0
	and.b	d0,flag_byte
	rts

	;; Routine to turn 68k flags into z80 flags.
	;; Preconditions:
	;;   Flags to change are noted in d0 by a 1 bit
flags_normalize:
	move.b	host_ccr,d1
	movea	lut_ccr(pc),a1
	move.b	(lut_ccr,a1),d1
	;; XXX do this
	rts

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

lut_valid:
	dc.b	%11000101

storage:
	;; 1 if tmp_???b is valid, 0 if tmp_???w is valid
f_tmp_byte:	ds.b	0
	;; 2 if P is 0, 3 if P is 1, 4 if P is Parity, 5 if P is oVerflow
f_tmp_p_type:	ds.b	0

	;; byte operands
f_tmp_src_b:	ds.b	0
f_tmp_dst_b:	ds.b	0
f_tmp_result_b:	ds.b	0

EVEN	;; word operands
f_tmp_src_w:	ds.w	0
f_tmp_dst_w:	ds.w	0
f_tmp_result_w:	ds.w	0

	;; 000XNZVC
f_host_ccr:	ds.b	0

EVEN
flag_byte:	ds.b	0	; Byte of all flags
flag_valid:	ds.b	0	; Validity mask -- 1 if valid.

