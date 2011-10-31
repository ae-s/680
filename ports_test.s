|| -*- gas -*-

	|| Testing harness to pretend to be IO ports.

port_in:
	andi.w	#0xff,d0
	rts

port_out:
	andi.w	#0xff,d0
	rts
