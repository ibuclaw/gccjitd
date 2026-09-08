import gccjit;

nothrow @nogc unittest
{
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.CompileResult()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Object)JIT.CompileResult()));
    assert(!__traits(compiles, cast(JIT.CompileResult)JIT.Object()));

    // A default constructed result has no value.
    assert(!JIT.CompileResult());
}

nothrow @nogc unittest
{
    // Compile a function in-memory, then call it.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "square", false, param);

    auto block = func.new_block();
    block.end_with_return(ctxt.new_mult(int_type, param, param));

    auto result = ctxt.compile();
    assert(result);

    auto code = result.get_code!(int function(int))("square");
    assert(code !is null);
    assert((cast(int function(int) nothrow @nogc)code)(4) == 16);

    result.release();
    assert(!result);
}

nothrow @nogc unittest
{
    // Exported globals are reachable in the compiled result.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto global = ctxt.new_global(GlobalKind.Exported, int_type, "counter");

    auto func = ctxt.new_function(FunctionType.Exported, ctxt.get_type(CType.Void), "bump", false);
    auto block = func.new_block();
    block.add_assignment_op(global, BinaryOp.Plus, ctxt.new_rvalue(int_type, 7));
    block.end_with_return();

    auto result = ctxt.compile();
    scope(exit) result.release();

    auto counter = result.get_global!int("counter");
    assert(counter !is null);
    assert(*counter == 0);

    auto bump = cast(void function() nothrow @nogc)result.get_code!(void function())("bump");
    assert(bump !is null);
    bump();
    assert(*counter == 7);
}

nothrow @nogc unittest
{
    // Compiling to a file, and dumping the context to a file.
    import core.stdc.stdio : fopen, fclose, fseek, ftell, remove, SEEK_END;

    static bool notEmpty(const(char)* path) nothrow @nogc
    {
        auto file = fopen(path, "rb");
        if (file is null)
            return false;
        scope(exit) fclose(file);
        fseek(file, 0, SEEK_END);
        return ftell(file) > 0;
    }

    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "answer", false);
    func.new_block().end_with_return(ctxt.new_rvalue(int_type, 42));

    if (ctxt.compile(OutputKind.Assembler, "test_compile_answer.s") !is ctxt)
        assert(0);
    if (!notEmpty("test_compile_answer.s"))
        assert(0);
    remove("test_compile_answer.s");

    if (ctxt.dump_to_file("test_compile_answer.c", true) !is ctxt)
        assert(0);
    if (!notEmpty("test_compile_answer.c"))
        assert(0);
    remove("test_compile_answer.c");
}
