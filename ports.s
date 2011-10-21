	;; Routines to process OUT and IN instructions.  This is the
	;; bit that's unique to TI calculators.

	;; Port is in d0, byte is in d1
	;; Destroys a0
port_in:
	andi.w	#$ff,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	lut_ports_in(pc,d0),a0
	jmp	(a0)
	rts

lut_ports_in:
	.int	port_in_00
	.int	port_in_01
	.int	port_in_02
	.int	port_in_03
	.int	port_in_04
	.int	port_in_05
	.int	port_in_06
	.int	port_in_07
	.int	port_in_08
	.int	port_in_09
	.int	port_in_0a
	.int	port_in_0b
	.int	port_in_0c
	.int	port_in_0d
	.int	port_in_0e
	.int	port_in_0f
	.int	port_in_10
	.int	port_in_11
	.int	port_in_12
	.int	port_in_13
	.int	port_in_14
	.int	port_in_15
	.int	port_in_16
	.int	port_in_17
	.int	port_in_18
	.int	port_in_19
	.int	port_in_1a
	.int	port_in_1b
	.int	port_in_1c
	.int	port_in_1d
	.int	port_in_1e
	.int	port_in_1f
	.int	port_in_20
	.int	port_in_21
	.int	port_in_22
	.int	port_in_23
	.int	port_in_24
	.int	port_in_25
	.int	port_in_26
	.int	port_in_27
	.int	port_in_28
	.int	port_in_29
	.int	port_in_2a
	.int	port_in_2b
	.int	port_in_2c
	.int	port_in_2d
	.int	port_in_2e
	.int	port_in_2f
	.int	port_in_30
	.int	port_in_31
	.int	port_in_32
	.int	port_in_33
	.int	port_in_34
	.int	port_in_35
	.int	port_in_36
	.int	port_in_37
	.int	port_in_38
	.int	port_in_39
	.int	port_in_3a
	.int	port_in_3b
	.int	port_in_3c
	.int	port_in_3d
	.int	port_in_3e
	.int	port_in_3f
	.int	port_in_40
	.int	port_in_41
	.int	port_in_42
	.int	port_in_43
	.int	port_in_44
	.int	port_in_45
	.int	port_in_46
	.int	port_in_47
	.int	port_in_48
	.int	port_in_49
	.int	port_in_4a
	.int	port_in_4b
	.int	port_in_4c
	.int	port_in_4d
	.int	port_in_4e
	.int	port_in_4f
	.int	port_in_50
	.int	port_in_51
	.int	port_in_52
	.int	port_in_53
	.int	port_in_54
	.int	port_in_55
	.int	port_in_56
	.int	port_in_57
	.int	port_in_58
	.int	port_in_59
	.int	port_in_5a
	.int	port_in_5b
	.int	port_in_5c
	.int	port_in_5d
	.int	port_in_5e
	.int	port_in_5f
	.int	port_in_60
	.int	port_in_61
	.int	port_in_62
	.int	port_in_63
	.int	port_in_64
	.int	port_in_65
	.int	port_in_66
	.int	port_in_67
	.int	port_in_68
	.int	port_in_69
	.int	port_in_6a
	.int	port_in_6b
	.int	port_in_6c
	.int	port_in_6d
	.int	port_in_6e
	.int	port_in_6f
	.int	port_in_70
	.int	port_in_71
	.int	port_in_72
	.int	port_in_73
	.int	port_in_74
	.int	port_in_75
	.int	port_in_76
	.int	port_in_77
	.int	port_in_78
	.int	port_in_79
	.int	port_in_7a
	.int	port_in_7b
	.int	port_in_7c
	.int	port_in_7d
	.int	port_in_7e
	.int	port_in_7f
	.int	port_in_80
	.int	port_in_81
	.int	port_in_82
	.int	port_in_83
	.int	port_in_84
	.int	port_in_85
	.int	port_in_86
	.int	port_in_87
	.int	port_in_88
	.int	port_in_89
	.int	port_in_8a
	.int	port_in_8b
	.int	port_in_8c
	.int	port_in_8d
	.int	port_in_8e
	.int	port_in_8f
	.int	port_in_90
	.int	port_in_91
	.int	port_in_92
	.int	port_in_93
	.int	port_in_94
	.int	port_in_95
	.int	port_in_96
	.int	port_in_97
	.int	port_in_98
	.int	port_in_99
	.int	port_in_9a
	.int	port_in_9b
	.int	port_in_9c
	.int	port_in_9d
	.int	port_in_9e
	.int	port_in_9f
	.int	port_in_a0
	.int	port_in_a1
	.int	port_in_a2
	.int	port_in_a3
	.int	port_in_a4
	.int	port_in_a5
	.int	port_in_a6
	.int	port_in_a7
	.int	port_in_a8
	.int	port_in_a9
	.int	port_in_aa
	.int	port_in_ab
	.int	port_in_ac
	.int	port_in_ad
	.int	port_in_ae
	.int	port_in_af
	.int	port_in_b0
	.int	port_in_b1
	.int	port_in_b2
	.int	port_in_b3
	.int	port_in_b4
	.int	port_in_b5
	.int	port_in_b6
	.int	port_in_b7
	.int	port_in_b8
	.int	port_in_b9
	.int	port_in_ba
	.int	port_in_bb
	.int	port_in_bc
	.int	port_in_bd
	.int	port_in_be
	.int	port_in_bf
	.int	port_in_c0
	.int	port_in_c1
	.int	port_in_c2
	.int	port_in_c3
	.int	port_in_c4
	.int	port_in_c5
	.int	port_in_c6
	.int	port_in_c7
	.int	port_in_c8
	.int	port_in_c9
	.int	port_in_ca
	.int	port_in_cb
	.int	port_in_cc
	.int	port_in_cd
	.int	port_in_ce
	.int	port_in_cf
	.int	port_in_d0
	.int	port_in_d1
	.int	port_in_d2
	.int	port_in_d3
	.int	port_in_d4
	.int	port_in_d5
	.int	port_in_d6
	.int	port_in_d7
	.int	port_in_d8
	.int	port_in_d9
	.int	port_in_da
	.int	port_in_db
	.int	port_in_dc
	.int	port_in_dd
	.int	port_in_de
	.int	port_in_df
	.int	port_in_e0
	.int	port_in_e1
	.int	port_in_e2
	.int	port_in_e3
	.int	port_in_e4
	.int	port_in_e5
	.int	port_in_e6
	.int	port_in_e7
	.int	port_in_e8
	.int	port_in_e9
	.int	port_in_ea
	.int	port_in_eb
	.int	port_in_ec
	.int	port_in_ed
	.int	port_in_ee
	.int	port_in_ef
	.int	port_in_f0
	.int	port_in_f1
	.int	port_in_f2
	.int	port_in_f3
	.int	port_in_f4
	.int	port_in_f5
	.int	port_in_f6
	.int	port_in_f7
	.int	port_in_f8
	.int	port_in_f9
	.int	port_in_fa
	.int	port_in_fb
	.int	port_in_fc
	.int	port_in_fd
	.int	port_in_fe
	.int	port_in_ff

