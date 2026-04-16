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
public import gccjit.flags;

/// D API
struct JIT
{
    static import gccjit.object;
    ///
    alias Object = gccjit.object.JitObject;

    static import gccjit.location;
    ///
    alias Location = gccjit.location.Location;

    static import gccjit.context;
    ///
    alias Context = gccjit.context.Context;

    static import gccjit.decls;
    ///
    alias Field = gccjit.decls.Field;
    ///
    alias Function = gccjit.decls.Function;
    ///
    alias Parameter = gccjit.decls.Parameter;

    static import gccjit.types;
    ///
    alias Type = gccjit.types.Type;
    ///
    alias Struct = gccjit.types.Struct;
    ///
    alias FunctionPtrType = gccjit.types.FunctionPtrType;
    ///
    alias VectorType = gccjit.types.VectorType;

    static import gccjit.block;
    ///
    alias Block = gccjit.block.Block;
    ///
    alias Case = gccjit.block.Case;
    ///
    alias ExtendedAsm = gccjit.block.ExtendedAsm;

    static import gccjit.values;
    ///
    alias RValue = gccjit.values.RValue;
    ///
    alias LValue = gccjit.values.LValue;

    static import gccjit.compile;
    ///
    alias CompileResult = gccjit.compile.CompileResult;

    static import gccjit.timer;
    ///
    alias Timer = gccjit.timer.Timer;
    ///
    alias AutoTime = gccjit.timer.AutoTime;

    static import gccjit.version_;
    ///
    alias Version = gccjit.version_.Version;

    nothrow @nogc:
    import gccjit.helpers : Have;

    /// Feature flags to indicate the presense of libgccjit
    /// functions or API linked into this library.
    ///
    static bool Have_Context_add_command_line_option()
    { mixin(Have!(["gcc_jit_context_add_command_line_option"])); }

    ///
    static bool Have_Context_set_allow_unreachable_blocks()
    { mixin(Have!(["gcc_jit_context_set_bool_allow_unreachable_blocks"])); }

    ///
    static bool Have_Switch_Statements()
    { mixin(Have!(["gcc_jit_block_end_with_switch",
                   "gcc_jit_case_as_object",
                   "gcc_jit_context_new_case"])); }

    ///
    static bool Have_Timing_API()
    { mixin(Have!(["gcc_jit_context_get_timer",
                   "gcc_jit_context_set_timer",
                   "gcc_jit_timer_new",
                   "gcc_jit_timer_release",
                   "gcc_jit_timer_push",
                   "gcc_jit_timer_pop",
                   "gcc_jit_timer_print"])); }

    ///
    static bool Have_Context_set_use_external_driver()
    { mixin(Have!(["gcc_jit_context_set_bool_use_external_driver"])); }

    ///
    static bool Have_RValue_set_require_tail_call()
    { mixin(Have!(["gcc_jit_rvalue_set_bool_require_tail_call"])); }

    ///
    static bool Have_Type_get_aligned()
    { mixin(Have!(["gcc_jit_type_get_aligned"])); }

    ///
    static bool Have_Type_get_vector()
    { mixin(Have!(["gcc_jit_type_get_vector"])); }

    ///
    static bool Have_Function_get_address()
    { mixin(Have!(["gcc_jit_function_get_address"])); }

    ///
    static bool Have_Context_new_rvalue_from_vector()
    { mixin(Have!(["gcc_jit_context_new_rvalue_from_vector"])); }

    ///
    static bool Have_Context_add_driver_option()
    { mixin(Have!(["gcc_jit_context_add_driver_option"])); }

    ///
    static bool Have_Context_new_bitfield()
    { mixin(Have!(["gcc_jit_context_new_bitfield"])); }

    ///
    static bool Have_Version()
    { mixin(Have!(["gcc_jit_version_major",
                   "gcc_jit_version_minor",
                   "gcc_jit_version_patchlevel"])); }

    ///
    static bool Have_LValue_set_initiailizer()
    { mixin(Have!(["gcc_jit_global_set_initializer"])); }

