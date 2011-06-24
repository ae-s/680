# these files are written as .asm
ASM_FILES=alu.asm flags.asm ports.asm main.asm

# these files are written as .asm.m4 and then preprocessed to .asm
M4_ASM_OUTPUT=opcodes.asm interrupts.asm
M4_ASM_INCLUDES=opcodes.inc.m4

# this is the set of file(s) which is fed to the assembler, and uses
# INCLUDE directives to include the rest of assembly source.
ASM=main.asm

C_HEADERS=global.h asm_vars.h
C_FILES=loader.c bankswap.c video.c misc.c debug.c
S_FILES=loader.s bankswap.s video.s misc.s debug.s
O_FILES=loader.o bankswap.o video.o misc.o debug.o main.o

# temporary, for including z80 code in the final binary
MADE_FILES=testbenches/mine.testbench.h testbenches/zexdoc.testbench.h
MADE_BINS=testbenches/mine.testbench.bin testbenches/zexdoc.testbench.bin

# final output files
BINS_DEBUG=z680d.dbg z680d.listing
OBJ_DEBUG=z680d.89z
OBJ=z680k.89z

# flags for the tigcc cross-compiler
TIGCCFLAGS_DEBUG=--debug -WA,-lz680k.listing
TIGCCFLAGS=-Wall

# flags for the native C compiler
CFLAGS=-Wall -ltifiles

.PHONY: clean

all: packager $(OBJ)

clean:
	rm -f $(S_FILES) $(O_FILES) $(M4_ASM_OUTPUT) $(MADE_FILES) $(MADE_BINS) $(OBJ) $(OBJ_DEBUG)


$(OBJ): $(ASM_FILES) $(M4_ASM_OUTPUT) $(C_FILES) $(MADE_FILES) $(C_HEADERS)
	tigcc $(TIGCCFLAGS) $(ASM) $(C_FILES) -o $(OBJ)

$(OBJ_DEBUG): $(ASM_FILES) $(M4_ASM_OUTPUT) $(C_FILES) $(MADE_FILES) $(C_HEADERS)
	tigcc $(TIGCCFLAGS) $(TIGCCFLAGS_DEBUG) $(ASM) $(C_FILES) -o $(OBJ_DEBUG)

# use the host system's native gcc for this
packager: packager.c
	gcc $(CFLAGS) packager.c -o packager

# preprocess asm files using m4 as necessary
%.asm: %.asm.m4
	m4 $(M4_ASM_INCLUDES) $< > $@

# assemble z80 code
%.testbench.bin:	%.testbench.z80
	spasm $(*D)/$(*F).testbench.z80

# process a z80 binary into a header for inclusion into a 68k .c file
%.testbench.h:	%.testbench.bin
	echo 'char testbench[] = {' > $(*D)/$(*F).testbench.h
	hexdump -v -e '12/1 "0x%02x, "' -e '"\n"' $(*D)/$(*F).testbench.bin | sed -e 's/0x *,//g' >> $(*D)/$(*F).testbench.h
	echo '};' >> $(*D)/$(*F).testbench.h