port_out:
	andi.w	#$ff,d0
	;; This is the fastest way to shift left 2 bits.  :S
	add.w	d0,d0
	add.w	d0,d0
	movea.l	lut_ports_out(pc,d0.w),a0
	jmp	(a0)

lut_ports_out:
	.int	port_out_00
	.int	port_out_01
	.int	port_out_02
	.int	port_out_03
	.int	port_out_04
	.int	port_out_05
	.int	port_out_06
	.int	port_out_07
	.int	port_out_08
	.int	port_out_09
	.int	port_out_0a
	.int	port_out_0b
	.int	port_out_0c
	.int	port_out_0d
	.int	port_out_0e
	.int	port_out_0f
	.int	port_out_10
	.int	port_out_11
	.int	port_out_12
	.int	port_out_13
	.int	port_out_14
	.int	port_out_15
	.int	port_out_16
	.int	port_out_17
	.int	port_out_18
	.int	port_out_19
	.int	port_out_1a
	.int	port_out_1b
	.int	port_out_1c
	.int	port_out_1d
	.int	port_out_1e
	.int	port_out_1f
	.int	port_out_20
	.int	port_out_21
	.int	port_out_22
	.int	port_out_23
	.int	port_out_24
	.int	port_out_25
	.int	port_out_26
	.int	port_out_27
	.int	port_out_28
	.int	port_out_29
	.int	port_out_2a
	.int	port_out_2b
	.int	port_out_2c
	.int	port_out_2d
	.int	port_out_2e
	.int	port_out_2f
	.int	port_out_30
	.int	port_out_31
	.int	port_out_32
	.int	port_out_33
	.int	port_out_34
	.int	port_out_35
	.int	port_out_36
	.int	port_out_37
	.int	port_out_38
	.int	port_out_39
	.int	port_out_3a
	.int	port_out_3b
	.int	port_out_3c
	.int	port_out_3d
	.int	port_out_3e
	.int	port_out_3f
	.int	port_out_40
	.int	port_out_41
	.int	port_out_42
	.int	port_out_43
	.int	port_out_44
	.int	port_out_45
	.int	port_out_46
	.int	port_out_47
	.int	port_out_48
	.int	port_out_49
	.int	port_out_4a
	.int	port_out_4b
	.int	port_out_4c
	.int	port_out_4d
	.int	port_out_4e
	.int	port_out_4f
	.int	port_out_50
	.int	port_out_51
	.int	port_out_52
	.int	port_out_53
	.int	port_out_54
	.int	port_out_55
	.int	port_out_56
	.int	port_out_57
	.int	port_out_58
	.int	port_out_59
	.int	port_out_5a
	.int	port_out_5b
	.int	port_out_5c
	.int	port_out_5d
	.int	port_out_5e
	.int	port_out_5f
	.int	port_out_60
	.int	port_out_61
	.int	port_out_62
	.int	port_out_63
	.int	port_out_64
	.int	port_out_65
	.int	port_out_66
	.int	port_out_67
	.int	port_out_68
	.int	port_out_69
	.int	port_out_6a
	.int	port_out_6b
	.int	port_out_6c
	.int	port_out_6d
	.int	port_out_6e
	.int	port_out_6f
	.int	port_out_70
	.int	port_out_71
	.int	port_out_72
	.int	port_out_73
	.int	port_out_74
	.int	port_out_75
	.int	port_out_76
	.int	port_out_77
	.int	port_out_78
	.int	port_out_79
	.int	port_out_7a
	.int	port_out_7b
	.int	port_out_7c
	.int	port_out_7d
	.int	port_out_7e
	.int	port_out_7f
	.int	port_out_80
	.int	port_out_81
	.int	port_out_82
	.int	port_out_83
	.int	port_out_84
	.int	port_out_85
	.int	port_out_86
	.int	port_out_87
	.int	port_out_88
	.int	port_out_89
	.int	port_out_8a
	.int	port_out_8b
	.int	port_out_8c
	.int	port_out_8d
	.int	port_out_8e
	.int	port_out_8f
	.int	port_out_90
	.int	port_out_91
	.int	port_out_92
	.int	port_out_93
	.int	port_out_94
	.int	port_out_95
	.int	port_out_96
	.int	port_out_97
	.int	port_out_98
	.int	port_out_99
	.int	port_out_9a
	.int	port_out_9b
	.int	port_out_9c
	.int	port_out_9d
	.int	port_out_9e
	.int	port_out_9f
	.int	port_out_a0
	.int	port_out_a1
	.int	port_out_a2
	.int	port_out_a3
	.int	port_out_a4
	.int	port_out_a5
	.int	port_out_a6
	.int	port_out_a7
	.int	port_out_a8
	.int	port_out_a9
	.int	port_out_aa
	.int	port_out_ab
	.int	port_out_ac
	.int	port_out_ad
	.int	port_out_ae
	.int	port_out_af
	.int	port_out_b0
	.int	port_out_b1
	.int	port_out_b2
	.int	port_out_b3
	.int	port_out_b4
	.int	port_out_b5
	.int	port_out_b6
	.int	port_out_b7
	.int	port_out_b8
	.int	port_out_b9
	.int	port_out_ba
	.int	port_out_bb
	.int	port_out_bc
	.int	port_out_bd
	.int	port_out_be
	.int	port_out_bf
	.int	port_out_c0
	.int	port_out_c1
	.int	port_out_c2
	.int	port_out_c3
	.int	port_out_c4
	.int	port_out_c5
	.int	port_out_c6
	.int	port_out_c7
	.int	port_out_c8
	.int	port_out_c9
	.int	port_out_ca
	.int	port_out_cb
	.int	port_out_cc
	.int	port_out_cd
	.int	port_out_ce
	.int	port_out_cf
	.int	port_out_d0
	.int	port_out_d1
	.int	port_out_d2
	.int	port_out_d3
	.int	port_out_d4
	.int	port_out_d5
	.int	port_out_d6
	.int	port_out_d7
	.int	port_out_d8
	.int	port_out_d9
	.int	port_out_da
	.int	port_out_db
	.int	port_out_dc
	.int	port_out_dd
	.int	port_out_de
	.int	port_out_df
	.int	port_out_e0
	.int	port_out_e1
	.int	port_out_e2
	.int	port_out_e3
	.int	port_out_e4
	.int	port_out_e5
	.int	port_out_e6
	.int	port_out_e7
	.int	port_out_e8
	.int	port_out_e9
	.int	port_out_ea
	.int	port_out_eb
	.int	port_out_ec
	.int	port_out_ed
	.int	port_out_ee
	.int	port_out_ef
	.int	port_out_f0
	.int	port_out_f1
	.int	port_out_f2
	.int	port_out_f3
	.int	port_out_f4
	.int	port_out_f5
	.int	port_out_f6
	.int	port_out_f7
	.int	port_out_f8
	.int	port_out_f9
	.int	port_out_fa
	.int	port_out_fb
	.int	port_out_fc
	.int	port_out_fd
	.int	port_out_fe
	.int	port_out_ff

