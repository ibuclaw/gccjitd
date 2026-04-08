import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.FunctionPtrType)JIT.FunctionPtrType()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.FunctionPtrType()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Type)JIT.FunctionPtrType()));
    assert(__traits(compiles, cast(JIT.Object)JIT.FunctionPtrType()));
    // Can downcast from Type objects.
    assert(__traits(compiles, cast(JIT.FunctionPtrType)JIT.Type()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.FunctionPtrType)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.FunctionPtrType()));
}
