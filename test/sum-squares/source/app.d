
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

module gccjitd.test.sum_squares;

import gccjit;

JIT.CompileResult create_fn()
{
    // Create a compilation context
    JIT.Context ctxt = JIT.Context.acquire();

    // Turn these on to get various kinds of debugging
    version(none)
    {
        ctxt.set_dump_initial_tree = true;
        ctxt.set_dump_initial_gimple = true;
        ctxt.set_dump_generated_code = true;
    }

    // Adjust this to control optimization level of the generated code
    version(none)
        ctxt.set_optimization_level = OptimizationLevel.Aggressive;

    // Build function
    JIT.Parameter param_n = ctxt.new_param(CType.Int, "n");
    JIT.Function fn = ctxt.new_function(FunctionType.Exported, CType.Int,
                                        "loop_test", false, param_n);

    // Build locals
    JIT.LValue local_i = fn.new_local(ctxt.get_type(CType.Int), "i");
    JIT.LValue local_sum = fn.new_local(ctxt.get_type(CType.Int), "sum");

    // This is what you get back from local_i.toString()
    assert(local_i.toString() == "i");

    // Build blocks
    JIT.Block entry_block = fn.new_block("entry");
    JIT.Block cond_block = fn.new_block("cond");
    JIT.Block loop_block = fn.new_block("loop");
    JIT.Block after_loop_block = fn.new_block("after_loop");

    // sum = 0
    entry_block.add_assignment(local_sum, ctxt.new_rvalue_zero(CType.Int));

    // i = 0
    entry_block.add_assignment(local_i, ctxt.new_rvalue_zero(CType.Int));

    entry_block.end_with_jump(cond_block);

    // while (i < n)
    cond_block.end_with_conditional(ctxt.new_lt(local_i, param_n),
                                    loop_block, after_loop_block);

    // sum += i * i
    loop_block.add_assignment_op(local_sum, BinaryOp.Plus,
                                 ctxt.new_mult(ctxt.get_type(CType.Int),
                                               local_i, local_i));

    // i++
    loop_block.add_assignment_op(local_i, BinaryOp.Plus, ctxt.new_rvalue_one(CType.Int));

    // goto cond_block
    loop_block.end_with_jump(cond_block);

    // return sum
    after_loop_block.end_with_return(local_sum);

    JIT.CompileResult result = ctxt.compile();
    return result;
}

int loop_test(int n)
{
    JIT.CompileResult result = create_fn();
    auto code = cast(int function(int))(result.get_code("loop_test"));
    return code(n);
}

void main()
{
    assert(loop_test(10) == 285);
}
