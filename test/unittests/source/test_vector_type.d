import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.VectorType)JIT.VectorType()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.VectorType()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Type)JIT.VectorType()));
    assert(__traits(compiles, cast(JIT.Object)JIT.VectorType()));
    // Can downcast from Type objects.
    assert(__traits(compiles, cast(JIT.VectorType)JIT.Type()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.VectorType)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.VectorType()));
}
