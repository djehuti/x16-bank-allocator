; Commander X16 Bank Allocator
;
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, impl.p8, implements the bank allocator.
; This is not a standalone unit; it is intended to be %imported.
; The functions here are exposed to the %importer but are not
; considered part of the "public" API. (The "public" API will be
; a jump table for ASM users and some asmsub wrappers for p8 callers,
; and the jump table will point to internal wrappers that call
; these functions.
; (That is: external ASM callers jump to the jump table, which
; jumps to a tiny asmsub in the manager that calls these functions;
; external prog8 callers get asmsub wrappers for the jump table.
; That way the jump table is the only exposed ABI; callers don't
; need to know or care that the implementation is in p8.

%import syslib

%import banks
%import signatures

impl {
    ; A simple flag to keep us from repeating initialization and wiping stuff
    ; if the user accidentally SYSes to our entry point.
    ubyte setup = $00

    ; Initializes things.
    sub init() -> ubyte {
        if setup == 0 {
            banks.initmap()
            setup = $FF
        }
        return banks.getAvailBanks()
    }

    ; Allocates a bank, and returns the index of it, or 0 if that fails.
    ; If it succeeds, writes your bank signature to the bank, after verifying
    ; it.
    ; Or, deallocates a bank and invalidates the signature in the descriptor
    ; block. Here again 0 means failure, nonzero means OK.
    sub allocate(ubyte bank, bool alloc, uword signature) -> ubyte {
        ; In the dealloc case, the bank arg is which bank we're deallocating.
        if not alloc {
            ; Don't let them free banks 0 or 1, or nonexistent banks.
            if not banks.validBank(bank) {
                return 0
            }
            ubyte old = banks.setBit(bank, false)
            if old != 0 { ; don't touch it if it wasn't already allocated!
                signatures.wipe(bank)
            }
            return old
        }

        ; In the allocate case, the bank arg is the source bank containing
        ; the signature to be copied into the allocated bank.
        ; Don't even look for a free bank, if we have an invalid signature.
        banks.save()
        cx16.rambank(bank)
        if not signatures.validate(signature) {
            ; Nope out
            banks.restore()
            return 0
        }
        banks.restore()

        ; OK the signature is valid. Let's find a free bank to put it in.
        ubyte newbank
        for newbank in 2 to banks.maxRamBank {
            ; Since setBit returns the old value here, we're just going to set it.
            ; If it was set, no harm no foul, and we won't touch it.
            ; If it wasn't, then we want it, so now it's ours.
            if banks.setBit(newbank, true) == 0 {
                ; old state was free: now this is ours, plant the flag.
                ; copy the (validated) signature from the srcbank+addr
                ; to the newly-allocated bank at the sigblock location.
                void signatures.install(bank, newbank, signature)
                return newbank
            }
        }
        ; Walked off the end without finding one. A pity, that.
        return 0
    }

    ; Looks for a bank with the signature the caller specifies, returns
    ; its bank number in A. The routine checks checksums or whatever to validate
    ; that the bank doesn't just happen to contain a petscii string.
    ; The API between the caller and the callee is up to them to negotiate.
    ; The API, by convention, should be a set of jump vectors in the signature
    ; block. If this returns 0, there is no such bank.
    sub findbank(str name) -> ubyte {
        banks.save()
        ubyte i
        for i in 2 to banks.maxRamBank {
            if banks.getBit(i) != 0 {
                if signatures.check(i) {
                    cx16.rambank(i)
                    if signatures.matchname(&sigblock.block, name) {
                        banks.restore()
                        return i
                    }
                }
            }
        }
        banks.restore()
        return 0
    }

    ; Copy out the bitmap of allocated banks (64 bytes).
    sub listbanks(uword addr) {
        banks.copymap(addr)
        return
    }

    ; Copy out the given bank's descriptor block.
    ; returns true if the bank is valid, false if not.
    ; If false is returned, the addr is left untouched.
    sub bankinfo(ubyte bank, uword addr) -> bool {
        if not banks.validBank(bank) {
            return false
        }
        if banks.getBit(bank) == 0 {
            return false
        }
        banks.save()
        cx16.rambank(bank)
        if not signatures.validate(&sigblock.block) {
            banks.restore()
            return false
        }
        signatures.copy(&sigblock.block, &signatures.temp)
        banks.restore()
        signatures.copy(&signatures.temp, addr)
        return true
    }

    ; Sets the name of a block and signs it, in preparation for allocate
    sub nameAndSign(uword block, str name) {
        signatures.setname(block, name)
        signatures.sign(block)
    }
}
