import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Context)JIT.Context()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Context()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Object)JIT.Context()));
    assert(!__traits(compiles, cast(JIT.Context)JIT.Object()));

    // A default constructed context has no value.
    assert(!JIT.Context());

    auto ctxt = JIT.Context.acquire();
    assert(ctxt);
    ctxt.release();
    assert(!ctxt);
}

nothrow @nogc unittest
{
    // Child contexts can reference objects of the parent context.
    auto parent = JIT.Context.acquire();
    scope(exit) parent.release();

    auto child = parent.new_child_context();
    scope(exit) child.release();

    assert(child);
    assert(child !is parent);

    auto type = parent.get_type(CType.Int);
    auto value = child.new_rvalue(type, 42);
    assert(value.toString() == "(int)42");
}

nothrow @nogc unittest
{
    // All option setters return the context, so are chainable.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto result = ctxt.set_program_name("unittests")
        .set_optimization_level(OptimizationLevel.Standard)
        .set_debug_info(false)
        .set_dump_initial_tree(false)
        .set_dump_initial_gimple(false)
        .set_dump_generated_code(false)
        .set_dump_summary(false)
        .set_dump_everything(false)
        .set_selfcheck_gc(false)
        .set_keep_intermediates(false);

    assert(result is ctxt);

    if (JIT.Have_Context_set_allow_unreachable_blocks)
        assert(ctxt.set_allow_unreachable_blocks(true) is ctxt);

    if (JIT.Have_Context_set_use_external_driver)
        assert(ctxt.set_use_external_driver(false) is ctxt);

    if (JIT.Have_Context_add_command_line_option)
        assert(ctxt.add_command_line_option("-fno-strict-aliasing") is ctxt);

    if (JIT.Have_Context_add_driver_option)
        assert(ctxt.add_driver_option("-nostdlib") is ctxt);

    if (JIT.Have_Context_set_output_ident)
        assert(ctxt.set_output_ident("gccjitd") is ctxt);
}

nothrow @nogc unittest
{
    // Errors are recorded on the context, the first one being kept.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Context_set_print_errors_to_stderr)
        return;

    ctxt.set_print_errors_to_stderr(false);
    assert(ctxt.get_first_error() is null);

    ctxt.get_builtin_function("__gccjitd_not_a_builtin");
    auto first = ctxt.get_first_error();
    assert(first.length != 0);

    ctxt.get_builtin_function("__gccjitd_also_not_a_builtin");
    assert(ctxt.get_first_error() == first);
}

nothrow @nogc unittest
{
    // Integer types can be built from a size, or deduced from a D type.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    assert(ctxt.get_type(CType.Int).toString() == "int");
    assert(ctxt.get_type(CType.Void).toString() == "void");
    assert(ctxt.get_type(CType.ConstCharPtr).toString() == "const char *");

    assert(ctxt.get_int_type!byte().toString() == ctxt.get_int_type(1, true).toString());
    assert(ctxt.get_int_type!ubyte().toString() == ctxt.get_int_type(1, false).toString());
    assert(ctxt.get_int_type!int().toString() == ctxt.get_int_type(4, true).toString());
    assert(ctxt.get_int_type!ulong().toString() == ctxt.get_int_type(8, false).toString());

    // Non-integral types are rejected.
    assert(!__traits(compiles, ctxt.get_int_type!double()));

    assert(ctxt.new_array_type(CType.Int, 3).toString() == "int[3]");
    assert(ctxt.new_array_type(ctxt.get_type(CType.Char), 2).toString() == "char[2]");

    if (JIT.Have_Context_new_array_type_u64)
        assert(ctxt.new_array_type_u64(CType.Int, 4).toString() == "int[4]");
}

nothrow @nogc unittest
{
    // Constants of all supported kinds.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    assert(ctxt.new_rvalue_from_int(CType.Int, 42).toString() == "(int)42");
    assert(ctxt.new_rvalue(CType.Int, 42).toString() == "(int)42");
    assert(ctxt.new_rvalue_from_long(CType.Long, 42L).toString() == "(long)42");
    assert(ctxt.new_rvalue(CType.Long, 42L).toString() == "(long)42");
    assert(ctxt.new_rvalue_from_double(CType.Double, 0.5).toString()
           == ctxt.new_rvalue(CType.Double, 0.5).toString());
    assert(ctxt.new_rvalue(CType.Double, 0.5).get_type().toString() == "double");
    assert(ctxt.new_rvalue_from_ptr(CType.VoidPtr, null).toString() == "(void *)NULL");
    assert(ctxt.new_rvalue(CType.VoidPtr, null).toString() == "(void *)NULL");
    assert(ctxt.new_string_literal("hello").toString() == `"hello"`);
    assert(ctxt.new_rvalue("hello").toString() == `"hello"`);

    assert(ctxt.new_rvalue_zero(CType.Int).toString() == "(int)0");
    assert(ctxt.new_rvalue_one(CType.Int).toString() == "(int)1");
    assert(ctxt.new_null(CType.VoidPtr).toString() == "(void *)NULL");

    // Constants have the type they were created with.
    auto type = ctxt.get_type(CType.Float);
    assert(ctxt.new_rvalue_zero(type).get_type().toString() == "float");
}

