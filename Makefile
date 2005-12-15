
DISTFILES=labelnation README COPYING
EXAMPLEFILES=examples/*.txt

all: www

dist:
	./labelnation --version | cut -d " " -f 3 - | cut -f 1 > vn.tmp
	rm -rf labelnation-`cat vn.tmp`
	mkdir labelnation-`cat vn.tmp`
	mkdir labelnation-`cat vn.tmp`/examples
	cp ${DISTFILES} labelnation-`cat vn.tmp`
	cp ${EXAMPLEFILES} labelnation-`cat vn.tmp`/examples
	tar zcvf labelnation-`cat vn.tmp`.tar.gz labelnation-`cat vn.tmp`
	rm -rf labelnation-`cat vn.tmp`

www: dist
	./labelnation --list-types \
        | grep -v Predefined | grep -v Remember | grep -v example > types.tmp
	cat index.html-top types.tmp index.html-bottom > index.html
	rm types.tmp

	(VN=`cat vn.tmp`; \
  sed -e "s/labelnation-[0-9]*.[0-9]*.tar.gz/labelnation-$${VN}.tar.gz/g" \
      index.html > index.html.tmp)
	mv index.html.tmp index.html

	(VN=`cat vn.tmp`; \
  sed -e "s/Latest version: [0-9]*.[0-9]*/Latest version: $${VN}/g" \
      index.html > index.html.tmp)
	mv index.html.tmp index.html

	echo "    (This is the result of running 'labelnation --help')" \
             > help.txt
	echo "" >> help.txt
	./labelnation --help >> help.txt

	(if [ -L labelnation.tar.gz ]; then rm labelnation.tar.gz; fi)
	(VN=`cat vn.tmp`; ln -s labelnation-$${VN}.tar.gz labelnation.tar.gz)

samples:
	@echo "Generating PostScript in examples/ directory..."
	@echo "Trying lines-1.txt..."
	@./labelnation -t avery-5160           \
                       --show-bounding-box     \
                       -i examples/lines-1.txt \
                       -l                      \
                       -o examples/lines-1.ps
	@echo "Trying lines-2.txt..."
	@./labelnation -d -------------        \
                       -t avery-5160           \
                       --show-bounding-box     \
                       -i examples/lines-2.txt \
                       -l                      \
                       -o examples/lines-2.ps
	@echo "Trying multipage.txt..."
	@./labelnation -d -------------          \
                       -t avery-5160             \
                       --show-bounding-box       \
                       -i examples/multipage.txt \
                       -l                        \
                       -o examples/multipage.ps

check:
	@echo "Running tests..."
	@for t in tests/*-*; do                                        \
           (cd $${t}; ./cmd);                                          \
           if cmp --silent $${t}/out $${t}/expect; then                \
             if [ -f $${t}/xfail ]; then                               \
               echo "XPASS: $${t}";                                    \
             else                                                      \
               echo "PASS:  $${t}";                                    \
             fi                                                        \
           else                                                        \
             if [ -f $${t}/xfail ]; then                               \
               echo "XFAIL: $${t}";                                    \
             else                                                      \
               echo "FAIL:  $${t}";                                    \
             fi                                                        \
           fi                                                          \
        done

clean: 
	rm -f *~ *.tmp labelnation*.tar.gz help.txt index.html
