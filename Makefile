
all: www

dist:
	./labelnation.pl --version | cut -d " " -f 3 - | cut -c 1,2,3 > vn.tmp
	tar zcvf labelnation-`cat vn.tmp`.tar.gz \
                 labelnation.pl README examples/ \
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

	cvs ci -m "made www" index.html

	echo "    (This is the result of running 'labelnation.pl --help')" \
             > help.txt
	echo "" >> help.txt
	./labelnation.pl --help >> help.txt

test:
	echo "Generating PostScript in examples/ directory..."
	./labelnation.pl -d -------------        \
                         -t avery-5160           \
                         --show-bounding-box     \
                         -l examples/lines-2.txt \
                         -o examples/lines-2.ps


clean: 
	rm -f *~ *.tmp