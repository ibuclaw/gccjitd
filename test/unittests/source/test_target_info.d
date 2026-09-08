import gccjit;

unittest
{
    // Bool cast
    assert(__traits(compiles, cast(bool)JIT.TargetInfo()));
    // Disallow cast to unrelated object
    assert(!__traits(compiles, cast(JIT.Object)JIT.TargetInfo()));
    assert(!__traits(compiles, cast(JIT.TargetInfo)JIT.Object()));

    // A default constructed target info has no value.
    assert(!JIT.TargetInfo());
}

unittest
{
    // Query the target the library generates code for.
    if (!JIT.Have_TargetInfo_API)
        return;

    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto info = ctxt.get_target_info();
    assert(info);

    assert(info.arch().length != 0);

    // An unknown feature is never supported.
    assert(!info.cpu_supports("__gccjitd_not_a_cpu_feature"));

    version (X86_64)
    {
        assert(info.arch() == "x86_64");
        assert(info.cpu_supports("sse2"));
    }

    info.release();
    assert(!info);
}
