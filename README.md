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

I think we need 4 (or 5) functions in the API (these names are placeholders):

(initialization: set the bitmap to all free except banks 0, 1, and
any we use for data storage, such as wherever the implementation of this is)

1) SETALLOC. Allocates or deallocates a block by its index, and returns the
   previous state of that bank. Don't clobber a bank if this returns nonezero.
   But indeed don't call this at all, use ALLOCATE.

2) ALLOCATE. Allocates a bank, and returns the index of it, or 0 if that fails.
   If it succeeds, writes your bank signature to the bank, after verifying it.
   Or deallocates a bank and overwrites the signature in the descriptor block.

3) FINDBANK. Looks for a bank with the signature the caller specifies, returns
   its bank number in A. The routine checks checksums or whatever to validate
   that the bank doesn't just happen to contain a petscii string.
   The API between the caller and the callee is up to them to negotiate.
   The API, by convention, should be a set of jump vectors in the signature
   block.

4) LISTBANKS return the bitmap of allocated banks (64 bytes).

Optionally:

5) BANKINFO return info about the given bank (its descriptor block)

Plus an internal function to compute the checksum. I guess maybe that should
be public too, for developer convenience. Unless there's one in the KERNAL
already?

If these are located in RAM, they can just be a library you link your
program with. If ROM, then we need to expose these 4 functions (we can
likely get away with one KERNAL ext vector and use the same entry point
for all 4 functions).

I think that's all that's really needed.
