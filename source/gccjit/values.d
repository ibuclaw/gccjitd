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

module gccjit.values;

import gccjit.bindings;
import gccjit.decls;
import gccjit.exception;
import gccjit.flags;
import gccjit.helpers;
import gccjit.location;
import gccjit.object;
import gccjit.types;

/// Struct wrapper for gcc_jit_rvalue
struct RValue
{
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_rvalue* rvalue) @nogc
    {
        if (!rvalue)
        {
            version (D_Exceptions)
                throw staticException!JitException(ErrorBadRValue);
            else
                abort!ErrorBadRValue();
        }
        __super = JitObject(gcc_jit_rvalue_as_object(rvalue));
    }

    /// Returns the internal gcc_jit_rvalue object.
    gcc_jit_rvalue* get_rvalue() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_rvalue *)get_object();
    }

    /// Returns the JIT.Type of the rvalue.
    Type get_type() @nogc
    {
        auto result = gcc_jit_rvalue_get_type(get_rvalue());
        return Type(result);
    }

    /// Accessing a field of an rvalue of struct type.
    /// This is equivalent to "(value).field".
    RValue access_field(Location loc, Field field) @nogc
    {
        auto result = gcc_jit_rvalue_access_field(get_rvalue(),
                                                  loc.get_location(),
                                                  field.get_field());
        return RValue(result);
    }

    /// Ditto
    RValue access_field(Field field) @nogc
    { return access_field(Location(), field); }

    /// Accessing a field of an rvalue of pointer type.
    /// This is equivalent to "(*value).field".
    LValue dereference_field(Location loc, Field field) @nogc
    {
        auto result = gcc_jit_rvalue_dereference_field(get_rvalue(),
                                                       loc.get_location(),
                                                       field.get_field());
        return LValue(result);
    }

    /// Ditto
    LValue dereference_field(Field field) @nogc
    { return dereference_field(Location(), field); }

    /// Dereferencing an rvalue of pointer type.
    /// This is equivalent to "*(value)".
    LValue dereference(Location loc = Location()) @nogc
    {
        auto result = gcc_jit_rvalue_dereference(get_rvalue(),
                                                 loc.get_location());
        return LValue(result);
    }

    /// Convert an rvalue to the given JIT.Type.  See JIT.Context.new_cast for
    /// limitations.
    RValue cast_to(Location loc, Type type) @nogc
    {
        return get_context().new_cast(loc, this, type);
    }

    /// Ditto
    RValue cast_to(Type type) @nogc
    { return cast_to(Location(), type); }

    /// Ditto
    RValue cast_to(Location loc, CType kind) @nogc
    { return cast_to(loc, get_context().get_type(kind)); }

    /// Ditto
    RValue cast_to(CType kind) @nogc
    { return cast_to(Location(), get_context().get_type(kind)); }

    /// Given a JIT.RValue for a call created through JIT.Context.new_call,
    /// mark/clear the call as needing tail-call optimization.
    void set_require_tail_call(bool require_tail_call) nothrow @nogc @property
    { gcc_jit_rvalue_set_bool_require_tail_call(get_rvalue(), require_tail_call); }

    /// Overloaded operators, for those who want the most terse API
    /// (at the possible risk of being a little too magical).

    /// In each case, the "this" parameter is used to determine which context
    /// owns the resulting expression, and, where appropriate,  what the
    /// latter's type is.

    /// Array access.
    LValue opIndex(RValue index)
    { return get_context().new_array_access(this, index); }

    /// Ditto
    LValue opIndex(int index)
    { with (get_context())
        return new_array_access(this, new_rvalue(get_int_type!int, index)); }

    /// Unary operators.

    ///
    RValue opUnary(string op : "-")()
    { return get_context().new_minus(get_type(), this); }

    ///
    RValue opUnary(string op : "~")()
    { return get_context().new_bitwise_negate(get_type(), this); }

    /// Binary operators

    ///
    RValue opBinary(string op : "+")(RValue b)
    { return get_context().new_plus(get_type(), this, b); }

    ///
    RValue opBinary(string op : "-")(RValue b)
    { return get_context().new_minus(get_type(), this, b); }

    ///
    RValue opBinary(string op : "*")(RValue b)
    { return get_context().new_mult(get_type(), this, b); }

    ///
    RValue opBinary(string op : "/")(RValue b)
    { return get_context().new_divide(get_type(), this, b); }

    ///
    RValue opBinary(string op : "%")(RValue b)
    { return get_context().new_modulo(get_type(), this, b); }

    ///
    RValue opBinary(string op : "&")(RValue b)
    { return get_context().new_bitwise_and(get_type(), this, b); }

    ///
    RValue opBinary(string op : "^")(RValue b)
    { return get_context().new_bitwise_xor(get_type(), this, b); }

    ///
    RValue opBinary(string op : "|")(RValue b)
    { return get_context().new_bitwise_or(get_type(), this, b); }

    ///
    RValue opBinary(string op : "<<")(RValue b)
    { return get_context().new_lshift(get_type(), this, b); }

    ///
    RValue opBinary(string op : ">>")(RValue b)
    { return get_context().new_rshift(get_type(), this, b); }

    /// Dereferencing
    LValue opUnary(string op : "*")()
    { return dereference(); }
}

/// Struct wrapper for gcc_jit_lvalue
struct LValue
{
    RValue __super;
    alias __super this;

    ///
    this(gcc_jit_lvalue* lvalue) @nogc
    {
        if (!lvalue)
        {
            version (D_Exceptions)
                throw staticException!JitException(ErrorBadLValue);
            else
                abort!ErrorBadLValue();
        }
        __super = RValue(gcc_jit_lvalue_as_rvalue(lvalue));
    }

    /// Returns the internal gcc_jit_lvalue object.
    gcc_jit_lvalue* get_lvalue() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_lvalue *)get_object();
    }

    /// Accessing a field of an lvalue of struct type.
    /// This is equivalent to "(value).field = ...".
    LValue access_field(Location loc, Field field) @nogc
    {
        auto result = gcc_jit_lvalue_access_field(get_lvalue(),
                                                  loc.get_location(),
                                                  field.get_field());
        return LValue(result);
    }

    /// Ditto
    LValue access_field(Field field) @nogc
    { return access_field(Location(), field); }

    /// Taking the address of an lvalue.
    /// This is equivalent to "&(value)".
    RValue get_address(Location loc = Location()) @nogc
    {
        auto result = gcc_jit_lvalue_get_address(get_lvalue(),
                                                 loc.get_location());
        return RValue(result);
    }
}
