; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under MIT license. See LICENSE for details.
;
; This file, siginatures_test.p8, tests signatures.p8.

%zeropage basicsafe
%launcher basic 
%option no_sysinit

%import syslib
%import textio

%import banks
%import signatures
%import testing

main {
    sub start() {
        banks.initmap()
        testCopy()
        testSignValidate()
        testInstallCheckWipe()
        testNames()
        return
    }

    sub testCopy() {
        testing.starttest("copy")

        ubyte i
        for i in 0 to 31 {
            sigone[i] = i
            sigtwo[i] = i+32
        }
        signatures.copy(&sigone, &sigtwo)
        for i in 0 to 31 {
            if sigtwo[i] != sigone[i] {
                testing.fail()
                txt.print("comparing copied block failed\n")
                break
            }
        }

        testing.finish()
        return
    }

    sub testSignValidate() { ; also tests checksum
        testing.starttest("checksum")

        ubyte i
        for i in 0 to 15 {
            sys.memset(&sigone, 32, i)
            signatures.sign(&sigone)
            if not signatures.validate(&sigone) {
                testing.fail()
                txt.print("signed block immediately fails validation\n")
            }
            sigone[17] ^= $ff
            if signatures.validate(&sigone) {
                testing.fail()
                txt.print("modified signed block should have failed validation\n")
            }
        }

        testing.finish()
        return
    }

    sub testInstallCheckWipe() {
        testing.starttest("installcheckwipe")

        void banks.setBit(2, true)
        sys.memset(&sigone, 32, $AA)
    
        bool ok = signatures.install(0, 2, &sigone)
        if ok {
            testing.fail()
            txt.print("invalid signature should have failed install\n")
        }
        signatures.sign(&sigone)
        ok = signatures.install(0, 2, &sigone)
        if not ok {
            testing.fail()
            txt.print("installing a signed block should not fail\n")
        }
        ok = signatures.check(2)
        if not ok {
            testing.fail()
            txt.print("block 2 should have passed validation\n")
        }
        signatures.wipe(2)
        ok = signatures.check(2)
        if ok {
            testing.fail()
            txt.print("wiping block 2 should have invalidated it\n")
        }

        void banks.setBit(2, false)

        testing.finish()
        return
    }

    sub testNames() {
        testing.starttest("names")

        signatures.setname(&sigone, "moe")
        signatures.setname(&sigtwo, "larry")

        bool ok = signatures.matchname(&sigone, "moe")
        if not ok {
            testing.fail()
            txt.print("moe should match moe\n")
        }

        ok = signatures.matchname(&sigone, "larry")
        if ok {
            testing.fail()
            txt.print("larry should not match moe\n")
        }

        ok = signatures.matchname(&sigtwo, "curly")
        if ok {
            testing.fail()
            txt.print("curly should not match larry\n")
        }

        testing.finish()
        return
    }

    ubyte[32] sigone
    ubyte[32] sigtwo
}
