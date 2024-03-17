; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, banks.p8, implements the bank map and some bank utilities.
;
; The subroutines in this file should be considered internal; we won't
; expose them to clients of our API.

%import syslib

%import bits

%zeropage dontuse
%option ignore_unused

banks {
    ubyte[64] bankmap       ; The bank bitmap - 256 bits (64 bytes)
    ubyte maxRamBank        ; The max valid bank that holds RAM
    ubyte savedBank         ; Saved bank for later restore.

    ; initmap (unconditionally) initializes the bank bitmap, reserving
    ; banks 0 and 1, and marking any bank that isn't present as used.
    sub initmap() {
        ; Why & $FFFC? Because (a) it's astonishingly unlikely that anyone
        ; would ever actually have a number of populated banks that's not a
        ; multiple of 8 (is that even possible?), and (2) it's easier to
        ; deal with the bitmap this way.
        uword numBanks = cx16.numbanks() & $FFFC
        maxRamBank = numBanks - 1 as ubyte

        ubyte firstMissingMap = (numBanks >> 3) as ubyte
        ubyte i
        for i in 63 downto firstMissingMap step -1 {
            bankmap[i] = %11111111
        }
        for i in firstMissingMap-1 to 1 step -1 {
            bankmap[i] = %00000000
        }
        bankmap[0] = %11000000
        return
    }

    ; copymap copies out the bitmap to the given address (current bank).
    sub copymap(uword addr) {
        sys.memcopy(bankmap, addr, 64)
        return
    }

    ; getAvailBanks returns the number of available banks in the bitmap
    ; (those whose corresponding bits are 0).
    sub getAvailBanks() -> ubyte {
        ubyte availBanks = 0
        ubyte x
        for x in bankmap {
            availBanks += (8 - bits.bitcount(x))
        }
        return availBanks
    }

    ; validBank returns true if the given bank number is a valid bank
    ; that we could allocate (it doesn't reflect allocation state).
    sub validBank(ubyte bank) -> bool {
        return bank >= 2 and bank <= maxRamBank
    }

    ; setBit ets or clears a single bit in the bitmap.
    ; Returns the old value (0 or nonzero).
    sub setBit(ubyte bank, bool bit) -> ubyte {
        ubyte index = bank >> 3
        ubyte shift = bank & $07
        ubyte mask = $80 >> shift
        ; Invalid banks always show as allocated, and can't be changed.
        if not validBank(bank) {
            return mask
        }
        ubyte old = bankmap[index] & mask
        if bit {
            bankmap[index] |= mask
        } else {
            bankmap[index] &= ($ff ^ mask)
        }
        return old
    }

    ; getBit returns a single bit from the bitmap.
    ; (0 or nonzero; the actual value is 1/2/4/8/etc)
    sub getBit(ubyte bank) -> ubyte {
        ubyte index = bank >> 3
        ubyte shift = bank & $07
        ubyte mask = $80 >> shift
        if not validBank(bank) {
            return mask
        }
        return bankmap[index] & mask
    }

    ; save a copy of the current RAM bank register.
    sub save() {
        savedBank = cx16.getrambank()
        return
    }

    ; restore the saved value of the RAM bank register.
    sub restore() {
        cx16.rambank(savedBank)
        return
    }
}
