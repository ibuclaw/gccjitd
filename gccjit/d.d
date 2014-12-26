
/// A D API for libgccjit, purely as final class wrapper functions.

module gccjit.d;

public import gccjit.c;

import std.conv : to;
import std.string : toStringz;
import std.traits : isIntegral, isSigned;

/// Errors within the API become D exceptions of this class.
final class JITError : Error
{
    ///
    @safe pure nothrow this(string msg, Throwable next = null)
    {
        super(msg, next);
    }

    ///
    @safe pure nothrow this(string msg, string file, size_t line, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/// Class wrapper for gcc_jit_object
class JITObject
{
    ///
    final JITContext getContext()
    {
        auto result = gcc_jit_object_get_context(this.m_inner_obj);
        return new JITContext(result);
    }

    ///
    override final string toString()
    {
        auto result = gcc_jit_object_get_debug_string(this.m_inner_obj);
        return to!string(result);
    }

protected:
    this()
    {
        this.m_inner_obj = null;
    }

    this(gcc_jit_object *obj)
    {
        if (!obj)
            throw new JITError("Unknown error, got bad object");
        this.m_inner_obj = obj;
    }

    final gcc_jit_object *getObject()
    {
        return this.m_inner_obj;
    }

private:
    gcc_jit_object *m_inner_obj;
}

/// Class wrapper for gcc_jit_location
class JITLocation : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_location *loc)
    {
        super(gcc_jit_location_as_object(loc));
    }

    ///
    final gcc_jit_location *getLocation()
    {
        // Manual downcast.
        return cast(gcc_jit_location *)(this.getObject());
    }
}

/// The top-level of the API is the JITContext class.

/// A JITContext instance encapsulates the state of a compilation.
/// It goes through two states.
/// Initial:
///     During which you can set up options on it, and add types,
///     functions and code, using the API below. Invoking compile
///     on it transitions it to the "after compilation" state.
/// PostCompilation:
final class JITContext
{
    ///
    this(bool acquire = true)
    {
        if (acquire)
            this.m_inner_ctxt = gcc_jit_context_acquire();
        else
            this.m_inner_ctxt = null;
    }

    ///
    this(gcc_jit_context *context)
    {
        if (!context)
            throw new JITError("Unknown error, got bad context");
        this.m_inner_ctxt = context;
    }

    ///
    static JITContext acquire()
    {
        return new JITContext(gcc_jit_context_acquire());
    }

    ///
    void release()
    {
        gcc_jit_context_release(this.m_inner_ctxt);
        this.m_inner_ctxt = null;
    }

    /// Set a string option of the context; see JITStrOption for notes
    /// on the options and their meanings.
    /// Params:
    ///     opt   = Which option to set.
    ///     value = The new value.
    void setOption(JITStrOption opt, string value)
    {
        gcc_jit_context_set_str_option(this.m_inner_ctxt, opt, value.toStringz());
    }

    /// Set an integer option of the context; see JITIntOption for notes
    /// on the options and their meanings.
    /// Params:
    ///     opt   = Which option to set.
    ///     value = The new value.
    void setOption(JITIntOption opt, int value)
    {
        gcc_jit_context_set_int_option(this.m_inner_ctxt, opt, value);
    }

    /// Set a boolean option of the context; see JITBoolOption for notes
    /// on the options and their meanings.
    /// Params:
    ///     opt   = Which option to set.
    ///     value = The new value.
    void setOption(JITBoolOption opt, bool value)
    {
        gcc_jit_context_set_bool_option(this.m_inner_ctxt, opt, value);
    }

    ///
    JITResult compile()
    {
        auto result = gcc_jit_context_compile(this.m_inner_ctxt);
        if (!result)
            throw new JITError(this.getFirstError());
        return new JITResult(result);
    }

    ///
    string getFirstError()
    {
        const char *err = gcc_jit_context_get_first_error(this.m_inner_ctxt);
        if (err)
            return to!string(err);
        return null;
    }

    /// Dump context to file.
    void dump(string path, bool update_locations)
    {
        gcc_jit_context_dump_to_file(this.m_inner_ctxt,
                                     path.toStringz(),
                                     update_locations);
    }

    ///
    gcc_jit_context *getContext()
    {
        return this.m_inner_ctxt;
    }

    ///
    JITType getType(JITTypeKind kind)
    {
        auto result = gcc_jit_context_get_type(this.m_inner_ctxt, kind);
        return new JITType(result);
    }

    ///
    JITType getIntType(int num_bytes, bool is_signed)
    {
        auto result = gcc_jit_context_get_int_type(this.m_inner_ctxt,
                                                   num_bytes, is_signed);
        return new JITType(result);
    }

    /// A way to map a specific int type, using the compiler to
    /// get the details automatically e.g:
    ///     JITType type = getIntType!my_int_type_t();
    JITType getIntType(T)() if (isIntegral!T)
    {
        return this.getIntType(T.sizeof, isSigned!T);
    }

