# Make 

PROG=../labelnation.pl

default: reminder

reminder:
	echo "Rules are 'self', 'office-return', and 'office-out'."

self:
	${PROG} -p office-80.param -t maco-ll8100 \
                -l self.txt -o self.ps

collins-sussman:
	${PROG} -p office-80.param -t maco-ll8100 \
                -l collins-sussman.txt -o collins-sussman.ps

office-return:
	${PROG} -p office-80.param -t maco-ll8100 \
                -l chi-collab.txt -o chi-collab.ps

office-out:
	${PROG} -p office-20.param -t avery-5261 \
                -l sf-collab.txt -o sf-collab.ps

clean:
	rm *~ *.ps
