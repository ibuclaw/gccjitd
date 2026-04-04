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
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_block* block) @nogc
    {
        __super = JitObject(gcc_jit_block_as_object(block));
    }

    /// Returns the internal gcc_jit_block object.
    gcc_jit_block* get_block() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_block *)get_object();
    }

    /// Returns the JIT.Function this JIT.Block is within.
    Function get_function() @nogc
    {
        auto result = gcc_jit_block_get_function(get_block());
        return Function(result);
    }

    /// Add evaluation of an rvalue, discarding the result.
    void add_eval(Location loc, RValue rvalue) nothrow @nogc
    {
        gcc_jit_block_add_eval(get_block(),
                               loc.get_location(),
                               rvalue.get_rvalue());
    }

    /// Ditto
    void add_eval(RValue rvalue) nothrow @nogc
    { return add_eval(Location(), rvalue); }

    /// Add evaluation of an rvalue, assigning the result to the given lvalue.
    /// This is equivalent to "lvalue = rvalue".
    void add_assignment(Location loc, LValue lvalue, RValue rvalue) nothrow @nogc
    {
        gcc_jit_block_add_assignment(get_block(), loc.get_location(),
                                     lvalue.get_lvalue(), rvalue.get_rvalue());
    }

    /// Ditto
    void add_assignment(LValue lvalue, RValue rvalue) nothrow @nogc
    { return add_assignment(Location(), lvalue, rvalue); }

    /// Add evaluation of an rvalue, using the result to modify an lvalue.
    /// This is equivalent to "lvalue op= rvalue".
    void add_assignment_op(Location loc, LValue lvalue, BinaryOp op, RValue rvalue) nothrow @nogc
    {
        gcc_jit_block_add_assignment_op(get_block(), loc.get_location(),
                                        lvalue.get_lvalue(), op, rvalue.get_rvalue());
    }

    /// Ditto
    void add_assignment_op(LValue lvalue, BinaryOp op, RValue rvalue) nothrow @nogc
    { return add_assignment_op(Location(), lvalue, op, rvalue); }

    /// A way to add a function call to the body of a function being
    /// defined, with various number of args.
    RValue add_call(Location loc, Function func, scope RValue[] args...) @nogc
    {
        RValue rv = get_context().new_call(loc, func, args);
        add_eval(loc, rv);
        return rv;
    }

    /// Ditto
    RValue add_call(Function func, scope RValue[] args...) @nogc
    { return add_call(Location(), func, args); }

    /// Add a no-op textual comment to the internal representation of the code.
    /// It will be optimized away, but visible in the dumps seens via
    /// `set_dump_initial_tree` and `set_dump_initial_gimple`.
    void add_comment(Location loc, string text) nothrow @nogc
    {
        text.toCStringThen!((t)
            => gcc_jit_block_add_comment(get_block(), loc.get_location(), t.ptr));
    }

    /// Ditto
    void add_comment(string text) nothrow @nogc
    { return add_comment(Location(), text); }

    /// Terminate a block by adding evaluation of an rvalue, branching on the
    /// result to the appropriate successor block.
    void end_with_conditional(Location loc, RValue val, Block on_true, Block on_false) nothrow @nogc
    {
        gcc_jit_block_end_with_conditional(get_block(),
                                           loc.get_location(),
                                           val.get_rvalue(),
                                           on_true.get_block(),
                                           on_false.get_block());
    }

    /// Ditto
    void end_with_conditional(RValue val, Block on_true, Block on_false) nothrow @nogc
    { return end_with_conditional(Location(), val, on_true, on_false); }

    /// Terminate a block by adding a jump to the given target block.
    /// This is equivalent to "goto target".
    void end_with_jump(Location loc, Block target) nothrow @nogc
    {
        gcc_jit_block_end_with_jump(get_block(),
                                    loc.get_location(),
                                    target.get_block());
    }

    /// Ditto
    void end_with_jump(Block target) nothrow @nogc
    { return end_with_jump(Location(), target); }

    /// Terminate a block by adding evaluation of an rvalue, returning the value.
    /// This is equivalent to "return rvalue".
    void end_with_return(Location loc, RValue rvalue) nothrow @nogc
    {
        gcc_jit_block_end_with_return(get_block(),
                                      loc.get_location(),
                                      rvalue.get_rvalue());
    }

    /// Ditto
    void end_with_return(RValue rvalue) nothrow @nogc
    { return end_with_return(Location(), rvalue); }

    /// Terminate a block by adding a valueless return, for use within a
    /// function with "void" return type.
    /// This is equivalent to "return".
    void end_with_return(Location loc = Location()) nothrow @nogc
    {
        gcc_jit_block_end_with_void_return(get_block(),
                                           loc.get_location());
    }

    ///
    void end_with_switch(Location loc, RValue expr, Block default_block,
                         scope Case[] cases...) nothrow @nogc
    {
        // Treat the array as being of the underlying pointers, relying on
        // the wrapper type being such a pointer internally.
        gcc_jit_block_end_with_switch(get_block(),
                                      loc.get_location(),
                                      expr.get_rvalue(),
                                      default_block.get_block(),
                                      cast(int)cases.length,
                                      cast(gcc_jit_case**)cases.ptr);
    }

    /// Ditto
    void end_with_switch(RValue expr, Block default_block, scope Case[] cases...) nothrow @nogc
    { return end_with_switch(Location(), expr, default_block, cases); }
}

/// Struct wrapper for gcc_jit_case
struct Case
{
    JitObject __super;
    alias __super this;

    ///
    this(gcc_jit_case* case_) @nogc
    {
        __super = JitObject(gcc_jit_case_as_object(case_));
    }

    /// Returns the internal gcc_jit_case object.
    gcc_jit_case* get_case() pure nothrow @nogc
    {
        // Manual downcast.
        return cast(gcc_jit_case *)get_object();
    }
}
