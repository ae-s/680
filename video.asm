

video_row:	dc.b	0	; $01 if in row mode - x
				; $00 if in column mode - y
video_increment:	dc.b	0	; $02 if in increment mode
				; $00 if in decrement mode
video_enabled:	dc.b	0	; $20 if screen is blanked
video_6bit:	dc.b	0	; $40 if in 8 bit mode, $00 if in 6
				; bit mode
video_busy:	dc.b	0	; always 0

video_cur_row:	dc.b	0
video_cur_col:	dc.b	0

	EVEN

video_read:
	rts

video_write:
	rts
