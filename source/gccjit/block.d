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

module gccjit.block;

package(gccjit):

import gccjit.bindings;
import gccjit.decls;
import gccjit.flags;
import gccjit.helpers;
import gccjit.location;
import gccjit.object;
import gccjit.values;

/// Struct wrapper for gcc_jit_block
struct Block
{
    union
    {
        private gcc_jit_block* m_block = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_block* block) pure nothrow @nogc
    {
        m_block = block;
    }

    /// Returns the internal gcc_jit_block object.
    inout(gcc_jit_block)* get_block() inout pure nothrow @nogc
    {
        return m_block;
    }

    /// Returns true if this JIT.Block has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_block !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_block_as_object(cast(gcc_jit_block*)m_block);
        return typeof(return)(result);
    }

    /// Returns the JIT.Function this JIT.Block is within.
    Function get_function() nothrow @nogc
    {
        auto result = gcc_jit_block_get_function(m_block);
        return Function(result);
    }

    /// Add evaluation of an rvalue, discarding the result.
    Block add_eval(Location loc, RValue rvalue) return nothrow @nogc
    {
        gcc_jit_block_add_eval(m_block,
                               loc.get_location(),
                               rvalue.get_rvalue());
        return this;
    }

    /// Ditto
    Block add_eval(RValue rvalue) return nothrow @nogc
    { return add_eval(Location(), rvalue); }

    /// Add evaluation of an rvalue, assigning the result to the given lvalue.
    /// This is equivalent to "lvalue = rvalue".
    Block add_assignment(Location loc, LValue lvalue, RValue rvalue) return nothrow @nogc
    {
        gcc_jit_block_add_assignment(m_block, loc.get_location(),
                                     lvalue.get_lvalue(), rvalue.get_rvalue());
        return this;
    }

    /// Ditto
    Block add_assignment(LValue lvalue, RValue rvalue) return nothrow @nogc
    { return add_assignment(Location(), lvalue, rvalue); }

    /// Add evaluation of an rvalue, using the result to modify an lvalue.
    /// This is equivalent to "lvalue op= rvalue".
    Block add_assignment_op(Location loc, LValue lvalue, BinaryOp op,
                            RValue rvalue) return nothrow @nogc
    {
        gcc_jit_block_add_assignment_op(m_block, loc.get_location(),
                                        lvalue.get_lvalue(), op, rvalue.get_rvalue());
        return this;
    }

    /// Ditto
    Block add_assignment_op(LValue lvalue, BinaryOp op, RValue rvalue) return nothrow @nogc
    { return add_assignment_op(Location(), lvalue, op, rvalue); }

    /// A way to add a function call to the body of a function being
    /// defined, with various number of args.
    RValue add_call(Location loc, Function func, scope RValue[] args) nothrow @nogc
    {
        RValue rv = get_context().new_call(loc, func, args);
        add_eval(loc, rv);
        return rv;
    }

    /// Ditto
    RValue add_call(Function func, scope RValue[] args) nothrow @nogc
    { return add_call(Location(), func, args); }

    /// Ditto
    RValue add_call(Location loc, Function func, scope RValue[] args...) nothrow @nogc
    { return add_call(loc, func, args); }

    /// Ditto
    RValue add_call(Function func, scope RValue[] args...) nothrow @nogc
    { return add_call(Location(), func, args); }

    /// Add a no-op textual comment to the internal representation of the code.
    /// It will be optimized away, but visible in the dumps seens via
    /// `set_dump_initial_tree` and `set_dump_initial_gimple`.
    Block add_comment(Location loc, string text) return nothrow @nogc
    {
        text.toCStringThen!((t)
            => gcc_jit_block_add_comment(m_block, loc.get_location(), t.ptr));
        return this;
    }

    /// Ditto
    Block add_comment(string text) return nothrow @nogc
    { return add_comment(Location(), text); }

    /// Terminate a block by adding evaluation of an rvalue, branching on the
    /// result to the appropriate successor block.
    Block end_with_conditional(Location loc, RValue val,
                               Block on_true, Block on_false) return nothrow @nogc
    {
        gcc_jit_block_end_with_conditional(m_block,
                                           loc.get_location(),
                                           val.get_rvalue(),
                                           on_true.get_block(),
                                           on_false.get_block());
        return this;
    }

    /// Ditto
    Block end_with_conditional(RValue val, Block on_true, Block on_false) return nothrow @nogc
    { return end_with_conditional(Location(), val, on_true, on_false); }

    /// Terminate a block by adding a jump to the given target block.
    /// This is equivalent to "goto target".
    Block end_with_jump(Location loc, Block target) return nothrow @nogc
    {
        gcc_jit_block_end_with_jump(m_block,
                                    loc.get_location(),
                                    target.get_block());
        return this;
    }

    /// Ditto
    Block end_with_jump(Block target) return nothrow @nogc
    { return end_with_jump(Location(), target); }

    /// Terminate a block by adding evaluation of an rvalue, returning the value.
    /// This is equivalent to "return rvalue".
    Block end_with_return(Location loc, RValue rvalue) return nothrow @nogc
    {
        gcc_jit_block_end_with_return(m_block,
                                      loc.get_location(),
                                      rvalue.get_rvalue());
        return this;
    }

    /// Ditto
    Block end_with_return(RValue rvalue) return nothrow @nogc
    { return end_with_return(Location(), rvalue); }

    /// Terminate a block by adding a valueless return, for use within a
    /// function with "void" return type.
    /// This is equivalent to "return".
    Block end_with_return(Location loc = Location()) return nothrow @nogc
    {
        gcc_jit_block_end_with_void_return(m_block,
                                           loc.get_location());
        return this;
    }

    ///
    Block end_with_switch(Location loc, RValue expr, Block default_block,
                          scope Case[] cases) return nothrow @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        gcc_jit_block_end_with_switch(m_block,
                                      loc.get_location(),
                                      expr.get_rvalue(),
                                      default_block.get_block(),
                                      cast(int)cases.length,
                                      cast(gcc_jit_case**)cases.ptr);
        return this;
    }

    /// Ditto
    Block end_with_switch(RValue expr, Block default_block,
                          scope Case[] cases) return nothrow @nogc
    { return end_with_switch(Location(), expr, default_block, cases); }

    /// Ditto
    Block end_with_switch(Location loc, RValue expr, Block default_block,
                          scope Case[] cases...) return nothrow @nogc
    { return end_with_switch(loc, expr, default_block, cases); }

    /// Ditto
    Block end_with_switch(RValue expr, Block default_block,
                          scope Case[] cases...) return nothrow @nogc
    { return end_with_switch(Location(), expr, default_block, cases); }

    ///
    ExtendedAsm add_extended_asm(Location loc, string asm_template) nothrow @nogc
    {
        auto result = asm_template.toCStringThen!((a)
            => gcc_jit_block_add_extended_asm(m_block, loc.get_location(), a.ptr));
        return ExtendedAsm(result);
    }

    /// Ditto
    ExtendedAsm add_extended_asm(string asm_template) nothrow @nogc
    { return add_extended_asm(Location(), asm_template); }

    ///
    ExtendedAsm end_with_extended_asm_goto(Location loc, string asm_template, scope Block[] goto_blocks,
                                           Block fallthrough_block = Block()) nothrow @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        auto result = asm_template.toCStringThen!((a)
            => gcc_jit_block_end_with_extended_asm_goto(m_block, loc.get_location(), a.ptr,
                                                        cast(int)goto_blocks.length,
                                                        cast(gcc_jit_block**)goto_blocks.ptr,
                                                        fallthrough_block.get_block()));
        return ExtendedAsm(result);
    }

    /// Ditto
    ExtendedAsm end_with_extended_asm_goto(string asm_template, scope Block[] goto_blocks,
                                           Block fallthrough_block = Block()) nothrow @nogc
    { return end_with_extended_asm_goto(Location(), asm_template, goto_blocks, fallthrough_block); }
}