    ///
    JITFunction getBuiltinFunction(string name)
    {
        auto result = gcc_jit_context_get_builtin_function(this.m_inner_ctxt,
                                                           name.toStringz());
        return new JITFunction(result);
    }

    ///
    JITContext newChildContext()
    {
        auto result = gcc_jit_context_new_child_context(this.m_inner_ctxt);
        if (!result)
            throw new JITError("Unknown error creating child context");
        return new JITContext(result);
    }

    /// Make a JITLocation representing a source location,
    /// for use by the debugger.
    /// Note:
    ///     You need to enable JITBoolOption.DEBUGINFO on the context
    ///     for these locations to actually be usable by the debugger.
    JITLocation newLocation(string filename, int line, int column)
    {
        auto result = gcc_jit_context_new_location(this.m_inner_ctxt,
                                                   filename.toStringz(),
                                                   line, column);
        return new JITLocation(result);
    }

    ///
    JITType newArrayType(JITLocation loc, JITType type, int dims)
    {
        auto result = gcc_jit_context_new_array_type(this.m_inner_ctxt,
                                                     loc ? loc.getLocation() : null,
                                                     type.getType(), dims);
        return new JITType(result);
    }

    /// Ditto
    JITType newArrayType(JITType type, int dims)
    {
        return this.newArrayType(null, type, dims);
    }

    ///
    JITField newField(JITLocation loc, JITType type, string name)
    {
        auto result = gcc_jit_context_new_field(this.m_inner_ctxt,
                                                loc ? loc.getLocation() : null,
                                                type.getType(),
                                                name.toStringz());
        return new JITField(result);
    }

    /// Ditto
    JITField newField(JITType type, string name)
    {
        return this.newField(null, type, name);
    }

    ///
    JITStruct newStructType(JITLocation loc, string name, JITField[] fields...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_field*[] field_p = new gcc_jit_field*[fields.length];
        foreach(i, field; fields)
            field_p[i] = field.getField();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_struct_type(this.m_inner_ctxt,
                                                      loc ? loc.getLocation() : null,
                                                      name.toStringz(),
                                                      cast(int)fields.length,
                                                      field_p.ptr);
        return new JITStruct(result);
    }

    /// Ditto
    JITStruct newStructType(string name, JITField[] fields...)
    {
        return this.newStructType(null, name, fields);
    }

    ///
    JITStruct newOpaqueStructType(JITLocation loc, string name)
    {
        auto result = gcc_jit_context_new_opaque_struct(this.m_inner_ctxt,
                                                        loc ? loc.getLocation() : null,
                                                        name.toStringz());
        return new JITStruct(result);
    }

    /// Ditto
    JITStruct newOpaqueStructType(string name)
    {
        return this.newOpaqueStructType(null, name);
    }

    ///
    JITType newUnionType(JITLocation loc, string name, JITField[] fields...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_field*[] field_p = new gcc_jit_field*[fields.length];
        foreach(i, field; fields)
            field_p[i] = field.getField();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_union_type(this.m_inner_ctxt,
                                                     loc ? loc.getLocation() : null,
                                                     name.toStringz(),
                                                     cast(int)fields.length,
                                                     field_p.ptr);
        return new JITType(result);
    }

    /// Ditto
    JITType newUnionType(string name, JITField[] fields...)
    {
        return this.newUnionType(null, name, fields);
    }

    ///
    JITType newFunctionType(JITLocation loc, JITType return_type,
                            bool is_variadic, JITType[] param_types...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_type*[] type_p = new gcc_jit_type*[param_types.length];
        foreach(i, type; param_types)
            type_p[i] = type.getType();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_function_ptr_type(this.m_inner_ctxt,
                                                            loc ? loc.getLocation() : null,
                                                            return_type.getType(),
                                                            cast(int)param_types.length,
                                                            type_p.ptr, is_variadic);
        return new JITType(result);
    }

    /// Ditto
    JITType newFunctionType(JITType return_type, bool is_variadic,
                            JITType[] param_types...)
    {
        return this.newFunctionType(null, return_type, is_variadic,
                                    param_types);
    }

    ///
    JITType newFunctionType(JITLocation loc, JITTypeKind return_kind,
                            bool is_variadic, JITType[] param_types...)
    {
        return this.newFunctionType(loc, this.getType(return_kind),
                                    is_variadic, param_types);
    }

    /// Ditto
    JITType newFunctionType(JITTypeKind return_kind, bool is_variadic,
                            JITType[] param_types...)
    {
        return this.newFunctionType(null, this.getType(return_kind),
                                    is_variadic, param_types);
    }

    ///
    JITParam newParam(JITLocation loc, JITType type, string name)
    {
        auto result = gcc_jit_context_new_param(this.m_inner_ctxt,
                                                loc ? loc.getLocation() : null,
                                                type.getType(),
                                                name.toStringz());
        return new JITParam(result);
    }

