import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Function)JIT.Function()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Function()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Function()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Function)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.Function()));
}

nothrow @nogc unittest
{
    // Functions know their signature, and their parameters.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto a = ctxt.new_param(int_type, "a");
    auto b = ctxt.new_param(int_type, "b");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "add", false, a, b);

    assert(func);
    assert(func.toString() == "add");
    assert(func.get_context() is ctxt);

    if (JIT.Have_Reflection)
    {
        assert(func.get_return_type().toString() == "int");
        assert(func.get_param_count() == 2);
    }

    assert(func.get_param(0).toString() == a.toString());
    assert(func.get_param(1).toString() == b.toString());

    // Blocks and locals belong to the function they were created from.
    auto block = func.new_block("entry");
    assert(block.toString() == "entry");
    assert(block.get_function().toString() == func.toString());
    assert(func.new_block().get_function().toString() == func.toString());

    auto local = func.new_local(int_type, "tmp");
    assert(local.toString() == "tmp");
    assert(local.get_type().toString() == "int");

    if (JIT.Have_Function_new_temp)
        assert(func.new_temp(int_type).get_type().toString() == "int");
}

nothrow @nogc unittest
{
    // Calling a function builds an rvalue of the return type.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto one = ctxt.new_rvalue(int_type, 1);
    auto param = ctxt.new_param(int_type, "i");

    auto nullary = ctxt.new_function(FunctionType.Imported, int_type, "nullary", false);
    assert(nullary().toString() == "nullary ()");
    assert(nullary().get_type().toString() == "int");

    auto unary = ctxt.new_function(FunctionType.Imported, int_type, "unary", false, param);
    assert(unary(one).toString() == "unary ((int)1)");

    auto binary = ctxt.new_function(FunctionType.Imported, int_type, "binary", false,
                                    ctxt.new_param(int_type, "i"),
                                    ctxt.new_param(int_type, "j"));
    assert(binary(one, one).toString() == "binary ((int)1, (int)1)");

    auto ternary = ctxt.new_function(FunctionType.Imported, int_type, "ternary", false,
                                     ctxt.new_param(int_type, "i"),
                                     ctxt.new_param(int_type, "j"),
                                     ctxt.new_param(int_type, "k"));
    assert(ternary(one, one, one).toString() == "ternary ((int)1, (int)1, (int)1)");

    // Builtin functions can be looked up by name.
    auto builtin = ctxt.get_builtin_function("abs");
    assert(builtin);
    assert(builtin.toString() == "abs");

    if (JIT.Have_Function_get_address)
        assert(unary.get_address().get_type().toString() != "int");
}

nothrow @nogc unittest
{
    // Functions can be dumped to a dot file.
    import core.stdc.stdio : fopen, fclose, fgetc, remove;

    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "answer", false);
    func.new_block().end_with_return(ctxt.new_rvalue(int_type, 42));

    assert(func.dump_to_dot("test_function_answer.dot") is func);

    auto file = fopen("test_function_answer.dot", "rb");
    assert(file !is null);
    assert(fgetc(file) != -1);
    fclose(file);
    remove("test_function_answer.dot");
}
