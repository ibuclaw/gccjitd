import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Field)JIT.Field()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Field()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Field()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Field)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Field()));
}

nothrow @nogc unittest
{
    // Fields are named and typed, and belong to a context.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto field = ctxt.new_field(CType.Int, "x");
    assert(field);
    assert(field.toString() == "x");
    assert(field.get_context() is ctxt);

    JIT.Object obj = field;
    assert(obj.toString() == field.toString());
    assert(obj.get_context() is ctxt);

    auto other = ctxt.new_field(ctxt.get_type(CType.Double), "y");
    assert(other.toString() == "y");

    if (JIT.Have_Context_new_bitfield)
    {
        auto bits = ctxt.new_bitfield(CType.UInt, 3, "bits");
        assert(bits);
        assert(bits.get_context() is ctxt);
    }
}
