import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Type)JIT.Type()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Type()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Type()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Type)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.Type()));
}
