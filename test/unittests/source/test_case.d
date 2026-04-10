import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Case)JIT.Case()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Case()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Case()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Case)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Case()));
}

nothrow @nogc unittest
{
    // Check Context never changes when passing between types.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto block = ctxt.new_function(FunctionType.Exported, CType.Int, "fun", false)
                    .new_block("case block");
    auto caseval = ctxt.new_rvalue_one(CType.Int);

    auto cs = ctxt.new_case(caseval, caseval, block);
    JIT.Object obj = cs;
    assert(cs.get_context() is obj.get_context());

    // Likewise, toString is equal.
    assert(cs.toString() == obj.toString());
}
