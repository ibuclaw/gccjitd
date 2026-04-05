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

module gccjit;

import gccjit.bindings;

/// D API
struct JIT
{
    import gccjit.exception;
    ///
    alias Exception = JitException;

    import gccjit.object;
    ///
    alias Object = JitObject;

    import gccjit.location;
    ///
    alias Location = gccjit.location.Location;

    import gccjit.context;
    ///
    alias Context = gccjit.context.Context;

    import gccjit.decls;
    ///
    alias Field = gccjit.decls.Field;
    ///
    alias Function = gccjit.decls.Function;
    ///
    alias Parameter = gccjit.decls.Parameter;

    import gccjit.types;
    ///
    alias Type = gccjit.types.Type;
    ///
    alias Struct = gccjit.types.Struct;

    import gccjit.block;
    ///
    alias Block = gccjit.block.Block;

    import gccjit.values;
    ///
    alias RValue = gccjit.values.RValue;
    ///
    alias LValue = gccjit.values.LValue;

    import gccjit.compile;
    ///
    alias CompileResult = gccjit.compile.CompileResult;

    import gccjit.timer;
    ///
    alias Timer = gccjit.timer.Timer;
    ///
    alias AutoTime = gccjit.timer.AutoTime;
}

public import gccjit.flags;
