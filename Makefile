
all: nothing


nothing:
	echo "No default Makefile action; perhaps you want 'make test'?"


test:
	echo "Generating PostScript in examples/ directory..."
	./labelnation.pl -d -------------        \
                         -t avery-5160           \
                         --show-bounding-box     \
                         -l examples/lines-2.txt \
                         -o examples/lines-2.ps
