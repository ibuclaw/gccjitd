import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.RValue)JIT.RValue()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.RValue()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.RValue()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.RValue)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Type)JIT.RValue()));
}

nothrow @nogc unittest
{
    // Operators on rvalues build the equivalent expression.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto a = ctxt.new_rvalue(int_type, 2);
    auto b = ctxt.new_rvalue(int_type, 3);

    assert((-a).toString() == "-((int)2)");
    assert((~a).toString() == "~((int)2)");

    assert((a + b).toString() == "(int)2 + (int)3");
    assert((a - b).toString() == "(int)2 - (int)3");
    assert((a * b).toString() == "(int)2 * (int)3");
    assert((a / b).toString() == "(int)2 / (int)3");
    assert((a % b).toString() == "(int)2 % (int)3");
    assert((a & b).toString() == "(int)2 & (int)3");
    assert((a ^ b).toString() == "(int)2 ^ (int)3");
    assert((a | b).toString() == "(int)2 | (int)3");
    assert((a << b).toString() == "(int)2 << (int)3");
    assert((a >> b).toString() == "(int)2 >> (int)3");

    // Expressions keep the type of their operands.
    assert((a + b).get_type().toString() == "int");
    assert((a + b).get_context() is ctxt);
}

nothrow @nogc unittest
{
    // Casts, dereferences and array accesses.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto value = ctxt.new_rvalue(int_type, 2);

    assert(value.cast_to(CType.Double).get_type().toString() == "double");
    assert(value.cast_to(ctxt.get_type(CType.Long)).get_type().toString() == "long");

    // Dereferencing a pointer gives back an lvalue of the pointee type.
    auto ptr = ctxt.new_global(GlobalKind.Imported, int_type.get_pointer(), "ptr");
    JIT.RValue rvalue = ptr;
    assert((*rvalue).get_type().toString() == "int");
    assert(rvalue.dereference().toString() == "*ptr");

    // Indexing an array gives back an lvalue of the element type.
    auto array = ctxt.new_global(GlobalKind.Imported, ctxt.new_array_type(int_type, 4), "arr");
    JIT.RValue array_rvalue = array;
    assert(array_rvalue[1].toString() == "arr[(int)1]");
    assert(array_rvalue[value].toString() == "arr[(int)2]");
    assert(array_rvalue[1].get_type().toString() == "int");
}

nothrow @nogc unittest
{
    // Field accesses, both direct and through a pointer.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto int_type = ctxt.get_type(CType.Int);
    auto x = ctxt.new_field(int_type, "x");
    auto point = cast(JIT.Type)ctxt.new_struct_type("point", x);

    auto value = ctxt.new_global(GlobalKind.Imported, point, "origin");
    JIT.RValue rvalue = value;
    assert(rvalue.access_field(x).toString() == "origin.x");
    assert(rvalue.access_field(x).get_type().toString() == "int");
    assert(value.access_field(x).toString() == "origin.x");

    auto ptr = ctxt.new_global(GlobalKind.Imported, point.get_pointer(), "pptr");
    JIT.RValue ptr_rvalue = ptr;
    assert(ptr_rvalue.dereference_field(x).toString() == "pptr->x");
}

nothrow @nogc unittest
{
    // Calls can be marked as requiring a tail call.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    if (!JIT.Have_RValue_set_require_tail_call)
        return;

    auto int_type = ctxt.get_type(CType.Int);
    auto func = ctxt.new_function(FunctionType.Imported, int_type, "callee", false);
    auto call = ctxt.new_call(func);

    assert(call.set_require_tail_call(true).toString() == call.toString());
}
