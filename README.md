# Commander X-16 RAM Bank Allocator

Here I propose a new X16 KERNAL API, for managing RAM memory banks,
to be used by cooperating programs to share space non-intrusively.

## Why

There are plenty of programs like BASLOAD (the non-ROM version), or
various input wedges that can do neat tricks like add commands to BASIC,
and such. We want to load these programs and mostly have them stick
around. Too many times we run a program that doesn't cooperate and stomps
them, and we have to reload the wedge or reboot the machine.

The only API we have in the KERNAL for programs to even be able to cooperate
with each other is MEMTOP, and because that routine just manages a "max"
pointer (and max bank), it can't be dynamic (you can't load and unload things
and reclaim the space).

On a machine with an MMU and protected memory, multiple programs can run
at once by giving them their own memory spaces and disallowing them certain
I/O or memory management capabilities. On the 65xx, we don't have these
facilities in hardware, so there isn't a notion of a process table.

Multiple programs running "at once" on such a machine is possible, but we
need other tricks to avoid code-relocation nightmares...such as banked RAM.

Turning the CX16 into a multi-user multi-tasking operating system is not the
goal here -- but it should be possible for me as a user to say "hey I want to
have this set of code and data loaded into bank 237 so I can use it when I'm
just DOSing around" and then be able to let other programs know not to trash
it.

## Proposal

I propose an additional KERNAL API vector, which will extend MEMTOP (and work
with it) to a more powerful allocation/reservation mechanism. This can be done
with a minimal API surface change.

It may be possible to wedge this into the existing MEMTOP call by checking some
weird combination of flags or something, but I propose instead that we just
make a new one as an extapi. There are actually a few functions I want to
support, but those can all be behind one extapi vector.

These functions will manage a 256-bit bitmap, which simply tracks which RAM
banks are in use and which are available. The bitmap consumes 64 bytes of RAM
somewhere (in bank 0 for example).

### New KERNAL API

The new Kernal API should support just a few basic functions:

  * Return the index of the "next available bank"
  * Allocate or free a bank, by its (single-byte) bank index
    That is, just set or reset the corresponding bit in the bitmap
  * Convenience operation that finds the next available bank,
    allocates it, and returns the bank index in A (ie both of the above)
  * Retrieve the bitmap

Banks 0 and 1 (and 64-255 on 512k systems) are considered preallocated
and untouchable. 0 because the kernal uses it, and 1 because it's the
default bank and naive programs are more likely to use lower-numbered banks
(and specifically 1 because it's the default).

### Interaction with MEMTOP

The "basic RAM" part of MEMTOP remains unchanged. The bank functionality of
MEMTOP is changed as follows.

At boot time, the bitmap should contain 1s for all of the banks that don't
exist on the machine. These will be "at the end" of the bitmap.
Allocation of blocks proceeds with the highest-numbered-index that is 0
in the bitmap. So, allocating ten banks in a row with the bitmap API is
like calling MEMTOP and subtracting ten from the top bank.

So we change MEMTOP so that reading the bank finds the lowest-numbered
allocated bank (not quite the same as the first entrypoint above, because it
ignores holes). Writing the bank with a lower value allocates all of the
banks between the old and new values; writing the bank with a higher value
deallocates all of the interim banks.

A program that uses MEMTOP only, and knows nothing about the new API, "just
works".

## Requirements for programs to cooperate

* Use this new API and only write to banks you get from the allocator,
  and deallocate them when you're finished. (Yes, even when your program
  is "exiting".)
* Use MEMTOP and ignore the new API. Still only write to banks you get this
  way. Remember to restore MEMTOP when you "exit".

(Why do I put "exit" in quotes? Because when you RTS your code is, or at
least can be, still there, to be jumped back into with your state possibly
intact, and it's much more likely to be intact if you put it in a bank and
you have a way to allocate that bank and mark it used.)

## Interaction with non-cooperating programs

* Non-cooperating programs that just use banks numbered from 1 and ascending,
  and don't use enough to run into "cooperatively allocated" banks, won't make
  any difference.
* Non-cooperating programs can trash all of memory and do whatever they want.
  Note that this is true with or without this API because this is a 65xx.

## Alternatives Considered

* Just using MEMTOP as we can right now. (I.e., do nothing.)

## Disadvantages

* This will use 64 bytes more RAM somewhere (in bank 0; shouldn't use up
  low RAM).
* This will use a couple of hundred bytes of ROM and consume an extapi slot.
* If this is NOT a KERNAL API, then it'll need to borrow few more bytes of
  fixed RAM to use as a jsrfar trampoline.

## Potential Usage Examples

* A loader program allocates a couple of banks of RAM and installs a text
  editor in it, and a small wedge to invoke that editor (like with !E or
  something, for example...).
* That editor can allocate more banks of RAM for text editing buffers.
  When it "exits", it can keep that memory active and have your buffer
  intact when you "reenter". (The distinction between exiting the editor
  and using DOS/BASIC can be as blurry as you want here.) You can now
  swap between editing and running without reboots.
* Load up an assembler into another couple of banks. Now you're cooking.
* Want new BASIC commands? Install a wedge into Golden RAM and you can
  Simoniz your BASIC all you want.
* I am thinking about writing a wedge where you can hit a hotkey and it
  snapshots your fixed RAM area to banked RAM, and you can swap snapshots
  in and out and load and save them to disk.
