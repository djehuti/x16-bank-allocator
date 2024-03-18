; Commander X16 Bank Allocator
;
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, signatures.p8, implements the bank allocator
; signatures subroutines.

%import string
%import syslib

%import banks

; This is the signature block at the end of each RAM bank.
; We're not exposing this to callers; they should consider those
; last 32 bytes of the bank to be our housekeeping area.
; They'll keep a structure like this somewhere else, and we'll
; maintain the copy at the end of the bank (install it for them
; and copy it out for callers who want to examine it). They should
; only directly examine this address in banks they own, and use
; the exposed library function (which will wrap one of these
; non-public functions).

sigblock {
    &ubyte[32] block     = $BFE0

    ; TODO re-express these as constant offsets and use them below
    ; How the block breaks down:
    &uword     sigsum    = $BFE0
    &ubyte[14] userbytes = $BFE2
    ; space-padded to fill all 16 bytes (NOT nul-terminated text!)
    &ubyte[16] name      = $BFF0
}


; The implementations of the functions to manipulate these.
; exposed to %importers but not in the public API.
signatures {
    ; copy copies a signature block from src to dest,
    ; ignoring banking altogether.
    sub copy(uword src, uword dest) {
        sys.memcopy(src, dest, 32)
        return
    }

    ; Compute the checksum for the block at the given address.
    sub checksum(uword block) -> uword {
        return cx16.memory_crc(block+2, 30)
    }

    ; validate returns true if the signature block at the given
    ; address (in the current bank) is valid.
    sub validate(uword block) -> bool {
        uword crc = checksum(block)
        uword incrc = (block[1] as uword) << 8 | block[0]
        return incrc == crc
    }

    ; Put the name "name" into the block (at bytes 16-31), truncated
    ; to 16 characters and right-padded with spaces.
    sub setname(uword block, str name) {
        ubyte l = string.length(name)
        if l > 16 {
            l = 16
        }
        sys.memcopy(name, block+16, l)
        if l < 16 {
            sys.memset(block+16+l, 16-l, 32)
        }
    }

    ; Does "block" (which should have a space-padded name in bytes 16-31)
    ; contain the name "name" (which will be a nul-terminated string)?
    sub matchname(uword block, str name) -> bool {
        ubyte l = string.length(name)
        if l > 16 {
            l = 16
        }
        ubyte i
        ubyte c
        for i in 0 to 15 {
            c = block[16+i]
            if (i < l and c != name[i]) or (i >= l and c != 32) {
                return false
            }
        }
        return true
    }

    ; sign places the correct checksum into the block at the
    ; given address (in the current bank).
    sub sign(uword block) {
        uword crc = checksum(block)
        block[0] = (crc & $FF) as ubyte
        block[1] = (crc >> 8) as ubyte
        return
    }

    ; Clear and invalidate the signature for the given bank.
    sub wipe(ubyte bank) {
        banks.save()
        cx16.rambank(bank)
        sys.memset(&sigblock.block, 32, 0)
        banks.restore()
        return
    }

    ; Install the signature at the given address in the given bank.
    sub install(ubyte srcbank, ubyte destbank, uword block) -> bool {
        banks.save()                    ; Save current bank
        cx16.rambank(srcbank)           ; Switch to source bank
        if not validate(block) {        ; Does signature check out?
            banks.restore()             ; Nope, switch back and fail.
            return false
        }
        sys.memcopy(block, &temp, 32)   ; Yes: copy it to our temp loc
        cx16.rambank(destbank)          ; Then switch to the dest bank
        sys.memcopy(&temp, &sigblock.block, 32) ; & copy it over
        banks.restore()                 ; switch back to original bank
        return true                     ; all good
    }

    ; Does the signature for the given bank check out?
    sub check(ubyte bank) -> bool {
        banks.save()
        cx16.rambank(bank)
        bool v = validate(&sigblock.block)
        banks.restore()
        return v
    }

    ; Temporary area (somewhere) in fixed RAM to copy signatures between banks.
    ubyte[32] temp
}
