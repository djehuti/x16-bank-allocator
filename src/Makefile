P8COMPILE=p8compile
P8FLAGS=-target cx16 -quietasm -sourcelines -out out -srcdirs library

TARGETS=out/loader.prg out/manager.prg

all: $(TARGETS)

out/loader.prg: loader.p8 library/*.p8
	$(P8COMPILE) $(P8FLAGS) loader.p8

out/manager.prg: manager.p8 library/*.p8
	$(P8COMPILE) $(P8FLAGS) manager.p8

clean:
	$(RM) out/*.asm out/*.prg out/*.vice-mon-list
