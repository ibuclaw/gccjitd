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

module gccjit.object;

package(gccjit):

import gccjit.bindings;
import gccjit.context;
import gccjit.helpers;

/// Struct wrapper for gcc_jit_object.
/// All JitObjects's are created within a JIT.Context, and are automatically
/// cleaned up when the context is released.

/// The struct hierachy looks like this:
///  $(OL - JitObject
///      $(OL - Location)
///      $(OL - Type
///         $(OL - Struct)
///         $(OL - FunctionPtrType)
///         $(OL - VectorType))
///      $(OL - Field)
///      $(OL - Function)
///      $(OL - Block)
///      $(OL - RValue
///          $(OL - LValue
///              $(OL - Parameter)))
///      $(OL - Case)
///      $(OL - ExtendedAsm))
struct JitObject
{
    /// Return the context this JitObject is within.
    Context get_context() nothrow @nogc
    {
        auto result = gcc_jit_object_get_context(m_object);
        return Context(result);
    }

    /// Get a human-readable description of this object.
    string toString() nothrow @nogc
    {
        return gcc_jit_object_get_debug_string(m_object).toDString();
    }

    /// Returns true if this JitObject has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_object !is null;
    }

package(gccjit):
    // Constructors and get_object are hidden from public.
    this(gcc_jit_object* obj) pure nothrow @nogc
    {
        m_object = obj;
    }

    inout(gcc_jit_object)* get_object() inout pure nothrow @nogc
    {
        return m_object;
    }

private:
    // The actual gccjit object we interface with.
    gcc_jit_object* m_object = null;
}
