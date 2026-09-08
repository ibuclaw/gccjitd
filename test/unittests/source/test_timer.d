import gccjit;

nothrow @nogc unittest
{
    // Timers record the time spent in each named item pushed onto them.
    import core.stdc.stdio : fopen, fclose, fgetc, remove;

    if (!JIT.Have_Timing_API)
        return;

    // The underlying timer is created on demand, so a default constructed
    // timer is as usable as one that starts timing straight away.
    auto timer = JIT.Timer(true);
    auto lazy_timer = JIT.Timer(false);

    timer.push!"phase"();
    timer.pop!"phase"();

    // A scoped timer pushes and pops the named item for you.
    {
        auto scoped = JIT.AutoTime!"scoped"(lazy_timer);
    }

    auto file = fopen("test_timer_report.txt", "w+b");
    assert(file !is null);
    timer.print(file);
    fclose(file);

    file = fopen("test_timer_report.txt", "rb");
    assert(file !is null);
    assert(fgetc(file) != -1);
    fclose(file);
    remove("test_timer_report.txt");

    timer.release();
    lazy_timer.release();
}

nothrow @nogc unittest
{
    // A context has its own timer, which can also be replaced.
    if (!JIT.Have_Timing_API)
        return;

    auto ctxt = JIT.Context.acquire();
    scope(exit) ctxt.release();

    auto timer = JIT.Timer(true);
    ctxt.timer = timer;

    // The scoped timer of a context times against the context's own timer.
    {
        auto scoped = JIT.AutoTime!"compile"(ctxt);
        ctxt.compile().release();
    }
}
