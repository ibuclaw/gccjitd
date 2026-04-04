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

import gccjit.bindings;
import gccjit.context;
import gccjit.exception;
import gccjit.helpers;

/// Struct wrapper for gcc_jit_object.
/// All JitObjects's are created within a JIT.Context, and are automatically
/// cleaned up when the context is released.

/// The struct hierachy looks like this:
///  $(OL - JitObject
///      $(OL - Location)
///      $(OL - Type
///         $(OL - Struct))
///      $(OL - Field)
///      $(OL - Function)
///      $(OL - Block)
///      $(OL - RValue
///          $(OL - LValue
///              $(OL - Parameter)))
///      $(OL - Case))
struct JitObject
{
    /// Return the context this JitObject is within.
    Context get_context() @nogc
    {
        auto result = gcc_jit_object_get_context(__impl);
        return Context(result);
    }

    /// Get a human-readable description of this object.
    string toString() nothrow @nogc
    {
        return gcc_jit_object_get_debug_string(__impl).toDString();
    }

    /// Returns true if this JitObject has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return __impl !is null;
    }

    /// Prevents `opCast` from disabling built-in conversions.
    auto ref T opCast(T, this This)() const nothrow @nogc
    if (is(This : T) || This.sizeof == T.sizeof)
    {
        static if (is(This : T))
            // Implicit conversion
            return this;
        else
            // Reinterpret - relaxed about up/down casting for now
            return *cast(T*) &this;
    }

package(gccjit):
    // Constructors and get_object are hidden from public.
    this(gcc_jit_object* obj) @nogc
    {
        if (!obj)
            throw staticException!JitException("Unknown error, got bad object");
        __impl = obj;
    }

    gcc_jit_object* get_object() pure nothrow @nogc
    {
        return __impl;
    }

private:
    // The actual gccjit object we interface with.
    gcc_jit_object* __impl = null;
}
