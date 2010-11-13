dnl # change the comments to match the assembler.  Prevents/reduces
dnl # confusion, since m4 likes to use ' as a quoting character.
changecom(;)dnl
define(`OPCODE',`	START
`emu_op_'$1`:'
$2
	TIME	$3
	DONE')dnl