port_in_00:
port_out_00:
	;; Temporary test harness.  Writing to this port writes a
	;; character to the screen.
	SAVEREG
	andi.w	#$ff,d1
	move.w	d1,-(sp)
	jsr	char_draw
	addq	#2,sp
	RESTREG
	rts

port_in_01:
port_out_01:
port_in_02:
port_out_02:
port_in_03:
port_out_03:
port_in_04:
port_out_04:
	;; Bank B paging, among other things
	SAVEREG
	move.b	d1,-(a7)
	jsr	bankswap_b_write
	addq	#2,a7
	RESTREG
	rts

port_in_05:
port_out_05:
port_in_06:
port_out_06:
	;; Bank A paging
	SAVEREG
	move.b	d1,-(a7)
	jsr	bankswap_a_write
	addq	#2,a7
	RESTREG
	rts

port_in_07:
port_out_07:
port_in_08:
port_out_08:
port_in_09:
port_out_09:
port_in_0a:
port_out_0a:
port_in_0b:
port_out_0b:
port_in_0c:
port_out_0c:
port_in_0d:
port_out_0d:
port_in_0e:
port_out_0e:
port_in_0f:
port_out_0f:
port_in_10:
.xref	video_row
.xref	video_increment
.xref	video_enabled
.xref	video_6bit
.xref	video_busy
.xref	video_cur_row
.xref	video_cur_col
.xref	video_write
.xref	video_read

	;; LCD status
	clr.b	d1
	or.b	video_increment,d1
	or.b	video_row,d1
	or.b	video_enabled,d1
	or.b	video_6bit,d1
	or.b	video_busy,d1
	rts

