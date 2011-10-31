.xdef		_ti89
.include	"./tios.inc"
.include	"global.inc"
.include	"memory.s"
.include	"ports_test.s"
.include	"flags.s"
.include	"alu.s"
.include	"interrupts.s"
.include	"opcodes.s"


emu_op_undo_cb:
emu_op_undo_dd:
emu_op_undo_ed:
emu_op_undo_fd:
	rts
