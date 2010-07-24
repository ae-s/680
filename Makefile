ASM_FILES=alu.asm flags.asm opcodes.asm ports.asm interrupts.asm main.asm
C_FILES=loader.c bankswap.c video.c

CFLAGS=-Wall

z680.89k: $(ASM_FILES) $(C_FILES)
	tigcc $(CFLAGS) $(ASM_FILES) $(C_FILES) -o z680.89z
