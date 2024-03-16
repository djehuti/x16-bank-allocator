; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under MIT license. See LICENSE for details.
;
; This file, banks_test.p8, tests banks.p8.

%import syslib
%import textio

%import banks
%import testing

%zeropage basicsafe
%launcher basic 
%option no_sysinit

main {
    sub start() {
        testInit()
        testCopy()
        testBanks()
        testValidBank()
        testSetGetBit()
        testSaveRestore()
        return
    }

    ; Test the banks.initmap function.
    sub testInit() {
        testing.starttest("bank")

        ; This is a stupid test, but it exercises the UUT.
        banks.initmap()

        testing.finish()
        return
    }

    ; Test the banks.copymap function.
    sub testCopy() {
        testing.starttest("copymap")

        ; We're copying this out after doing nothing to it, so it should
        ; show banks 1-2 allocated, and no more allocated in the first 2
        ; bytes of the map. We assume that any CX16 will have at least 16
        ; banks (128K) of banked RAM available (current shipping systems
        ; start at 64 banks; 512K. The emulator shows 62 banks free).
        ubyte[64] mycopy
        banks.copymap(&mycopy)
        if mycopy[0] != %11000000 or mycopy[1] != 0 {
            testing.fail()
            txt.print("got unexpected values in fresh map")
        }

        testing.finish()
        return
    }

    ; Test the banks.getAvailBanks function.
    sub testBanks() {
        testing.starttest("availbanks")

        ; This is also a dumb test, but we're not testing other
        ; functions yet, so it'll be more interesting later, when
        ; we test whether it changes. ;)
        ubyte nb = banks.getAvailBanks()
        if nb < 14 {
            testing.fail()
            txt.print("fewer than 14 free banks right after init")
        }

        testing.finish()
        return
    }

    ; Test the banks.validBank function, which should return true for banks
    ; between 2 and maxRamBank, and false for banks 0-1 and absent banks.
    sub testValidBank() {
        testing.starttest("validbank")
        ubyte sysMaxBank = cx16.numbanks() - 1 as ubyte

        ; Just test some obvious stuff.
        if banks.validBank(0) or banks.validBank(1) {
            testing.fail()
            txt.print("banks 0 and 1 should return false from validbank")
        }
        if not banks.validBank(2) {
            testing.fail()
            txt.print("bank 2 should be valid")
        }
        if not banks.validBank(sysMaxBank) {
            testing.fail()
            txt.print("sysMaxBank (")
            txt.print_ub(sysMaxBank)
            txt.print(") should be valid\n")
        }
        if sysMaxBank < $FF {
            ubyte bigbank = sysMaxBank + 1
            if banks.validBank(bigbank) {
                testing.fail()
                txt.print("bank ")
                txt.print_ub(bigbank)
                txt.print(" should be invalid\n")
            }
        }

        testing.finish()
        return
    }

    ; Test the banks.getBit and banks.setBit functions.
    sub testSetGetBit() {
        testing.starttest("setgetbit")

        if banks.getBit(0) == 0 or banks.getBit(1) == 0 {
            testing.fail()
            txt.print("banks 0 and 1 should show allocated")
        }

        ; Banks 2- at least 15 should be free.
        ubyte i
        for i in 2 to 15 {
            if banks.getBit(i) != 0 {
                testing.fail()
                txt.print("bank ")
                txt.print_ub(i)
                txt.print(" should show as free")
            }
        }

        ; This test does things that normal clients absolutely should not do.
        ubyte bf = banks.getAvailBanks()
        ubyte old = banks.setBit(2, true)
        ubyte nf = banks.getAvailBanks()
        if nf != bf - 1 {
            testing.fail()
            txt.print("setting bit for bank 2 should have taken a bank")
        }
        if old != 0 {
            ; Should have returned 0 to say it was previously available
            ; especially since we checked for that just up above.
            testing.fail()
            txt.print("setting bit for bank 2 should have returned 0")
        }
        banks.setBit(2, false)
        nf = banks.getAvailBanks()
        if nf != bf {
            testing.fail()
            txt.print("clearing bit for bank 2 should reclaimed it")
        }

        testing.finish()
        return
    }

    ; Test the banks.save() and banks.restore() functions.
    sub testSaveRestore() {
        testing.starttest("save/restore")

        ubyte initial = cx16.getrambank()

        ubyte i
        ubyte j
        ubyte k
        for i in 0 to 15 {
            cx16.rambank(i)
            banks.save()
            for j in 0 to 15 {
                cx16.rambank(j)                
            }
            banks.restore()
            k = cx16.getrambank()
            if k != i {
                testing.fail()
                txt.print("save and restore bank ")
                txt.print_ub(i)
                txt.print(" failed")
            }
        }

        testing.finish()
        return
    }
}
