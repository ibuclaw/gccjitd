import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Object)JIT.Object()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Object()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Location)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Object()));
}
