import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.LValue)JIT.LValue()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.LValue()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.RValue)JIT.LValue()));
    assert(__traits(compiles, cast(JIT.Object)JIT.LValue()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.LValue)JIT.RValue()));
    assert(!__traits(compiles, cast(JIT.LValue)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.LValue()));
}

nothrow @nogc unittest
{
    // Globals are lvalues that can be given an initial value.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto global = ctxt.new_global(GlobalKind.Exported, int_type, "counter");

    assert(global);
    assert(global.toString() == "counter");
    assert(global.get_context() is ctxt);
    assert(global.get_type().toString() == "int");
    assert(global.get_address().get_type().toString() == "int *");

    JIT.RValue rvalue = global;
    JIT.Object obj = global;
    assert(rvalue.toString() == global.toString());
    assert(obj.toString() == global.toString());

    if (JIT.Have_Ctors)
    {
        assert(global.set_initializer(ctxt.new_rvalue(int_type, 42)).toString()
               == global.toString());
    }

    if (JIT.Have_LValue_set_initializer)
    {
        int[2] blob = [1, 2];
        auto array = ctxt.new_global(GlobalKind.Exported,
                                     ctxt.new_array_type(int_type, 2), "values");
        assert(array.set_initializer(blob.ptr, blob.sizeof).toString() == array.toString());
    }
}

nothrow @nogc unittest
{
    // Variable attributes.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto global = ctxt.new_global(GlobalKind.Exported, CType.Int, "attributed");

    if (JIT.Have_Alignment)
    {
        assert(global.set_alignment(16).toString() == global.toString());
        assert(global.get_alignment() == 16);
    }

    if (JIT.Have_LValue_set_link_section)
        assert(global.set_link_section(".data").toString() == global.toString());

    if (JIT.Have_LValue_set_tls_model)
    {
        auto tls = ctxt.new_global(GlobalKind.Exported, CType.Int, "tls");
        assert(tls.set_tls_model(TlsModel.GlobalDynamic).toString() == tls.toString());
    }

    if (JIT.Have_LValue_set_readonly)
        assert(global.set_readonly().toString() == global.toString());
}

nothrow @nogc unittest
{
    // Locals are lvalues within the scope of a function.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Exported, int_type, "fun", false);
    auto local = func.new_local(int_type, "i");

    assert(local.toString() == "i");
    assert(local.get_type().toString() == "int");
    assert(local.get_context() is ctxt);

    if (JIT.Have_LValue_set_register_name)
    {
        auto reg = func.new_local(int_type, "r");
        assert(reg.set_register_name("r12").toString() == reg.toString());
    }

    // Fields of a local struct are lvalues too.
    auto x = ctxt.new_field(int_type, "x");
    auto point = cast(JIT.Type)ctxt.new_struct_type("point", x);
    auto value = func.new_local(point, "p");
    assert(value.access_field(x).toString() == "p.x");
    assert(value.access_field(x).get_type().toString() == "int");
}
