//  Toy interpreter backend using gccjitd.
//
// Copyright (C) 2014-2015 Iain Buclaw.
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

module toy.backend;

import toy.ast;

private import gccjit.d;

/// Internal backend value exposed via alias.
alias BEValue = JITRValue;

/// Backend visitor class.
class Backend
{
    JITContext context;
    JITFunction func;
    JITBlock block;

    this()
    {
        this.context = new JITContext();
        this.func = this.context.newFunction(JITFunctionKind.EXPORTED,
                                             JITTypeKind.VOID, "toymain", false);
        this.block = this.func.newBlock();
        this.context.setOption(JITStrOption.PROGNAME, "toy");
        debug this.context.setOption(JITBoolOption.DUMP_INITIAL_GIMPLE, true);
    }

    void run()
    {
        this.block.endWithReturn();

        JITResult result = this.context.compile();
        this.context.release();

        auto toymain = cast(void function()) result.getCode("toymain");
        toymain();

        result.release();
    }

    void compile(AssignStatement as)
    {
        JITLValue name = cast(JITLValue) as.name.compile(this);
        JITRValue value = as.value.compile(this);
        this.block.addAssignment(name, value);
    }

    void compile(CompoundStatement cs)
    {
        if (cs.s1 !is null)
            cs.s1.compile(this);
        if (cs.s2 !is null)
            cs.s2.compile(this);
    }

    void compile(IfStatement ifs)
    {
        JITBlock condblock = this.func.newBlock();
        JITBlock exitblock = this.func.newBlock();
        JITBlock trueblock = this.func.newBlock();
        JITBlock falseblock = ifs.elsebody ? this.func.newBlock() : null;

        this.block.endWithJump(condblock);
        this.block = condblock;
        JITRValue condition = ifs.condition.compile(this);
        this.block.endWithConditional(condition, trueblock, falseblock ? falseblock : exitblock);

        this.block = trueblock;
        ifs.ifbody.compile(this);
        this.block.endWithJump(exitblock);

        if (falseblock !is null)
        {
            this.block = falseblock;
            ifs.elsebody.compile(this);
            this.block.endWithJump(exitblock);
        }

        this.block = exitblock;
    }

    void compile(WhileStatement ws)
    {
        JITBlock condblock = this.func.newBlock();
        JITBlock exitblock = this.func.newBlock();
        JITBlock loopblock = this.func.newBlock();

        this.block.endWithJump(condblock);
        this.block = condblock;
        JITRValue condition = ws.condition.compile(this);
        this.block.endWithConditional(condition, loopblock, exitblock);

        this.block = loopblock;
        ws.whilebody.compile(this);
        this.block.endWithJump(condblock);

        this.block = exitblock;
    }

    void compile(PrintStatement ps)
    {
        JITRValue value = ps.value.compile(this);
        this.block.addCall(this.context.getBuiltinFunction("printf"),
                           this.context.newRValue("%d\n"), value);
    }

    BEValue compile(IntegerExp ie)
    {
        if (ie.bevalue is null)
            ie.bevalue = this.context.newRValue(JITTypeKind.INT, ie.e1);
        return ie.bevalue;
    }

    BEValue compile(VarExp ve)
    {
        if (ve.bevalue is null)
            ve.bevalue = this.func.newLocal(this.context.getType(JITTypeKind.INT), ve.e1);
        return ve.bevalue;
    }

    BEValue compile(BinExp be)
    {
        JITRValue e1 = be.e1.compile(this);
        JITRValue e2 = be.e2.compile(this);
        JITBinaryOp op;

        final switch (be.op)
        {
            case "/": op = JITBinaryOp.DIVIDE; break;
            case "*": op = JITBinaryOp.MULT; break;
            case "+": op = JITBinaryOp.PLUS; break;
            case "-": op = JITBinaryOp.MINUS; break;
        }
        return this.context.newBinaryOp(op, e2.getType(), e1, e2);
    }

    BEValue compile(CmpExp ce)
    {
        JITRValue e1 = ce.e1.compile(this);
        JITRValue e2 = ce.e2.compile(this);
        JITComparison op;

        final switch (ce.op)
        {
            case "=":   op = JITComparison.EQ; break;
            case "!=":  op = JITComparison.NE; break;
            case "<":   op = JITComparison.LT; break;
            case "<=":  op = JITComparison.LE; break;
            case ">":   op = JITComparison.GT; break;
            case ">=":  op = JITComparison.GE; break;
        }
        return this.context.newComparison(op, e1, e2);
    }

    BEValue compile(AndExp ae)
    {
        JITRValue e1 = ae.e1.compile(this);
        JITRValue e2 = ae.e2.compile(this);
        return this.context.newBinaryOp(JITBinaryOp.LOGICAL_AND, e2.getType(), e1, e2);
    }

    BEValue compile(OrExp oe)
    {
        JITRValue e1 = oe.e1.compile(this);
        JITRValue e2 = oe.e2.compile(this);
        return this.context.newBinaryOp(JITBinaryOp.LOGICAL_OR, e2.getType(), e1, e2);
    }

    BEValue compile(NotExp ne)
    {
        JITRValue e1 = ne.e1.compile(this);
        return this.context.newUnaryOp(JITUnaryOp.LOGICAL_NEGATE, e1.getType(), e1);
    }
}
