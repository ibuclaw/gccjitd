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

module gccjit.location;

import gccjit.bindings;
import gccjit.object;

/// Struct wrapper for gcc_jit_location.
/// A jit_location encapsulates a source code locations, so that you can associate
/// locations in your language with statements in the JIT-compiled code.
struct Location
{
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_location* loc) nothrow @nogc
    {
        __super = JitObject(gcc_jit_location_as_object(loc));
    }

    /// Returns the internal gcc_jit_location object.
    gcc_jit_location* get_location() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_location *)get_object();
    }
}
