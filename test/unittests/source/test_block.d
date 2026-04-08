import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Block)JIT.Block()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Block()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Block()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Block)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Block()));
}

nothrow @nogc unittest
{
    // Check Context never changes when passing between types.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto fun = ctxt.new_function(FunctionType.Exported, CType.Int, "fun", false);
    auto block = fun.new_block("fun block");
    JIT.Object obj = block;

    assert(block.get_context() is ctxt);
    assert(obj.get_context() is ctxt);

    // Likewise, toString is equal.
    assert(block.toString() == "fun block");
    assert(block.toString() == obj.toString());
}
