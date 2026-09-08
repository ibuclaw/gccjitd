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

nothrow @nogc unittest
{
    // Function pointer types know their signature.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto double_type = ctxt.get_type(CType.Double);
    auto type = ctxt.new_function_type(int_type, false, double_type, int_type);

    assert(type);
    assert(type.get_context() is ctxt);

    if (!JIT.Have_Reflection)
        return;

    auto fnptr = type.dyncast_function_ptr_type();
    assert(fnptr);
    assert(fnptr.get_return_type().toString() == "int");
    assert(fnptr.get_param_count() == 2);
    assert(fnptr.get_param_type(0).toString() == "double");
    assert(fnptr.get_param_type(1).toString() == "int");
    assert((cast(JIT.Type)fnptr).toString() == fnptr.toString());

    // Variadic function types are also function pointers.
    auto variadic = ctxt.new_function_type(int_type, true, int_type)
                        .dyncast_function_ptr_type();
    assert(variadic.get_param_count() == 1);
}
