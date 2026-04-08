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
