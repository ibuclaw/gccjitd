import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Parameter)JIT.Parameter()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Parameter()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.LValue)JIT.Parameter()));
    assert(__traits(compiles, cast(JIT.RValue)JIT.Parameter()));
    assert(__traits(compiles, cast(JIT.Object)JIT.Parameter()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.LValue()));
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.RValue()));
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.Parameter()));
}
