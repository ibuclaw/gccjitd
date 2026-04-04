
// Sample client code for D API

module gccjitd.test.dapi;

import gccjit;

void main()
{
    // Memory mangement is simple: all objects created are associated with a gcc_jit_context,
    // and get automatically cleaned up when the context is released.
    JIT.Context ctxt = JIT.Context.acquire();

    // Let's inject the equivalent of:
    //  extern(C) int printf(in char *format, ...);
    //  void hello_fn(in char *name)
    //  {
    //      printf("hello %s\n", name);
    //  }
    // into the context.
    JIT.Parameter param_format = ctxt.new_param(CType.ConstCharPtr, "format");
    JIT.Function printf_func = ctxt.new_function(FunctionType.Imported, CType.Int,
                                                 "printf", true, param_format);

    JIT.Parameter param_name = ctxt.new_param(CType.ConstCharPtr, "name");
    JIT.Function func = ctxt.new_function(FunctionType.Exported, CType.Void,
                                          "hello_fn", false, param_name);

    JIT.Block block = func.new_block("initial");
    block.add_eval(ctxt.new_call(printf_func, ctxt.new_rvalue("hello %s\n"), param_name));
    block.end_with_return();

    // OK, we're done populating the context.
    // The next line actually calls into GCC and runs the build, all
    // in a mutex for now, getting make a result object.
    // The result is actually a wrapper around a DSO.
    JIT.CompileResult result = ctxt.compile();
    ctxt.release();

    // Look up a generated function by name, getting a void* back
    // from the result object (pointing to the machine code), and
    // cast it to the appropriate type for the function:
    alias hello_fn_type = void function(in char *);
    auto hello_fn = cast(hello_fn_type) result.get_code("hello_fn");

    // We can now call the machine code:
    hello_fn("world");

    // Presumably we'd call it more than once.
    // Once we're done with the code, this unloads the built DSO:
    result.release();
}