port_out_10:
	;; LCD command
	tst.b	d1
	beq	port_out_10_00
	subq.b	#1,d1
	beq	port_out_10_01
	subq.b	#1,d1
	beq	port_out_10_02
	subq.b	#1,d1
	beq	port_out_10_03
	subq.b	#1,d1
	beq	port_out_10_04
	subq.b	#1,d1
	beq	port_out_10_05
	subq.b	#1,d1
	beq	port_out_10_06
	subq.b	#1,d1
	beq	port_out_10_07
	addq.b	#7,d1
	cmpi.b	#$0b,d1		; power supply enhancement
	ble	port_out_10_undef
	cmpi.b	#$13,d1		; power supply level
	ble	port_out_10_undef
	cmpi.b	#$17,d1		; undefined
	ble	port_out_10_undef
	cmpi.b	#$18,d1		; cancel test mode
	beq	port_out_10_undef
	cmpi.b	#$1b,d1		; undefined
	beq	port_out_10_undef
	cmpi.b	#$1f,d1		; enter test mode
	ble	port_out_10_undef
	cmpi.b	#$3f,d1		; set column
	ble	port_out_10_set_col
	cmpi.b	#$7f,d1		; z-addressing
	ble	port_out_10_undef ; XXX?
	cmpi.b	#$df,d1		; set row
	ble	port_out_10_set_row
	;; fallthrough: set contrast (unimplemented)
	rts
	;; ...
