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

import gccjit.bindings;
import gccjit.exception;
import gccjit.helpers;

/// Struct wrapper for gcc_jit_result
struct CompileResult
{
    ///
    this(gcc_jit_result* result) @nogc
    {
        if (!result)
            throw staticException!JitException("Unknown error, got bad result");
        __impl = result;
    }

    /// Returns the internal gcc_jit_result object.
    gcc_jit_result* get_result() pure nothrow @nogc
    {
        return __impl;
    }

    /// Locate a given function within the built machine code.
    /// This will need to be cast to a function pointer of the correct type
    /// before it can be called.
    void* get_code(string name) nothrow @nogc
    {
        return name.toCStringThen!((n)
            => gcc_jit_result_get_code(__impl, n.ptr));
    }

    /// Locate a given global within the built machine code.
    /// It must have been created using GlobalKind.EXPORTED.
    /// This returns is a pointer to the global.
    void* get_global(string name) nothrow @nogc
    {
        return name.toCStringThen!((n)
            => gcc_jit_result_get_global(__impl, n.ptr));
    }

    /// Once we're done with the code, this unloads the built .so file.
    /// After this call, it's no longer valid to use this JIT.CompileResult.
    void release() nothrow @nogc
    {
        gcc_jit_result_release(__impl);
    }

private:
    gcc_jit_result* __impl = null;
}
