import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Field)JIT.Field()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Field()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Field()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Field)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Field()));
}
