
all: www

changelog: log

ChangeLog: log

log:
	cvs2cl.pl --fsf -S -r 

dist:
	./labelnation.pl --version | cut -d " " -f 3 - | cut -f 1 > vn.tmp
	tar zcvf labelnation-`cat vn.tmp`.tar.gz \
                 labelnation.pl README COPYING examples/ \
                 --exclude examples/CVS          \
                 --exclude examples/.cvsignore

www: dist
	(VN=`cat vn.tmp`; \
  sed -e "s/labelnation-[0-9]*.[0-9]*.tar.gz/labelnation-$${VN}.tar.gz/g" \
      index.html | tee index.html.tmp)
	mv index.html.tmp index.html

	(VN=`cat vn.tmp`; \
  sed -e "s/Latest version: [0-9]*.[^<]/Latest version: $${VN}/g" \
      index.html | tee index.html.tmp)
	mv index.html.tmp index.html

	echo "    (This is the result of running 'labelnation.pl --help')" \
             > help.txt
	echo "" >> help.txt
	./labelnation.pl --help >> help.txt

	cvs2cl.pl -r -R labelnation
	(VN=`cat vn.tmp`; ln -s labelnation-$${VN}.tar.gz labelnation.tar.gz)

test:
	@echo "Generating PostScript in examples/ directory..."
	@./labelnation.pl -t avery-5160           \
                          --show-bounding-box     \
                          -i examples/lines-1.txt \
                          -l                      \
                          -o examples/lines-1.ps
	@./labelnation.pl -d -------------        \
                          -t avery-5160           \
                          --show-bounding-box     \
                          -i examples/lines-2.txt \
                          -l                      \
                          -o examples/lines-2.ps
	@./labelnation.pl -d -------------          \
                          -t avery-5160             \
                          --show-bounding-box       \
                          -i examples/multipage.txt \
                          -l                        \
                          -o examples/multipage.ps


clean: 
	rm -f *~ *.tmp labelnation-*.tar.gz