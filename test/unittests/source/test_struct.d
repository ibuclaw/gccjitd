import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Struct)JIT.Struct()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Struct()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Type)JIT.Struct()));
    assert(__traits(compiles, cast(JIT.Object)JIT.Struct()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Struct)JIT.Type()));
    assert(!__traits(compiles, cast(JIT.Struct)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.Struct()));
}

nothrow @nogc unittest
{
    // Structs can be created from their fields.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto x = ctxt.new_field(int_type, "x");
    auto y = ctxt.new_field(int_type, "y");
    auto point = ctxt.new_struct_type("point", x, y);

    assert(point);
    assert(point.toString() == "struct point");
    assert(point.get_context() is ctxt);
    assert((cast(JIT.Type)point).toString() == point.toString());

    if (JIT.Have_Reflection)
    {
        assert(point.get_field_count() == 2);
        assert(point.get_field(0).toString() == x.toString());
        assert(point.get_field(1).toString() == y.toString());
    }
}

nothrow @nogc unittest
{
    // Or as an opaque struct that is populated later, allowing the struct
    // to refer to itself.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto node = ctxt.new_opaque_struct_type("node");
    assert(node);
    assert(node.toString() == "struct node");

    auto value = ctxt.new_field(CType.Int, "value");
    auto next = ctxt.new_field((cast(JIT.Type)node).get_pointer(), "next");
    assert(node.set_fields(value, next) is node);

    if (JIT.Have_Reflection)
    {
        assert(node.get_field_count() == 2);
        assert(node.get_field(1).toString() == next.toString());
    }
}

nothrow @nogc unittest
{
    // Unions are plain types, not structs.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto i = ctxt.new_field(CType.Int, "i");
    auto f = ctxt.new_field(CType.Float, "f");
    auto onion = ctxt.new_union_type("onion", i, f);

    assert(onion.toString() == "union onion");
    assert(onion.get_context() is ctxt);
}