    /// Ditto
    JITParam newParam(JITType type, string name)
    {
        return this.newParam(null, type, name);
    }

    ///
    JITParam newParam(JITLocation loc, JITTypeKind kind, string name)
    {
        return this.newParam(loc, this.getType(kind), name);
    }

    /// Ditto
    JITParam newParam(JITTypeKind kind, string name)
    {
        return this.newParam(null, this.getType(kind), name);
    }

    ///
    JITFunction newFunction(JITLocation loc, JITFunctionKind kind, JITType return_type,
                            string name, bool is_variadic, JITParam[] params...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_param*[] param_p = new gcc_jit_param*[params.length];
        foreach(i, param; params)
            param_p[i] = param.getParam();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_function(this.m_inner_ctxt,
                                                   loc ? loc.getLocation() : null,
                                                   kind, return_type.getType(),
                                                   name.toStringz(),
                                                   cast(int)params.length,
                                                   param_p.ptr, is_variadic);
        return new JITFunction(result);
    }

    /// Ditto
    JITFunction newFunction(JITFunctionKind kind, JITType return_type,
                            string name, bool is_variadic, JITParam[] params...)
    {
        return this.newFunction(null, kind, return_type, name, is_variadic, params);
    }

    ///
    JITFunction newFunction(JITLocation loc, JITFunctionKind kind, JITTypeKind return_kind,
                            string name, bool is_variadic, JITParam[] params...)
    {
        return this.newFunction(loc, kind, this.getType(return_kind),
                                name, is_variadic, params);
    }

    /// Ditto
    JITFunction newFunction(JITFunctionKind kind, JITTypeKind return_kind,
                            string name, bool is_variadic, JITParam[] params...)
    {
        return this.newFunction(null, kind, this.getType(return_kind),
                                name, is_variadic, params);
    }

    ///
    JITLValue newGlobal(JITLocation loc, JITType type, string name)
    {
        auto result = gcc_jit_context_new_global(this.m_inner_ctxt,
                                                 loc ? loc.getLocation() : null,
                                                 type.getType(),
                                                 name.toStringz());
        return new JITLValue(result);
    }

    /// Ditto
    JITLValue newGlobal(JITType type, string name)
    {
        return this.newGlobal(null, type, name);
    }

