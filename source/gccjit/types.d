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

package(gccjit):

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
    union
    {
        private gcc_jit_type* m_type = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_type* type) pure nothrow @nogc
    {
        m_type = type;
    }

    /// Returns the internal gcc_jit_type object.
    inout(gcc_jit_type)* get_type() inout pure nothrow @nogc
    {
        return m_type;
    }

    /// Returns true if this JIT.Type has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_type !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_type_as_object(cast(gcc_jit_type*)m_type);
        return typeof(return)(result);
    }

    /// Downcast to the child JIT.FunctionPtrType.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == FunctionPtrType))
    {
        auto result = gcc_jit_type_dyncast_function_ptr_type(cast(gcc_jit_type*)m_type);
        return typeof(return)(result);
    }

    /// Downcast to the child JIT.VectorType.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == VectorType))
    {
        auto result = gcc_jit_type_dyncast_vector(cast(gcc_jit_type*)m_type);
        return typeof(return)(result);
    }

    /// Given type T, get type T*.
    Type get_pointer() nothrow @nogc
    {
        auto result = gcc_jit_type_get_pointer(m_type);
        return Type(result);
    }

    /// Given type T, get type const T.
    Type get_const() nothrow @nogc
    {
        auto result = gcc_jit_type_get_const(m_type);
        return Type(result);
    }

    /// Given type T, get type volatile T.
    Type get_volatile() nothrow @nogc
    {
        auto result = gcc_jit_type_get_volatile(m_type);
        return Type(result);
    }

    /// Given type T, get type T __attribute__((aligned(alignment_in_bytes))).
    Type get_aligned(size_t alignment_in_bytes) nothrow @nogc
    {
        auto result = gcc_jit_type_get_aligned(m_type, alignment_in_bytes);
        return Type(result);
    }

    /// Given type T, get type T __attribute__((vector_size(sizeof(T) * num_units))).
    Type get_vector(size_t num_units) nothrow @nogc
    {
        auto result = gcc_jit_type_get_vector(m_type, num_units);
        return Type(result);
    }

    /// Given type T, get type restrict T.
    Type get_restrict() nothrow @nogc
    {
        auto result = gcc_jit_type_get_restrict(m_type);
        return Type(result);
    }

    /// Returns true if the given JIT.Type is compatible with this JIT.Type.
    bool is_compatible_with(Type type) nothrow @nogc
    {
        return !!gcc_jit_compatible_types(m_type, type.get_type());
    }

    /// Returns the size of this JIT.Type.
    size_t get_size() nothrow @nogc
    {
        return gcc_jit_type_get_size(m_type);
    }

    /// Return the element type of an array or null if it's not an array.
    Type dyncast_array() nothrow @nogc
    {
        auto result = gcc_jit_type_dyncast_array(m_type);
        return result ? Type(result) : Type();
    }

    /// Returns true if the type is a bool.
    bool is_bool() nothrow @nogc
    {
        return !!gcc_jit_type_is_bool(m_type);
    }

    /// Return the JIT.FunctionPtrType if it is one or null.
    FunctionPtrType dyncast_function_ptr_type() nothrow @nogc
    {
        auto result = gcc_jit_type_dyncast_function_ptr_type(m_type);
        return FunctionPtrType(result);
    }

    /// Returns true if the type is integral.
    bool is_integral() nothrow @nogc
    {
        return !!gcc_jit_type_is_integral(m_type);
    }

    /// Returns the type pointer by the pointer type or null if it's not a pointer.
    Type get_pointee() nothrow @nogc
    {
        auto result = gcc_jit_type_is_pointer(m_type);
        return result ? Type(result) : Type();
    }

    /// Return the JIT.VectorType if it is one or null.
    VectorType dyncast_vector() nothrow @nogc
    {
        auto result = gcc_jit_type_dyncast_vector(m_type);
        return VectorType(result);
    }

    /// Return the JIT.Struct if it is one or null.
    Struct is_struct() nothrow @nogc
    {
        auto result = gcc_jit_type_is_struct(m_type);
        return result ? Struct(result) : Struct();
    }

    /// Return the unqualified type of this JIT.Type, removing `const`, `volatile`,
    /// and alignment qualifiers.
    Type unqualified() nothrow @nogc
    {
        auto result = gcc_jit_type_unqualified(m_type);
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
    union
    {
        private gcc_jit_struct* m_struct = null;
        Type m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_struct* agg) pure nothrow @nogc
    {
        m_struct = agg;
    }

    /// Returns the internal gcc_jit_struct object.
    inout(gcc_jit_struct)* get_struct() inout pure nothrow @nogc
    {
        return m_struct;
    }

    /// Returns true if this JIT.Struct has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_struct !is null;
    }

    /// Upcast to the parent JIT.Type.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == Type))
    {
        auto result = gcc_jit_struct_as_type(cast(gcc_jit_struct*)m_struct);
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = cast(gcc_jit_object*)get_object();
        return typeof(return)(result);
    }

    /// Populate the fields of a formerly-opaque struct type.
    /// This can only be called once on a given struct type.
    Struct set_fields(Location loc, Field[] fields) return nothrow @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        gcc_jit_struct_set_fields(m_struct, loc.get_location(),
                                  cast(int)fields.length,
                                  cast(gcc_jit_field**)fields.ptr);
        return this;
    }

    /// Ditto
    Struct set_fields(Field[] fields) return nothrow @nogc
    { return set_fields(Location(), fields); }

    /// Ditto
    Struct set_fields(Location loc, Field[] fields...) return nothrow @nogc
    { return set_fields(loc, fields); }

    /// Ditto
    Struct set_fields(Field[] fields...) return nothrow @nogc
    { return set_fields(Location(), fields); }

    /// Get a field by index.
    Field get_field(size_t index) nothrow @nogc
    {
        auto result = gcc_jit_struct_get_field(m_struct, index);
        return Field(result);
    }

    /// Get the number of fields.
    size_t get_field_count() nothrow @nogc
    {
        return gcc_jit_struct_get_field_count(m_struct);
    }
}

