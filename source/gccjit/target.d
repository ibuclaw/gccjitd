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

module gccjit.target;

import gccjit.bindings;
import gccjit.flags;
import gccjit.helpers;

package(gccjit):

/// Struct wrapper for gcc_jit_target_info
/// This API endpoint was added in LIBGCCJIT_ABI_35; you can test for
/// its presence using `if (JIT.Have_TargetInfo_API)`.
struct TargetInfo
{
    /// Returns true if this JIT.TargetInfo has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_target_info !is null;
    }

    /// Release a JIT.TargetInfo instance.
    void release() nothrow @nogc
    {
        gcc_jit_target_info_release(m_target_info);
        m_target_info = null;
    }

    /// Returns true if `feature` is supported by the specified target.
    bool cpu_supports(string feature) nothrow @nogc
    {
        auto result = feature.toCStringThen!((p)
            => gcc_jit_target_info_cpu_supports(m_target_info, p.ptr));
        return !!result;
    }

    string arch() nothrow @nogc
    {
        return gcc_jit_target_info_arch(m_target_info).toDString();
    }

    /// Returns true if the target natively supports the target-dependent `type`.
    bool supports_type(CType type) nothrow @nogc
    {
        auto result = gcc_jit_target_info_supports_target_dependent_type(m_target_info,
                                                                         type);
        return !!result;
    }

package(gccjit):
    // Constructors and get_target_info are hidden from public.
    this(gcc_jit_target_info* target_info) pure nothrow @nogc
    {
        m_target_info = target_info;
    }

    inout(gcc_jit_target_info)* get_target_info() inout pure nothrow @nogc
    {
        return m_target_info;
    }

private:
    gcc_jit_target_info* m_target_info = null;
}
