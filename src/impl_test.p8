; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, impl_test.p8, contains unit tests for impl.p8.

%import syslib
%import textio

%import impl
%import testing

%zeropage basicsafe
%launcher basic
%option no_sysinit

main {
    sub start() {
        testInit()
        testAllocate()
        testFindbank()
        testListbanks()
        testBankinfo()
        testDeallocate()
        return
    }

    sub testInit() {
        testing.starttest("init")

        ubyte banksFree = impl.init()
        if banksFree < 14 {
            testing.fail()
            txt.print("fewer than 14 free banks right after init\n")
        }

        testing.finish()
        return
    }

    sub testAllocate() {
        testing.starttest("allocate")

        impl.nameAndSign(&myblock, "bens bank")
        bensBank = impl.allocate(0, true, &myblock)
        if bensBank == 0 {
            testing.fail()
            txt.print("could not allocate bank\n")
        }

        testing.finish()
        return
    }

    sub testFindbank() {
        testing.starttest("findbank")

        ubyte found = impl.findbank("piggy bank")
        if found != 0 {
            testing.fail()
            txt.print("should not have found piggy bank\n")
        }

        found = impl.findbank("bens bank")
        if found != bensBank {
            testing.fail()
            txt.print("should have found bens bank\n")
            txt.print("expected ")
            txt.print_ub(bensBank)
            txt.print(", got ")
            txt.print_ub(found)
            txt.print(".\n")
        }

        testing.finish()
        return
    }

    sub testListbanks() {
        testing.starttest("listbanks")

        impl.listbanks(&mymap)
        if mymap[0] != %11100000 {
            testing.fail()
            txt.print("bank 2 should be allocated")
        }

        testing.finish()
        return
    }

    sub testBankinfo() {
        testing.starttest("bankinfo")

        ubyte foundbanks = 0
        ubyte bank
        for bank in 0 to 255 {
            bool r = impl.bankinfo(bank, &myblock)
            if r {
                foundbanks += 1
                txt.print("\nbank ")
                txt.print_ub(bank)
                txt.print(": >>>")
                ubyte j
                for j in 0 to 15 {
                    cbm.CHROUT(myblock[16+j])
                }
                txt.print("<<<\n")
            }
        }
        if foundbanks != 1 {
            testing.fail()
            txt.print("should have found one bank")
        }

        testing.finish()
        return
    }

    sub testDeallocate() {
        testing.starttest("deallocate")

        ubyte r = impl.allocate(bensBank+1, false, 0)
        if r != 0 {
            testing.fail()
            txt.print("deallocating invalid bank should fail")
        }

        r = impl.allocate(bensBank, false, 0)
        if r == 0 {
            testing.fail()
            txt.print("deallocating bens bank should succeed")
        }

        bensBank = impl.findbank("bens bank")
        if bensBank != 0 {
            testing.fail()
            txt.print("should not find bens bank after deallocation")
        }

        testing.finish()
        return
    }

    ubyte bensBank
    ubyte[32] myblock
    ubyte[64] mymap
}
