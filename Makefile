# these files are written as .s
ASM_FILES=alu.s flags.s ports.s main.s memory.s

# these files are written as .s.m4 and then preprocessed to .s
M4_ASM_OUTPUT=opcodes.s interrupts.s
M4_ASM_INCLUDES=opcodes.inc.m4

# this is the set of file(s) which is fed to the assembler, and uses
# INCLUDE directives to include the rest of assembly source.
ASM=main.s

C_HEADERS=global.h asm_vars.h
C_FILES=loader.c bankswap.c video.c misc.c debug.c
S_FILES=loader.s bankswap.s video.s misc.s debug.s
O_FILES=loader.o bankswap.o video.o misc.o debug.o main.o

# temporary, for including z80 code in the final binary
MADE_FILES=testbenches/mine.testbench.h testbenches/zexdoc.testbench.h
MADE_BINS=testbenches/mine.testbench.bin testbenches/zexdoc.testbench.bin

# final output files
LISTING_DEBUG=z680d.listing
BINS_DEBUG=z680d.dbg
OBJ_DEBUG=z680d.89z
OBJ=z680k.89k

NAME=z680k Emulator

OBJ_TEST=z680test.89z

# executables to build for the host platform
NATIVE_OBJ=packager

# this is the Sierra linker from the TI Flash Studio SDK.  It works
# quite well under Wine, and is a purely command-line tool.
LINKER=wine ~/.wine/drive_c/SIERRA/BIN/link68.exe
LINKERFLAGS=-m -r

SIGNER=wine  ~/.wine/drive_c/SIERRA/BIN/sdkpc.exe
SIGNERFLAGS=-O 3

# the gnu cross-assembler
GAS=/opt/gcc4ti/bin/as
GASFLAGS=--register-prefix-optional

# flags for the tigcc cross-compiler
TIGCCFLAGS_DEBUG=--debug -WA,-l$(LISTING_DEBUG) -Wa,-ahls
TIGCCFLAGS=-falign-functions=4 -ffunction-sections -fdata-sections -Wall -Wextra -Wwrite-strings -Wa,$(GASFLAGS)

# flags for the native C compiler
CFLAGS=-Wall -ltifiles

.PHONY: clean debug test

all: $(OBJ) $(NATIVE_OBJ)

clean:
	rm -f $(S_FILES) $(O_FILES) $(M4_ASM_OUTPUT) $(MADE_FILES) $(MADE_BINS) $(BINS_DEBUG) $(OBJ) $(OBJ_DEBUG) $(NATIVE_OBJ) $(LISTING_DEBUG) $(OBJ)

debug: $(OBJ_DEBUG)

test: $(OBJ_TEST)

$(OBJ_DEBUG): $(ASM_FILES) $(M4_ASM_OUTPUT) $(C_FILES) $(MADE_FILES) $(C_HEADERS)
	tigcc $(TIGCCFLAGS) $(TIGCCFLAGS_DEBUG) $(ASM) $(C_FILES) -o $(OBJ_DEBUG)

$(OBJ_TEST): unittest.c unittest.h $(M4_ASM_OUTPUT)
	tigcc $(TIGCCFLAGS) $(TIGCCFLAGS_DEBUG) -Wa,--defsym,TEST=1 unittest.c test.s -o $(OBJ_TEST)

# use the host system's native gcc for this
# utility to turn a romdump into a set of image files
packager: packager.c
	gcc $(CFLAGS) packager.c -o packager

# preprocess asm files using m4 as necessary
%.s: %.s.m4
	m4 $(M4_ASM_INCLUDES) $< > $@

$(EXECUTABLE).89k: $(EXECUTABLE).out
	$(SIGNER) $(SIGNER_FLAGS) -s sdk-89.key 89 $(EXECUTABLE).out "$(NAME)"

$(EXECUTABLE).out: $(O_FILES)
	$(LINKER) $(LINKERFLAGS) $(O_FILES) -o $(EXECUTABLE).out

# assemble z80 code
%.testbench.bin:	%.testbench.z80
	spasm $(*D)/$(*F).testbench.z80

# process a z80 binary into a header for inclusion into a 68k .c file
%.testbench.h:	%.testbench.bin
	echo 'char testbench[] = {' > $(*D)/$(*F).testbench.h
	hexdump -v -e '12/1 "0x%02x, "' -e '"\n"' $(*D)/$(*F).testbench.bin | sed -e 's/0x *,//g' >> $(*D)/$(*F).testbench.h
	echo '};' >> $(*D)/$(*F).testbench.h


# relatively speaking, these are easy peasy
loader.o: loader.c asm_vars.h global.h image.h testbenches/zexdoc.testbench.h
	tigcc -c $(TIGCCFLAGS) loader.c -o loader.o

bankswap.o: bankswap.c asm_vars.h
	tigcc -c $(TIGCCFLAGS) bankswap.c -o bankswap.o

video.o: video.c
	tigcc -c $(TIGCCFLAGS) video.c -o video.o

misc.o: misc.c asm_vars.h
	tigcc -c $(TIGCCFLAGS) misc.c -o misc.o

debug.o: debug.c
	tigcc -c $(TIGCCFLAGS) debug.c -o debug.o

main.o: main.s global.inc tios.inc ports.s interrupts.s flags.s alu.s opcodes.s
	$(GAS) $(GASFLAGS) main.s -o main.o

