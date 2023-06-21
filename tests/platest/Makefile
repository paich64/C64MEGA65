all: platest.prg

basic_stub.bin: basic_stub.bas
		petcat -w2 -l 0x0801 -o $@ $<

platest.o: platest.s basic_stub.bin
		ca65 --target c64 -l platest.lst -o $@ $<

platest.prg: platest.o
		cl65 -Ln platest.labels -m platest.map  -C platest.cfg -o $@ $<
