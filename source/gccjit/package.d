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

public import gccjit.bindings;

/// D API
struct JIT
{
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
    ///
    alias FunctionPtrType = gccjit.types.FunctionPtrType;
    ///
    alias VectorType = gccjit.types.VectorType;

    import gccjit.block;
    ///
    alias Block = gccjit.block.Block;
    ///
    alias Case = gccjit.block.Case;
    ///
    alias ExtendedAsm = gccjit.block.ExtendedAsm;

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

    import gccjit.version_;
    ///
    alias Version = gccjit.version_.Version;

    /// Feature flags to indicate the presense of libgccjit
    /// functions or API linked into this library.
    pure nothrow @nogc:

    ///
    static bool Have_Context_add_command_line_option()
    { return LIBGCCJIT_ABI >= 1; }

    ///
    static bool Have_Context_set_allow_unreachable_blocks()
    { return LIBGCCJIT_ABI >= 2; }

    ///
    static bool Have_Switch_Statements()
    { return LIBGCCJIT_ABI >= 3; }

    ///
    static bool Have_Timing_API()
    { return LIBGCCJIT_ABI >= 4; }

    ///
    static bool Have_Context_set_use_external_driver()
    { return LIBGCCJIT_ABI >= 5; }

    ///
    static bool Have_RValue_set_require_tail_call()
    { return LIBGCCJIT_ABI >= 6; }

    ///
    static bool Have_Type_get_aligned()
    { return LIBGCCJIT_ABI >= 7; }

    ///
    static bool Have_Type_get_vector()
    { return LIBGCCJIT_ABI >= 8; }

    ///
    static bool Have_Function_get_address()
    { return LIBGCCJIT_ABI >= 9; }

    ///
    static bool Have_Context_new_rvalue_from_vector()
    { return LIBGCCJIT_ABI >= 10; }

    ///
    static bool Have_Context_add_driver_option()
    { return LIBGCCJIT_ABI >= 11; }

    ///
    static bool Have_Context_new_bitfield()
    { return LIBGCCJIT_ABI >= 12; }

    ///
    static bool Have_Version()
    { return LIBGCCJIT_ABI >= 13; }

    ///
    static bool Have_LValue_set_initiailizer()
    { return LIBGCCJIT_ABI >= 14; }

    ///
    static bool Have_Asm_Statements()
    { return LIBGCCJIT_ABI >= 15; }

    ///
    static bool Have_Reflection()
    { return LIBGCCJIT_ABI >= 16; }

    ///
    static bool Have_LValue_set_tls_model()
    { return LIBGCCJIT_ABI >= 17; }

    ///
    static bool Have_LValue_set_link_section()
    { return LIBGCCJIT_ABI >= 18; }

    ///
    static bool Have_Ctors()
    { return LIBGCCJIT_ABI >= 19; }

    ///
    static bool Have_Sized_Integers()
    { return LIBGCCJIT_ABI >= 20; }

    ///
    static bool Have_Context_new_bitcast()
    { return LIBGCCJIT_ABI >= 21; }

    ///
    static bool Have_LValue_set_register_name()
    { return LIBGCCJIT_ABI >= 22; }

    ///
    static bool Have_Context_set_print_errors_to_stderr()
    { return LIBGCCJIT_ABI >= 23; }

    ///
    static bool Have_Alignment()
    { return LIBGCCJIT_ABI >= 24; }

    ///
    static bool Have_Type_get_restrict()
    { return LIBGCCJIT_ABI >= 25; }

    ///
    static bool Have_Attributes()
    { return LIBGCCJIT_ABI >= 26; }

    ///
    static bool Have_Context_new_sizeof()
    { return LIBGCCJIT_ABI >= 27; }

    ///
    static bool Have_Context_new_alignof()
    { return LIBGCCJIT_ABI >= 28; }

    ///
    static bool Have_LValue_set_readonly()
    { return LIBGCCJIT_ABI >= 29; }

    ///
    static bool Have_Context_convert_vector()
    { return LIBGCCJIT_ABI >= 30; }

    ///
    static bool Have_Vector_Operations()
    { return LIBGCCJIT_ABI >= 31; }

    ///
    static bool Have_Context_get_target_builtin_function()
    { return LIBGCCJIT_ABI >= 32; }

    ///
    static bool Have_Function_new_temp()
    { return LIBGCCJIT_ABI >= 33; }

    ///
    static bool Have_Context_set_output_ident()
    { return LIBGCCJIT_ABI >= 34; }
}

public import gccjit.flags;
