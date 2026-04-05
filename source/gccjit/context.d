/// A D API for libgccjit, purely as struct wrapper functions.
/// Copyright (C) 2014-2026 Iain Buclaw.

/// This file is part of gccjitd.

/// This program is free software: you can redistribute it and/or modify
/// it under the terms of the GNU General Public License as published by
/// the Free Software Foundation, either version 3 of the License, or
/// (at your option) any later version.

/// This program is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU General Public License for more details.

/// You should have received a copy of the GNU General Public License
/// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module gccjit.context;

import gccjit.bindings;
import gccjit.block;
import gccjit.compile;
import gccjit.decls;
import gccjit.exception;
import gccjit.flags;
import gccjit.helpers;
import gccjit.location;
import gccjit.timer;
import gccjit.types;
import gccjit.values;

import core.stdc.stdio : FILE;
import core.stdc.config : c_long;

/// The top-level of the API is the JIT.Context class.

/// A JIT.Context instance encapsulates the state of a compilation.
/// It goes through two states.
/// Initial:
///     During which you can set up options on it, and add types,
///     functions and code, using the API below. Invoking compile
///     on it transitions it to the PostCompilation state.
/// PostCompilation:
///     When you can call JIT.Context.release to clean it up.
struct Context
{
    ///
    this(gcc_jit_context* context) @nogc
    {
        if (!context)
            throw staticException!JitException("Unknown error, got bad context");
        __impl = context;
    }

    /// Acquire a JIT-compilation context.
    static Context acquire() @nogc
    {
        return Context(gcc_jit_context_acquire());
    }

    /// Create a new child context of the given JIT.Context, inheriting a copy
    /// of all option settings from the parent.
    /// The returned JIT.Context can reference objects created within the
    /// parent, but not vice-versa.  The lifetime of the child context must be
    /// bounded by that of the parent. You should release a child context
    /// before releasing the parent context.
    Context new_child_context() @nogc
    {
        auto result = gcc_jit_context_new_child_context(__impl);
        if (!result)
            throw staticException!JitException("Unknown error creating child context");
        return Context(result);
    }

    /// Returns the internal gcc_jit_context object.
    gcc_jit_context* get_context() nothrow @nogc
    {
        return __impl;
    }

    /// Release the context.
    /// After this call, it's no longer valid to use this JIT.Context.
    void release() nothrow @nogc
    {
        gcc_jit_context_release(__impl);
        __impl = null;
    }

    /// Calls into GCC and runs the build.  It can be called more than once on
    /// a given context.
    /// Returns:
    ///     A wrapper around a .so file.
    CompileResult compile() @nogc
    {
        auto result = gcc_jit_context_compile(__impl);
        if (!result)
            throw staticException!JitException(get_first_error());
        return CompileResult(result);
    }

    /// Ditto
    /// Params:
    ///     kind = What of output file to write.
    ///     path = Location of file to write to.
    void compile(OutputKind kind, string path) nothrow @nogc
    {
        path.toCStringThen!((p)
            => gcc_jit_context_compile_to_file(__impl, kind, p.ptr));
    }

    /// Dump a C-like representation describing what's been set up on the
    /// context to file.
    /// Params:
    ///     path             = Location of file to write to.
    ///     update_locations = If true, then also write JIT.Location information.
    void dump_to_file(string path, bool update_locations) nothrow @nogc
    {
        path.toCStringThen!((p)
            => gcc_jit_context_dump_to_file(__impl, p.ptr, update_locations));
    }

    ///
    void set_logfile(FILE* logfile, int flags, int verbosity) nothrow @nogc
    {
        gcc_jit_context_set_logfile(__impl, logfile, flags, verbosity);
    }

    ///
    void dump_reproducer(string path) nothrow @nogc
    {
        path.toCStringThen!((p)
            => gcc_jit_context_dump_reproducer_to_file(__impl, p.ptr));
    }

    deprecated("Use per option entrypoints rather than generic set_option")
    void set_option(StrOption opt, string value) nothrow @nogc
    {
        value.toCStringThen!((v)
            => gcc_jit_context_set_str_option(__impl, opt, v.ptr));
    }

