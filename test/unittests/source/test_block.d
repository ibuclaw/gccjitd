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

    auto block = ctxt.new_function(FunctionType.Exported, CType.Int, "fun", false)
                    .new_block("fun block");
    JIT.Object obj = block;

    assert(block.get_context() is ctxt);
    assert(obj.get_context() is ctxt);

    // Likewise, toString is equal.
    assert(block.toString() == "fun block");
    assert(block.toString() == obj.toString());
}

nothrow @nogc unittest
{
    // Statements added to a block.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "fun", false);
    auto block = func.new_block("entry");
    auto local = func.new_local(int_type, "i");
    auto one = ctxt.new_rvalue(int_type, 1);

    // All statement builders return the block they were called on.
    assert(block.add_comment("a comment") is block);
    assert(block.add_eval(one) is block);
    assert(block.add_assignment(local, one) is block);
    assert(block.add_assignment_op(local, BinaryOp.Plus, one) is block);

    // Adding a call evaluates it, returning the call expression itself.
    auto callee = ctxt.new_function(FunctionType.Imported, ctxt.get_type(CType.Void),
                                    "side_effect", false);
    assert(block.add_call(callee).toString() == "side_effect ()");

    assert(block.end_with_return(local) is block);
}

nothrow @nogc unittest
{
    // Terminating a block with a conditional or a jump.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "abs", false, param);

    auto entry = func.new_block("entry");
    auto on_true = func.new_block("on_true");
    auto on_false = func.new_block("on_false");
    auto end = func.new_block("end");

    auto zero = ctxt.new_rvalue_zero(int_type);
    assert(entry.end_with_conditional(ctxt.new_lt(param, zero), on_true, on_false) is entry);
    assert(on_true.end_with_jump(end) is on_true);
    assert(on_false.end_with_jump(end) is on_false);
    end.end_with_return(param);

    // Void functions return with no value.
    auto proc = ctxt.new_function(FunctionType.Exported, ctxt.get_type(CType.Void), "proc", false);
    auto block = proc.new_block();
    assert(block.end_with_return() is block);
}

nothrow @nogc unittest
{
    // Terminating a block with a switch.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Switch_Statements)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "sw", false, param);

    auto entry = func.new_block("entry");
    auto one_block = func.new_block("one");
    auto range_block = func.new_block("range");
    auto default_block = func.new_block("default");

    auto one = ctxt.new_rvalue(int_type, 1);
    auto two = ctxt.new_rvalue(int_type, 2);
    auto four = ctxt.new_rvalue(int_type, 4);

    JIT.Case[2] cases = [ctxt.new_case(one, one, one_block),
                         ctxt.new_case(two, four, range_block)];
    assert(cases[0].get_context() is ctxt);

    assert(entry.end_with_switch(param, default_block, cases[]) is entry);
    one_block.end_with_return(one);
    range_block.end_with_return(two);
    default_block.end_with_return(ctxt.new_rvalue_zero(int_type));

    // Compiling proves the switch was well formed.
    auto result = ctxt.compile();
    scope(exit) result.release();

    auto code = cast(int function(int) nothrow @nogc)result.get_code!(int function(int))("sw");
    assert(code !is null);
    assert(code(1) == 1);
    assert(code(3) == 2);
    assert(code(9) == 0);
}
