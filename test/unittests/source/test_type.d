import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Type)JIT.Type()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Type()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Type()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Type)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Function)JIT.Type()));
}

nothrow @nogc unittest
{
    // Derived types.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto type = ctxt.get_type(CType.Int);
    assert(type.get_pointer().toString() == "int *");
    assert(type.get_const().toString() == "const int");
    assert(type.get_volatile().toString() == "volatile int");
    assert(type.get_const().get_pointer().toString() == "const int *");

    if (JIT.Have_Type_get_aligned)
        assert(type.get_aligned(16));

    if (JIT.Have_Type_get_vector)
        assert(type.get_vector(4).toString() == "int  __attribute__((vector_size(sizeof (int) * 4)))");

    if (JIT.Have_Type_get_restrict)
        assert(type.get_pointer().get_restrict());

    // Context is carried over to all derived types.
    assert(type.get_context() is ctxt);
    assert(type.get_pointer().get_context() is ctxt);
}

nothrow @nogc unittest
{
    // Type sizes and compatibility.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Sized_Integers)
        return;

    assert(ctxt.get_type(CType.Int).get_size() == 4);
    assert(ctxt.get_int_type(2, true).get_size() == 2);
    assert(ctxt.get_int_type!byte().get_size() == 1);

    auto int_type = ctxt.get_type(CType.Int);
    assert(int_type.is_compatible_with(ctxt.get_int_type(4, true)));
    assert(!int_type.is_compatible_with(ctxt.get_type(CType.Double)));
}

nothrow @nogc unittest
{
    // Type reflection.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_Reflection)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto bool_type = ctxt.get_type(CType.Bool);
    auto double_type = ctxt.get_type(CType.Double);

    assert(bool_type.is_bool());
    assert(!int_type.is_bool());
    assert(int_type.is_integral());
    assert(!double_type.is_integral());

    // Pointers know what they point to, other types don't.
    assert(int_type.get_pointer().get_pointee().toString() == "int");
    assert(!int_type.get_pointee());

    // Arrays know their element type, other types don't.
    assert(ctxt.new_array_type(int_type, 3).dyncast_array().toString() == "int");
    assert(!int_type.dyncast_array());

    // Qualifiers can be stripped back off again.
    assert(int_type.get_const().unqualified().toString() == "int");
    assert(int_type.get_volatile().unqualified().toString() == "int");

    // Only struct types are structs.
    auto field = ctxt.new_field(int_type, "i");
    auto agg = ctxt.new_struct_type("s", field);
    assert((cast(JIT.Type)agg).is_struct());
    assert(!int_type.is_struct());

    // Only function pointer types are function pointers.
    assert(ctxt.new_function_type(int_type, false).dyncast_function_ptr_type());
    assert(!int_type.dyncast_function_ptr_type());
}
