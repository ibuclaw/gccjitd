//  Toy interpreter AST
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

module toy.ast;

import toy.backend;
import toy.diag;

import std.conv;

///// AST /////

class TokenClass
{
    string value;

    this(string value)
    {
        this.value = value;
    }
}

class Keyword
{
    string value;

    this(string value)
    {
        this.value = value;
    }
}

/// Statements ///

class Statement
{
    void compile(Backend)
    {
        throw new InternalError("compile() not implemented for Statement class: " ~ this.toString());
    }
}

class AssignStatement : Statement
{
    Expression name, value;

    this(Expression name, Expression value)
    {
        this.name = name;
        this.value = value;
    }

    override void compile(Backend b)
    {
        b.compile(this);
    }
}

class CompoundStatement : Statement
{
    Statement s1, s2;

    this(Statement s1, Statement s2)
    {
        this.s1 = s1;
        this.s2 = s2;
    }

    override void compile(Backend b)
    {
        b.compile(this);
    }
}

class IfStatement : Statement
{
    Expression condition;
    Statement ifbody, elsebody;

    this(Expression condition, Statement ifbody, Statement elsebody)
    {
        this.condition = condition;
        this.ifbody = ifbody;
        this.elsebody = elsebody;
    }

    override void compile(Backend b)
    {
        b.compile(this);
    }
}

class WhileStatement : Statement
{
    Expression condition;
    Statement whilebody;

    this(Expression condition, Statement whilebody)
    {
        this.condition = condition;
        this.whilebody = whilebody;
    }

    override void compile(Backend b)
    {
        b.compile(this);
    }
}

class PrintStatement : Statement
{
    Expression value;

    this(Expression value)
    {
        this.value = value;
    }

    override void compile(Backend b)
    {
        b.compile(this);
    }
}

/// Expressions ///

class Expression
{
    BEValue compile(Backend b)
    {
        throw new InternalError("compile() not implemented for Expression class: " ~ this.toString());
    }
}

class IntegerExp : Expression
{
    int e1;
    BEValue bevalue;

    this(string e1)
    {
        this.e1 = to!int(e1);
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class VarExp : Expression
{
    string e1;
    BEValue bevalue;

    this(string e1)
    {
        this.e1 = e1;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class BinExp : Expression
{
    string op;
    Expression e1, e2;

    this(string op, Expression e1, Expression e2)
    {
        this.op = op;
        this.e1 = e1;
        this.e2 = e2;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class CmpExp : Expression
{
    string op;
    Expression e1, e2;

    this(string op, Expression e1, Expression e2)
    {
        this.op = op;
        this.e1 = e1;
        this.e2 = e2;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class AndExp : Expression
{
    Expression e1, e2;

    this(Expression e1, Expression e2)
    {
        this.e1 = e1;
        this.e2 = e2;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class OrExp : Expression
{
    Expression e1, e2;

    this(Expression e1, Expression e2)
    {
        this.e1 = e1;
        this.e2 = e2;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

class NotExp : Expression
{
    Expression e1;

    this(Expression e1)
    {
        this.e1 = e1;
    }

    override BEValue compile(Backend b)
    {
        return b.compile(this);
    }
}

