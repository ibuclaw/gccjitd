import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Object)JIT.Object()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Object()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Location)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Object()));
}

nothrow @nogc unittest
{
    // Every object in a context can be described, and knows its context.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(int_type, "i");
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "fun", false, param);

    JIT.Object[6] objects = [cast(JIT.Object)int_type,
                             cast(JIT.Object)ctxt.new_field(int_type, "x"),
                             cast(JIT.Object)param,
                             cast(JIT.Object)func,
                             cast(JIT.Object)func.new_block("entry"),
                             cast(JIT.Object)ctxt.new_rvalue_one(int_type)];

    foreach (obj; objects)
    {
        assert(obj);
        assert(obj.toString().length != 0);
        assert(obj.get_context() is ctxt);
    }

    // A default constructed object has no value.
    assert(!JIT.Object());
}