nothrow @nogc unittest
{
    // Unary, binary and comparison expressions.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto type = ctxt.get_type(CType.Int);
    auto zero = ctxt.new_rvalue_zero(type);
    auto one = ctxt.new_rvalue_one(type);

    assert(ctxt.new_unary_op(UnaryOp.Minus, type, one).toString() == "-((int)1)");
    assert(ctxt.new_minus(type, one).toString() == "-((int)1)");
    assert(ctxt.new_bitwise_negate(type, one).toString() == "~((int)1)");
    assert(ctxt.new_logical_negate(type, one).toString() == "!((int)1)");

    assert(ctxt.new_binary_op(BinaryOp.Plus, type, zero, one).toString() == "(int)0 + (int)1");
    assert(ctxt.new_plus(type, zero, one).toString() == "(int)0 + (int)1");
    assert(ctxt.new_minus(type, zero, one).toString() == "(int)0 - (int)1");
    assert(ctxt.new_mult(type, zero, one).toString() == "(int)0 * (int)1");
    assert(ctxt.new_divide(type, zero, one).toString() == "(int)0 / (int)1");
    assert(ctxt.new_modulo(type, zero, one).toString() == "(int)0 % (int)1");
    assert(ctxt.new_bitwise_and(type, zero, one).toString() == "(int)0 & (int)1");
    assert(ctxt.new_bitwise_xor(type, zero, one).toString() == "(int)0 ^ (int)1");
    assert(ctxt.new_bitwise_or(type, zero, one).toString() == "(int)0 | (int)1");
    assert(ctxt.new_logical_and(type, zero, one).toString() == "(int)0 && (int)1");
    assert(ctxt.new_logical_or(type, zero, one).toString() == "(int)0 || (int)1");
    assert(ctxt.new_lshift(type, zero, one).toString() == "(int)0 << (int)1");
    assert(ctxt.new_rshift(type, zero, one).toString() == "(int)0 >> (int)1");

    assert(ctxt.new_comparison(ComparisonOp.Equals, zero, one).toString() == "(int)0 == (int)1");
    assert(ctxt.new_eq(zero, one).toString() == "(int)0 == (int)1");
    assert(ctxt.new_ne(zero, one).toString() == "(int)0 != (int)1");
    assert(ctxt.new_lt(zero, one).toString() == "(int)0 < (int)1");
    assert(ctxt.new_le(zero, one).toString() == "(int)0 <= (int)1");
    assert(ctxt.new_gt(zero, one).toString() == "(int)0 > (int)1");
    assert(ctxt.new_ge(zero, one).toString() == "(int)0 >= (int)1");

    // Comparisons are always of boolean type.
    assert(ctxt.new_eq(zero, one).get_type().toString() == "bool");
}

nothrow @nogc unittest
{
    // Calls, casts and array accesses.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Imported, int_type, "callee", false, param);
    auto one = ctxt.new_rvalue_one(int_type);

    assert(ctxt.new_call(func, one).toString() == "callee ((int)1)");

    auto fnptr_type = ctxt.new_function_type(int_type, false, int_type);
    auto fnptr = ctxt.new_global(GlobalKind.Imported, fnptr_type, "callback");
    assert(ctxt.new_call(cast(JIT.RValue)fnptr, one).toString() == "callback ((int)1)");

    assert(ctxt.new_cast(one, CType.Double).toString() == "(double)(int)1");
    assert(ctxt.new_cast(one, ctxt.get_type(CType.Double)).toString() == "(double)(int)1");

    auto array = ctxt.new_global(GlobalKind.Imported, ctxt.new_array_type(CType.Int, 4), "arr");
    assert(ctxt.new_array_access(cast(JIT.RValue)array, one).toString() == "arr[(int)1]");

    if (JIT.Have_Context_new_bitcast)
    {
        auto value = ctxt.new_rvalue(CType.Float, 1.0);
        assert(ctxt.new_bitcast(value, int_type).get_type().toString() == "int");
    }
}
