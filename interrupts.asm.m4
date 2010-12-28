;;; interrupt handling code

	;; Current interrupt mode.  IM 1 and friends will modify
	;; this, it can be any of 0, 1, 2.
int_mode:	dc.b	0

	;; 0 if the emulated device doesn't want interrupts.
	;; 1 if interrupts are turned on.
int_enabled:	dc.b	1


	;; In interrupt mode 0, an interrupt will force a byte onto
	;; the data bus for the processor to execute.  To handle
	;; those, the emulator will store the bus byte in int_opcode,
	;; which is followed by an absolute jump to the "next
	;; instruction". The value of int_jump will then be
	;; &int_opcode.
	;;
	;; This differs slightly from what I understand to be actual
	;; handling.  The hardware will fetch an immediate argument to
	;; the interrupting instruction from the next location in
	;; memory.
	;;
	;; This emulator, on the other hand, will fetch the immediate
	;; argument from the JP instruction in the shim, and then
	;; dance off into la-la land.
int_opcode:	dc.b	0
		dc.b	$c3		; JP immed.w
int_return:	dc.w	0		; the destination address


	;; This is the interrupt routine.  It can come at any point
	;; during an instruction, though routines that use a5 (e.g. by
	;; calling C subroutines) will have to turn off interrupts.
	;; Routines that call into TIOS will have to remove this
	;; interrupt handler.
int_handler:
	sub.l	#4,a5
	rte


int_nevermind:
	rts
do_interrupt:
	;; todo: make this file m4'd
	add.l	#INT_OFFSET,a5		; clear the interrupt flag

	tst.b	int_enabled		; 4 cycles
	beq.b	int_nevermind		; 8 cycles not taken
	;; Common case: interrupts enabled, fall through

	;; Since this is an instruction all its own, we have D0, D1,
	;; and D2 available.

	pop.l	a0

	;; Interrupts are most often in mode 1, then mode 2, and
	;; almost never in mode 0.
	move.b	int_mode,d0
	cmpi.b	#1,d0
	beq	int_do_mode2
	cmpi.b	#2,d0
	beq	int_do_mode1
	cmpi.b	#1,d0
	beq	int_do_mode0
	jmp	(a0)

	;; This routine emulates a mode 0 interrupt.

	;; IM 0: A byte is placed on the bus and executed as if it
	;; were inline in the program.  This emulator will put that
	;; byte into int_opcode and set epc (or int_jump) to point
	;; there.
int_do_mode0:
	rts

	;; This routine emulates a mode 1 interrupt.

	;; IM 1: RST 38 is executed on every interrupt.  This is what
	;; the TI-83+ uses almost all the time.
int_do_mode1:
	jmp	emu_op_ff


	;; This routine emulates a mode 2 interrupt.

	;; IM 2: Vectored, the address jumped to is as follows:
	;;
	;; (I << 8) | (byte & 0xfe)
	;;
	;; where I is the I register, and byte is the byte that was
	;; found on the bus.
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

