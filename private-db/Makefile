# Make 

PROG=../labelnation.pl

default: reminder

self:
	${PROG} -p office-80.param -t maco-ll8100 -l \
                -i self.txt -o self.ps

rachel:
	${PROG} -p office-80.param -t maco-ll8100 -l \
                -i rachel.txt -o rachel.ps

collins-sussman:
	${PROG} -p office-80.param -t maco-ll8100 -l \
                -i collins-sussman.txt -o collins-sussman.ps

office-return:
	${PROG} -p office-80.param -t maco-ll8100 -l \
                -i chi-collab.txt -o chi-collab.ps

office-out:
	${PROG} -p office-20.param -t avery-5261 -l \
                -i sf-collab.txt -o sf-collab.ps

massolit-from:
	${PROG} --show-bounding-box -t avery-5167 -l \
                -i massolit.txt -o massolit-from.ps

massolit-to:
	${PROG} --show-bounding-box -t avery-5263 -l \
                -i massolit.txt -o massolit-to.ps

clean:
	rm *~ *.ps
