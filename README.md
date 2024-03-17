# Commander X16 Bank Allocator

This is a proof-of-concept library for cooperating programs to
allocate RAM banks without stepping on each other, and to expose
APIs to each other.

## How It Works

### Main Entry Point

The primary entry point to the program can either be a KERNAL system
call, or can be somewhere in RAM. (More on these options later.)
The program itself can be in ROM as part of the kernal (or in a ROM
bank), or could be loaded into a RAM bank by a loader program.

#### The Loader

If this becomes part of the ROM, we don't need one. If RAM (this
prototype, for example) then a small loader can load the program into
RAM and install the call vector somewhere well-known in Fixed RAM.

### Bank Allocation

We have three options here:

1. There could be a central map of what application is where, what
   banks it uses, etc, somewhere in either fixed or banked RAM.
   (If this is in ROM, then maybe space in Bank 0; if in RAM, then
   the map can go in the manager's bank; it should fit.)
2. There could be a central bitmap of allocations (like above), but
   only the bitmap, and space could be reserved in each bank for
   further description.
3. There could be no central bitmap of allocations, and space in
   each bank serves as both indication of allocation and a registry.

Option 3 is dangerous. Option 1 is wasteful of precious fixed RAM
(or possibly bank-0 RAM), but if this goes in the KERNAL and there
is space, it might be a good option. Option 2 seems like a decent
middle ground and remains usable for a KERNAL implementation if
one should be desired later.

So, this prototype will use option 2.

### The API

TODO Update this
