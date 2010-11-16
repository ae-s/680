ASM_FILES=alu.asm flags.asm ports.asm interrupts.asm main.asm
M4_ASM_OUTPUT=opcodes.asm
ASM=main.asm
C_HEADERS=global.h asm_vars.h
C_FILES=loader.c bankswap.c video.c misc.c debug.c
S_FILES=loader.s bankswap.s video.s misc.s debug.s
O_FILES=loader.o bankswap.o video.o misc.o debug.o main.o
MADE_FILES=testbenches/zexdoc.h testbenches/mine.h
MADE_BINS=testbenches/zexdoc.bin testbenches/mine.bin
OBJ=z680k.89z

TIGCCFLAGS=-Wall
CFLAGS=-Wall -ltifiles

.PHONY: clean

z680k.89z: $(ASM_FILES) $(M4_ASM_OUTPUT) $(C_FILES) $(MADE_FILES) $(C_HEADERS) $
	tigcc $(TIGCCFLAGS) $(ASM) $(C_FILES) -o $(OBJ)

clean:
	rm -f $(S_FILES) $(O_FILES) $(M4_ASM_OUTPUT) $(MADE_FILES) $(OBJ) $(MADE_BINS)

packager: packager.c
	gcc $(CFLAGS) packager.c -o packager

opcodes.asm: opcodes.inc.m4 opcodes.asm.m4
	m4 opcodes.inc.m4 opcodes.asm.m4 > opcodes.asm

testbenches/zexdoc.h:	testbenches/zexdoc.bin
	echo 'char zexdoc[] = {' > testbenches/zexdoc.h
	hexdump -v -e '12/1 "0x%02x, "' -e '"\n"' testbenches/zexdoc.bin | sed -e 's/0x *,//g' >> testbenches/zexdoc.h
	echo '};' >> testbenches/zexdoc.h

testbenches/zexdoc.bin:	testbenches/zexdoc.z80
	spasm testbenches/zexdoc.z80


testbenches/mine.h:	testbenches/mine.bin
	echo 'char zexdoc[] = {' > testbenches/mine.h
	hexdump -v -e '12/1 "0x%02x, "' -e '"\n"' testbenches/mine.bin | sed -e 's/0x *,//g' >> testbenches/mine.h
	echo '};' >> testbenches/mine.h

testbenches/mine.bin:	testbenches/mine.z80
	spasm testbenches/mine.z80
