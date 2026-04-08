import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.RValue)JIT.RValue()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.RValue()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.RValue()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.RValue)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.RValue()));
}
