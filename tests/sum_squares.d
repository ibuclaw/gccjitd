
// This examples creates and runs the equivalent of this C function:

//  int loop_test (int n)
//  {
//      int i = 0;
//      int sum = 0;
//      while (i < n)
//      {
//          sum += i * i;
//          i++;
//      }
//      return sum;
//  }

module gccjitd.tests.sum_squares;

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

    // Build function
    JITParam param_n = ctxt.newParam(JITTypeKind.INT, "n");
    JITFunction fn = ctxt.newFunction(JITFunctionKind.EXPORTED,
                                      JITTypeKind.INT,
                                      "loop_test", false, param_n);

    // Build locals
    JITLValue local_i = fn.newLocal(ctxt.getType(JITTypeKind.INT), "i");
    JITLValue local_sum = fn.newLocal(ctxt.getType(JITTypeKind.INT), "sum");

    // This is what you get back from local_i.toString()
    assert(local_i.toString() == "i");

    // Build blocks
    JITBlock entry_block = fn.newBlock("entry");
    JITBlock cond_block = fn.newBlock("cond");
    JITBlock loop_block = fn.newBlock("loop");
    JITBlock after_loop_block = fn.newBlock("after_loop");

    // sum = 0
    entry_block.addAssignment(local_sum, ctxt.zero(JITTypeKind.INT));

    // i = 0
    entry_block.addAssignment(local_i, ctxt.zero(JITTypeKind.INT));

    entry_block.endWithJump(cond_block);

    // while (i < n)
    cond_block.endWithConditional(ctxt.newComparison(JITComparison.LT, local_i, param_n),
                                  loop_block, after_loop_block);

    // sum += i * i
    loop_block.addAssignmentOp(local_sum, JITBinaryOp.PLUS,
                               ctxt.newBinaryOp(JITBinaryOp.MULT,
                                                ctxt.getType(JITTypeKind.INT),
                                                local_i, local_i));

    // i++
    loop_block.addAssignmentOp(local_i, JITBinaryOp.PLUS, ctxt.one(JITTypeKind.INT));

    // goto cond_block
    loop_block.endWithJump(cond_block);

    // return sum
    after_loop_block.endWithReturn(local_sum);

    JITResult result = ctxt.compile();
    return result;
}

int loop_test(int n)
{
    JITResult result = create_fn();
    auto code = cast(int function(int))(result.getCode("loop_test"));
    return code(n);
}

void main()
{
    import std.stdio : writeln;
    writeln(loop_test(10));
}
