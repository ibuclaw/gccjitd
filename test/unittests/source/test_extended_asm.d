import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.ExtendedAsm)JIT.ExtendedAsm()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.ExtendedAsm()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.ExtendedAsm()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.ExtendedAsm)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.ExtendedAsm()));
}

nothrow @nogc unittest
{
    // Check Context never changes when passing between types.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto extasm = ctxt.new_function(FunctionType.Exported, CType.Int, "fun", false)
                    .new_block("asm block")
                    .add_extended_asm("instruction");
    JIT.Object obj = extasm;

    assert(extasm.get_context() is obj.get_context());

    // Check basic functionality
    extasm.set_volatile_flag(true)
        .set_inline_flag(true)
        .add_input_operand("a", ctxt.new_rvalue_one(CType.Int));

    // Check toString is equal.
    assert(extasm.toString() == obj.toString());
}
