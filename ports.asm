	;; Routines to process OUT and IN instructions.  This is the
	;; bit that's unique to TI calculators.

	;; Port is in d0, byte is in d1
	;; Destroys a0
port_in:
	movea	lut_ports_in(pc,d0),a0
	jmp	(a0)
	rts

port_out:
	;; Fix this to work properly ...
;	movea	lut_ports_in(pc,d0),a0
	jmp	(a0)
	rts

lut_ports_in:
	dc.l	port_in_00
	dc.l	port_in_01
	dc.l	port_in_02
	dc.l	port_in_03
	dc.l	port_in_04
	dc.l	port_in_05
	dc.l	port_in_06
	dc.l	port_in_07
	dc.l	port_in_08
	dc.l	port_in_09
	dc.l	port_in_0a
	dc.l	port_in_0b
	dc.l	port_in_0c
	dc.l	port_in_0d
	dc.l	port_in_0e
	dc.l	port_in_0f
	dc.l	port_in_10
	dc.l	port_in_11
	dc.l	port_in_12
	dc.l	port_in_13
	dc.l	port_in_14
	dc.l	port_in_15
	dc.l	port_in_16
	dc.l	port_in_17
	dc.l	port_in_18
	dc.l	port_in_19
	dc.l	port_in_1a
	dc.l	port_in_1b
	dc.l	port_in_1c
	dc.l	port_in_1d
	dc.l	port_in_1e
	dc.l	port_in_1f
	dc.l	port_in_20
	dc.l	port_in_21
	dc.l	port_in_22
	dc.l	port_in_23
	dc.l	port_in_24
	dc.l	port_in_25
	dc.l	port_in_26
	dc.l	port_in_27
	dc.l	port_in_28
	dc.l	port_in_29
	dc.l	port_in_2a
	dc.l	port_in_2b
	dc.l	port_in_2c
	dc.l	port_in_2d
	dc.l	port_in_2e
	dc.l	port_in_2f
	dc.l	port_in_30
	dc.l	port_in_31
	dc.l	port_in_32
	dc.l	port_in_33
	dc.l	port_in_34
	dc.l	port_in_35
	dc.l	port_in_36
	dc.l	port_in_37
	dc.l	port_in_38
	dc.l	port_in_39
	dc.l	port_in_3a
	dc.l	port_in_3b
	dc.l	port_in_3c
	dc.l	port_in_3d
	dc.l	port_in_3e
	dc.l	port_in_3f
	dc.l	port_in_40
	dc.l	port_in_41
	dc.l	port_in_42
	dc.l	port_in_43
	dc.l	port_in_44
	dc.l	port_in_45
	dc.l	port_in_46
	dc.l	port_in_47
	dc.l	port_in_48
	dc.l	port_in_49
	dc.l	port_in_4a
	dc.l	port_in_4b
	dc.l	port_in_4c
	dc.l	port_in_4d
	dc.l	port_in_4e
	dc.l	port_in_4f
	dc.l	port_in_50
	dc.l	port_in_51
	dc.l	port_in_52
	dc.l	port_in_53
	dc.l	port_in_54
	dc.l	port_in_55
	dc.l	port_in_56
	dc.l	port_in_57
	dc.l	port_in_58
	dc.l	port_in_59
	dc.l	port_in_5a
	dc.l	port_in_5b
	dc.l	port_in_5c
	dc.l	port_in_5d
	dc.l	port_in_5e
	dc.l	port_in_5f
	dc.l	port_in_60
	dc.l	port_in_61
	dc.l	port_in_62
	dc.l	port_in_63
	dc.l	port_in_64
	dc.l	port_in_65
	dc.l	port_in_66
	dc.l	port_in_67
	dc.l	port_in_68
	dc.l	port_in_69
	dc.l	port_in_6a
	dc.l	port_in_6b
	dc.l	port_in_6c
	dc.l	port_in_6d
	dc.l	port_in_6e
	dc.l	port_in_6f
	dc.l	port_in_70
	dc.l	port_in_71
	dc.l	port_in_72
	dc.l	port_in_73
	dc.l	port_in_74
	dc.l	port_in_75
	dc.l	port_in_76
	dc.l	port_in_77
	dc.l	port_in_78
	dc.l	port_in_79
	dc.l	port_in_7a
	dc.l	port_in_7b
	dc.l	port_in_7c
	dc.l	port_in_7d
	dc.l	port_in_7e
	dc.l	port_in_7f
	dc.l	port_in_80
	dc.l	port_in_81
	dc.l	port_in_82
	dc.l	port_in_83
	dc.l	port_in_84
	dc.l	port_in_85
	dc.l	port_in_86
	dc.l	port_in_87
	dc.l	port_in_88
	dc.l	port_in_89
	dc.l	port_in_8a
	dc.l	port_in_8b
	dc.l	port_in_8c
	dc.l	port_in_8d
	dc.l	port_in_8e
	dc.l	port_in_8f
	dc.l	port_in_90
	dc.l	port_in_91
	dc.l	port_in_92
	dc.l	port_in_93
	dc.l	port_in_94
	dc.l	port_in_95
	dc.l	port_in_96
	dc.l	port_in_97
	dc.l	port_in_98
	dc.l	port_in_99
	dc.l	port_in_9a
	dc.l	port_in_9b
	dc.l	port_in_9c
	dc.l	port_in_9d
	dc.l	port_in_9e
	dc.l	port_in_9f
	dc.l	port_in_a0
	dc.l	port_in_a1
	dc.l	port_in_a2
	dc.l	port_in_a3
	dc.l	port_in_a4
	dc.l	port_in_a5
	dc.l	port_in_a6
	dc.l	port_in_a7
	dc.l	port_in_a8
	dc.l	port_in_a9
	dc.l	port_in_aa
	dc.l	port_in_ab
	dc.l	port_in_ac
	dc.l	port_in_ad
	dc.l	port_in_ae
	dc.l	port_in_af
	dc.l	port_in_b0
	dc.l	port_in_b1
	dc.l	port_in_b2
	dc.l	port_in_b3
	dc.l	port_in_b4
	dc.l	port_in_b5
	dc.l	port_in_b6
	dc.l	port_in_b7
	dc.l	port_in_b8
	dc.l	port_in_b9
	dc.l	port_in_ba
	dc.l	port_in_bb
	dc.l	port_in_bc
	dc.l	port_in_bd
	dc.l	port_in_be
	dc.l	port_in_bf
	dc.l	port_in_c0
	dc.l	port_in_c1
	dc.l	port_in_c2
	dc.l	port_in_c3
	dc.l	port_in_c4
	dc.l	port_in_c5
	dc.l	port_in_c6
	dc.l	port_in_c7
	dc.l	port_in_c8
	dc.l	port_in_c9
	dc.l	port_in_ca
	dc.l	port_in_cb
	dc.l	port_in_cc
	dc.l	port_in_cd
	dc.l	port_in_ce
	dc.l	port_in_cf
	dc.l	port_in_d0
	dc.l	port_in_d1
	dc.l	port_in_d2
	dc.l	port_in_d3
	dc.l	port_in_d4
	dc.l	port_in_d5
	dc.l	port_in_d6
	dc.l	port_in_d7
	dc.l	port_in_d8
	dc.l	port_in_d9
	dc.l	port_in_da
	dc.l	port_in_db
	dc.l	port_in_dc
	dc.l	port_in_dd
	dc.l	port_in_de
	dc.l	port_in_df
	dc.l	port_in_e0
	dc.l	port_in_e1
	dc.l	port_in_e2
	dc.l	port_in_e3
	dc.l	port_in_e4
	dc.l	port_in_e5
	dc.l	port_in_e6
	dc.l	port_in_e7
	dc.l	port_in_e8
	dc.l	port_in_e9
	dc.l	port_in_ea
	dc.l	port_in_eb
	dc.l	port_in_ec
	dc.l	port_in_ed
	dc.l	port_in_ee
	dc.l	port_in_ef
	dc.l	port_in_f0
	dc.l	port_in_f1
	dc.l	port_in_f2
	dc.l	port_in_f3
	dc.l	port_in_f4
	dc.l	port_in_f5
	dc.l	port_in_f6
	dc.l	port_in_f7
	dc.l	port_in_f8
	dc.l	port_in_f9
	dc.l	port_in_fa
	dc.l	port_in_fb
	dc.l	port_in_fc
	dc.l	port_in_fd
	dc.l	port_in_fe
	dc.l	port_in_ff

