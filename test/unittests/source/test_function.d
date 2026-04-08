import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Function)JIT.Function()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Function()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Function()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Function)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.Function()));
}
