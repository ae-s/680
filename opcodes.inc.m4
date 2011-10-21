dnl # change the comments to match the assembler.  Prevents/reduces
dnl # confusion.
changecom(|)dnl
dnl # I'm using these, in this direction, specifically to confuse Germans.
changequote(`«', `»')dnl
dnl #
dnl # OPCODE takes up to five arguments:
dnl # 1. Instruction opcode
dnl # 2. 68k code
dnl # 3. Tstates for the native instruction
dnl # 4. Cycles the emulator takes
dnl # 5. Bytes of emulator code for this instruction
dnl #
define(«OPCODE»,«	START
dnl # This little bit of trickery lets me define a local label.
dnl # Calling local(end) inside of OPCODE(10, ...) will expand to
dnl # end_10, and is undefined everywhere else.
define(«local»,$«»1_««$1»»)dnl
«emu_op_»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_DD»,«	START_DD
define(«local»,$«»1_dd««$1»»)dnl
«emu_op_dd»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_CB»,«	START_CB
define(«local»,$«»1_cb««$1»»)dnl
«emu_op_cb»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_DDCB»,«	START_DDCB
define(«local»,$«»1_ddcb««$1»»)dnl
«emu_op_ddcb»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_FD»,«	START_FD
define(«local»,$«»1_fd««$1»»)dnl
«emu_op_fd»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_FDCB»,«	START_FDCB
define(«local»,$«»1_fdcb««$1»»)dnl
«emu_op_fdcb»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«OP_ED»,«	START_ED
define(«local»,$«»1_ed««$1»»)dnl
«emu_op_ed»$1«:»
$2
	TIME	$3 ifelse(«,$4»,  «,»,  «»,  «,$4»)
undefine(«label»)dnl
	DONE»)dnl
dnl
define(«INT_OFFSET», 4)dnl
