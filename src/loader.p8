; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under MIT license. See LICENSE for details.
;
; This file, loader.p8, installs the manager and initializes things.

%zeropage basicsafe
%option no_sysinit
%launcher basic 

%import syslib
%import textio

main {
    sub start() {
        install_api()
        txt.print("installed bank manager\n")
        ; then jump to its init
        return
    }

    sub install_api() {
        ; TODO: load the manager.bin into $0400
    }
}
