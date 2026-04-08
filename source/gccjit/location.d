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

package(gccjit):

import gccjit.bindings;
import gccjit.object;

/// Struct wrapper for gcc_jit_location.
/// A jit_location encapsulates a source code locations, so that you can associate
/// locations in your language with statements in the JIT-compiled code.
struct Location
{
    union
    {
        private gcc_jit_location* m_location = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_location* loc) pure nothrow @nogc
    {
        m_location = loc;
    }

    /// Returns the internal gcc_jit_location object.
    inout(gcc_jit_location)* get_location() inout pure nothrow @nogc
    {
        return m_location;
    }

    /// Returns true if this JIT.Location has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_location !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_location_as_object(cast(gcc_jit_location*)m_location);
        return typeof(return)(result);
    }
}
