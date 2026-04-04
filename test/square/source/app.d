
//  This examples creates and runs the equivalent of this C function:
//
//  int square(int i)
//  {
//      return i * i;
//  }

module gccjitd.test.square;

import gccjit;

JIT.CompileResult create_fn()
{
    // Create a compilation context
    JIT.Context ctxt = JIT.Context.acquire();

    // Turn these on to get various kinds of debugging
    version(none)
    {
        ctxt.set_option(BoolOption.DumpInitialTree, true);
        ctxt.set_option(BoolOption.DumpInitialGimple, true);
        ctxt.set_option(BoolOption.DumpGeneratedCode, true);
    }

    // Adjust this to control optimization level of the generated code
    version(none)
        ctxt.setOption(IntOption.OptimizationLevel, 3);

    // Create parameter "i"
    JIT.Parameter param_i = ctxt.new_param(CType.Int, "i");
    // Create the function
    JIT.Function fn = ctxt.new_function(FunctionType.Exported, CType.Int,
                                        "square", false, param_i);

    // Create a basic block within the function
    JIT.Block block = fn.new_block("entry");

    // This basic block is relatively simple
    block.end_with_return(ctxt.new_mult(ctxt.get_type(CType.Int),
                                        param_i, param_i));

    // Having populated the context, compile it
    JIT.CompileResult result = ctxt.compile();
    return result;
}

int square(int i)
{
    JIT.CompileResult result = create_fn();

    // Look up a specific machine code routine within the JIT.CompileResult,
    // in this case, the function we created above.
    void *void_ptr = result.get_code("square");

    // Now turn it into something we can call from D.
    auto code = cast(int function(int))(void_ptr);

    // Now try running the code
    return code(i);
}

void main()
{
    assert(square(5) == 25);
}
