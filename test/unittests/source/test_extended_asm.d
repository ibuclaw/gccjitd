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

    if (!JIT.Have_Asm_Statements)
        return;

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

nothrow @nogc unittest
{
    // An extended asm statement with operands and clobbers, compiled and run.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Asm_Statements)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "add_one", false, param);
    auto block = func.new_block();
    auto local = func.new_local(int_type, "result");

    version (X86_64)
    {
        auto extasm = block.add_extended_asm("addl $1, %0;")
            .set_volatile_flag(true)
            .add_output_operand("=r", local)
            .add_input_operand("0", param);
        // Despite the name, this adds to the list of clobbered registers.
        extasm.add_input_operand("cc");

        assert(extasm.toString().length != 0);

        block.end_with_return(local);

        auto result = ctxt.compile();
        scope(exit) result.release();

        auto code = cast(int function(int) nothrow @nogc)
            result.get_code!(int function(int))("add_one");
        assert(code !is null);
        assert(code(41) == 42);
    }
}

nothrow @nogc unittest
{
    // An asm goto statement jumps to one of its blocks.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Asm_Statements)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "jumper", false);
    auto entry = func.new_block("entry");
    auto target = func.new_block("target");
    auto fallthrough = func.new_block("fallthrough");

    JIT.Block[1] blocks = [target];
    auto extasm = entry.end_with_extended_asm_goto("", blocks[], fallthrough);
    assert(extasm);
    assert(extasm.get_context() is ctxt);

    target.end_with_return(ctxt.new_rvalue_one(int_type));
    fallthrough.end_with_return(ctxt.new_rvalue_zero(int_type));

    // Statements can also be added without any operands at all.
    auto simple = ctxt.new_function(FunctionType.Exported, ctxt.get_type(CType.Void),
                                    "nop", false);
    auto block = simple.new_block();
    block.add_extended_asm("nop").set_inline_flag(false);
    assert(block.toString().length != 0);
    block.end_with_return();
}