/// Function Types can be created using JIT.Context.new_function_type().
/// To get an instance of FunctionPtrType use JIT.Type.dyncast_function_ptr_type().
struct FunctionPtrType
{
    union
    {
        private gcc_jit_function_type* m_function_type = null;
        Type m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_function_type* function_type) pure nothrow @nogc
    {
        m_function_type = function_type;
    }

    /// Returns the internal gcc_jit_function_type object.
    inout(gcc_jit_function_type)* get_function_type() inout pure nothrow @nogc
    {
        return m_function_type;
    }

    /// Returns true if this JIT.FunctionPtrType has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_function_type !is null;
    }

    /// Upcast to the parent JIT.Type.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == Type))
    {
        auto result = cast(gcc_jit_type*)m_super.get_type();
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = cast(gcc_jit_object*)get_object();
        return typeof(return)(result);
    }

    /// Get function return type.
    Type get_return_type() nothrow @nogc
    {
        auto result = gcc_jit_function_type_get_return_type(m_function_type);
        return Type(result);
    }

    /// Get the number of parameters of the function type.
    size_t get_param_count() nothrow @nogc
    {
        return gcc_jit_function_type_get_param_count(m_function_type);
    }

    /// Get a parameter type by index.
    Type get_param_type(size_t index) nothrow @nogc
    {
        auto result = gcc_jit_function_type_get_param_type(m_function_type, index);
        return Type(result);
    }
}

/// Vector Types can be created using JIT.Type.get_vector().
/// To get an instance of VectorType use JIT.Type.dyncast_vector().
struct VectorType
{
    union
    {
        private gcc_jit_vector_type* m_vector_type = null;
        Type m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_vector_type* vector_type) pure nothrow @nogc
    {
        m_vector_type = vector_type;
    }

    /// Returns the internal gcc_jit_vector_type object.
    inout(gcc_jit_vector_type)* get_vector_type() inout pure nothrow @nogc
    {
        return m_vector_type;
    }

    /// Returns true if this JIT.VectorType has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_vector_type !is null;
    }

    /// Upcast to the parent JIT.Type.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == Type))
    {
        auto result = cast(gcc_jit_type*)m_super.get_type();
        return typeof(return)(result);
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = cast(gcc_jit_object*)get_object();
        return typeof(return)(result);
    }

    /// Return number of units contained in this JIT.VectorType.
    size_t get_num_units() nothrow @nogc
    {
        return gcc_jit_vector_type_get_num_units(m_vector_type);
    }

    /// Return the element type of this JIT.VectorType.
    Type get_element_type() nothrow @nogc
    {
        auto result = gcc_jit_vector_type_get_element_type(m_vector_type);
        return Type(result);
    }
}
