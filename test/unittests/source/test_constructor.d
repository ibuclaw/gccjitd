import gccjit;

nothrow @nogc unittest
{
    // Aggregate constructors.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Ctors)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto one = ctxt.new_rvalue(int_type, 1);
    auto two = ctxt.new_rvalue(int_type, 2);

    JIT.Field[2] fields = [ctxt.new_field(int_type, "x"), ctxt.new_field(int_type, "y")];
    JIT.RValue[2] values = [one, two];

    auto point = cast(JIT.Type)ctxt.new_struct_type("point", fields[]);
    auto ctor = ctxt.new_struct_constructor(point, fields[], values[]);
    assert(ctor);
    assert(ctor.get_type().toString() == point.toString());

    auto i = ctxt.new_field(int_type, "i");
    auto onion = ctxt.new_union_type("onion", i, ctxt.new_field(CType.Float, "f"));
    auto union_ctor = ctxt.new_union_constructor(onion, i, one);
    assert(union_ctor);
    assert(union_ctor.get_type().toString() == onion.toString());

    auto array_type = ctxt.new_array_type(int_type, 2);
    auto array_ctor = ctxt.new_array_constructor(array_type, one, two);
    assert(array_ctor);
    assert(array_ctor.get_type().toString() == array_type.toString());
}

nothrow @nogc unittest
{
    // sizeof and alignof expressions.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);

    if (JIT.Have_Context_new_sizeof)
        assert(ctxt.new_sizeof(int_type).toString() == "sizeof (int)");

    if (JIT.Have_Context_new_alignof)
        assert(ctxt.new_alignof(int_type).toString() == "_Alignof (int)");
}

nothrow @nogc unittest
{
    // Vector operations.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Vector_Operations || !JIT.Have_Context_new_rvalue_from_vector)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto vector_type = int_type.get_vector(2);
    auto zero = ctxt.new_rvalue_zero(int_type);
    auto one = ctxt.new_rvalue_one(int_type);

    JIT.RValue[2] elements = [zero, one];
    auto vector = ctxt.new_rvalue_from_vector(vector_type, elements[]);
    auto mask = ctxt.new_rvalue_from_vector(vector_type, elements[]);

    auto perm = ctxt.new_rvalue_vector_perm(vector, vector, mask);
    assert(perm.get_type().toString() == vector_type.toString());

    auto element = ctxt.new_vector_access(vector, zero);
    assert(element.get_type().toString() == "int");

    if (JIT.Have_Context_convert_vector)
    {
        auto double_vector = ctxt.get_type(CType.Double).get_vector(2);
        assert(ctxt.convert_vector(vector, double_vector).get_type().toString()
               == double_vector.toString());
    }
}