    /// Given a JITType, which must be a numeric type, get an
    /// integer constant as a JITRValue of that type.
    JITRValue newRValue(JITType type, int value)
    {
        auto result = gcc_jit_context_new_rvalue_from_int(this.m_inner_ctxt,
                                                          type.getType(), value);
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newRValue(JITTypeKind kind, int value)
    {
        return newRValue(this.getType(kind), value);
    }

    /// Given a JITType, which must be a numeric type, get an
    /// floating point constant as a JITRValue of that type.
    JITRValue newRValue(JITType type, double value)
    {
        auto result = gcc_jit_context_new_rvalue_from_double(this.m_inner_ctxt,
                                                             type.getType(), value);
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newRValue(JITTypeKind kind, double value)
    {
        return newRValue(this.getType(kind), value);
    }

    /// Given a JITType, which must be a pointer type, and an
    /// address, get a JITRValue representing that address as a
    /// pointer of that type.
    JITRValue newRValue(JITType type, void *value)
    {
        auto result = gcc_jit_context_new_rvalue_from_ptr(this.m_inner_ctxt,
                                                          type.getType(), value);
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newRValue(JITTypeKind kind, void *value)
    {
        return newRValue(this.getType(kind), value);
    }

    /// Make a JITRValue for the given string literal value.
    /// Params:
    ///     value = The string literal.
    JITRValue newRValue(string value)
    {
        auto result = gcc_jit_context_new_string_literal(this.m_inner_ctxt,
                                                         value.toStringz());
        return new JITRValue(result);
    }

    /// Given a JITType, which must be a numeric type, get the
    /// constant 0 as a JITRValue of that type.
    JITRValue zero(JITType type)
    {
        auto result = gcc_jit_context_zero(this.m_inner_ctxt, type.getType());
        return new JITRValue(result);
    }

    /// Given a JITType, which must be a numeric type, get the
    /// constant 1 as a JITRValue of that type.
    JITRValue one(JITType type)
    {
        auto result = gcc_jit_context_one(this.m_inner_ctxt, type.getType());
        return new JITRValue(result);
    }

    /// Given a JITType, which must be a pointer type, get a
    /// JITRValue representing the NULL pointer of that type.
    JITRValue nil(JITType type)
    {
        auto result = gcc_jit_context_null(this.m_inner_ctxt, type.getType());
        return new JITRValue(result);
    }

    /// Generic unary operations.

    /// Make a JITRValue for the given unary operation.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which unary operation.
    ///     type = The type of the result.
    ///     a    = The input expression.
    JITRValue newUnaryOp(JITLocation loc, JITUnaryOp op, JITType type, JITRValue a)
    {
        auto result = gcc_jit_context_new_unary_op(this.m_inner_ctxt,
                                                   loc ? loc.getLocation() : null,
                                                   op, type.getType(),
                                                   a.getRValue());
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newUnaryOp(JITUnaryOp op, JITType type, JITRValue a)
    {
        return this.newUnaryOp(null, op, type, a);
    }

    /// Generic binary operations.

    /// Make a JITRValue for the given binary operation.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which binary operation.
    ///     type = The type of the result.
    ///     a    = The first input expression.
    ///     b    = The second input expression.
    JITRValue newBinaryOp(JITLocation loc, JITBinaryOp op,
                          JITType type, JITRValue a, JITRValue b)
    {
        auto result = gcc_jit_context_new_binary_op(this.m_inner_ctxt,
                                                    loc ? loc.getLocation() : null,
                                                    op, type.getType(),
                                                    a.getRValue(),
                                                    b.getRValue());
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newBinaryOp(JITBinaryOp op, JITType type, JITRValue a, JITRValue b)
    {
        return this.newBinaryOp(null, op, type, a, b);
    }

    /// Generic comparisons.

    /// Make a JITRValue of boolean type for the given comparison.
    /// Params:
    ///     loc  = The source location, if any.
    ///     op   = Which comparison.
    ///     a    = The first input expression.
    ///     b    = The second input expression.
    JITRValue newComparison(JITLocation loc, JITComparison op,
                            JITRValue a, JITRValue b)
    {
        auto result = gcc_jit_context_new_comparison(this.m_inner_ctxt,
                                                     loc ? loc.getLocation() : null,
                                                     op, a.getRValue(),
                                                     b.getRValue());
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newComparison(JITComparison op, JITRValue a, JITRValue b)
    {
        return this.newComparison(null, op, a, b);
    }

    /// The most general way of creating a function call.
    JITRValue newCall(JITLocation loc, JITFunction func, JITRValue[] args...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_rvalue*[] arg_p = new gcc_jit_rvalue*[args.length];
        foreach(i, arg; args)
            arg_p[i] = arg.getRValue();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_call(this.m_inner_ctxt,
                                               loc ? loc.getLocation() : null,
                                               func.getFunction(),
                                               cast(int)args.length,
                                               arg_p.ptr);
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newCall(JITFunction func, JITRValue[] args...)
    {
        return this.newCall(null, func, args);
    }

    /// Calling a function through a pointer.
    JITRValue newCall(JITLocation loc, JITRValue ptr, JITRValue[] args...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_rvalue*[] arg_p = new gcc_jit_rvalue*[args.length];
        foreach(i, arg; args)
            arg_p[i] = arg.getRValue();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = gcc_jit_context_new_call_through_ptr(this.m_inner_ctxt,
                                                           loc ? loc.getLocation() : null,
                                                           ptr.getRValue(),
                                                           cast(int)args.length,
                                                           arg_p.ptr);
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newCall(JITRValue ptr, JITRValue[] args...)
    {
        return this.newCall(null, ptr, args);
    }

    ///
    JITRValue newCast(JITLocation loc, JITRValue expr, JITType type)
    {
        auto result = gcc_jit_context_new_cast(this.m_inner_ctxt,
                                               loc ? loc.getLocation() : null,
                                               expr.getRValue(), type.getType());
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue newCast(JITRValue expr, JITType type)
    {
        return this.newCast(null, expr, type);
    }

    /// Params:
    ///     loc   = The source location, if any.
    ///     ptr   = The pointer or array.
    ///     index = The index within the array.
    JITLValue newArrayAccess(JITLocation loc, JITRValue ptr, JITRValue index)
    {
        auto result = gcc_jit_context_new_array_access(this.m_inner_ctxt,
                                                       loc ? loc.getLocation() : null,
                                                       ptr.getRValue(), index.getRValue());
        return new JITLValue(result);
    }

    /// Ditto
    JITLValue newArrayAccess(JITRValue ptr, JITRValue index)
    {
        return this.newArrayAccess(null, ptr, index);
    }

private:
    gcc_jit_context *m_inner_ctxt;
}

/// Class wrapper for gcc_jit_field
class JITField : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_field *field)
    {
        super(gcc_jit_field_as_object(field));
    }

    ///
    final gcc_jit_field *getField()
    {
        // Manual downcast.
        return cast(gcc_jit_field *)(this.getObject());
    }
}

/// Types can be created in several ways:
/// $(UL
///     $(LI Fundamental types can be accessed using JITContext.getType())
///     $(LI Derived types can be accessed by calling methods on an existing type.)
///     $(LI By creating structures via JITStruct.)
/// )

class JITType : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_type *type)
    {
        super(gcc_jit_type_as_object(type));
    }

    ///
    final gcc_jit_type *getType()
    {
        // Manual downcast.
        return cast(gcc_jit_type *)(this.getObject());
    }

    /// Given type T, get type T*.
    final JITType pointerOf()
    {
        auto result = gcc_jit_type_get_pointer(this.getType());
        return new JITType(result);
    }

    /// Given type T, get type const T.
    final JITType constOf()
    {
        auto result = gcc_jit_type_get_const(this.getType());
        return new JITType(result);
    }

    /// Given type T, get type volatile T.
    final JITType volatileOf()
    {
        auto result = gcc_jit_type_get_volatile(this.getType());
        return new JITType(result);
    }
}

/// You can model C struct types by creating JITStruct and JITField
/// instances, in either order:
/// $(UL
///     $(LI By creating the fields, then the structure.)
///     $(LI By creating the structure, then populating it with fields,
///          typically to allow modelling self-referential structs.)
/// )
class JITStruct : JITType
{
    ///
    this()
    {
        super(null);
    }

    ///
    this(gcc_jit_struct *agg)
    {
        super(gcc_jit_struct_as_type(agg));
    }

    ///
    final gcc_jit_struct *getStruct()
    {
        // Manual downcast.
        return cast(gcc_jit_struct *)(this.getObject());
    }

    /// Populate the fields of a formerly-opaque struct type.
    /// This can only be called once on a given struct type.
    final void setFields(JITLocation loc, JITField[] fields...)
    {
        // Convert to an array of inner pointers.
        gcc_jit_field*[] field_p = new gcc_jit_field*[fields.length];
        foreach(i, field; fields)
            field_p[i] = field.getField();

        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        gcc_jit_struct_set_fields(this.getStruct(), loc ? loc.getLocation() : null,
                                  cast(int)fields.length, field_p.ptr);
    }

    /// Ditto
    final void setFields(JITField[] fields...)
    {
        this.setFields(null, fields);
    }
}

/// Class wrapper for gcc_jit_function
class JITFunction : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_function *func)
    {
        if (!func)
            throw new JITError("Unknown error, got bad function");
        super(gcc_jit_function_as_object(func));
    }

    ///
    final gcc_jit_function *getFunction()
    {
        // Manual downcast.
        return cast(gcc_jit_function *)(this.getObject());
    }

    /// Dump function to dot file.
    final void dump(string path)
    {
        gcc_jit_function_dump_to_dot(this.getFunction(), path.toStringz());
    }

    ///
    final JITParam getParam(int index)
    {
        auto result = gcc_jit_function_get_param(this.getFunction(), index);
        return new JITParam(result);
    }

    ///
    final JITBlock newBlock()
    {
        auto result = gcc_jit_function_new_block(this.getFunction(), null);
        return new JITBlock(result);
    }

    ///
    final JITBlock newBlock(string name)
    {
        auto result = gcc_jit_function_new_block(this.getFunction(),
                                                 name.toStringz());
        return new JITBlock(result);
    }

    ///
    final JITLValue newLocal(JITLocation loc, JITType type, string name)
    {
        auto result = gcc_jit_function_new_local(this.getFunction(),
                                                 loc ? loc.getLocation() : null,
                                                 type.getType(),
                                                 name.toStringz());
        return new JITLValue(result);
    }

    /// Ditto
    final JITLValue newLocal(JITType type, string name)
    {
        return this.newLocal(null, type, name);
    }
}


/// Class wrapper for gcc_jit_block
class JITBlock : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_block *block)
    {
        super(gcc_jit_block_as_object(block));
    }

    ///
    final gcc_jit_block *getBlock()
    {
        // Manual downcast.
        return cast(gcc_jit_block *)(this.getObject());
    }

    ///
    final JITFunction getFunction()
    {
        auto result = gcc_jit_block_get_function(this.getBlock());
        return new JITFunction(result);
    }

    ///
    final void addEval(JITLocation loc, JITRValue rvalue)
    {
        gcc_jit_block_add_eval(this.getBlock(),
                               loc ? loc.getLocation() : null,
                               rvalue.getRValue());
    }

    /// Ditto
    final void addEval(JITRValue rvalue)
    {
        return this.addEval(null, rvalue);
    }

    ///
    final void addAssignment(JITLocation loc, JITLValue lvalue, JITRValue rvalue)
    {
        gcc_jit_block_add_assignment(this.getBlock(),
                                     loc ? loc.getLocation() : null,
                                     lvalue.getLValue(), rvalue.getRValue());
    }

    /// Ditto
    final void addAssignment(JITLValue lvalue, JITRValue rvalue)
    {
        return this.addAssignment(null, lvalue, rvalue);
    }

    ///
    final void addAssignmentOp(JITLocation loc, JITLValue lvalue,
                         JITBinaryOp op, JITRValue rvalue)
    {
        gcc_jit_block_add_assignment_op(this.getBlock(),
                                        loc ? loc.getLocation() : null,
                                        lvalue.getLValue(), op, rvalue.getRValue());
    }

    /// Ditto
    final void addAssignmentOp(JITLValue lvalue, JITBinaryOp op, JITRValue rvalue)
    {
        return this.addAssignmentOp(null, lvalue, op, rvalue);
    }

    /// A way to add a function call to the body of a function being
    /// defined, with various number of args.
    final JITRValue addCall(JITLocation loc, JITFunction func, JITRValue[] args...)
    {
        JITRValue rv = this.getContext().newCall(loc, func, args);
        this.addEval(loc, rv);
        return rv;
    }

    /// Ditto
    final JITRValue addCall(JITFunction func, JITRValue[] args...)
    {
        return this.addCall(null, func, args);
    }

    ///
    final void addComment(JITLocation loc, string text)
    {
        gcc_jit_block_add_comment(this.getBlock(),
                                  loc ? loc.getLocation() : null,
                                  text.toStringz());
    }

    /// Ditto
    final void addComment(string text)
    {
        return this.addComment(null, text);
    }

    ///
    final void endWithConditional(JITLocation loc, JITRValue val,
                            JITBlock on_true, JITBlock on_false)
    {
        gcc_jit_block_end_with_conditional(this.getBlock(),
                                           loc ? loc.getLocation() : null,
                                           val.getRValue(),
                                           on_true.getBlock(),
                                           on_false.getBlock());
    }

    /// Ditto
    final void endWithConditional(JITRValue val, JITBlock on_true, JITBlock on_false)
    {
        return this.endWithConditional(null, val, on_true, on_false);
    }

    ///
    final void endWithJump(JITLocation loc, JITBlock target)
    {
        gcc_jit_block_end_with_jump(this.getBlock(),
                                    loc ? loc.getLocation() : null,
                                    target.getBlock());
    }

    /// Ditto
    final void endWithJump(JITBlock target)
    {
        return this.endWithJump(null, target);
    }

    ///
    final void endWithReturn(JITLocation loc, JITRValue rvalue)
    {
        gcc_jit_block_end_with_return(this.getBlock(),
                                      loc ? loc.getLocation() : null,
                                      rvalue.getRValue());
    }

    /// Ditto
    final void endWithReturn(JITRValue rvalue)
    {
        return this.endWithReturn(null, rvalue);
    }

    ///
    final void endWithReturn(JITLocation loc = null)
    {
        gcc_jit_block_end_with_void_return(this.getBlock(),
                                           loc ? loc.getLocation() : null);
    }
}

/// Class wrapper for gcc_jit_rvalue
class JITRValue : JITObject
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_rvalue *rvalue)
    {
        if (!rvalue)
            throw new JITError("Unknown error, got bad rvalue");
        super(gcc_jit_rvalue_as_object(rvalue));
    }

    ///
    final gcc_jit_rvalue *getRValue()
    {
        // Manual downcast.
        return cast(gcc_jit_rvalue *)(this.getObject());
    }

    ///
    final JITType getType()
    {
        auto result = gcc_jit_rvalue_get_type(this.getRValue());
        return new JITType(result);
    }

    ///
    JITRValue accessField(JITLocation loc, JITField field)
    {
        auto result = gcc_jit_rvalue_access_field(this.getRValue(),
                                                  loc ? loc.getLocation() : null,
                                                  field.getField());
        return new JITRValue(result);
    }

    /// Ditto
    JITRValue accessField(JITField field)
    {
        return this.accessField(null, field);
    }

    ///
    final JITLValue dereferenceField(JITLocation loc, JITField field)
    {
        auto result = gcc_jit_rvalue_dereference_field(this.getRValue(),
                                                       loc ? loc.getLocation() : null,
                                                       field.getField());
        return new JITLValue(result);
    }

    /// Ditto
    final JITLValue dereferenceField(JITField field)
    {
        return this.dereferenceField(null, field);
    }

    ///
    final JITLValue dereference(JITLocation loc = null)
    {
        auto result = gcc_jit_rvalue_dereference(this.getRValue(),
                                                 loc ? loc.getLocation() : null);
        return new JITLValue(result);
    }

    ///
    final JITRValue castTo(JITLocation loc, JITType type)
    {
        return this.getContext().newCast(loc, this, type);
    }

    /// Ditto
    final JITRValue castTo(JITType type)
    {
        return this.castTo(null, type);
    }

    ///
    final JITRValue castTo(JITLocation loc, JITTypeKind kind)
    {
        return this.castTo(loc, this.getContext().getType(kind));
    }

    /// Ditto
    final JITRValue castTo(JITTypeKind kind)
    {
        return this.castTo(null, this.getContext().getType(kind));
    }
}

