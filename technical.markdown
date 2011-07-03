z680k: The Tricky Bits
======================

For those following along at home, here's some explanation of the
tricky bits of z680k.

Flags
-----

Computing flags is hard, and can take a long time.  So I avoid doing
it whenever possible.  Flag computation is usually done only when an
instruction asks for it, and then generally a minimum amount of work
is done in order to maintain performance.

After every instruction that can influence flags, z680k notes down
what has changed.  It records this information in one of several ways:

1. Simulated F register

   The simplest to understand is the simulated F register, which is
   composed of `flag_storage` and `flag_valid`.  `flag_valid` is a
   mask indicating what bits of `flag_storage` are part of the F
   register.  This storage space may be fully, partially, or not at
   all valid.  It is considered most authoritative.

2. Saved 68k Condition Code Register

   After all operations that affect the Sign, Zero, Parity/oVerflow
   (in the oVerflow mode), or Carry flags, the 68k condition code
   register is saved in `f_host_ccr`.  As necessary, this is looked up
   in `lut_ccr` for a mapping to Z80 flags.  The validity mask of this
   table is at most `11000101`.

3. Saved Operands

   After arithmetic operations that affect the half-carry (H) flag,
   the operands are saved in `f_tmp_src_b` and `f_tmp_dst_b`.
   (Instructions that affect the half-carry flag and operate on words
   use `f_tmp_???_w` instead.)

4. Miscellany

   Parity may be recorded immediately?  I haven't written it yet.
   `f_tmp_p_type` records whether it is parity or overflow, and
   whether it's been calculated or not.  Parity is looked up in
   `lut_parity`, a table that was stolen^Wborrowed from some other
   emulator.  No malice intended; I simply forget which it was.

