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

package(gccjit):

import gccjit.bindings;
import gccjit.decls;
import gccjit.flags;
import gccjit.helpers;
import gccjit.location;
import gccjit.object;
import gccjit.types;

/// Struct wrapper for gcc_jit_rvalue
struct RValue
{
    union
    {
        private gcc_jit_rvalue* m_rvalue = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_rvalue* rvalue) pure nothrow @nogc
    {
        m_rvalue = rvalue;
    }

    /// Returns the internal gcc_jit_rvalue object.
    inout(gcc_jit_rvalue)* get_rvalue() inout pure nothrow @nogc
    {
        return m_rvalue;
    }

    /// Returns true if this JIT.RValue has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_rvalue !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_rvalue_as_object(cast(gcc_jit_rvalue*)m_rvalue);
        return typeof(return)(result);
    }

    /// Returns the JIT.Type of the rvalue.
    Type get_type() nothrow @nogc
    {
        auto result = gcc_jit_rvalue_get_type(m_rvalue);
        return Type(result);
    }

    /// Accessing a field of an rvalue of struct type.
    /// This is equivalent to "(value).field".
    RValue access_field(Location loc, Field field) nothrow @nogc
    {
        auto result = gcc_jit_rvalue_access_field(m_rvalue,
                                                  loc.get_location(),
                                                  field.get_field());
        return RValue(result);
    }

    /// Ditto
    RValue access_field(Field field) nothrow @nogc
    { return access_field(Location(), field); }

    /// Accessing a field of an rvalue of pointer type.
    /// This is equivalent to "(*value).field".
    LValue dereference_field(Location loc, Field field) nothrow @nogc
    {
        auto result = gcc_jit_rvalue_dereference_field(m_rvalue,
                                                       loc.get_location(),
                                                       field.get_field());
        return LValue(result);
    }

    /// Ditto
    LValue dereference_field(Field field) nothrow @nogc
    { return dereference_field(Location(), field); }

    /// Dereferencing an rvalue of pointer type.
    /// This is equivalent to "*(value)".
    LValue dereference(Location loc = Location()) nothrow @nogc
    {
        auto result = gcc_jit_rvalue_dereference(m_rvalue,
                                                 loc.get_location());
        return LValue(result);
    }

    /// Convert an rvalue to the given JIT.Type.  See JIT.Context.new_cast for
    /// limitations.
    RValue cast_to(Location loc, Type type) nothrow @nogc
    {
        return get_context().new_cast(loc, this, type);
    }

    /// Ditto
    RValue cast_to(Type type) nothrow @nogc
    { return cast_to(Location(), type); }

    /// Ditto
    RValue cast_to(Location loc, CType kind) nothrow @nogc
    { return cast_to(loc, get_context().get_type(kind)); }

    /// Ditto
    RValue cast_to(CType kind) nothrow @nogc
    { return cast_to(Location(), get_context().get_type(kind)); }

    /// Given a JIT.RValue for a call created through JIT.Context.new_call,
    /// mark/clear the call as needing tail-call optimization.
    RValue set_require_tail_call(bool require_tail_call) return nothrow @nogc @property
    {
        gcc_jit_rvalue_set_bool_require_tail_call(m_rvalue, require_tail_call);
        return this;
    }

    /// Overloaded operators, for those who want the most terse API
    /// (at the possible risk of being a little too magical).

    /// In each case, the "this" parameter is used to determine which context
    /// owns the resulting expression, and, where appropriate,  what the
    /// latter's type is.

    /// Array access.
    LValue opIndex(RValue index) nothrow @nogc
    { return get_context().new_array_access(this, index); }

    /// Ditto
    LValue opIndex(int index) nothrow @nogc
    { with (get_context())
        return new_array_access(this, new_rvalue(get_int_type!int, index)); }

    /// Unary operators.

    ///
    RValue opUnary(string op : "-")() nothrow @nogc
    { return get_context().new_minus(get_type(), this); }

    ///
    RValue opUnary(string op : "~")() nothrow @nogc
    { return get_context().new_bitwise_negate(get_type(), this); }

    /// Binary operators

    ///
    RValue opBinary(string op : "+")(RValue b) nothrow @nogc
    { return get_context().new_plus(get_type(), this, b); }

    ///
    RValue opBinary(string op : "-")(RValue b) nothrow @nogc
    { return get_context().new_minus(get_type(), this, b); }

    ///
    RValue opBinary(string op : "*")(RValue b) nothrow @nogc
    { return get_context().new_mult(get_type(), this, b); }

    ///
    RValue opBinary(string op : "/")(RValue b) nothrow @nogc
    { return get_context().new_divide(get_type(), this, b); }

    ///
    RValue opBinary(string op : "%")(RValue b) nothrow @nogc
    { return get_context().new_modulo(get_type(), this, b); }

    ///
    RValue opBinary(string op : "&")(RValue b) nothrow @nogc
    { return get_context().new_bitwise_and(get_type(), this, b); }

    ///
    RValue opBinary(string op : "^")(RValue b) nothrow @nogc
    { return get_context().new_bitwise_xor(get_type(), this, b); }

    ///
    RValue opBinary(string op : "|")(RValue b) nothrow @nogc
    { return get_context().new_bitwise_or(get_type(), this, b); }

    ///
    RValue opBinary(string op : "<<")(RValue b) nothrow @nogc
    { return get_context().new_lshift(get_type(), this, b); }

    ///
    RValue opBinary(string op : ">>")(RValue b) nothrow @nogc
    { return get_context().new_rshift(get_type(), this, b); }

    /// Dereferencing
    LValue opUnary(string op : "*")() nothrow @nogc
    { return dereference(); }
}

