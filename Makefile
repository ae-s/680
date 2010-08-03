ASM_FILES=alu.asm flags.asm opcodes.asm ports.asm interrupts.asm main.asm
ASM=main.asm
C_FILES=loader.c bankswap.c video.c misc.c

TIGCCFLAGS=-Wall
CFLAGS=-Wall -ltifiles

z680.89z: $(ASM_FILES) $(C_FILES)
	tigcc $(TIGCCFLAGS) $(ASM) $(C_FILES) -o z680.89z

packager: packager.c
	gcc $(CFLAGS) packager.c -o packager
