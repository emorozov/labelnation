
all: www

dist:
	./labelnation.pl --version | cut -d " " -f 3 - | cut -c 1,2,3 > vn.tmp
	tar zcvf labelnation-`cat vn.tmp`.tar.gz \
                 labelnation.pl README examples/ \
                 --exclude examples/CVS          \
                 --exclude examples/.cvsignore

www: dist
	VN=`cat vn.tmp` \
  sed -e "s/labelnation-[0-9]*.[0-9]*.tar.gz/labelnation-$${VN}.tar.gz/g" \
      index.html | tee index.html.tmp
	mv index.html.tmp index.html

	VN=`cat vn.tmp` \
  sed -e "s/Current version: [0-9]*.[0-9]*/Current version: $${VN}/g" \
      index.html | tee index.html.tmp
	mv index.html.tmp index.html

	cvs ci -m "made www" index.html
	rm vn.tmp

test:
	echo "Generating PostScript in examples/ directory..."
	./labelnation.pl -d -------------        \
                         -t avery-5160           \
                         --show-bounding-box     \
                         -l examples/lines-2.txt \
                         -o examples/lines-2.ps


clean: 
	rm -f *~ *.tmp