lut_ports_out:
	dc.l	port_out_00
	dc.l	port_out_01
	dc.l	port_out_02
	dc.l	port_out_03
	dc.l	port_out_04
	dc.l	port_out_05
	dc.l	port_out_06
	dc.l	port_out_07
	dc.l	port_out_08
	dc.l	port_out_09
	dc.l	port_out_0a
	dc.l	port_out_0b
	dc.l	port_out_0c
	dc.l	port_out_0d
	dc.l	port_out_0e
	dc.l	port_out_0f
	dc.l	port_out_10
	dc.l	port_out_11
	dc.l	port_out_12
	dc.l	port_out_13
	dc.l	port_out_14
	dc.l	port_out_15
	dc.l	port_out_16
	dc.l	port_out_17
	dc.l	port_out_18
	dc.l	port_out_19
	dc.l	port_out_1a
	dc.l	port_out_1b
	dc.l	port_out_1c
	dc.l	port_out_1d
	dc.l	port_out_1e
	dc.l	port_out_1f
	dc.l	port_out_20
	dc.l	port_out_21
	dc.l	port_out_22
	dc.l	port_out_23
	dc.l	port_out_24
	dc.l	port_out_25
	dc.l	port_out_26
	dc.l	port_out_27
	dc.l	port_out_28
	dc.l	port_out_29
	dc.l	port_out_2a
	dc.l	port_out_2b
	dc.l	port_out_2c
	dc.l	port_out_2d
	dc.l	port_out_2e
	dc.l	port_out_2f
	dc.l	port_out_30
	dc.l	port_out_31
	dc.l	port_out_32
	dc.l	port_out_33
	dc.l	port_out_34
	dc.l	port_out_35
	dc.l	port_out_36
	dc.l	port_out_37
	dc.l	port_out_38
	dc.l	port_out_39
	dc.l	port_out_3a
	dc.l	port_out_3b
	dc.l	port_out_3c
	dc.l	port_out_3d
	dc.l	port_out_3e
	dc.l	port_out_3f
	dc.l	port_out_40
	dc.l	port_out_41
	dc.l	port_out_42
	dc.l	port_out_43
	dc.l	port_out_44
	dc.l	port_out_45
	dc.l	port_out_46
	dc.l	port_out_47
	dc.l	port_out_48
	dc.l	port_out_49
	dc.l	port_out_4a
	dc.l	port_out_4b
	dc.l	port_out_4c
	dc.l	port_out_4d
	dc.l	port_out_4e
	dc.l	port_out_4f
	dc.l	port_out_50
	dc.l	port_out_51
	dc.l	port_out_52
	dc.l	port_out_53
	dc.l	port_out_54
	dc.l	port_out_55
	dc.l	port_out_56
	dc.l	port_out_57
	dc.l	port_out_58
	dc.l	port_out_59
	dc.l	port_out_5a
	dc.l	port_out_5b
	dc.l	port_out_5c
	dc.l	port_out_5d
	dc.l	port_out_5e
	dc.l	port_out_5f
	dc.l	port_out_60
	dc.l	port_out_61
	dc.l	port_out_62
	dc.l	port_out_63
	dc.l	port_out_64
	dc.l	port_out_65
	dc.l	port_out_66
	dc.l	port_out_67
	dc.l	port_out_68
	dc.l	port_out_69
	dc.l	port_out_6a
	dc.l	port_out_6b
	dc.l	port_out_6c
	dc.l	port_out_6d
	dc.l	port_out_6e
	dc.l	port_out_6f
	dc.l	port_out_70
	dc.l	port_out_71
	dc.l	port_out_72
	dc.l	port_out_73
	dc.l	port_out_74
	dc.l	port_out_75
	dc.l	port_out_76
	dc.l	port_out_77
	dc.l	port_out_78
	dc.l	port_out_79
	dc.l	port_out_7a
	dc.l	port_out_7b
	dc.l	port_out_7c
	dc.l	port_out_7d
	dc.l	port_out_7e
	dc.l	port_out_7f
	dc.l	port_out_80
	dc.l	port_out_81
	dc.l	port_out_82
	dc.l	port_out_83
	dc.l	port_out_84
	dc.l	port_out_85
	dc.l	port_out_86
	dc.l	port_out_87
	dc.l	port_out_88
	dc.l	port_out_89
	dc.l	port_out_8a
	dc.l	port_out_8b
	dc.l	port_out_8c
	dc.l	port_out_8d
	dc.l	port_out_8e
	dc.l	port_out_8f
	dc.l	port_out_90
	dc.l	port_out_91
	dc.l	port_out_92
	dc.l	port_out_93
	dc.l	port_out_94
	dc.l	port_out_95
	dc.l	port_out_96
	dc.l	port_out_97
	dc.l	port_out_98
	dc.l	port_out_99
	dc.l	port_out_9a
	dc.l	port_out_9b
	dc.l	port_out_9c
	dc.l	port_out_9d
	dc.l	port_out_9e
	dc.l	port_out_9f
	dc.l	port_out_a0
	dc.l	port_out_a1
	dc.l	port_out_a2
	dc.l	port_out_a3
	dc.l	port_out_a4
	dc.l	port_out_a5
	dc.l	port_out_a6
	dc.l	port_out_a7
	dc.l	port_out_a8
	dc.l	port_out_a9
	dc.l	port_out_aa
	dc.l	port_out_ab
	dc.l	port_out_ac
	dc.l	port_out_ad
	dc.l	port_out_ae
	dc.l	port_out_af
	dc.l	port_out_b0
	dc.l	port_out_b1
	dc.l	port_out_b2
	dc.l	port_out_b3
	dc.l	port_out_b4
	dc.l	port_out_b5
	dc.l	port_out_b6
	dc.l	port_out_b7
	dc.l	port_out_b8
	dc.l	port_out_b9
	dc.l	port_out_ba
	dc.l	port_out_bb
	dc.l	port_out_bc
	dc.l	port_out_bd
	dc.l	port_out_be
	dc.l	port_out_bf
	dc.l	port_out_c0
	dc.l	port_out_c1
	dc.l	port_out_c2
	dc.l	port_out_c3
	dc.l	port_out_c4
	dc.l	port_out_c5
	dc.l	port_out_c6
	dc.l	port_out_c7
	dc.l	port_out_c8
	dc.l	port_out_c9
	dc.l	port_out_ca
	dc.l	port_out_cb
	dc.l	port_out_cc
	dc.l	port_out_cd
	dc.l	port_out_ce
	dc.l	port_out_cf
	dc.l	port_out_d0
	dc.l	port_out_d1
	dc.l	port_out_d2
	dc.l	port_out_d3
	dc.l	port_out_d4
	dc.l	port_out_d5
	dc.l	port_out_d6
	dc.l	port_out_d7
	dc.l	port_out_d8
	dc.l	port_out_d9
	dc.l	port_out_da
	dc.l	port_out_db
	dc.l	port_out_dc
	dc.l	port_out_dd
	dc.l	port_out_de
	dc.l	port_out_df
	dc.l	port_out_e0
	dc.l	port_out_e1
	dc.l	port_out_e2
	dc.l	port_out_e3
	dc.l	port_out_e4
	dc.l	port_out_e5
	dc.l	port_out_e6
	dc.l	port_out_e7
	dc.l	port_out_e8
	dc.l	port_out_e9
	dc.l	port_out_ea
	dc.l	port_out_eb
	dc.l	port_out_ec
	dc.l	port_out_ed
	dc.l	port_out_ee
	dc.l	port_out_ef
	dc.l	port_out_f0
	dc.l	port_out_f1
	dc.l	port_out_f2
	dc.l	port_out_f3
	dc.l	port_out_f4
	dc.l	port_out_f5
	dc.l	port_out_f6
	dc.l	port_out_f7
	dc.l	port_out_f8
	dc.l	port_out_f9
	dc.l	port_out_fa
	dc.l	port_out_fb
	dc.l	port_out_fc
	dc.l	port_out_fd
	dc.l	port_out_fe
	dc.l	port_out_ff