/// Struct wrapper for gcc_jit_case
struct Case
{
    union
    {
        private gcc_jit_case* m_case = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_case* case_) pure nothrow @nogc
    {
        m_case = case_;
    }

    /// Returns the internal gcc_jit_case object.
    inout(gcc_jit_case)* get_case() inout pure nothrow @nogc
    {
        return m_case;
    }

    /// Returns true if this JIT.Case has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_case !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_case_as_object(cast(gcc_jit_case*)m_case);
        return typeof(return)(result);
    }
}

/// Struct wrapper for gcc_jit_extended_asm
struct ExtendedAsm
{
    union
    {
        private gcc_jit_extended_asm* m_extended_asm = null;
        JitObject m_super;
    }
    alias m_super this;

    ///
    this(gcc_jit_extended_asm* extended_asm) pure nothrow @nogc
    {
        m_extended_asm = extended_asm;
    }

    /// Returns the internal gcc_jit_extended_asm object.
    inout(gcc_jit_extended_asm)* get_extended_asm() inout pure nothrow @nogc
    {
        return m_extended_asm;
    }

    /// Returns true if this JIT.ExtendedAsm has a value.
    bool opCast(T : bool)() const nothrow @nogc
    {
        return m_extended_asm !is null;
    }

    /// Upcast to the parent JIT.Object.
    auto ref T opCast(T)() const nothrow @nogc
    if (is(T == JitObject))
    {
        auto result = gcc_jit_extended_asm_as_object(cast(gcc_jit_extended_asm*)m_extended_asm);
        return typeof(return)(result);
    }

