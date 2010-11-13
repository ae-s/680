dnl # change the comments to match the assembler.  Prevents/reduces
dnl # confusion.
changecom(;)dnl
dnl # I'm using these, in this direction, specifically to confuse Germans.
changequote(`«', `»')dnl
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
define(«INT_OFFSET», 6)dnl
