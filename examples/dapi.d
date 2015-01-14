
// Sample client code for D API

module gccjitd.examples.dapi;

import gccjit.d;

void main()
{
    // Memory mangement is simple: all objects created are associated with a gcc_jit_context,
    // and get automatically cleaned up when the context is released.
    JITContext ctxt = new JITContext();

    // Let's inject the equivalent of:
    //  extern(C) int printf(in char *format, ...);
    //  void hello_fn(in char *name)
    //  {
    //      printf("hello %s\n", name);
    //  }
    // into the context.
    JITParam param_format = ctxt.newParam(JITTypeKind.CONST_CHAR_PTR, "format");
    JITFunction printf_func = ctxt.newFunction(JITFunctionKind.IMPORTED, JITTypeKind.INT,
                                               "printf", true, param_format);

    JITParam param_name = ctxt.newParam(JITTypeKind.CONST_CHAR_PTR, "name");
    JITFunction func = ctxt.newFunction(JITFunctionKind.EXPORTED, JITTypeKind.VOID,
                                        "hello_fn", false, param_name);

    JITBlock block = func.newBlock("initial");
    block.addEval(ctxt.newCall(printf_func, ctxt.newRValue("hello %s\n"), param_name));
    block.endWithReturn();

    // OK, we're done populating the context.
    // The next line actually calls into GCC and runs the build, all
    // in a mutex for now, getting make a result object.
    // The result is actually a wrapper around a DSO.
    JITResult result = ctxt.compile();
    ctxt.release();

    // Look up a generated function by name, getting a void* back
    // from the result object (pointing to the machine code), and
    // cast it to the appropriate type for the function:
    alias hello_fn_type = void function(in char *);
    auto hello_fn = cast(hello_fn_type) result.getCode("hello_fn");

    // We can now call the machine code:
    hello_fn("world");

    // Presumably we'd call it more than once.
    // Once we're done with the code, this unloads the built DSO:
    result.release();
}