port_out_10_00:		; 6-bit mode
	move.b	#$00,video_6bit
	rts
port_out_10_01:		; 8-bit mode
	move.b	#$40,video_6bit
	rts
port_out_10_02:		; screen off
	move.b	#$20,video_enabled
	rts
port_out_10_03:		; screen on
	move.b	#$00,video_enabled
	rts
port_out_10_04:		; x--
	move.b	#$01,video_row
	move.b	#$00,video_increment
	rts
port_out_10_05:		; x++
	move.b	#$01,video_row
	move.b	#$02,video_increment
	rts
port_out_10_06:		; y--
	move.b	#$00,video_row
	move.b	#$00,video_increment
	rts
port_out_10_07:		; y++
	move.b	#$00,video_row
	move.b	#$02,video_increment
	rts
port_out_10_undef:
	rts
port_out_10_set_col:
	sub.b	#$20,d1
	move.b	d1,video_cur_col
	rts
port_out_10_set_row:
	sub.b	#$80,d1
	move.b	d1,video_cur_row
	rts


port_in_11:
	;; LCD data
	SAVEREG
	jsr	video_read
	move.b	d0,d1		; return value
	RESTREG
	rts

port_out_11:
	;; LCD data
	SAVEREG
	move.b	d1,-(a7)
	jsr	video_write
	addq	#2,a7
	RESTREG
	rts

