; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, manager.p8, implements the bank allocator loadable part.
; The functionality is %imported from `impl`; this file exposes an ABI
; that uses it.
;
; Build this into manager.bin, to be loaded into golden ram.

%zeropage dontuse
%launcher none
%option no_sysinit

%import impl

%address $0400

main $0400 {
    asmsub start() {
        %asm{{
    pubinit:
            jmp p8b_impl.p8s_init
    puballoc:
            jmp p8b_wrappers.p8s_allocate
    pubfind:
            jmp p8b_wrappers.p8s_findbank
    publist:
            jmp p8b_wrappers.p8s_listbanks
    pubinfo:
            jmp p8b_wrappers.p8s_bankinfo
    pubsign:
            jmp p8b_wrappers.p8s_nameAndSign
    endmarker:
            brk
            brk
            brk
        }}
    }
}

wrappers {
    ; The internal stub for impl.allocate.
    asmsub allocate(ubyte bank @A, bool alloc @Pc, uword sigblock @R0) clobbers(X, Y) -> ubyte @A {
        %asm{{
            stz p8b_impl.p8s_allocate.p8v_alloc
            rol p8b_impl.p8s_allocate.p8v_alloc
            sta p8b_impl.p8s_allocate.p8v_bank
            lda cx16.r0L
            sta p8b_impl.p8s_allocate.p8v_signature
            lda cx16.r0H
            sta p8b_impl.p8s_allocate.p8v_signature+1
            jmp p8b_impl.p8s_allocate
        }}
    }

    asmsub findbank(uword name @AY) clobbers(X, Y) -> ubyte @A {
        %asm{{
            sta p8b_impl.p8s_findbank.p8v_name
            sty p8b_impl.p8s_findbank.p8v_name+1
            jmp p8b_impl.p8s_findbank
        }}
    }

    asmsub listbanks(uword addr @R0) clobbers(A, X, Y) {
        %asm{{
            lda cx16.r0L
            sta p8b_impl.p8s_listbanks.p8v_addr
            lda cx16.r0H
            sta p8b_impl.p8s_listbanks.p8v_addr+1
            jmp p8b_impl.p8s_listbanks
        }}
    }

    asmsub bankinfo(ubyte bank @A, uword addr @R0) clobbers(X, Y) -> bool @A {
        %asm{{
            sta p8b_impl.p8s_bankinfo.p8v_bank
            lda cx16.r0L
            sta p8b_impl.p8s_bankinfo.p8v_addr
            lda cx16.r0H
            sta p8b_impl.p8s_bankinfo.p8v_addr+1
            jmp p8b_impl.p8s_bankinfo
        }}
    }

    asmsub nameAndSign(uword block @R0, uword name @AY) {
        %asm{{
            sta p8b_impl.p8s_nameAndSign.p8v_name
            sty p8b_impl.p8s_nameAndSign.p8v_name+1
            lda cx16.r0L
            sta p8b_impl.p8s_nameAndSign.p8v_block
            lda cx16.r0H
            sta p8b_impl.p8s_nameAndSign.p8v_block+1
            jmp p8b_impl.p8s_nameAndSign
        }}
    }
}
