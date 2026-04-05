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

module gccjit.types;

import gccjit.bindings;
import gccjit.decls;
import gccjit.location;
import gccjit.object;

/// Types can be created in several ways:
/// $(UL
///     $(LI Fundamental types can be accessed using JIT.Context.get_type())
///     $(LI Derived types can be accessed by calling methods on an existing type.)
///     $(LI By creating structures via JIT.Struct.)
/// )
struct Type
{
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_type* type) @nogc
    {
        __super = JitObject(gcc_jit_type_as_object(type));
    }

    /// Returns the internal gcc_jit_type object.
    gcc_jit_type* get_type() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_type *)get_object();
    }

    /// Given type T, get type T*.
    Type get_pointer() @nogc
    {
        auto result = gcc_jit_type_get_pointer(get_type());
        return Type(result);
    }

    /// Given type T, get type const T.
    Type get_const() @nogc
    {
        auto result = gcc_jit_type_get_const(get_type());
        return Type(result);
    }

    /// Given type T, get type volatile T.
    Type get_volatile() @nogc
    {
        auto result = gcc_jit_type_get_volatile(get_type());
        return Type(result);
    }

    /// Given type T, get type T __attribute__((aligned(alignment_in_bytes))).
    Type get_aligned(size_t alignment_in_bytes) @nogc
    {
        auto result = gcc_jit_type_get_aligned(get_type(), alignment_in_bytes);
        return Type(result);
    }

    /// Given type T, get type T __attribute__((vector_size(sizeof(T) * num_units))).
    Type get_vector(size_t num_units) @nogc
    {
        auto result = gcc_jit_type_get_vector(get_type(), num_units);
        return Type(result);
    }
}

/// You can model C struct types by creating JIT.Struct and JIT.Field
/// instances, in either order:
/// $(UL
///     $(LI By creating the fields, then the structure.)
///     $(LI By creating the structure, then populating it with fields,
///          typically to allow modelling self-referential structs.)
/// )
struct Struct
{
    Type __super;
    alias __super this;

    ///
    this(gcc_jit_struct* agg) @nogc
    {
        __super = Type(gcc_jit_struct_as_type(agg));
    }

    /// Returns the internal gcc_jit_struct object.
    gcc_jit_struct* get_struct() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_struct *)get_object();
    }

    /// Populate the fields of a formerly-opaque struct type.
    /// This can only be called once on a given struct type.
    void set_fields(Location loc, Field[] fields...) nothrow @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        gcc_jit_struct_set_fields(get_struct(), loc.get_location(),
                                  cast(int)fields.length,
                                  cast(gcc_jit_field**)fields.ptr);
    }

    /// Ditto
    void set_fields(Field[] fields...) nothrow @nogc
    { set_fields(Location(), fields); }
}
