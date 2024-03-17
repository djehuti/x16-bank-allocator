; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, manager.p8, implements the bank allocator loadable part.
; Build this into manager.bin, to be loaded into golden ram.

%import syslib
%import textio

%zeropage dontuse
%launcher none
%option no_sysinit, ignore_unused
%address $0400

%import impl

; main $0400 { ; This block should be exactly 24 bytes long.
;     %asm{{
;     pubinit:
;         JMP wrappers.init
;     puballoc:
;         JMP wrappers.allocate
;     pubsetalloc:
;         JMP wrappers.setalloc
;     pubfindbank:
;         JMP wrappers.findbank
;     publistbanks:
;         JMP wrappers.listbanks
;     pubbankinfo:
;         JMP wrappers.bankinfo
;     extra1:
;         BRK
;         BRK
;         BRK
;     extra2:
;         BRK
;         BRK
;         BRK
;     }}
; }
;
; wrappers { ; Should wind up at $0418 (but we don't actually care)
;     asmsub init() clobbers(A, X, Y) {
;         %asm{{
;             JMP impl.init
;         }}
;     }
;
;     asmsub allocate(ubyte bank @ A, bool alloc @ Pc) clobbers(A, X, Y) -> ubyte @A {
;         %asm{{
;             PHP
;             STA impl.allocate.p8a_bank
;             PLA
;             STA impl.allocate.p8a_alloc
;             JMP impl.allocate
;         }}
;     }
;
;     asmsub setalloc() {
;         %asm{{
;             JMP impl.setalloc
;         }}
;     }
;     ; etc.
; }
