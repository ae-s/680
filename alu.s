	;; Parting out the big math/logic routines from the
	;; instruction dispatch table.

.text

alu_add:
	;; ADD instruction
	;; ADD d1,d0
	;; d1 + d0 -> d1
	move.b	d0,f_tmp_src_b	; preserve operands for flag work
	move.b	d1,f_tmp_dst_b
	move.b	#1,f_tmp_byte
	add	d0,d1
	move	sr,f_host_sr
	move.w	#0202,flag_byte
	rts

alu_adc:
	;; ADC instruction
	;; ADC d1,d0
	;; d1 + d0 + carry -> d1
	bsr	flags_normalize
	move.b	flag_byte(pc),d2
	andi.b	#1,d2
	add.b	d0,d2
	move.b	d2,f_tmp_src_b
	move.b	d1,f_tmp_dst_b
	add.b	d2,d1
	move	sr,f_host_ccr
	move.w	#$0202,flag_byte
	rts

alu_sbc:
	;; SBC instruction
	;; SBC d1,d0
	;; d1 - (d0+C) -> d1
	;; sets flags

	push.l	d2
	bsr	flags_normalize
	move.b	flag_byte(pc),d2
	andi.b	#1,d2
	add.b	d0,d2
	move.b	d2,f_tmp_src_b
	move.b	d1,f_tmp_dst_b
	sub.b	d2,d1
	move	sr,f_host_sr
	move.b	#$02,flag_byte
	move.b	#$02,flag_valid
	pop.l	d2
	rts

alu_sub:
	;; SUB instruction
	;; SUB d1,d0
	;; d1 - d0 -> d1
	;; sets flags

	;; XXX use lea and then d(an) if you have a spare register.

	;; preserve operands for flagging
	move.b	d0,f_tmp_src_b
	move.b	d1,f_tmp_dst_b
	move.b	#1,f_tmp_byte
	andi.b	#%00000010,flag_valid
	move.b	#%00000010,flag_byte
	sub	d0,d1
	move	sr,f_host_sr
	rts

alu_and:
	;; XXX do this
	rts

alu_xor:
	;; XXX do this
	rts

alu_or:
	;; XXX do this
	rts

alu_cp:
	;; Same as SUB but the macro that calls this doesn't save the
	;; result.

	;; SPEED can hardcode one of the arguments to always be the A register.
	move.b	d0,f_tmp_src_b
	move.b	d1,f_tmp_dst_b
	move.b	#1,f_tmp_byte
	andi.b	#%00000010,flag_valid
	move.b	#%00000010,flag_byte
	sub.b	d0,d1
	move	sr,f_host_sr
	rts
