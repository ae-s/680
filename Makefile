ASM_FILES=alu.asm flags.asm ports.asm interrupts.asm main.asm
M4_ASM_OUTPUT=opcodes.asm
ASM=main.asm
C_HEADERS=global.h asm_vars.h
C_FILES=loader.c bankswap.c video.c misc.c debug.c
S_FILES=loader.s bankswap.s video.s misc.s debug.s
O_FILES=loader.o bankswap.o video.o misc.o debug.o main.o
MADE_FILES=testbenches/mine.testbench.h testbenches/zexdoc.testbench.h testbenches/zexall.testbench.h
MADE_BINS=testbenches/mine.testbench.bin testbenches/zexdoc.testbench.bin testbenches/zexall.testbench.bin
OBJ=z680k.89z

TIGCCFLAGS=-Wall -WA,-lz680k.listing
CFLAGS=-Wall -ltifiles
M4_ASM_INCLUDES=opcodes.inc.m4

.PHONY: clean

z680k.89z: $(ASM_FILES) $(M4_ASM_OUTPUT) $(C_FILES) $(MADE_FILES) $(C_HEADERS) $
	tigcc $(TIGCCFLAGS) $(ASM) $(C_FILES) -o $(OBJ)

clean:
	rm -f $(S_FILES) $(O_FILES) $(M4_ASM_OUTPUT) $(MADE_FILES) $(OBJ) $(MADE_BINS)

packager: packager.c
	gcc $(CFLAGS) packager.c -o packager

%.asm: %.asm.m4
	m4 $(M4_ASM_INCLUDES) $< > $@

%.testbench.h:	%.testbench.bin
	echo 'char testbench[] = {' > $(*D)/$(*F).testbench.h
	hexdump -v -e '12/1 "0x%02x, "' -e '"\n"' $(*D)/$(*F).testbench.bin | sed -e 's/0x *,//g' >> $(*D)/$(*F).testbench.h
	echo '};' >> $(*D)/$(*F).testbench.h

%.testbench.bin:	%.testbench.z80
	spasm $(*D)/$(*F).testbench.z80