port_in_12:
port_out_12:
port_in_13:
port_out_13:
port_in_14:
port_out_14:
port_in_15:
port_out_15:
port_in_16:
port_out_16:
port_in_17:
port_out_17:
port_in_18:
port_out_18:
port_in_19:
port_out_19:
port_in_1a:
port_out_1a:
port_in_1b:
port_out_1b:
port_in_1c:
port_out_1c:
port_in_1d:
port_out_1d:
port_in_1e:
port_out_1e:
port_in_1f:
port_out_1f:
port_in_20:
port_out_20:
port_in_21:
port_out_21:
port_in_22:
port_out_22:
port_in_23:
port_out_23:
port_in_24:
port_out_24:
port_in_25:
port_out_25:
port_in_26:
port_out_26:
port_in_27:
port_out_27:
port_in_28:
port_out_28:
port_in_29:
port_out_29:
port_in_2a:
port_out_2a:
port_in_2b:
port_out_2b:
port_in_2c:
port_out_2c:
port_in_2d:
port_out_2d:
port_in_2e:
port_out_2e:
port_in_2f:
port_out_2f:
port_in_30:
port_out_30:
port_in_31:
port_out_31:
port_in_32:
port_out_32:
port_in_33:
port_out_33:
port_in_34:
port_out_34:
port_in_35:
port_out_35:
port_in_36:
port_out_36:
port_in_37:
port_out_37:
port_in_38:
port_out_38:
port_in_39:
port_out_39:
port_in_3a:
port_out_3a:
port_in_3b:
port_out_3b:
port_in_3c:
port_out_3c:
port_in_3d:
port_out_3d:
port_in_3e:
port_out_3e:
port_in_3f:
port_out_3f:
port_in_40:
port_out_40:
port_in_41:
port_out_41:
port_in_42:
port_out_42:
port_in_43:
port_out_43:
port_in_44:
port_out_44:
port_in_45:
port_out_45:
port_in_46:
port_out_46:
port_in_47:
port_out_47:
port_in_48:
port_out_48:
port_in_49:
port_out_49:
port_in_4a:
port_out_4a:
port_in_4b:
port_out_4b:
port_in_4c:
port_out_4c:
port_in_4d:
port_out_4d:
port_in_4e:
port_out_4e:
port_in_4f:
port_out_4f:
port_in_50:
port_out_50:
port_in_51:
port_out_51:
port_in_52:
port_out_52:
port_in_53:
port_out_53:
port_in_54:
port_out_54:
port_in_55:
port_out_55:
port_in_56:
port_out_56:
port_in_57:
port_out_57:
port_in_58:
port_out_58:
port_in_59:
port_out_59:
port_in_5a:
port_out_5a:
port_in_5b:
port_out_5b:
port_in_5c:
port_out_5c:
port_in_5d:
port_out_5d:
port_in_5e:
port_out_5e:
port_in_5f:
port_out_5f:
port_in_60:
port_out_60:
port_in_61:
port_out_61:
port_in_62:
port_out_62:
port_in_63:
port_out_63:
port_in_64:
port_out_64:
port_in_65:
port_out_65:
port_in_66:
port_out_66:
port_in_67:
port_out_67:
port_in_68:
port_out_68:
port_in_69:
port_out_69:
port_in_6a:
port_out_6a:
port_in_6b:
port_out_6b:
port_in_6c:
port_out_6c:
port_in_6d:
port_out_6d:
port_in_6e:
port_out_6e:
port_in_6f:
port_out_6f:
port_in_70:
port_out_70:
port_in_71:
port_out_71:
port_in_72:
port_out_72:
port_in_73:
port_out_73:
port_in_74:
port_out_74:
port_in_75:
port_out_75:
port_in_76:
port_out_76:
port_in_77:
port_out_77:
port_in_78:
port_out_78:
port_in_79:
port_out_79:
port_in_7a:
port_out_7a:
port_in_7b:
port_out_7b:
port_in_7c:
port_out_7c:
port_in_7d:
port_out_7d:
port_in_7e:
port_out_7e:
port_in_7f:
port_out_7f:
port_in_80:
port_out_80:
port_in_81:
port_out_81:
port_in_82:
port_out_82:
port_in_83:
port_out_83:
port_in_84:
port_out_84:
port_in_85:
port_out_85:
port_in_86:
port_out_86:
port_in_87:
port_out_87:
port_in_88:
port_out_88:
port_in_89:
port_out_89:
port_in_8a:
port_out_8a:
port_in_8b:
port_out_8b:
port_in_8c:
port_out_8c:
port_in_8d:
port_out_8d:
port_in_8e:
port_out_8e:
port_in_8f:
port_out_8f:
port_in_90:
port_out_90:
port_in_91:
port_out_91:
port_in_92:
port_out_92:
port_in_93:
port_out_93:
port_in_94:
port_out_94:
port_in_95:
port_out_95:
port_in_96:
port_out_96:
port_in_97:
port_out_97:
port_in_98:
port_out_98:
port_in_99:
port_out_99:
port_in_9a:
port_out_9a:
port_in_9b:
port_out_9b:
port_in_9c:
port_out_9c:
port_in_9d:
port_out_9d:
port_in_9e:
port_out_9e:
port_in_9f:
port_out_9f:
port_in_a0:
port_out_a0:
port_in_a1:
port_out_a1:
port_in_a2:
port_out_a2:
port_in_a3:
port_out_a3:
port_in_a4:
port_out_a4:
port_in_a5:
port_out_a5:
port_in_a6:
port_out_a6:
port_in_a7:
port_out_a7:
port_in_a8:
port_out_a8:
port_in_a9:
port_out_a9:
port_in_aa:
port_out_aa:
port_in_ab:
port_out_ab:
port_in_ac:
port_out_ac:
port_in_ad:
port_out_ad:
port_in_ae:
port_out_ae:
port_in_af:
port_out_af:
port_in_b0:
port_out_b0:
port_in_b1:
port_out_b1:
port_in_b2:
port_out_b2:
port_in_b3:
port_out_b3:
port_in_b4:
port_out_b4:
port_in_b5:
port_out_b5:
port_in_b6:
port_out_b6:
port_in_b7:
port_out_b7:
port_in_b8:
port_out_b8:
port_in_b9:
port_out_b9:
port_in_ba:
port_out_ba:
port_in_bb:
port_out_bb:
port_in_bc:
port_out_bc:
port_in_bd:
port_out_bd:
port_in_be:
port_out_be:
port_in_bf:
port_out_bf:
port_in_c0:
port_out_c0:
port_in_c1:
port_out_c1:
port_in_c2:
port_out_c2:
port_in_c3:
port_out_c3:
port_in_c4:
port_out_c4:
port_in_c5:
port_out_c5:
port_in_c6:
port_out_c6:
port_in_c7:
port_out_c7:
port_in_c8:
port_out_c8:
port_in_c9:
port_out_c9:
port_in_ca:
port_out_ca:
port_in_cb:
port_out_cb:
port_in_cc:
port_out_cc:
port_in_cd:
port_out_cd:
port_in_ce:
port_out_ce:
port_in_cf:
port_out_cf:
port_in_d0:
port_out_d0:
port_in_d1:
port_out_d1:
port_in_d2:
port_out_d2:
port_in_d3:
port_out_d3:
port_in_d4:
port_out_d4:
port_in_d5:
port_out_d5:
port_in_d6:
port_out_d6:
port_in_d7:
port_out_d7:
port_in_d8:
port_out_d8:
port_in_d9:
port_out_d9:
port_in_da:
port_out_da:
port_in_db:
port_out_db:
port_in_dc:
port_out_dc:
port_in_dd:
port_out_dd:
port_in_de:
port_out_de:
port_in_df:
port_out_df:
port_in_e0:
port_out_e0:
port_in_e1:
port_out_e1:
port_in_e2:
port_out_e2:
port_in_e3:
port_out_e3:
port_in_e4:
port_out_e4:
port_in_e5:
port_out_e5:
port_in_e6:
port_out_e6:
port_in_e7:
port_out_e7:
port_in_e8:
port_out_e8:
port_in_e9:
port_out_e9:
port_in_ea:
port_out_ea:
port_in_eb:
port_out_eb:
port_in_ec:
port_out_ec:
port_in_ed:
port_out_ed:
port_in_ee:
port_out_ee:
port_in_ef:
port_out_ef:
port_in_f0:
port_out_f0:
port_in_f1:
port_out_f1:
port_in_f2:
port_out_f2:
port_in_f3:
port_out_f3:
port_in_f4:
port_out_f4:
port_in_f5:
port_out_f5:
port_in_f6:
port_out_f6:
port_in_f7:
port_out_f7:
port_in_f8:
port_out_f8:
port_in_f9:
port_out_f9:
port_in_fa:
port_out_fa:
port_in_fb:
port_out_fb:
port_in_fc:
port_out_fc:
port_in_fd:
port_out_fd:
port_in_fe:
port_out_fe:
port_in_ff:
port_out_ff:
