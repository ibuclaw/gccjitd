
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

module gccjitd.examples.brainf;

import gccjit.d;
import std.stdio;
import std.string;

void readToBlock(File finput, ref JITBlock block, JITContext ctx,
                 JITLValue stack, JITLValue stackp, int labelnum = 0)
{
    char input;

    while(finput.readf("%s", &input))
    {
        switch(input)
        {
            case '>':
                // stackp += 1;
                block.addAssignmentOp(stackp, JITBinaryOp.PLUS,
                                      ctx.newRValue(JITTypeKind.UNSIGNED_SHORT, 1));
                break;

            case '<':
                // stackp -= 1;
                block.addAssignmentOp(stackp, JITBinaryOp.MINUS,
                                      ctx.newRValue(JITTypeKind.UNSIGNED_SHORT, 1));
                break;

            case '+':
                // stack[stackp] += 1;
                block.addAssignmentOp(ctx.newArrayAccess(stack, stackp), JITBinaryOp.PLUS,
                                      ctx.newRValue(JITTypeKind.SHORT, 1));
                break;

            case '-':
                // stack[stackp] -= 1;
                block.addAssignmentOp(ctx.newArrayAccess(stack, stackp), JITBinaryOp.MINUS,
                                      ctx.newRValue(JITTypeKind.SHORT, 1));
                break;

            case '.':
                // putchar(stack[stackp]);
                block.addCall(ctx.getBuiltinFunction("putchar"),
                              ctx.newArrayAccess(stack, stackp).castTo(JITTypeKind.INT));
                break;

            case ',':
                // stack[stackp] = getchar();
                JITFunction getchar = ctx.newFunction(JITFunctionKind.IMPORTED,
                                                      JITTypeKind.INT, "getchar", false);
                block.addAssignment(ctx.newArrayAccess(stack, stackp),
                                    ctx.newCall(getchar).castTo(JITTypeKind.SHORT));
                break;

            case '[':
                // while (stack[stackp] != 0) { [loop] } 
                JITFunction func = block.getFunction();
                JITBlock condblock = func.newBlock("cond%s".format(labelnum));
                JITBlock loopblock = func.newBlock("loop%s".format(labelnum));
                JITBlock exitblock = func.newBlock("exit%s".format(labelnum));
                labelnum++;

                // Close current block with jump to condition.
                block.endWithJump(condblock);

                // Evaluate condition, jumping to the loop block if true, else
                // continue by jumping to the exit block.
                JITRValue cond = ctx.newComparison(JITComparison.NE,
                                                   ctx.newArrayAccess(stack, stackp),
                                                   ctx.newRValue(JITTypeKind.SHORT, 0));
                condblock.endWithConditional(cond, loopblock, exitblock);

                // Do code generation for the loop block.
                readToBlock(finput, loopblock, ctx, stack, stackp, labelnum);

                // Close loop with jump back to condition.
                loopblock.endWithJump(condblock);

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

    JITContext ctx = new JITContext();
    ctx.setOption(JITStrOption.PROGNAME, "brainf***");

    // Turn these on to get various kinds of debugging
    version(none)
    {
        ctx.setOption(JITBoolOption.DUMP_INITIAL_TREE, true);
        ctx.setOption(JITBoolOption.DUMP_INITIAL_GIMPLE, true);
        ctx.setOption(JITBoolOption.DUMP_GENERATED_CODE, true);
    }

    // Adjust this to control optimization level of the generated code
    version(none)
        ctx.setOption(JITIntOption.OPTIMIZATION_LEVEL, 1);

    // int bfmain() {
    JITFunction func = ctx.newFunction(JITFunctionKind.EXPORTED,
                                       JITTypeKind.INT, "bfmain", false);
    JITBlock block = func.newBlock("start");
    // short[65536] stack;
    JITLValue stack = func.newLocal(ctx.newArrayType(JITTypeKind.SHORT, 65536), "stack");
    // unsigned short stackp;
    JITLValue stackp = func.newLocal(ctx.getType(JITTypeKind.UNSIGNED_SHORT), "stackp");
    // stackp = 0;
    block.addAssignment(stackp, ctx.newRValue(JITTypeKind.UNSIGNED_SHORT, 0));

    // [body]
    readToBlock(finput, block, ctx, stack, stackp);

    // return 0; }
    block.endWithReturn(ctx.newRValue(JITTypeKind.INT, 0));

    // 
    JITResult result = ctx.compile();
    ctx.release();

    auto mainfn = cast(int function()) result.getCode("bfmain");
    mainfn();

    result.release();
    return;
}


