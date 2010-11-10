z680k: z80 emulator for 68k calculators
=======================================

Duncan Smith  
Project started: 2010-06-06  
GPL

The intent of this project is to provide a fast and correct TI-83+
emulator to run on the TI-89.  Once that is done, perhaps I will
extend it to other models in the TI-83 family.

This project has a long and barren history, beginning with my first
contemplation of an emulator similar in interface to Macsbug -- in
September 2002.  That foray fizzled after a long email thread with
Michael Vincent.  The current iteration was sparked by a comment on
IRC by Brandon Wilson, on June 6 2010:

    <BrandonW> chronomex, you should create a z80 emulator for the 68k calculators.
    <chronomex> that sounds like a capital idea
    <chronomex> I started and abandoned such a project in *2002*
    <chronomex> http://students.washington.edu/f/projects/ti/ti83pemu.shtml
    <BrandonW> I think we desperately need it.
    <chronomex> yeah?
    <chronomex> why is MulTI inadequate?
    <BrandonW> My understanding is that it just runs select programs.
    <BrandonW> Right?
    <chronomex> I have not looked into it at all
    <chronomex> well other than finding the webpage
    <BrandonW> We need to be able to run the TI-OS.


The most difficult challenge in writing a 68k-hosted emulator
targetting the z80 is making it _fast_.  TI-83+ calculators have a
clock rate in the neighborhood of 12MHz, as do TI-89s.  z80
instructions take from 4 to 17 cycles to execute.  I can dispatch an
instruction with a fixed 42 cycle overhead:

	emu_fetch:
	  eor.w    d0,d0     ; 4 cycles
	  move.b   (a4)+,d0  ; 8 cycles
	  rol.w    #5,d0     ;16 cycles
	  jmp      0(a3,d0)  ;14 cycles
	  ;; overhead:        42 cycles

(Using techniques borrowed from
[Tezxas](http://tezxas.ticalc.org/technica.htm) I will be able to get
this to 30 cycles.)

From there, an instruction will take anywhere from 0 to, well, lots of
additional cycles.  Generally, however, it will take under 50, for 92
total.  In the worst reasonable case, a 4 cycle instruction emulated
in 92 cycles, that's a 23:1 ratio.  In the best possible case, a
17-cycle instruction emulated in 42 cycles, is more nearly a 1:2
ratio.

I am not aiming for exactly correct relative timing of instructions,
choosing instead to maintain the highest possible speed.  As a result,
programs that depend on cycle counts to function will not work as
expected.


## Useful resources:

* [68k timings](http://www.ticalc.org/pub/text/68k/timing.txt)
* [z80 instruction set in numerical order](http://z80.info/z80oplist.txt)
* [More z80 instruction set reference](http://nemesis.lonestar.org/computers/tandy/software/apps/m4/qd/opcodes.html)
* [Details on flags and other side effects](http://www.gaby.de/z80/z80code.htm)

