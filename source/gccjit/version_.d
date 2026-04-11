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

module gccjit.version_;

package(gccjit):

import gccjit.bindings;

/// Struct wrapper for gcc_jit_version API
/// This API endpoint was added in LIBGCCJIT_ABI_13; you can test for
/// its presence using `if (JIT.Have_Version)`.
struct Version
{
    ///
    static int major() @property
    {
        return gcc_jit_version_major();
    }

    ///
    static int minor() @property
    {
        return gcc_jit_version_minor();
    }

    ///
    static int patchlevel() @property
    {
        return gcc_jit_version_patchlevel();
    }

    // Disallow construction and copying.
    @disable this();
    @disable this(ref const Version);
    @disable this(this);
}
