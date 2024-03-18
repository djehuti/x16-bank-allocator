; Commander X16 Bank Allocator
;
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, bits.p8, implements a bit counter.
; Not a standalone unit; %import it.
;
; "exported" function: bits.bitcount(ubyte)->ubyte
;
; (not "exported" to external callers, just to the importing module)
;

bits {
    ; Count the 1-bits in the given byte.
    sub bitcount(ubyte a) -> ubyte {
        return counted[a & $0F] + counted[a >> 4]
    }

    ; Lookup table for a nybble at a time.
    ; This should be considered private and const.
    ubyte[16] counted = [
        0, 1, 1, 2, ; %0000 %0001 %0010 %0011
        1, 2, 2, 3, ; %0100 %0101 %0110 %0111
        1, 2, 2, 3, ; %1000 %1001 %1010 %1011
        2, 3, 3, 4  ; %1100 %1101 %1110 %1111
    ]
}
