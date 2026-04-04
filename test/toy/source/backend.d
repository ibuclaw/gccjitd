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

import gccjit;

/// Internal backend value exposed via alias.
alias BEValue = JIT.RValue;

/// Backend visitor class.
class Backend
{
    JIT.Context context;
    JIT.Function func;
    JIT.Block block;

    this()
    {
        this.context = JIT.Context.acquire();
        this.func = this.context.new_function(FunctionType.Exported,
                                              CType.Void, "toymain", false);
        this.block = this.func.new_block();
        this.context.set_program_name = "toy";
        debug this.context.set_dump_initial_gimple = true;
    }

    void run()
    {
        this.block.end_with_return();

        JIT.CompileResult result = this.context.compile();
        this.context.release();

        auto toymain = cast(void function()) result.get_code("toymain");
        toymain();

        result.release();
    }

    void compile(AssignStatement as)
    {
        JIT.LValue name = cast(JIT.LValue)as.name.compile(this);
        JIT.RValue value = as.value.compile(this);
        this.block.add_assignment(name, value);
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
        JIT.Block condblock = this.func.new_block();
        JIT.Block exitblock = this.func.new_block();
        JIT.Block trueblock = this.func.new_block();
        JIT.Block falseblock = ifs.elsebody ? this.func.new_block() : JIT.Block.init;

        this.block.end_with_jump(condblock);
        this.block = condblock;
        JIT.RValue condition = ifs.condition.compile(this);
        this.block.end_with_conditional(condition, trueblock, falseblock ? falseblock : exitblock);

        this.block = trueblock;
        ifs.ifbody.compile(this);
        this.block.end_with_jump(exitblock);

        if (falseblock)
        {
            this.block = falseblock;
            ifs.elsebody.compile(this);
            this.block.end_with_jump(exitblock);
        }

        this.block = exitblock;
    }

    void compile(WhileStatement ws)
    {
        JIT.Block condblock = this.func.new_block();
        JIT.Block exitblock = this.func.new_block();
        JIT.Block loopblock = this.func.new_block();

        this.block.end_with_jump(condblock);
        this.block = condblock;
        JIT.RValue condition = ws.condition.compile(this);
        this.block.end_with_conditional(condition, loopblock, exitblock);

        this.block = loopblock;
        ws.whilebody.compile(this);
        this.block.end_with_jump(condblock);

        this.block = exitblock;
    }

    void compile(PrintStatement ps)
    {
        JIT.RValue value = ps.value.compile(this);
        this.block.add_call(this.context.get_builtin_function("printf"),
                            this.context.new_rvalue("%d\n"), value);
    }

    BEValue compile(IntegerExp ie)
    {
        if (!ie.bevalue)
            ie.bevalue = this.context.new_rvalue(CType.Int, ie.e1);
        return ie.bevalue;
    }

    BEValue compile(VarExp ve)
    {
        if (!ve.bevalue)
            ve.bevalue = this.func.new_local(this.context.get_type(CType.Int), ve.e1);
        return ve.bevalue;
    }

    BEValue compile(BinExp be)
    {
        JIT.RValue e1 = be.e1.compile(this);
        JIT.RValue e2 = be.e2.compile(this);
        BinaryOp op;

        final switch (be.op)
        {
            case "/": op = BinaryOp.Divide; break;
            case "*": op = BinaryOp.Mult; break;
            case "+": op = BinaryOp.Plus; break;
            case "-": op = BinaryOp.Minus; break;
        }
        return this.context.new_binary_op(op, e2.get_type(), e1, e2);
    }

    BEValue compile(CmpExp ce)
    {
        JIT.RValue e1 = ce.e1.compile(this);
        JIT.RValue e2 = ce.e2.compile(this);
        ComparisonOp op;

        final switch (ce.op)
        {
            case "=":   op = ComparisonOp.Equals; break;
            case "!=":  op = ComparisonOp.NotEquals; break;
            case "<":   op = ComparisonOp.LessThan; break;
            case "<=":  op = ComparisonOp.LessThanEquals; break;
            case ">":   op = ComparisonOp.GreaterThan; break;
            case ">=":  op = ComparisonOp.GreaterThanEquals; break;
        }
        return this.context.new_comparison(op, e1, e2);
    }

    BEValue compile(AndExp ae)
    {
        JIT.RValue e1 = ae.e1.compile(this);
        JIT.RValue e2 = ae.e2.compile(this);
        return this.context.new_logical_and(e2.get_type(), e1, e2);
    }

    BEValue compile(OrExp oe)
    {
        JIT.RValue e1 = oe.e1.compile(this);
        JIT.RValue e2 = oe.e2.compile(this);
        return this.context.new_logical_or(e2.get_type(), e1, e2);
    }

    BEValue compile(NotExp ne)
    {
        JIT.RValue e1 = ne.e1.compile(this);
        return this.context.new_logical_negate(e1.get_type(), e1);
    }
}