    deprecated("Use per option entrypoints rather than generic set_option")
    void set_option(IntOption opt, int value) nothrow @nogc
    {
        gcc_jit_context_set_int_option(__impl, opt, value);
    }

    deprecated("Use per option entrypoints rather than generic set_option")
    void set_option(BoolOption opt, bool value) nothrow @nogc
    {
        gcc_jit_context_set_bool_option(__impl, opt, value);
    }

    /// Sets the name of the program, for use as a prefix when printing error
    /// messages to stderr. If null, or default, "libgccjit.so" is used.
    void set_program_name(string name) nothrow @nogc @property
    {
        name.toCStringThen!((n)
            => gcc_jit_context_set_str_option(__impl, GCC_JIT_STR_OPTION_PROGNAME, n.ptr));
    }

    /// How much to optimize the code.
    /// Valid values are 0-3, corresponding to GCC's command-line options
    /// -O0 through -O3.
    /// The default value is 0 (unoptimized).
    void set_optimization_level(OptimizationLevel level) nothrow @nogc @property
    { gcc_jit_context_set_int_option(__impl, GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL, level); }

    /// If true, JIT.Context.compile() will attempt to do the right thing
    /// so that if you attach a debugger to the process, it will be able
    /// to inspect variables and step through your code.
    /// Note that you can’t step through code unless you set up source
    /// location information for the code (by creating and passing in
    /// JIT.Location instances).
    void set_debug_info(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DEBUGINFO, value); }

    /// If true, JIT.Context.compile() will dump its initial "tree"
    /// representation of your code to stderr, before any optimizations.
    void set_dump_initial_tree(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE, value); }

    /// If true, JIT.Context.compile() will dump its initial "gimple"
    /// representation of your code to stderr, before any optimizations
    /// are performed. The dump resembles C code.
    void set_dump_initial_gimple(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE, value); }

    /// If true, JIT.Context.compile() will dump the final generated code
    /// to stderr, in the form of assembly language.
    void set_dump_generated_code(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE, value); }

    /// If true, JIT.Context.compile() will print information to stderr
    /// on the actions it is performing, followed by a profile showing
    /// the time taken and memory usage of each phase.
    void set_dump_summary(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DUMP_SUMMARY, value); }

    /// If true, JIT.Context.compile() will dump copious amounts of
    /// information on what it’s doing to various files within a
    /// temporary directory. Use `set_keep_intermediates` to see the
    /// results. The files are intended to be human-readable, but the
    /// exact files and their formats are subject to change.
    void set_dump_everything(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING, value); }

    /// If true, libgccjit will aggressively run its garbage collector,
    /// to shake out bugs (greatly slowing down the compile). This is
    /// likely to only be of interest to developers of the library.
    void set_selfcheck_gc(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_SELFCHECK_GC, value); }

    /// If true, the JIT.Context will not clean up intermediate files
    /// written to the filesystem, and will display their location on
    /// stderr.
    void set_keep_intermediates(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_option(__impl, GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES, value); }

    /// Controls whether libgccjit will issue an error about unreachable blocks
    /// within a function.
    void set_allow_unreachable_blocks(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_allow_unreachable_blocks(__impl, value); }

    /// Controls whether libgccjit will use an external executable for
    /// converting its generated assembler into other formats.
    void set_use_external_driver(bool value) nothrow @nogc @property
    { gcc_jit_context_set_bool_use_external_driver(__impl, value); }

    /// Add an arbitrary gcc command-line option to the context.
    void add_command_line_option(string optname) nothrow @nogc
    {
        optname.toCStringThen!((opt)
            => gcc_jit_context_add_command_line_option(__impl, opt.ptr));
    }

    /// Associate a gcc_jit_timer instance with a context.
    void timer(Timer t) nothrow @nogc @property
    {
        gcc_jit_context_set_timer(__impl, t.get_timer());
    }

    /// Get the timer associated with a context (if any).
    Timer timer() nothrow @nogc
    {
        auto result = gcc_jit_context_get_timer(__impl);
        return Timer(result);
    }

    /// Returns:
    ///     The first error message that occurred when compiling the context.
    string get_first_error() nothrow @nogc
    {
        return gcc_jit_context_get_first_error(__impl).toDString();
    }

    /// Make a JIT.Location representing a source location,
    /// for use by the debugger.
    /// Note:
    ///     You need to enable `set_debug_info` on the context for
    ///     these locations to actually be usable by the debugger.
    Location new_location(string filename, int line, int column) @nogc
    {
        auto result = filename.toCStringThen!((f)
            => gcc_jit_context_new_location(__impl, f.ptr, line, column));
        return Location(result);
    }

    /// Build a JIT.Type from one of the types in CType.
    Type get_type(CType kind) @nogc
    {
        auto result = gcc_jit_context_get_type(__impl, kind);
        return Type(result);
    }

    /// Build an integer type of a given size and signedness.
    Type get_int_type(int num_bytes, bool is_signed) @nogc
    {
        auto result = gcc_jit_context_get_int_type(__impl, num_bytes, is_signed);
        return Type(result);
    }

    /// A way to map a specific int type, using the compiler to
    /// get the details automatically e.g:
    ///     JIT.Type type = get_int_type!size_t();
    Type get_int_type(T)() @nogc
        if (__traits(isIntegral, T))
    {
        enum is_signed = __traits(isArithmetic, T) && !__traits(isUnsigned, T)
                                                   && is(T : real);
        return get_int_type(T.sizeof, is_signed);
    }

    /// Given type "T", build a new array type of "T[N]".
    Type new_array_type(Location loc, Type type, int dims) @nogc
    {
        auto result = gcc_jit_context_new_array_type(__impl, loc.get_location(),
                                                     type.get_type(), dims);
        return Type(result);
    }

    /// Ditto
    Type new_array_type(Type type, int dims) @nogc
    { return new_array_type(Location(), type, dims); }

    /// Ditto
    Type new_array_type(Location loc, CType kind, int dims) @nogc
    { return new_array_type(loc, get_type(kind), dims); }

    /// Ditto
    Type new_array_type(CType kind, int dims) @nogc
    { return new_array_type(Location(), get_type(kind), dims); }

    /// Create a field, for use within a struct or union.
    Field new_field(Location loc, Type type, string name) @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_field(__impl, loc.get_location(),
                                         type.get_type(), n.ptr));
        return Field(result);
    }

    /// Ditto
    Field new_field(Type type, string name) @nogc
    { return new_field(Location(), type, name); }

    /// Ditto
    Field new_field(Location loc, CType kind, string name) @nogc
    { return new_field(loc, get_type(kind), name); }

    /// Ditto
    Field new_field(CType kind, string name) @nogc
    { return new_field(Location(), get_type(kind), name); }

    /// Create a struct type from an array of fields.
    Struct new_struct_type(Location loc, string name, scope Field[] fields...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_struct_type(__impl, loc.get_location(), n.ptr,
                                               cast(int)fields.length,
                                               cast(gcc_jit_field**)fields.ptr));
        return Struct(result);
    }

    /// Ditto
    Struct new_struct_type(string name, scope Field[] fields...) @nogc
    { return new_struct_type(Location(), name, fields); }

    /// Create an opaque struct type.
    Struct new_opaque_struct_type(Location loc, string name) @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_opaque_struct(__impl, loc.get_location(), n.ptr));
        return Struct(result);
    }

    /// Ditto
    Struct new_opaque_struct_type(string name) @nogc
    { return new_opaque_struct_type(Location(), name); }

    /// Create a union type from an array of fields.
    Type new_union_type(Location loc, string name, scope Field[] fields...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_union_type(__impl, loc.get_location(), n.ptr,
                                              cast(int)fields.length,
                                              cast(gcc_jit_field**)fields.ptr));
        return Type(result);
    }

    /// Ditto
    Type new_union_type(string name, scope Field[] fields...) @nogc
    { return new_union_type(Location(), name, fields); }

    /// Create a function type.
    Type new_function_type(Location loc, Type return_type,
                           bool is_variadic, scope Type[] param_types...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_function_ptr_type(__impl, loc.get_location(),
                                                            return_type.get_type(),
                                                            cast(int)param_types.length,
                                                            cast(gcc_jit_type**)param_types.ptr,
                                                            is_variadic);
        return Type(result);
    }

    /// Ditto
    Type new_function_type(Type return_type, bool is_variadic,
                           scope Type[] param_types...) @nogc
    { return new_function_type(Location(), return_type, is_variadic, param_types); }

    /// Ditto
    Type new_function_type(Location loc, CType return_kind,
                           bool is_variadic, scope Type[] param_types...) @nogc
    { return new_function_type(loc, get_type(return_kind), is_variadic, param_types); }

    /// Ditto
    Type new_function_type(CType return_kind, bool is_variadic,
                           scope Type[] param_types...) @nogc
    { return new_function_type(Location(), get_type(return_kind), is_variadic, param_types); }

    /// Create a function parameter.
    Parameter new_param(Location loc, Type type, string name) @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_param(__impl, loc.get_location(),
                                         type.get_type(), n.ptr));
        return Parameter(result);
    }

    /// Ditto
    Parameter new_param(Type type, string name) @nogc
    { return new_param(Location(), type, name); }

    /// Ditto
    Parameter new_param(Location loc, CType kind, string name) @nogc
    { return new_param(loc, get_type(kind), name); }

    /// Ditto
    Parameter new_param(CType kind, string name) @nogc
    { return new_param(Location(), get_type(kind), name); }

    /// Create a function.
    Function new_function(Location loc, FunctionType kind, Type return_type,
                          string name, bool is_variadic, scope Parameter[] params...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_function(__impl, loc.get_location(),
                                            kind, return_type.get_type(), n.ptr,
                                            cast(int)params.length,
                                            cast(gcc_jit_param**)params.ptr,
                                            is_variadic));
        return Function(result);
    }

    /// Ditto
    Function new_function(FunctionType kind, Type return_type,
                          string name, bool is_variadic, scope Parameter[] params...) @nogc
    { return new_function(Location(), kind, return_type, name, is_variadic, params); }

    /// Ditto
    Function new_function(Location loc, FunctionType kind, CType return_kind,
                          string name, bool is_variadic, scope Parameter[] params...) @nogc
    { return new_function(loc, kind, get_type(return_kind), name, is_variadic, params); }

    /// Ditto
    Function new_function(FunctionType kind, CType return_kind,
                          string name, bool is_variadic, scope Parameter[] params...) @nogc
    { return new_function(Location(), kind, get_type(return_kind), name, is_variadic, params); }

    /// Create a reference to a GCC builtin function.
    Function get_builtin_function(string name) @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_get_builtin_function(__impl, n.ptr));
        return Function(result);
    }

    ///
    LValue new_global(Location loc, GlobalKind global_kind, Type type, string name) @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_context_new_global(__impl, loc.get_location(),
                                          global_kind, type.get_type(), n.ptr));
        return LValue(result);
    }

    /// Ditto
    LValue new_global(GlobalKind global_kind, Type type, string name) @nogc
    { return new_global(Location(), global_kind, type, name); }

    /// Ditto
    LValue new_global(Location loc, GlobalKind global_kind, CType kind, string name) @nogc
    { return new_global(loc, global_kind, get_type(kind), name); }

    /// Ditto
    LValue new_global(GlobalKind global_kind, CType kind, string name) @nogc
    { return new_global(Location(), global_kind, get_type(kind), name); }

    /// Given a JIT.Type, which must be a numeric type, get an integer constant
    /// as a JIT.RValue of that type.
    RValue new_rvalue(Type type, int value) @nogc
    {
        auto result = gcc_jit_context_new_rvalue_from_int(__impl, type.get_type(), value);
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue(CType kind, int value) @nogc
    { return new_rvalue(get_type(kind), value); }

    /// Ditto
    RValue new_rvalue(Type type, long value) @nogc
    {
        auto result = gcc_jit_context_new_rvalue_from_long(__impl, type.get_type(),
                                                           cast(c_long)value);
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue(CType kind, long value) @nogc
    { return new_rvalue(get_type(kind), value); }

    /// Given a JIT.Type, which must be a floating point type, get a floating
    /// point constant as a JIT.RValue of that type.
    RValue new_rvalue(Type type, double value) @nogc
    {
        auto result = gcc_jit_context_new_rvalue_from_double(__impl, type.get_type(), value);
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue(CType kind, double value) @nogc
    { return new_rvalue(get_type(kind), value); }

    /// Given a JIT.Type, which must be a pointer type, and an address, get a
    /// JIT.RValue representing that address as a pointer of that type.
    RValue new_rvalue(Type type, void* value) @nogc
    {
        auto result = gcc_jit_context_new_rvalue_from_ptr(__impl, type.get_type(), value);
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue(CType kind, void* value) @nogc
    { return new_rvalue(get_type(kind), value); }

    /// Make a JIT.RValue for the given string literal value.
    /// Params:
    ///     value = The string literal.
    RValue new_rvalue(string value) @nogc
    {
        auto result = value.toCStringThen!((v)
            => gcc_jit_context_new_string_literal(__impl, v.ptr));
        return RValue(result);
    }

    /// Given a JIT.Type, which must be a vector type, build a vector rvalue
    /// from an array of JIT.RValue elements.
    RValue new_rvalue(Type vector_type, scope RValue[] elements...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_rvalue_from_vector(__impl, null,
                                                             vector_type.get_type(),
                                                             cast(int)elements.length,
                                                             cast(gcc_jit_rvalue**)elements.ptr);
        return RValue(result);
    }

    /// Given a JIT.Type, which must be a numeric type, get the constant 0 as a
    /// JIT.RValue of that type.
    RValue new_rvalue_zero(Type type) @nogc
    {
        auto result = gcc_jit_context_zero(__impl, type.get_type());
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue_zero(CType kind) @nogc
    { return new_rvalue_zero(get_type(kind)); }

    /// Given a JIT.Type, which must be a numeric type, get the constant 1 as a
    /// JIT.RValue of that type.
    RValue new_rvalue_one(Type type) @nogc
    {
        auto result = gcc_jit_context_one(__impl, type.get_type());
        return RValue(result);
    }

    /// Ditto
    RValue new_rvalue_one(CType kind) @nogc
    { return new_rvalue_one(get_type(kind)); }

    /// Given a JIT.Type, which must be a pointer type, get a JIT.RValue
    /// representing the NULL pointer of that type.
    RValue new_null(Type type) @nogc
    {
        auto result = gcc_jit_context_null(__impl, type.get_type());
        return RValue(result);
    }

    /// Ditto
    RValue new_null(CType kind) @nogc
    { return new_null(get_type(kind)); }

    deprecated("Use new_rvalue_zero instead")
    RValue zero(Type type) @nogc
    { return new_rvalue_zero(type); }

    deprecated("Use new_rvalue_zero instead")
    RValue zero(CType kind) @nogc
    { return new_rvalue_zero(kind); }

    deprecated("Use new_rvalue_one instead")
    RValue one(Type type) @nogc
    { return new_rvalue_one(type); }

    deprecated("Use new_rvalue_one instead")
    RValue one(CType kind) @nogc
    { return new_rvalue_one(kind); }

    deprecated("Use new_null instead")
    RValue nil(Type type) @nogc
    { return new_null(type); }

    deprecated("Use new_null instead")
    RValue nil(CType kind) @nogc
    { return new_null(kind); }

    /// Generic unary operations.

    /// Make a JIT.RValue for the given unary operation.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which unary operation.
    ///     type = The type of the result.
    ///     a    = The input expression.
    RValue new_unary_op(Location loc, UnaryOp op, Type type, RValue a) @nogc
    {
        auto result = gcc_jit_context_new_unary_op(__impl, loc.get_location(),
                                                   op, type.get_type(),
                                                   a.get_rvalue());
        return RValue(result);
    }

    /// Ditto
    RValue new_unary_op(UnaryOp op, Type type, RValue a) @nogc
    { return new_unary_op(Location(), op, type, a); }

    /// Shorter ways to spell the various specific kinds of unary operation.

    ///
    RValue new_minus(Location loc, Type type, RValue a) @nogc
    { return new_unary_op(loc, UnaryOp.Minus, type, a); }

    /// Ditto
    RValue new_minus(Type type, RValue a) @nogc
    { return new_unary_op(Location(), UnaryOp.Minus, type, a); }

    ///
    RValue new_bitwise_negate(Location loc, Type type, RValue a) @nogc
    { return new_unary_op(loc, UnaryOp.BitwiseNegate, type, a); }

    /// Ditto
    RValue new_bitwise_negate(Type type, RValue a) @nogc
    { return new_unary_op(Location(), UnaryOp.BitwiseNegate, type, a); }

    ///
    RValue new_logical_negate(Location loc, Type type, RValue a) @nogc
    { return new_unary_op(loc, UnaryOp.LogicalNegate, type, a); }

    /// Ditto
    RValue new_logical_negate(Type type, RValue a) @nogc
    { return new_unary_op(Location(), UnaryOp.LogicalNegate, type, a); }

    /// Generic binary operations.

    /// Make a JIT.RValue for the given binary operation.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which binary operation.
    ///     type = The type of the result.
    ///     a    = The first input expression.
    ///     b    = The second input expression.
    RValue new_binary_op(Location loc, BinaryOp op, Type type, RValue a, RValue b) @nogc
    {
        auto result = gcc_jit_context_new_binary_op(__impl, loc.get_location(),
                                                    op, type.get_type(),
                                                    a.get_rvalue(),
                                                    b.get_rvalue());
        return RValue(result);
    }

    /// Ditto
    RValue new_binary_op(BinaryOp op, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), op, type, a, b); }

    /// Shorter ways to spell the various specific kinds of binary operation.

    ///
    RValue new_plus(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.Plus, type, a, b); }

    /// Ditto
    RValue new_plus(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.Plus, type, a, b); }

    ///
    RValue new_minus(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.Minus, type, a, b); }

    /// Ditto
    RValue new_minus(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.Minus, type, a, b); }

    ///
    RValue new_mult(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.Mult, type, a, b); }

    /// Ditto
    RValue new_mult(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.Mult, type, a, b); }

    ///
    RValue new_divide(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.Divide, type, a, b); }

    /// Ditto
    RValue new_divide(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.Divide, type, a, b); }

    ///
    RValue new_modulo(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.Modulo, type, a, b); }

    /// Ditto
    RValue new_modulo(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.Modulo, type, a, b); }

    ///
    RValue new_bitwise_and(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.BitwiseAnd, type, a, b); }

    /// Ditto
    RValue new_bitwise_and(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.BitwiseAnd, type, a, b); }

    ///
    RValue new_bitwise_xor(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.BitwiseXor, type, a, b); }

    /// Ditto
    RValue new_bitwise_xor(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.BitwiseXor, type, a, b); }

    ///
    RValue new_bitwise_or(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.BitwiseOr, type, a, b); }

    /// Ditto
    RValue new_bitwise_or(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.BitwiseOr, type, a, b); }

    ///
    RValue new_logical_and(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.LogicalAnd, type, a, b); }

    /// Ditto
    RValue new_logical_and(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.LogicalAnd, type, a, b); }

    ///
    RValue new_logical_or(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.LogicalOr, type, a, b); }

    /// Ditto
    RValue new_logical_or(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.LogicalOr, type, a, b); }

    ///
    RValue new_lshift(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.LShift, type, a, b); }

    /// Ditto
    RValue new_lshift(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.LShift, type, a, b); }

    ///
    RValue new_rshift(Location loc, Type type, RValue a, RValue b) @nogc
    { return new_binary_op(loc, BinaryOp.RShift, type, a, b); }

    /// Ditto
    RValue new_rshift(Type type, RValue a, RValue b) @nogc
    { return new_binary_op(Location(), BinaryOp.RShift, type, a, b); }

    /// Generic comparisons.

    /// Make a JIT.RValue of boolean type for the given comparison.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which comparison.
    ///     a    = The first input expression.
    ///     b    = The second input expression.
    RValue new_comparison(Location loc, ComparisonOp op, RValue a, RValue b) @nogc
    {
        auto result = gcc_jit_context_new_comparison(__impl, loc.get_location(),
                                                     op, a.get_rvalue(),
                                                     b.get_rvalue());
        return RValue(result);
    }

    /// Ditto
    RValue new_comparison(ComparisonOp op, RValue a, RValue b) @nogc
    { return new_comparison(Location(), op, a, b); }

    /// Shorter ways to spell the various specific kinds of comparison.

    ///
    RValue new_eq(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.Equals, a, b); }

    /// Ditto
    RValue new_eq(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.Equals, a, b); }

    ///
    RValue new_ne(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.NotEquals, a, b); }

    /// Ditto
    RValue new_ne(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.NotEquals, a, b); }

    ///
    RValue new_lt(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.LessThan, a, b); }

    /// Ditto
    RValue new_lt(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.LessThan, a, b); }

    ///
    RValue new_le(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.LessThanEquals, a, b); }

    /// Ditto
    RValue new_le(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.LessThanEquals, a, b); }

    ///
    RValue new_gt(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.GreaterThan, a, b); }

    /// Ditto
    RValue new_gt(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.GreaterThan, a, b); }

    ///
    RValue new_ge(Location loc, RValue a, RValue b) @nogc
    { return new_comparison(loc, ComparisonOp.GreaterThanEquals, a, b); }

    /// Ditto
    RValue new_ge(RValue a, RValue b) @nogc
    { return new_comparison(Location(), ComparisonOp.GreaterThanEquals, a, b); }

    /// The most general way of creating a function call.
    RValue new_call(Location loc, Function func, scope RValue[] args...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_call(__impl, loc.get_location(),
                                               func.get_function(),
                                               cast(int)args.length,
                                               cast(gcc_jit_rvalue**)args.ptr);
        return RValue(result);
    }

    /// Ditto
    RValue new_call(Function func, scope RValue[] args...) @nogc
    { return new_call(Location(), func, args); }

    /// Calling a function through a pointer.
    RValue new_call(Location loc, RValue ptr, scope RValue[] args...) @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_call_through_ptr(__impl, loc.get_location(),
                                                           ptr.get_rvalue(),
                                                           cast(int)args.length,
                                                           cast(gcc_jit_rvalue**)args.ptr);
        return RValue(result);
    }

    /// Ditto
    RValue new_call(RValue ptr, scope RValue[] args...) @nogc
    { return new_call(Location(), ptr, args); }

    /// Type-coercion.
    /// Currently only a limited set of conversions are possible.
    /// int <=> float and int <=> bool.
    RValue new_cast(Location loc, RValue expr, Type type) @nogc
    {
        auto result = gcc_jit_context_new_cast(__impl, loc.get_location(),
                                               expr.get_rvalue(), type.get_type());
        return RValue(result);
    }

    /// Ditto
    RValue new_cast(RValue expr, Type type) @nogc
    { return new_cast(Location(), expr, type); }

    /// Ditto
    RValue new_cast(Location loc, RValue expr, CType kind) @nogc
    { return new_cast(loc, expr, get_type(kind)); }

    /// Ditto
    RValue new_cast(RValue expr, CType kind) @nogc
    { return new_cast(Location(), expr, get_type(kind)); }

    /// Accessing an array or pointer through an index.
    /// Params:
    ///     loc   = The source location, if any.
    ///     ptr   = The pointer or array.
    ///     index = The index within the array.
    LValue new_array_access(Location loc, RValue ptr, RValue index) @nogc
    {
        auto result = gcc_jit_context_new_array_access(__impl, loc.get_location(),
                                                       ptr.get_rvalue(), index.get_rvalue());
        return LValue(result);
    }

    /// Ditto
    LValue new_array_access(RValue ptr, RValue index) @nogc
    { return new_array_access(Location(), ptr, index); }

    /// Make a JIT.Case representing a case for use in a switch statement.
    Case new_case(RValue min_value, RValue max_value, Block dest_block) @nogc
    {
        auto result = gcc_jit_context_new_case(__impl, min_value.get_rvalue(),
                                               max_value.get_rvalue(), dest_block.get_block());
        return Case(result);
    }

private:
    gcc_jit_context* __impl = null;
}
