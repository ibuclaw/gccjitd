
//  Brainf*** JIT frontend for gccjitd
//
// Copyright (C) 2014 Iain Buclaw.
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Written by Iain  Buclaw <ibuclaw@gdcproject.org>

module gccjitd.test.brainf;

import gccjit;
import std.stdio;
import std.string;

void readToBlock(File finput, ref JIT.Block block, JIT.Context ctx,
                 JIT.LValue stack, JIT.LValue stackp, int labelnum = 0)
{
    char input;

    while(finput.readf("%s", &input))
    {
        switch(input)
        {
            case '>':
                // stackp += 1;
                block.add_assignment_op(stackp, BinaryOp.Plus,
                                        ctx.new_rvalue(CType.UShort, 1));
                break;

            case '<':
                // stackp -= 1;
                block.add_assignment_op(stackp, BinaryOp.Minus,
                                        ctx.new_rvalue(CType.UShort, 1));
                break;

            case '+':
                // stack[stackp] += 1;
                block.add_assignment_op(ctx.new_array_access(stack, stackp), BinaryOp.Plus,
                                        ctx.new_rvalue(CType.Short, 1));
                break;

            case '-':
                // stack[stackp] -= 1;
                block.add_assignment_op(ctx.new_array_access(stack, stackp), BinaryOp.Minus,
                                        ctx.new_rvalue(CType.Short, 1));
                break;

            case '.':
                // putchar(stack[stackp]);
                block.add_call(ctx.get_builtin_function("putchar"),
                               ctx.new_array_access(stack, stackp).cast_to(CType.Int));
                break;

            case ',':
                // stack[stackp] = getchar();
                JIT.Function getchar = ctx.new_function(FunctionType.Imported,
                                                        CType.Int, "getchar", false);
                block.add_assignment(ctx.new_array_access(stack, stackp),
                                     ctx.new_call(getchar).cast_to(CType.Short));
                break;

            case '[':
                // while (stack[stackp] != 0) { [loop] }
                JIT.Function func = block.get_function();
                JIT.Block condblock = func.new_block("cond%s".format(labelnum));
                JIT.Block loopblock = func.new_block("loop%s".format(labelnum));
                JIT.Block exitblock = func.new_block("exit%s".format(labelnum));
                labelnum++;

                // Close current block with jump to condition.
                block.end_with_jump(condblock);

                // Evaluate condition, jumping to the loop block if true, else
                // continue by jumping to the exit block.
                JIT.RValue cond = ctx.new_ne(ctx.new_array_access(stack, stackp),
                                             ctx.new_rvalue(CType.Short, 0));
                condblock.end_with_conditional(cond, loopblock, exitblock);

                // Do code generation for the loop block.
                readToBlock(finput, loopblock, ctx, stack, stackp, labelnum);

                // Close loop with jump back to condition.
                loopblock.end_with_jump(condblock);

                // We now start generating code from the exit block.
                block = exitblock;
                break;

            case ']':
                return;

            default:
                // Silently ignore everything else.  They can be comment or typos
                // that will bring you to mental insanity.
                continue;
        }
    }
}


void main(string[] args)
{
    File finput = (args.length > 1) ? File(args[1], "r") : stdin;

    JIT.Context ctx = JIT.Context.acquire();
    ctx.set_program_name = "brainf***";

    // Turn these on to get various kinds of debugging
    version(none)
    {
        ctx.set_dump_initial_tree = true;
        ctx.set_dump_initial_gimple = true;
        ctx.set_dump_generated_code = true;
    }

    // Adjust this to control optimization level of the generated code
    version(all)
        ctx.set_optimization_level = OptimizationLevel.Limited;

    // int bfmain() {
    JIT.Function func = ctx.new_function(FunctionType.Exported,
                                         CType.Int, "bfmain", false);
    JIT.Block block = func.new_block("start");
    // static short[65536] stack;
    JIT.LValue stack = ctx.new_global(GlobalKind.Internal, ctx.new_array_type(CType.Short, 65536), "stack");
    // unsigned short stackp;
    JIT.LValue stackp = func.new_local(ctx.get_type(CType.UShort), "stackp");
    // stackp = 0;
    block.add_assignment(stackp, ctx.new_rvalue(CType.UShort, 0));

    // [body]
    readToBlock(finput, block, ctx, stack, stackp);

    // return 0; }
    block.end_with_return(ctx.new_rvalue(CType.Int, 0));

    //
    JIT.CompileResult result = ctx.compile();
    ctx.release();

    auto mainfn = cast(int function()) result.get_code("bfmain");
    mainfn();

    result.release();
    return;
}


