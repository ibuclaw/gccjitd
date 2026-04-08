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
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_field* field) nothrow @nogc
    {
        __super = JitObject(gcc_jit_field_as_object(field));
    }

    /// Returns the internal gcc_jit_field object.
    gcc_jit_field* get_field() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_field *)get_object();
    }
}

/// Struct wrapper for gcc_jit_function
struct Function
{
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_function* func) nothrow @nogc
    {
        __super = JitObject(gcc_jit_function_as_object(func));
    }

    /// Returns the internal gcc_jit_function object.
    gcc_jit_function* get_function() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_function *)get_object();
    }

    /// Dump function to dot file.
    void dump_to_dot(string path) nothrow @nogc
    {
        path.toCStringThen!((p)
            => gcc_jit_function_dump_to_dot(get_function(), p.ptr));
    }

    /// Get a specific parameter of a function by index.
    Parameter get_param(int index) nothrow @nogc
    {
        auto result = gcc_jit_function_get_param(get_function(), index);
        return Parameter(result);
    }

    /// Create a JIT.Block.
    /// The name can be null, or you can give it a meaningful name, which may
    /// show up in dumps of the internal representation, and in error messages.
    Block new_block() nothrow @nogc
    {
        auto result = gcc_jit_function_new_block(get_function(), null);
        return Block(result);
    }

    /// Ditto
    Block new_block(string name) nothrow @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_function_new_block(get_function(), n.ptr));
        return Block(result);
    }

    /// Create a new local variable.
    LValue new_local(Location loc, Type type, string name) nothrow @nogc
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_function_new_local(get_function(),
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
        auto result = gcc_jit_function_get_address(get_function(), loc.get_location());
        return RValue(result);
    }

    /// Get the return type of the function.
    Type get_return_type() nothrow @nogc
    {
        auto result = gcc_jit_function_get_return_type(get_function());
        return Type(result);
    }

    /// Get the number of parameters of the function.
    size_t get_param_count() nothrow @nogc
    {
        return gcc_jit_function_get_param_count(get_function());
    }

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
    LValue __super;
    alias __super this;

    ///
    this(gcc_jit_param* param) nothrow @nogc
    {
        __super = LValue(gcc_jit_param_as_lvalue(param));
    }

    /// Returns the internal gcc_jit_param object.
    gcc_jit_param* get_param() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_param *)get_object();
    }
}
