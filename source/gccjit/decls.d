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

module gccjit.decls;

package(gccjit):

import gccjit.bindings;
import gccjit.block;
import gccjit.helpers;
import gccjit.location;
import gccjit.object;
import gccjit.types;
import gccjit.values;

/// Struct wrapper for gcc_jit_field
struct Field
{
    union
    {
        private gcc_jit_field* m_field = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_field* field) pure nothrow @nogc
    {
        m_field = field;
    }

    /// Returns the internal gcc_jit_field object.
    inout(gcc_jit_field)* get_field() inout pure nothrow @nogc
    {
        return m_field;
    }

    /// Returns true if this JIT.Field has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_field !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_field_as_object(cast(gcc_jit_field*)m_field);
        return typeof(return)(result);
    }
}

/// Struct wrapper for gcc_jit_function
struct Function
{
    union
    {
        private gcc_jit_function* m_function = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_function* func) pure nothrow @nogc
    {
        m_function = func;
    }

    /// Returns the internal gcc_jit_function object.
    gcc_jit_function* get_function() pure nothrow @nogc
    {
        return m_function;
    }

    /// Returns true if this JIT.Function has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_function !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_function_as_object(cast(gcc_jit_function*)m_function);
        return typeof(return)(result);
    }

    /// Dump function to dot file.
    Function dump_to_dot(string path) return nothrow @nogc
    {
        path.toCStringThen!((p)
            => gcc_jit_function_dump_to_dot(m_function, p.ptr));
        return this;
    }

    /// Get a specific parameter of a function by index.
    Parameter get_param(int index) nothrow @nogc
    {
        auto result = gcc_jit_function_get_param(m_function, index);
        return Parameter(result);
    }

    /// Create a JIT.Block.
    /// The name can be null, or you can give it a meaningful name, which may
    /// show up in dumps of the internal representation, and in error messages.
    Block new_block() nothrow @nogc
    {
        auto result = gcc_jit_function_new_block(m_function, null);
        return Block(result);
    }

    /// Ditto
    Block new_block(string name) nothrow @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_function_new_block(m_function, n.ptr));
        return Block(result);
    }

    /// Create a new local variable.
    LValue new_local(Location loc, Type type, string name) nothrow @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_function_new_local(m_function,
                                          loc.get_location(),
                                          type.get_type(), n.ptr));
        return LValue(result);
    }

    /// Ditto
    LValue new_local(Type type, string name) nothrow @nogc
    { return new_local(Location(), type, name); }

    /// Return the address of the function.
    RValue get_address(Location loc = Location()) nothrow @nogc
    {
        auto result = gcc_jit_function_get_address(m_function, loc.get_location());
        return RValue(result);
    }

    /// Get the return type of the function.
    Type get_return_type() nothrow @nogc
    {
        auto result = gcc_jit_function_get_return_type(m_function);
        return Type(result);
    }

    /// Get the number of parameters of the function.
    size_t get_param_count() nothrow @nogc
    {
        return gcc_jit_function_get_param_count(m_function);
    }

    /// Add an attribute to a JIT.Function.
    Function add_attribute(FnAttribute attribute) return nothrow @nogc
    {
        gcc_jit_function_add_attribute(m_function, attribute);
        return this;
    }

    /// Ditto
    Function add_attribute(FnAttribute attribute, string value) return nothrow @nogc
    {
        value.toCStringThen!((v)
            => gcc_jit_function_add_string_attribute(m_function, attribute, v.ptr));
        return this;
    }

    /// Ditto
    Function add_attribute(FnAttribute attribute, scope int[] values) return nothrow @nogc
    {
        gcc_jit_function_add_integer_array_attribute(m_function, attribute,
                                                     values.ptr, values.length);
        return this;
    }

    /// Ditto
    Function add_attribute(FnAttribute attribute, scope int[] values...) return nothrow @nogc
    { return add_attribute(attribute, values); }

    /// Create a new compiler-generated variable.
    LValue new_temp(Location loc, Type type) nothrow @nogc
    {
        auto result = gcc_jit_function_new_temp(m_function, loc.get_location(), type.get_type());
        return LValue(result);
    }

    /// Ditto
    LValue new_temp(Type type) nothrow @nogc
    { return new_temp(Location(), type); }

    /// A series of overloaded call operators with various numbers of arguments
    /// for a very terse way of creating a call to this function.  The call
    /// is created within the same context as the function itself, which may
    /// not be what you want.

    ///
    RValue opCall(Location loc = Location()) nothrow @nogc
    { return get_context().new_call(loc, this); }

    ///
    RValue opCall(RValue arg0, Location loc = Location()) nothrow @nogc
    { return get_context().new_call(loc, this, arg0); }

    ///
    RValue opCall(RValue arg0, RValue arg1, Location loc = Location()) nothrow @nogc
    { return get_context().new_call(loc, this, arg0, arg1); }

    ///
    RValue opCall(RValue arg0, RValue arg1, RValue arg2, Location loc = Location()) nothrow @nogc
    { return get_context().new_call(loc, this, arg0, arg1, arg2); }
}

/// Struct wrapper for gcc_jit_param
struct Parameter
{
    union
    {
        private gcc_jit_param* m_parameter = null;
        LValue m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_param* param) pure nothrow @nogc
    {
        m_parameter = param;
    }

    /// Returns the internal gcc_jit_param object.
    gcc_jit_param* get_param() pure nothrow @nogc
    {
        return m_parameter;
    }

    /// Returns true if this JIT.Parameter has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_parameter !is null;
    }

    /// Upcast to the parent JIT.LValue.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == LValue))
    {
        auto result = gcc_jit_param_as_lvalue(cast(gcc_jit_param*)m_parameter);
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.RValue.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == RValue))
    {
        auto result = gcc_jit_param_as_rvalue(cast(gcc_jit_param*)m_parameter);
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_param_as_object(cast(gcc_jit_param*)m_parameter);
        return typeof(return)(result);
    }
}
