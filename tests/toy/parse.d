//  Toy interpreter parser.
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

module toy.parse;

import toy.ast;
import toy.combinator;
import toy.lex;
import toy.diag;

///// Parser /////

Statement parse(Token[] tokens)
{
    Parser ast = new Phrase(stmtList());
    Result result = ast(tokens, 0);

    if (result.values.length != 1 || (cast(Statement) result.values[0]) is null)
        throw new ParseError("error occurred at " ~ tokens[result.pos].value);

    return cast(Statement) result.values[0];
}

/// Statements

Parser stmtList()
{
    return (stmtTerm() * new Reserved(";"))
        & (Statement l, Keyword sep, Statement r) => new CompoundStatement(l, r);
}

Parser stmtTerm()
{
    return stmtAssign() | stmtIf() | stmtWhile() | stmtPrint();
}

Parser stmtAssign()
{
    return (valueIdent() + new Reserved(":=") + arithExp())
        ^ (Expression name, Keyword eq, Expression value) => new AssignStatement(name, value);
}

Parser stmtIf()
{
    return (new Reserved("if") + boolExp()
            + new Reserved("then") + new Lazy(&stmtList)
            + new Optional((new Reserved("else") + new Lazy(&stmtList))
                           ^ (Keyword e, Statement elsebody) => elsebody)
            + new Reserved("end"))
        ^ (Keyword i, Expression condition, Keyword t, Statement ifbody, Statement elsebody, Keyword e)
            => new IfStatement(condition, ifbody, elsebody);
}

Parser stmtWhile()
{
    return (new Reserved("while") + boolExp()
            + new Reserved("do") + new Lazy(&stmtList)
            + new Reserved("end"))
        ^ (Keyword w, Expression condition, Keyword d, Statement whilebody, Keyword e)
            => new WhileStatement(condition, whilebody);
}

Parser stmtPrint()
{
    return (new Reserved("print") + (boolExp() | arithExp()))
        ^ (Keyword w, Expression e) => new PrintStatement(e);
}

/// Boolean Expressions

Parser boolExp()
{
    return (boolTerm() * (new Reserved("and") | new Reserved("or")))
        & (Expression l, Keyword op, Expression r) => (op.value == "and") ? new AndExp(l, r) : new OrExp(l, r);
}

Parser boolTerm()
{
    return boolNot() | boolCmp() | boolGroup();
}

Parser boolNot()
{
    return (new Reserved("not") + new Lazy(&boolTerm))
        ^ (Keyword op, Expression e) => new NotExp(e);
}

Parser boolCmp()
{
    return (arithExp() + (new Reserved("<") | new Reserved("<=")
                          | new Reserved(">") | new Reserved(">=")
                          | new Reserved("=") | new Reserved("!=")) + arithExp())
        ^ (Expression l, Keyword op, Expression r) => new CmpExp(op.value, l, r);
}

Parser boolGroup()
{
    return (new Reserved("(") + new Lazy(&boolExp) + new Reserved(")"))
        ^ (Keyword b0, Expression e, Keyword b1) => e;
}

/// Aritmetic Expressions

Parser arithExp()
{
    return (arithTerm() * (new Reserved("/") | new Reserved("*") | new Reserved("+") | new Reserved("-")))
        & (Expression l, Keyword op, Expression r) => new BinExp(op.value, l, r);
}

Parser arithTerm()
{
    return arithValue() | arithGroup();
}

Parser arithGroup()
{
    return (new Reserved("(") + new Lazy(&arithExp) + new Reserved(")"))
        ^ (Keyword b0, Expression e, Keyword b1) => e;
}

Parser arithValue()
{
    return valueInt() | valueIdent();
}

/// Value types.

Parser valueInt()
{
    return new TokenTag(Tag.Integer)
        ^ (TokenClass e)
        {
            static IntegerExp[string] icache;

            if (e.value !in icache)
                icache[e.value] = new IntegerExp(e.value);

            return icache[e.value];
        };
}

Parser valueIdent()
{
    return new TokenTag(Tag.Identifier)
        ^ (TokenClass e)
        {
            static VarExp[string] vcache;

            if (e.value !in vcache)
                vcache[e.value] = new VarExp(e.value);

            return vcache[e.value];
        };
}