    ///
    static bool Have_Asm_Statements()
    { mixin(Have!(["gcc_jit_block_add_extended_asm",
                   "gcc_jit_block_end_with_extended_asm_goto",
                   "gcc_jit_extended_asm_as_object",
                   "gcc_jit_extended_asm_set_volatile_flag",
                   "gcc_jit_extended_asm_set_inline_flag",
                   "gcc_jit_extended_asm_add_output_operand",
                   "gcc_jit_extended_asm_add_input_operand",
                   "gcc_jit_extended_asm_add_clobber",
                   "gcc_jit_context_add_top_level_asm"])); }

    ///
    static bool Have_Reflection()
    { mixin(Have!(["gcc_jit_function_get_return_type",
                   "gcc_jit_function_get_param_count",
                   "gcc_jit_function_type_get_return_type",
                   "gcc_jit_function_type_get_param_count",
                   "gcc_jit_function_type_get_param_type",
                   "gcc_jit_type_dyncast_function_ptr_type",
                   "gcc_jit_vector_type_get_element_type",
                   "gcc_jit_vector_type_get_num_units",
                   "gcc_jit_type_unqualified",
                   "gcc_jit_type_dyncast_array",
                   "gcc_jit_type_is_bool",
                   "gcc_jit_type_is_integral",
                   "gcc_jit_type_is_pointer",
                   "gcc_jit_type_dyncast_vector",
                   "gcc_jit_struct_get_field",
                   "gcc_jit_type_is_struct",
                   "gcc_jit_struct_get_field_count"])); }

    ///
    static bool Have_LValue_set_tls_model()
    { mixin(Have!(["gcc_jit_lvalue_set_tls_model"])); }

    ///
    static bool Have_LValue_set_link_section()
    { mixin(Have!(["gcc_jit_lvalue_set_link_section"])); }

    ///
    static bool Have_Ctors()
    { mixin(Have!(["gcc_jit_context_new_array_constructor",
                   "gcc_jit_context_new_struct_constructor",
                   "gcc_jit_context_new_union_constructor",
                   "gcc_jit_global_set_initializer_rvalue"])); }

    ///
    static bool Have_Sized_Integers()
    { mixin(Have!(["gcc_jit_compatible_types",
                   "gcc_jit_type_get_size"])); }

    ///
    static bool Have_Context_new_bitcast()
    { mixin(Have!(["gcc_jit_context_new_bitcast"])); }

    ///
    static bool Have_LValue_set_register_name()
    { mixin(Have!(["gcc_jit_lvalue_set_register_name"])); }

    ///
    static bool Have_Context_set_print_errors_to_stderr()
    { mixin(Have!(["gcc_jit_context_set_bool_print_errors_to_stderr"])); }

    ///
    static bool Have_Alignment()
    { mixin(Have!(["gcc_jit_lvalue_set_alignment",
                   "gcc_jit_lvalue_get_alignment"])); }

    ///
    static bool Have_Type_get_restrict()
    { mixin(Have!(["gcc_jit_type_get_restrict"])); }

    ///
    static bool Have_Attributes()
    { mixin(Have!(["gcc_jit_function_add_attribute",
                   "gcc_jit_function_add_string_attribute",
                   "gcc_jit_lvalue_add_string_attribute",
                   "gcc_jit_function_add_integer_array_attribute"])); }

    ///
    static bool Have_Context_new_sizeof()
    { mixin(Have!(["gcc_jit_context_new_sizeof"])); }

    ///
    static bool Have_Context_new_alignof()
    { mixin(Have!(["gcc_jit_context_new_alignof"])); }

    ///
    static bool Have_LValue_set_readonly()
    { mixin(Have!(["gcc_jit_global_set_readonly"])); }

    ///
    static bool Have_Context_convert_vector()
    { mixin(Have!(["gcc_jit_context_convert_vector"])); }

    ///
    static bool Have_Vector_Operations()
    { mixin(Have!(["gcc_jit_context_new_vector_access",
                   "gcc_jit_context_new_rvalue_vector_perm"])); }

    ///
    static bool Have_Context_get_target_builtin_function()
    { mixin(Have!(["gcc_jit_context_get_target_builtin_function"])); }

    ///
    static bool Have_Function_new_temp()
    { mixin(Have!(["gcc_jit_function_new_temp"])); }

    ///
    static bool Have_Context_set_output_ident()
    { mixin(Have!(["gcc_jit_context_set_output_ident"])); }
}