port_in_00:
port_out_00:
port_in_01:
port_out_01:
port_in_02:
port_out_02:
port_in_03:
port_out_03:
port_in_04:
port_out_04:
port_in_05:
port_out_05:
port_in_06:
port_out_06:
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
	;; LCD status
	clr.b	d1
	or.b	p10_increment(pc),d1
	or.b	p10_row(pc),d1
	or.b	p10_enabled(pc),d1
	or.b	p10_6bit(pc),d1
	or.b	p10_busy(pc),d1
	rts

p10_row:	dc.b	0	; $01 if in row mode - x
				; $00 if in column mode - y
p10_increment:	dc.b	0	; $02 if in increment mode
				; $00 if in decrement mode
p10_enabled:	dc.b	0	; $20 if screen is blanked
p10_6bit:	dc.b	0	; $40 if in 8 bit mode, $00 if in 6
				; bit mode
p10_busy:	dc.b	0	; always 0

p10_cur_row:	dc.b	0
p10_cur_col:	dc.b	0

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
	move.b	#$00,p10_6bit
	rts
port_out_10_01:		; 8-bit mode
	move.b	#$40,p10_6bit
	rts
port_out_10_02:		; screen off
	move.b	#$20,p10_enabled
	rtsp
port_out_10_03:		; screen on
	move.b	#$00,p10_enabled
	rts
port_out_10_04:		; x--
	move.b	#$01,p10_row
	move.b	#$00,p10_increment
	rts
port_out_10_05:		; x++
	move.b	#$01,p10_row
	move.b	#$02,p10_increment
	rts
port_out_10_06:		; y--
	move.b	#$00,p10_row
	move.b	#$00,p10_increment
	rts
port_out_10_07:		; y++
	move.b	#$00,p10_row
	move.b	#$02,p10_increment
	rts
port_out_10_undef:
	rts
port_out_10_set_col:
	sub.b	#$20,d1
	move.b	d1,p10_cur_col
	rts
port_out_10_set_row:
	sub.b	#$80,d1
	move.b	d1,p10_cur_row
	rts

port_in_11:
	;; LCD data
port_out_11:
	;; LCD data
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
