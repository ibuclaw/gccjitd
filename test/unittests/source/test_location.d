import gccjit;

nothrow @nogc unittest
{
    // No-op cast
    assert(__traits(compiles, cast(JIT.Location)JIT.Location()));
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.Location()));
    // Allow upcast
    assert(__traits(compiles, cast(JIT.Object)JIT.Location()));
    // Disallow downcast
    assert(!__traits(compiles, cast(JIT.Location)JIT.Object()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Context)JIT.Location()));
}

nothrow @nogc unittest
{
    // Check Context never changes when passing between types.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();
    auto loc = ctxt.new_location("test.d", 1, 1);
    JIT.Object o1 = loc;
    JIT.Object o2 = cast(JIT.Object)loc;

    assert(loc.get_context() is ctxt);
    assert(o1.get_context() is ctxt);
    assert(o2.get_context() is ctxt);

    // Likewise, toString is equal.
    assert(loc.toString() == o1.toString());
    assert(o1.toString() == o2.toString());
}

nothrow @nogc unittest
{
    // Locations are only attached when debug info is enabled.
    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    ctxt.set_debug_info(true);

    auto loc = ctxt.new_location("test.d", 42, 7);
    assert(loc);
    assert(loc.get_context() is ctxt);

    // A default constructed location has no value, and can be passed anywhere
    // a location is expected.
    auto none = JIT.Location();
    assert(!none);

    auto int_type = ctxt.get_type(CType.Int);
    auto param = ctxt.new_param(loc, int_type, "i");
    auto func = ctxt.new_function(loc, FunctionType.Exported, int_type, "located", false, param);
    auto block = func.new_block();
    auto local = func.new_local(loc, int_type, "tmp");

    block.add_assignment(loc, local, param);
    block.end_with_return(loc, local);

    auto result = ctxt.compile();
    scope(exit) result.release();

    auto code = cast(int function(int) nothrow @nogc)
        result.get_code!(int function(int))("located");
    assert(code !is null);
    assert(code(7) == 7);
}
