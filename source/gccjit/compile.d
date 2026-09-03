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

module gccjit.compile;

package(gccjit):

import gccjit.bindings;
import gccjit.helpers;

/// Struct wrapper for gcc_jit_result
struct CompileResult
{
    /// Returns true if this JIT.CompileResult has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_result !is null;
    }

    /// Locate a given function within the built machine code.
    /// If the function does not exist in the CompileResult, this function will
    /// return a "null" pointer.
    /// It is the responsibility of the caller to check the pointer is not
    /// "null", and ensure that it is not used past the lifetime of the
    /// CompileResult object.
    T get_code(T)(string name) nothrow @nogc
        if (is(T U : U*) && is(U == function))
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_result_get_code(m_result, n.ptr));
        return cast(T)result;
    }

    /// Locate a given global within the built machine code.
    /// It must have been created using GlobalKind.EXPORTED.
    /// This returns is a pointer to the global.
    /// It is the responsibility of the caller to check the pointer is not
    /// "null", and ensure that it is not used past the lifetime of the
    /// CompileResult object.
    T* get_global(T)(string name) nothrow @nogc
        if (is(T))
    {
        auto result = name.toCStringThen!((n)
            => gcc_jit_result_get_global(m_result, n.ptr));
        return cast(T*)result;
    }

    /// Once we're done with the code, this unloads the built .so file.
    /// After this call, it's no longer valid to use this JIT.CompileResult.
    void release() nothrow @nogc
    {
        gcc_jit_result_release(m_result);
        m_result = null;
    }

package(gccjit):
    // Constructors and get_result are hidden from public.
    this(gcc_jit_result* result) pure nothrow @nogc
    {
        m_result = result;
    }

    inout(gcc_jit_result)* get_result() inout pure nothrow @nogc
    {
        return m_result;
    }

private:
    gcc_jit_result* m_result = null;
}
