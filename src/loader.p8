; Commander X16 Bank Allocator
;
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file, loader.p8, installs the manager and initializes things.

%zeropage basicsafe
%launcher basic 
%option ignore_unused

%import syslib
%import textio

main {
    sub start() {
        install_api()
        txt.print("installed bank manager\n")
        return
    }

    sub install_api() {
        ; TODO: load the manager.bin into $0400
        ; and then jump to its initialization entrypoint
        return
    }
}