/// Class wrapper for gcc_jit_lvalue
class JITLValue : JITRValue
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_lvalue *lvalue)
    {
        if (!lvalue)
            throw new JITError("Unknown error, got bad lvalue");
        super(gcc_jit_lvalue_as_rvalue(lvalue));
    }

    ///
    final gcc_jit_lvalue *getLValue()
    {
        // Manual downcast.
        return cast(gcc_jit_lvalue *)(this.getObject());
    }

    ///
    override JITLValue accessField(JITLocation loc, JITField field)
    {
        auto result = gcc_jit_lvalue_access_field(this.getLValue(),
                                                  loc ? loc.getLocation() : null,
                                                  field.getField());
        return new JITLValue(result);
    }

    /// Ditto
    override JITLValue accessField(JITField field)
    {
        return this.accessField(null, field);
    }

    ///
    final JITRValue getAddress(JITLocation loc = null)
    {
        auto result = gcc_jit_lvalue_get_address(this.getLValue(),
                                                 loc ? loc.getLocation() : null);
        return new JITRValue(result);
    }
}

/// Class wrapper for gcc_jit_param
class JITParam : JITLValue
{
    ///
    this()
    {
        super();
    }

    ///
    this(gcc_jit_param *param)
    {
        if (!param)
            throw new JITError("Unknown error, got bad param");
        super(gcc_jit_param_as_lvalue(param));
    }

