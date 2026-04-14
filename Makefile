COMPILER := gdc
DUB := dub
BUILD := debug
DUB_BUILD := $(DUB) build --build=$(BUILD) --compiler=$(COMPILER)
DUB_TEST := $(DUB) test --compiler=$(COMPILER)
DUB_RUN := $(DUB) run

all:
	$(DUB_BUILD)

check: check-gccjitd \
	check-brainf \
	check-capi \
	check-dapi \
	check-square \
	check-sum-squares \
	check-toy \
	check-unittests \
	check-lint

check-gccjitd:
	$(DUB_TEST)
	$(DUB_TEST) --config=betterC

check-brainf:
	$(DUB_TEST) :brainf -- test/brainf/mandelbrot.bf

check-capi:
	$(DUB_TEST) :capi

check-dapi:
	$(DUB_TEST) :dapi

check-lint:
	$(DUB_RUN) dscanner -- --syntaxCheck source/gccjit
	$(DUB_RUN) dscanner -- --styleCheck source/gccjit

check-square:
	$(DUB_TEST) :square

check-sum-squares:
	$(DUB_TEST) :sum-squares

check-toy:
	$(DUB_TEST) :toy -- test/toy/fact.toy

check-unittests:
	$(DUB_TEST) :unittests
	$(DUB_TEST) :unittests --config=betterC

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
	    test/toy/gccjitd_toy \
	    test/unittests/gccjitd-unittests-test-betterC \
	    test/unittests/gccjitd-unittests-test-library

clean:
	rm -vf $(DUB_ARTEFACTS)
	dub clean

.NOTPARALLEL:
