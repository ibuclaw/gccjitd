/**
  This examples creates and runs the equivalent of this C function:

    int square(int i)
    {
        return i * i;
    }
 */

module square;

import gccjit.d;

JITResult create_fn()
{
    // Create a compilation context
    JITContext ctxt = new JITContext();

    // Turn these on to get various kinds of debugging
    version(none)
    {
        ctxt.setOption(JITBoolOption.DUMP_INITIAL_TREE, true);
        ctxt.setOption(JITBoolOption.DUMP_INITIAL_GIMPLE, true);
        ctxt.setOption(JITBoolOption.DUMP_GENERATED_CODE, true);
    }

    // Adjust this to control optimization level of the generated code
    version(none)
        ctxt.setOption(JITIntOption.OPTIMIZATION_LEVEL, 3);

    JITType int_type = ctxt.getType(JITTypeKind.INT);

    // Create parameter "i"
    JITParam param_i = ctxt.newParam(int_type, "i");
    // Create the function
    JITFunction fn = ctxt.newFunction(JITFunctionKind.EXPORTED, int_type,
                                      "square", false, param_i);

    // Create a basic block within the function
    JITBlock block = fn.newBlock("entry");

    // This basic block is relatively simple
    block.endWithReturn(ctxt.newBinaryOp(JITBinaryOp.MULT, int_type,
                                         param_i, param_i));

    // Having populated the context, compile it
    JITResult result = ctxt.compile();
    return result;
}

int square(int i)
{
    JITResult result = create_fn();

    // Look up a specific machine code routine within the JITResult,
    // in this case, the function we created above.
    void *void_ptr = result.getCode("square");

    // Now turn it into something we can call from D.
    auto code = cast(int function(int))(void_ptr);

    // Now try running the code
    return code(i);
}

void main()
{
    import std.stdio : writeln;
    writeln(square(5));
}
