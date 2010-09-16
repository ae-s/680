ASM_FILES=alu.asm flags.asm opcodes.asm ports.asm interrupts.asm main.asm
ASM=main.asm
C_FILES=loader.c bankswap.c video.c misc.c debug.c
C_HEADERS=680.h asm_vars.h
MADE_FILES=testbenches/zexdoc.h testbenches/mine.h

TIGCCFLAGS=-Wall
CFLAGS=-Wall -ltifiles

z680.89z: $(ASM_FILES) $(C_FILES) $(MADE_FILES) $(C_HEADERS)
	tigcc $(TIGCCFLAGS) $(ASM) $(C_FILES) -o z680.89z

packager: packager.c
	gcc $(CFLAGS) packager.c -o packager

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
