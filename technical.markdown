z680k: The Tricky Bits
======================

For those following along at home, here's some explanation of the
tricky bits of z680k.

Flags
-----

Computing flags is hard, and can take a long time.  So I avoid doing
it whenever possible.  Flag computation is usually done only when an
instruction asks for it, and then a minimum amount of work is done in
calculating the requested flag.

After every instruction that can influence flags, z680k notes down
what has changed.  It records this information in one of several ways:

1. Simulated F register

   The simplest is the simulated F register, which is
   composed of `flag_byte` and `flag_valid`.  `flag_valid` is a
   mask indicating what bits of `flag_byte` are part of the F
   register.  This storage space may be fully, partially, or not at
   all valid.  It is considered most authoritative.

   That is, if a particular bit is set in `flag_valid` then that
   corresponding bit of `flag_byte` is the correct value for this
   flag.

2. Saved 68k Condition Code Register

   After all operations that affect the Sign, Zero, Parity/oVerflow
   (in the oVerflow mode), or Carry flags, the 68k condition code
   register is saved in `f_host_ccr`.  As necessary, this is looked up
   in `lut_ccr` for a mapping to Z80 flags.  The validity mask of this
   table is at most `11000101`: Sign (Z80: Negative), Zero, oVerflow
   (Z80: oVerflow / Parity), and Carry.

3. Saved Operands

   After arithmetic operations that affect the half-carry (H) flag,
   the operands are saved in `f_tmp_src_b` and `f_tmp_dst_b`.

   Instructions that affect the half-carry flag and operate on words
   use `f_tmp_src_w` and `f_tmp_dst_w` instead.

4. Miscellany

   Parity may be recorded immediately; I haven't written it yet.
   `f_tmp_p_type` records whether it is parity or overflow, and
   whether it's been calculated or not.  Parity is looked up in
   `lut_parity`, a table that was stolen^Wborrowed from some other
   Z80 emulator.  No malice intended; I simply forget which it was.


Instruction Dispatch
--------------------

I'll be using [a technique from
Tezxas](http://tezxas.ticalc.org/technica.htm) to perform instruction
dispatch quickly.  It's the fastest I've seen, and deserves exposition
here.

I haven't yet worked it into the system; presently the instruction
fetch is at a fixed location which is jumped to after each instruction
routine is executed.  (This is just to make it easy to set a
breakpoint on every instruction fetch, so I can single-step through
emulated code.)

01BB80: 1B 5E B1 10 MOVE.B (A6)+,($01BB86)
01BB84: 4E E4 xx 04 JMP ($xx04,A5)

The Tezxas setup requires instruction routines to begin at 256-byte
intervals within a 64k long block.

The fetch-go routine is two instructions long, ending with an absolute
long jump to an immediate short (with an index by address register
A5).  On emulator initialization, all of these immediate short
addresses are initialized to 0x0004 and the MOVE targets are adjusted
to the appropriate locations.

The first instruction fetches the next byte to be executed and writes
it into the *second* least significant byte of the jump address
offset.  This has the effect of multiplying it by 256 and adding it to
the base address, but is much faster.

The second instruction takes this offset and jumps to it + A5,
yielding the start address of the next instruction's routine.

After the emulator jumps away to its next instruction, the opcode is
left in the JMP target field; this is acceptable because it will be
overwritten next time the emulator runs this instruction.

The purpose of the extra offset of 4 is for interrupt handling.  On an
interrupt, the host's interrupt handler will subtract 4 from A5 and
return immediately.  When the next instruction fetch occurs, the jump
will go 4 bytes earlier, hitting a shim put in place to catch
interrupts.  The shim performs the interrupt function, restores A5,
and jumps back whence it came to continue with the next instruction.

This ensures that an emulated instruction isn't suspended to handle an
interrupt, which is (1) disallowed by the Z80 hardware and (2) an easy
way to mess up registers.
