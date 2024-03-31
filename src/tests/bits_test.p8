; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, siginatures_test.p8, tests signatures.p8.

%zeropage basicsafe
%launcher basic 

%import textio

%import bits
%import testing

main {
    sub start() {
        testCountbits()
        return
    }

    sub testCountbits() {
        testing.starttest("bits")

        ubyte i
        for i in 0 to 7 {
            ubyte got = bits.bitcount(tests[i])
            if got != expect[i] {
                testing.fail()
                txt.print("counted bits in ")
                txt.print_ubhex(tests[i], true)
                txt.print(", got ")
                txt.print_ub(got)
                txt.print(", expected ")
                txt.print_ub(expect[i])
                txt.print(".\n")
            }
        }

        testing.finish()
        return
    }

    ubyte[] tests  = [ $00, $FF, $A5, $AA, $3C, $C3, $CF, $F3 ]
    ubyte[] expect = [   0,   8,   4,   4,   4,   4,   6,   6 ]
}
