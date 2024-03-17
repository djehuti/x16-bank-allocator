; Commander X16 Bank Allocator
; by Ben Cox (c) 2024, under BSD license. See LICENSE for details.
;
; This file implements a superminiature testing "framework" (HA).

%import textio

%zeropage dontuse
%option ignore_unused

;
; To use this testing "framework":
;
; %import testing
;
; And then in each test func, do this:
;
; sub testBlahBlah() {
;     testing.starttest("blah blah")
;     ; do stuff
;     ; if a test fails, call testing.fail():
;     if badness {
;         testing.fail()
;         txt.print("no badness should happen")
;     }
;     ; then you can do more stuff, it doesn't abort.
;     ; then finish up with this:
;     testing.finish()
;     return
; }
;
; And your main.start can then just be a bunch of calls to these.
;

testing {
    bool ok

    ; Call this at the start of the test.
    sub starttest(str name) {
        txt.print("\ntesting ")
        txt.print(name)
        txt.print("...")
        ok = true
        return
    }

    ; Call this if/when your test fails.
    ; This prints a newline (to end the ...), but
    ; leaves any error message printing to you.
    sub fail() {
        ok = false
        txt.print("\n")
        return
    }

    ; Call this at the end of your test.
    sub finish() {
        if ok {
            txt.print("passed\n")
        } else {
            txt.print("failed\n")
        }
        return
    }
}
