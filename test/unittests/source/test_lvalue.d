import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.LValue)JIT.LValue()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.LValue()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.RValue)JIT.LValue()));
    assert(__traits(compiles, cast(JIT.Object)JIT.LValue()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.LValue)JIT.RValue()));
    assert(!__traits(compiles, cast(JIT.LValue)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.LValue()));
}
