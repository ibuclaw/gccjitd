import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Struct)JIT.Struct()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Struct()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Type)JIT.Struct()));
    assert(__traits(compiles, cast(JIT.Object)JIT.Struct()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Struct)JIT.Type()));
    assert(!__traits(compiles, cast(JIT.Struct)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.Struct()));
}