/// Struct wrapper for gcc_jit_lvalue
struct LValue
{
    union
    {
        private gcc_jit_lvalue* m_lvalue = null;
        RValue m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_lvalue* lvalue) pure nothrow @nogc
    {
        m_lvalue = lvalue;
    }

    /// Returns the internal gcc_jit_lvalue object.
    inout(gcc_jit_lvalue)* get_lvalue() inout pure nothrow @nogc
    {
        return m_lvalue;
    }

    /// Returns true if this JIT.LValue has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_lvalue !is null;
    }

    /// Upcast to the parent JIT.RValue.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == RValue))
    {
        auto result = gcc_jit_lvalue_as_rvalue(cast(gcc_jit_lvalue*)m_lvalue);
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_lvalue_as_object(cast(gcc_jit_lvalue*)m_lvalue);
        return typeof(return)(result);
    }

    /// Accessing a field of an lvalue of struct type.
    /// This is equivalent to "(value).field = ...".
    LValue access_field(Location loc, Field field) nothrow @nogc
    {
        auto result = gcc_jit_lvalue_access_field(m_lvalue,
                                                  loc.get_location(),
                                                  field.get_field());
        return LValue(result);
    }

    /// Ditto
    LValue access_field(Field field) nothrow @nogc
    { return access_field(Location(), field); }

    /// Taking the address of an lvalue.
    /// This is equivalent to "&(value)".
    RValue get_address(Location loc = Location()) nothrow @nogc
    {
        auto result = gcc_jit_lvalue_get_address(m_lvalue, loc.get_location());
        return RValue(result);
    }

    /// Set an initial value for a global.
    LValue set_initializer(scope const void* blob, size_t num_bytes) return nothrow @nogc
    {
        gcc_jit_global_set_initializer(m_lvalue, blob, num_bytes);
        return this;
    }

    /// Ditto
    LValue set_initializer(RValue init_value) nothrow @nogc
    {
        auto result = gcc_jit_global_set_initializer_rvalue(m_lvalue, init_value.get_rvalue());
        return LValue(result);
    }

    /// Set the TLS model of a global variable.
    LValue set_tls_model(TlsModel model) return nothrow @nogc
    {
        gcc_jit_lvalue_set_tls_model(m_lvalue, model);
        return this;
    }

    /// Set the link section name of a global variable.
    LValue set_link_section(string section_name) return nothrow @nogc
    {
        section_name.toCStringThen!((s)
            => gcc_jit_lvalue_set_link_section(m_lvalue, s.ptr));
        return this;
    }

    /// Set register name of a local variable.
    LValue set_register_name(string reg_name) return nothrow @nogc
    {
        reg_name.toCStringThen!((r)
            => gcc_jit_lvalue_set_register_name(m_lvalue, r.ptr));
        return this;
    }

    /// Set the alignment of a variable.
    LValue set_alignment(uint bytes) return nothrow @nogc @property
    {
        gcc_jit_lvalue_set_alignment(m_lvalue, bytes);
        return this;
    }

    /// Get the alignment of a variable
    uint get_alignment() nothrow @nogc
    { return gcc_jit_lvalue_get_alignment(m_lvalue); }

    /// Add an attribute to a variable.
    LValue add_attribute(VarAttribute attribute, string value) return nothrow @nogc
    {
        value.toCStringThen!((v)
            => gcc_jit_lvalue_add_string_attribute(m_lvalue, attribute, v.ptr));
        return this;
    }
}