    ///
    final gcc_jit_param *getParam()
    {
        // Manual downcast.
        return cast(gcc_jit_param *)(this.getObject());
    }
}

/// Class wrapper for gcc_jit_result
final class JITResult
{
    ///
    this()
    {
        this.m_inner_result = null;
    }

    ///
    this(gcc_jit_result *result)
    {
        if (!result)
            throw new JITError("Unknown error, got bad result");
        this.m_inner_result = result;
    }

    ///
    gcc_jit_result *getResult()
    {
        return this.m_inner_result;
    }

    ///
    void *getCode(string name)
    {
        return gcc_jit_result_get_code(this.getResult(), name.toStringz());
    }

    ///
    void release()
    {
        gcc_jit_result_release(this.getResult());
    }

private:
    gcc_jit_result *m_inner_result;
}

///
enum JITFunctionKind : gcc_jit_function_kind
{
    ///
    EXPORTED = GCC_JIT_FUNCTION_EXPORTED,
    ///
    INTERNAL = GCC_JIT_FUNCTION_INTERNAL,
    ///
    IMPORTED = GCC_JIT_FUNCTION_IMPORTED,
    ///
    ALWAYS_INLINE = GCC_JIT_FUNCTION_ALWAYS_INLINE,
}

/// Standard types
enum JITTypeKind : gcc_jit_types
{
    /// C's void type.
    VOID = GCC_JIT_TYPE_VOID,