    /// Set whether this JIT.ExtendedAsm statement has side-effects.
    ExtendedAsm set_volatile_flag(bool flag) return nothrow @nogc @property
    {
        gcc_jit_extended_asm_set_volatile_flag(m_extended_asm, flag);
        return this;
    }

    /// Set whether this JIT.ExtendedAsm statement is inlinable.
    ExtendedAsm set_inline_flag(bool flag) return nothrow @nogc @property
    {
        gcc_jit_extended_asm_set_inline_flag(m_extended_asm, flag);
        return this;
    }

    /// Add an output operand to this JIT.ExtendedAsm statement.
    ExtendedAsm add_output_operand(string asm_symbolic_name, string constraint,
                                   LValue dest) return nothrow @nogc
    {
        asm_symbolic_name.toCStringThen!((a)
            => constraint.toCStringThen!((c)
                => gcc_jit_extended_asm_add_output_operand(m_extended_asm, a.ptr, c.ptr,
                                                           dest.get_lvalue())));
        return this;
    }

    /// Ditto
    ExtendedAsm add_output_operand(string constraint, LValue dest) return nothrow @nogc
    {
        constraint.toCStringThen!((c)
            => gcc_jit_extended_asm_add_output_operand(m_extended_asm, null, c.ptr,
                                                       dest.get_lvalue()));
        return this;
    }

    /// Add an input operand to this JIT.ExtendedAsm statement.
    ExtendedAsm add_input_operand(string asm_symbolic_name, string constraint,
                                  RValue src) return nothrow @nogc
    {
        asm_symbolic_name.toCStringThen!((a)
            => constraint.toCStringThen!((c)
                => gcc_jit_extended_asm_add_input_operand(m_extended_asm, a.ptr, c.ptr,
                                                          src.get_rvalue())));
        return this;
    }

    /// Ditto
    ExtendedAsm add_input_operand(string constraint, RValue dest) return nothrow @nogc
    {
        constraint.toCStringThen!((c)
            => gcc_jit_extended_asm_add_input_operand(m_extended_asm, null, c.ptr,
                                                      dest.get_rvalue()));
        return this;
    }

    /// Append to the list of registers clobbered by this JIT.ExtendedAsm statement.
    ExtendedAsm add_input_operand(string victim) return nothrow @nogc
    {
        victim.toCStringThen!((v)
            => gcc_jit_extended_asm_add_clobber(m_extended_asm, v.ptr));
        return this;
    }
}
