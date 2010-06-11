680: z80 emulator for 68k calculators
=====================================

Astrid Smith  
Project started: 2010-06-06  
GPL

The aim of this project is to provide a fast and correct TI-83+
emulator to run on the TI-89.

This project has a long and barren history, beginning with my first
contemplation of an emulator similar in interface to Macsbug -- in
September 2002.  That foray fizzled after a long email thread with
Michael Vincent.  The current iteration was sparked by a comment on
IRC by Brandon Wilson, on June 6 2010.

The most difficult challenge in writing a 68k-hosted emulator
targetting the z80 is making it fast.  TI-83+ calculators have a clock
rate in the neighborhood of 12MHz, as do TI-89s.  z80 instructions
take from 4 to 23 cycles to execute.  I can dispatch an instruction
with a fixed 30 cycle overhead:

  emu_fetch:
    eor.w    d0,d0     ; 4 cycles
    move.b   (a4)+,d0  ; 8 cycles
    rol.w    #5,d0     ; 4 cycles   adjust to actual alignment
    jmp      0(a3,d0)  ;14 cycles
    ;; overhead:        30 cycles

From there, an instruction will take anywhere from 0 to lots of
additional cycles, but generally under 50.

I am not aiming for exactly correct relative timing of instructions,
choosing instead to maintain the highest possible speed.  As a result,
programs that depend on cycle counts to function will not work as
expected.



## Useful resources:


* [68k timings](http://www.ticalc.org/pub/text/68k/timing.txt)
* [z80 instruction set in numerical order](http://z80.info/z80oplist.txt)
* [More z80 instruction set reference](http://nemesis.lonestar.org/computers/tandy/software/apps/m4/qd/opcodes.html)
* [Details on flags and other side effects](http://www.gaby.de/z80/z80code.htm)

