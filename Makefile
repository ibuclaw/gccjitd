all:
	dub build

check: check-gccjitd \
	check-brainf \
	check-capi \
	check-dapi \
	check-square \
	check-sum-squares \
	check-toy

check-gccjitd:
	dub test
	dub test --config=betterC

check-brainf:
	dub test :brainf -- test/brainf/mandelbrot.bf

check-capi:
	dub test :capi

check-dapi:
	dub test :dapi

check-square:
	dub test :square

check-sum-squares:
	dub test :sum-squares

check-toy:
	dub test :toy -- test/toy/fact.toy

# Build objects
DUB_ARTEFACTS = \
	    libgccjitd.a \
	    gccjitd-test-library \
	    gccjitd-test-betterC \
	    test/brainf/gccjitd_brainf \
	    test/capi/gccjitd_capi \
	    test/dapi/gccjitd_dapi \
	    test/square/gccjitd_square \
	    test/sum-squares/gccjitd_sum-squares \
	    test/toy/gccjitd_toy

clean:
	rm -vf $(DUB_ARTEFACTS)
	dub clean
