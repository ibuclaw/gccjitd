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
	check-toylang \
	check-toyvm \
	check-unittests \
	check-lint

check-gccjitd:
	$(DUB_TEST)
	$(DUB_TEST) --config=betterC

check-brainf:
	$(DUB_BUILD) :brainf
	test/brainf/gccjitd_brainf test/brainf/mandelbrot.bf | diff -u test/brainf/mandelbrot.out -

check-capi:
	$(DUB_BUILD) :capi
	test/capi/gccjitd_capi | diff -u test/capi/test.out -

check-dapi:
	$(DUB_BUILD) :dapi
	test/dapi/gccjitd_dapi | diff -u test/dapi/test.out -

check-lint:
	$(DUB_RUN) dscanner -- --syntaxCheck source/gccjit
	$(DUB_RUN) dscanner -- --styleCheck source/gccjit

check-square:
	$(DUB_TEST) :square

check-sum-squares:
	$(DUB_TEST) :sum-squares

check-toylang:
	$(DUB_BUILD) :toylang
	test/toylang/gccjitd_toylang test/toylang/fact.toy | diff -u test/toylang/fact.out -

check-toyvm:
	$(DUB_TEST) :toyvm -- test/toyvm/factorial.toy 10
	$(DUB_TEST) :toyvm -- test/toyvm/fibonacci.toy 10

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
	    test/toylang/gccjitd_toylang \
	    test/toyvm/gccjitd_toyvm \
	    test/unittests/gccjitd-unittests-test-betterC \
	    test/unittests/gccjitd-unittests-test-library

clean:
	rm -vf $(DUB_ARTEFACTS)
	dub clean

.NOTPARALLEL:
