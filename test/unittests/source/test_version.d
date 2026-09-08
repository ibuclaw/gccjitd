import gccjit;

unittest
{
    // The version of the libgccjit library we are linked against.
    if (!JIT.Have_Version)
        return;

    assert(JIT.Version.major >= 9);
    assert(JIT.Version.minor >= 0);
    assert(JIT.Version.patchlevel >= 0);

    // Version is a namespace, it cannot be instantiated.
    assert(!__traits(compiles, JIT.Version()));
}
