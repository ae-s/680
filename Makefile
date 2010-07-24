ASM_FILES=alu.asm flags.asm opcodes.asm ports.asm interrupts.asm main.asm
C_FILES=loader.c bankswap.c video.c

TIGCCFLAGS=-Wall
CFLAGS=-Wall -ltifiles

z680.89k: $(ASM_FILES) $(C_FILES)
	tigcc $(TIGCCFLAGS) $(ASM_FILES) $(C_FILES) -o z680.89z

packager: packager.c
	gcc $(CFLAGS) packager.c -o packager
