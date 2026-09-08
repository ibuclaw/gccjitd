import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.VectorType)JIT.VectorType()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.VectorType()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Type)JIT.VectorType()));
    assert(__traits(compiles, cast(JIT.Object)JIT.VectorType()));
    // Can downcast from Type objects.
    assert(__traits(compiles, cast(JIT.VectorType)JIT.Type()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.VectorType)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.VectorType()));
}

nothrow @nogc unittest
{
    // Vector types know their element type and number of units.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Type_get_vector || !JIT.Have_Reflection)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto vector = int_type.get_vector(4).dyncast_vector();

    assert(vector);
    assert(vector.get_num_units() == 4);
    assert(vector.get_element_type().toString() == "int");
    assert(vector.get_context() is ctxt);
    assert((cast(JIT.Type)vector).toString() == vector.toString());

    // Non-vector types don't downcast to a vector type.
    assert(!int_type.dyncast_vector());
}

nothrow @nogc unittest
{
    // Vectors can be built from a set of rvalues.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Type_get_vector || !JIT.Have_Context_new_rvalue_from_vector)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto vector_type = int_type.get_vector(2);
    JIT.RValue[2] elements = [ctxt.new_rvalue(int_type, 1), ctxt.new_rvalue(int_type, 2)];

    auto vector = ctxt.new_rvalue_from_vector(vector_type, elements[]);
    assert(vector);
    assert(vector.get_type().toString() == vector_type.toString());
}
