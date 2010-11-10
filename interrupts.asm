;;; interrupt handling code

	;; Current interrupt mode.  IM 1 and friends will modify
	;; this.

	;; IM 0: A byte is placed on the bus and executed as if it
	;; were inline in the program.  This emulator will put that
	;; byte into int_opcode and set epc (or int_jump) to point
	;; there.

	;; IM 1: RST 38 is executed on every interrupt.

	;; IM 2: Vectored, the address jumped to is as follows:
	;;
	;; (I << 8) | (byte & 0xfe)
	;;
	;; where I is the I register, and byte is the byte that was
	;; found on the bus.
int_mode:	dc.b	0

	;; 0 if interrupts are turned on.
	;; 1 if they are being held.
int_held:	dc.b	0

	;; 0 if no interrupt is pending.
	;; 1 if an interrupt occurred while interrupts were being
	;; held.
	;; 3 (==1|2) if an NMI is pending.
int_waiting:	dc.b	0

	;; The value of epc as a result of a held interrupt.  This is
	;; stored as a derefenced value (pointer into host memory).

	;; I store it as a native pointer because Z80 interrupts can
	;; be very strange.  Interrupt mode 0 in particular requires
	;; a shim.
int_jump:	dc.l	0

	;; In interrupt mode 0, an interrupt will force a byte onto
	;; the data bus for the processor to execute.  To handle
	;; those, the emulator will store the bus byte in int_opcode,
	;; which is followed by an absolute jump to the "next
	;; instruction". The value of int_jump will then be
	;; &int_opcode.
int_opcode:	dc.b	0
		dc.b	$c3		; JP immed.w
int_return:	dc.w	0		; the destination address


	;; This is a macro to hold interrupts.

	;; When interrupts are "disabled" (held), host interrupts will
	;; still fire.  The ISR will see that they are held and update
	;; the above fields with the interrupt type and location.
	;; Then the EI macro to enable them will cause it to fire.
HOLD_INTS	MACRO
	moveq.b	#1,int_held	; 4 cycles
	ENDM

	;; This is a macro to release a held interrupts.
CONTINUE_INTS	MACRO
	bsr	ints_continue	; 18 cycles
	ENDM

ints_continue:
	tst.b	int_waiting	; 4 cycles
	bne.b	ints_continue_pending ; 8 cycles not taken
	;; Common case: no interrupt pending
	moveq.b	#0,int_held	; 4 cycles
	rts			; 16 cycles
	;; typical case: 4+18+4+8+4+16 = 54 cycles
	
	;; I can go faster (24 cycles typical case) by using 68k
	;; hardware interrupt disable/reenable.
ints_continue_pending:
	subq.b	#3,int_waiting
	beq	int_do_nmi
	move.b	int_mode,


	;; This routine emulates a mode 0 interrupt.
int_do_mode0:
	rts

	;; This routine emulates a mode 1 interrupt.
int_do_mode1:
	rts

	;; This routine emulates a mode 2 interrupt.
int_do_mode2:
	rts

	;; This routine emulates a non-maskable interrupt.
int_do_nmi:
	rts




	;; This routine is used by the emulated DI instruction, which
	;; turns off emulator interrupts.
ints_stop:
	rts

	;; This routine is used by the emulated EI instruction, which
	;; turns on emulator interrupts.
ints_start:
	rts

