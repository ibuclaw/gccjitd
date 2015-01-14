
// Sample client code for C API

module gccjitd.examples.capi;

import gccjit.c;

void main()
{
    // Memory mangement is simple: all objects created are associated with a gcc_jit_context,
    // and get automatically cleaned up when the context is released.
    gcc_jit_context *ctxt = gcc_jit_context_acquire();

    // Let's inject the equivalent of:
    //  extern(C) int printf(in char *format, ...);
    //  void hello_fn(in char *name)
    //  {
    //      printf("hello %s\n", name);
    //  }
    // into the context.
    gcc_jit_type *const_char_ptr_type = gcc_jit_context_get_type(ctxt, GCC_JIT_TYPE_CONST_CHAR_PTR);
    gcc_jit_param *param_format =
        gcc_jit_context_new_param(ctxt, null, const_char_ptr_type, "format");
    gcc_jit_function *printf_func =
        gcc_jit_context_new_function(ctxt, null, GCC_JIT_FUNCTION_IMPORTED,
                                     gcc_jit_context_get_type(ctxt, GCC_JIT_TYPE_INT),
                                     "printf", 1, &param_format, 1);

    gcc_jit_param *param_name =
        gcc_jit_context_new_param(ctxt, null, const_char_ptr_type, "name");
    gcc_jit_function *func =
        gcc_jit_context_new_function(ctxt, null, GCC_JIT_FUNCTION_EXPORTED,
                                     gcc_jit_context_get_type(ctxt, GCC_JIT_TYPE_VOID),
                                     "hello_fn", 1, &param_name, 0);

    gcc_jit_rvalue *args[2];
    args[0] = gcc_jit_context_new_string_literal(ctxt, "hello %s\n");
    args[1] = gcc_jit_param_as_rvalue(param_name);

    gcc_jit_block *block = gcc_jit_function_new_block(func, "initial");
    gcc_jit_block_add_eval(block, null,
                           gcc_jit_context_new_call(ctxt, null, printf_func, 2, args.ptr));
    gcc_jit_block_end_with_void_return(block, null);

    // OK, we're done populating the context.
    // The next line actually calls into GCC and runs the build, all
    // in a mutex for now, getting make a result object.
    // The result is actually a wrapper around a DSO.
    gcc_jit_result *result = gcc_jit_context_compile(ctxt);

    // Now that we have result, we're done with ctxt.  Releasing it will
    // automatically clean up all of the objects created within it.
    gcc_jit_context_release(ctxt);

    // Look up a generated function by name, getting a void* back
    // from the result object (pointing to the machine code), and
    // cast it to the appropriate type for the function:
    alias hello_fn_type = void function(in char *);
    auto hello_fn = cast(hello_fn_type)gcc_jit_result_get_code(result, "hello_fn");

    // We can now call the machine code:
    hello_fn("world");

    // Presumably we'd call it more than once.
    // Once we're done with the code, this unloads the built DSO:
    gcc_jit_result_release(result);
}