    /// C's void* type.
    VOID_PTR = GCC_JIT_TYPE_VOID_PTR,

    /// C++'s bool type.
    BOOL = GCC_JIT_TYPE_BOOL,

    /// C's char type.
    CHAR = GCC_JIT_TYPE_CHAR,

    /// C's signed char type.
    SIGNED_CHAR = GCC_JIT_TYPE_SIGNED_CHAR,

    /// C's unsigned char type.
    UNSIGNED_CHAR = GCC_JIT_TYPE_UNSIGNED_CHAR,

    /// C's short type.
    SHORT = GCC_JIT_TYPE_SHORT,

    /// C's unsigned short type.
    UNSIGNED_SHORT = GCC_JIT_TYPE_UNSIGNED_SHORT,

    /// C's int type.
    INT = GCC_JIT_TYPE_INT,

    /// C's unsigned int type.
    UNSIGNED_INT = GCC_JIT_TYPE_UNSIGNED_INT,

    /// C's long type.
    LONG = GCC_JIT_TYPE_LONG,

    /// C's unsigned long type.
    UNSIGNED_LONG = GCC_JIT_TYPE_UNSIGNED_LONG,

    /// C99's long long type.
    LONG_LONG = GCC_JIT_TYPE_LONG_LONG,

    /// C99's unsigned long long type.
    UNSIGNED_LONG_LONG = GCC_JIT_TYPE_UNSIGNED_LONG_LONG,

    /// Single precision floating point type.
    FLOAT = GCC_JIT_TYPE_FLOAT,

    /// Double precision floating point type.
    DOUBLE = GCC_JIT_TYPE_DOUBLE,

    /// Largest supported floating point type.
    LONG_DOUBLE = GCC_JIT_TYPE_LONG_DOUBLE,

    /// C's const char* type.
    CONST_CHAR_PTR = GCC_JIT_TYPE_CONST_CHAR_PTR,

    /// C's size_t type.
    SIZE_T = GCC_JIT_TYPE_SIZE_T,

    /// C's FILE* type.
    FILE_PTR = GCC_JIT_TYPE_FILE_PTR,

    /// Single precision complex float type.
    COMPLEX_FLOAT = GCC_JIT_TYPE_COMPLEX_FLOAT,

