import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Parameter)JIT.Parameter()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Parameter()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.LValue)JIT.Parameter()));
    assert(__traits(compiles, cast(JIT.RValue)JIT.Parameter()));
    assert(__traits(compiles, cast(JIT.Object)JIT.Parameter()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.LValue()));
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.RValue()));
    assert(!__traits(compiles, cast(JIT.Parameter)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.Parameter()));
}

nothrow @nogc unittest
{
    // Parameters are usable as both lvalues and rvalues.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto param = ctxt.new_param(CType.Int, "i");
    assert(param);
    assert(param.toString() == "i");
    assert(param.get_context() is ctxt);

    JIT.LValue lvalue = param;
    JIT.RValue rvalue = param;
    JIT.Object obj = param;

    assert(lvalue.toString() == param.toString());
    assert(rvalue.toString() == param.toString());
    assert(obj.toString() == param.toString());

    assert(rvalue.get_type().toString() == "int");
    assert(lvalue.get_address().get_type().toString() == "int *");
}
