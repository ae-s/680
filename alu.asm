	;; Parting out the big math/logic routines from the
	;; instruction dispatch table.

alu_add:
	;; ADD instruction
	;; ADD d1,d0
	;; d1 + d0 -> d1
	move.b	d0,f_tmp_src_b	; preserve operands for flag work
	move.b	d1,f_tmp_dst_b
	move.b	#1,(f_tmp_byte-flag_storage)(a3)
	add	d0,d1
	move	sr,(f_host_sr-flag_storage)(a3)
	move.w	#0202,(flag_byte-flag_storage)(a3)
	rts

alu_adc:
	;; ADC instruction
	;; ADC d1,d0
	;; d1 + d0 + carry -> d1
	bsr	flags_normalize
	move.b	flag_byte(pc),d2
	andi.b	#1,d2
	add.b	d0,d2
	move.b	d2,(f_tmp_src_b-flag_storage)(a3)
	move.b	d1,(f_tmp_dst_b-flag_storage)(a3)
	add.b	d2,d1
	move	sr,(f_host_ccr-flag_storage)(a3)
	move.w	#$0202,(flag_byte-flag_storage)(a3)
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
	move.b	d2,(f_tmp_src_b-flag_storage)(a3)
	move.b	d1,(f_tmp_dst_b-flag_storage)(a3)
	sub.b	d2,d1
	move	sr,(f_host_sr-flag_storage)(a3)
	move.w	#$0202,(flag_byte-flag_storage)(a3)
	pop.l	d2
	rts

alu_sub:
	;; SUB instruction
	;; SUB d1,d0
	;; d1 - d0 -> d1
	;; sets flags

	;; XXX use lea and then d(an) if you have a spare register.
	;; preserve operands for flagging

	move.b	d0,(f_tmp_src_b-flag_storage)(a3)
	move.b	d1,(f_tmp_dst_b-flag_storage)(a3)
	move.b	#1,(f_tmp_byte-flag_storage)(a3)
	andi.b	#%00000010,(flag_valid-flag_storage)(a3)
	move.b	#%00000010,(flag_byte-flag_storage)(a3)
	sub	d0,d1
	move	sr,(f_host_sr-flag_storage)(a3)
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
	;; XXX do this
	rts