    /// Double precision complex float type.
    COMPLEX_DOUBLE = GCC_JIT_TYPE_COMPLEX_DOUBLE,

    /// Largest supported complex float type.
    COMPLEX_LONG_DOUBLE = GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE
}

///
enum JITUnaryOp : gcc_jit_unary_op
{
    ///
    MINUS = GCC_JIT_UNARY_OP_MINUS,
    ///
    BITWISE_NEGATE = GCC_JIT_UNARY_OP_BITWISE_NEGATE,
    ///
    LOGICAL_NEGATE = GCC_JIT_UNARY_OP_LOGICAL_NEGATE,
}

///
enum JITBinaryOp : gcc_jit_binary_op
{
    ///
    PLUS = GCC_JIT_BINARY_OP_PLUS,
    ///
    MINUS = GCC_JIT_BINARY_OP_MINUS,
    ///
    MULT = GCC_JIT_BINARY_OP_MULT,
    ///
    DIVIDE = GCC_JIT_BINARY_OP_DIVIDE,
    ///
    MODULO = GCC_JIT_BINARY_OP_MODULO,
    ///
    BITWISE_AND = GCC_JIT_BINARY_OP_BITWISE_AND,
    ///
    BITWISE_XOR = GCC_JIT_BINARY_OP_BITWISE_XOR,
    ///
    BITWISE_OR = GCC_JIT_BINARY_OP_BITWISE_OR,
    ///
    LOGICAL_AND = GCC_JIT_BINARY_OP_LOGICAL_AND,
    ///
    LOGICAL_OR = GCC_JIT_BINARY_OP_LOGICAL_OR,
    ///
    LSHIFT = GCC_JIT_BINARY_OP_LSHIFT,
    ///
    RSHIFT = GCC_JIT_BINARY_OP_RSHIFT,
}

///
enum JITComparison : gcc_jit_comparison
{
    ///
    EQ = GCC_JIT_COMPARISON_EQ,
    ///
    NE = GCC_JIT_COMPARISON_NE,
    ///
    LT = GCC_JIT_COMPARISON_LT,
    ///
    LE = GCC_JIT_COMPARISON_LE,
    ///
    GT = GCC_JIT_COMPARISON_GT,
    ///
    GE = GCC_JIT_COMPARISON_GE,
}

/// String options
enum JITStrOption : gcc_jit_str_option
{
    /// The name of the program, for use as a prefix when printing error
    /// messages to stderr. If None, or default, "libgccjit.so" is used.
    PROGNAME = GCC_JIT_STR_OPTION_PROGNAME,
}

/// Integer options
enum JITIntOption : gcc_jit_int_option
{
    /// How much to optimize the code.

    /// Valid values are 0-3, corresponding to GCC's command-line options
    /// -O0 through -O3.

    /// The default value is 0 (unoptimized).
    OPTIMIZATION_LEVEL = GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL,
}

/// Boolean options
enum JITBoolOption : gcc_jit_bool_option
{
    /// If true, JITContext.compile() will attempt to do the right thing
    /// so that if you attach a debugger to the process, it will be able
    /// to inspect variables and step through your code.

    /// Note that you can’t step through code unless you set up source
    /// location information for the code (by creating and passing in
    /// JITLocation instances).
    DEBUGINFO = GCC_JIT_BOOL_OPTION_DEBUGINFO,

    /// If true, JITContext.compile() will dump its initial "tree"
    /// representation of your code to stderr, before any optimizations.
    DUMP_INITIAL_TREE = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE,

    /// If true, JITContext.compile() will dump its initial "gimple"
    /// representation of your code to stderr, before any optimizations
    /// are performed. The dump resembles C code.
    DUMP_INITIAL_GIMPLE = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE,

    /// If true, JITContext.compile() will dump the final generated code
    /// to stderr, in the form of assembly language.
    DUMP_GENERATED_CODE = GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE,

    /// If true, JITContext.compile() will print information to stderr
    /// on the actions it is performing, followed by a profile showing
    /// the time taken and memory usage of each phase.
    DUMP_SUMMARY = GCC_JIT_BOOL_OPTION_DUMP_SUMMARY,

    /// If true, JITContext.compile() will dump copious amounts of
    /// information on what it’s doing to various files within a
    /// temporary directory. Use JITBoolOption.KEEP_INTERMEDIATES
    /// to see the results. The files are intended to be human-readable,
    /// but the exact files and their formats are subject to change.
    DUMP_EVERYTHING = GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING,

    /// If true, libgccjit will aggressively run its garbage collector,
    /// to shake out bugs (greatly slowing down the compile). This is
    /// likely to only be of interest to developers of the library.
    SELFCHECK_GC = GCC_JIT_BOOL_OPTION_SELFCHECK_GC,

    /// If true, the JITContext will not clean up intermediate files
    /// written to the filesystem, and will display their location on
    /// stderr.
    KEEP_INTERMEDIATES = GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES,
}

