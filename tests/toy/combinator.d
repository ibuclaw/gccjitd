//  Toy interpreter combinator.
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

module toy.combinator;

import toy.lex;
import toy.ast;
import toy.diag;

import std.algorithm;

///// Combinators /////


/// All combinators return a result.
struct Result
{
    Object[] values;
    int pos;
    bool inited = false;

    this(Object value, int pos)
    {
        this([value], pos);
    }

    this(Object[] values, int pos)
    {
        this.values = values;
        this.pos = pos;
        this.inited = true;
    }
}

/// Base parser class with abstract operators.
class Parser
{
    Parser opBinary(string op, T)(T rhs)
    {
        static if (op == "+")
            return new Concat(this, rhs);
        else static if (op == "*")
            return new Expr(this, rhs);
        else static if (op == "|")
            return new Alternate(this, rhs);
        else static if (op == "^")
            return new Process!T(this, rhs);
        else static if (op == "&")
            return new Process!T(this, rhs, true);
        else
            static assert(false, "Operator " ~ op ~ " not implemented");
    }

    Result opCall(Token[] tokens, int pos)
    {
        throw new InternalError("opCall not implemented for Parser class: " ~ this.toString());
    }
}

/// Top-level parser, consumes all tokens passed.
class Phrase : Parser
{
    Parser parser;

    this(Parser parser)
    {
        this.parser = parser;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result result = this.parser(tokens, pos);

        if (result.inited && result.pos == tokens.length)
            return result;
        else
            throw new ParseError("parsing statement at " ~ tokens[result.pos].value);
    }
}

/// Parse individual token that matches a particular lex.Tag
class TokenTag : Parser
{
    Tag tag;

    this(Tag tag)
    {
        this.tag = tag;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        if (pos < tokens.length && tokens[pos].tag == this.tag)
            return Result(new TokenClass(tokens[pos].value), pos + 1);
        else
            return Result();
    }
}

/// Parse individual reserved keyword or operator.
class Reserved : Parser
{
    string value;

    this(string value)
    {
        this.value = value;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        if (pos < tokens.length && tokens[pos].value == this.value && tokens[pos].tag == Tag.Reserved)
            return Result(new Keyword(tokens[pos].value), pos + 1);
        else
            return Result();
    }
}

/// Join two parsers together, returning a pair if successful.
class Concat : Parser
{
    Parser left, right;

    this(Parser left, Parser right)
    {
        this.left = left;
        this.right = right;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result lresult = this.left(tokens, pos);
        if (lresult.inited)
        {
            Result rresult = this.right(tokens, lresult.pos);
            if (rresult.inited)
            {
                lresult.values ~= rresult.values;
                return Result(lresult.values, rresult.pos);
            }
        }
        return Result();
    }
}

/// Applies a parser repeatedly, delimited by a separator until it fails.
class Expr : Parser
{
    Parser parser, separator;

    this(Parser parser, Parser separator)
    {
        this.parser = parser;
        this.separator = separator;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result result = this.parser(tokens, pos);
        Parser next = this.separator + this.parser;
        Result nresult = result;

        while (nresult.inited)
        {
            nresult = next(tokens, result.pos);
            if (nresult.inited)
            {
                result.values ~= nresult.values;
                result.pos = nresult.pos;
            }
        }
        return result;
    }
}

/// Return either left (higher precedence) or right parser.
class Alternate : Parser
{
    Parser left, right;

    this(Parser left, Parser right)
    {
        this.left = left;
        this.right = right;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result result = this.left(tokens, pos);
        if (result.inited)
            return result;
        else
            return this.right(tokens, pos);
    }
}

/// Returns a successful, even if parsing failed.
/// The unsucessful result is represented as 'null'.
class Optional : Parser
{
    Parser parser;

    this(Parser parser)
    {
        this.parser = parser;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result result = this.parser(tokens, pos);
        if (result.inited)
            return result;
        else
            return Result([null], pos);
    }
}

/// Applies a parser repeatedly until it fails.
class Repetition : Parser
{
    Parser parser;

    this(Parser parser)
    {
        this.parser = parser;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Object[] results;
        Result result = this.parser(tokens, pos);
        while (result.inited)
        {
            results ~= result.values;
            pos = result.pos;
            result = this.parser(tokens, pos);
        }
        return Result(results, pos);
    }
}

/// Manipulates an array of Result values, reducing the result down to a single element.
class Process(T) : Parser
{
    Parser parser;
    T func;
    bool repeat;

    this(Parser parser, T func, bool repeat = false)
    {
        this.parser = parser;
        this.func = func;
        this.repeat = repeat;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        Result result = this.parser(tokens, pos);
        if (result.inited)
        {
            static if (is(T : Expression function(TokenClass)))
            {
                if (result.values.length != 1)
                    goto LruntimeError;

                TokenClass value = cast(TokenClass) result.values[0];

                result.values[0] = this.func(value);
            }
            else static if (is(T : Expression function(Keyword, Expression)))
            {
                if (result.values.length != 2)
                    goto LruntimeError;

                Keyword op = cast(Keyword) result.values[0];
                Expression e = cast(Expression) result.values[1];

                result.values[0] = this.func(op, e);
                result.values.length = 1;
            }
            else static if (is(T : Expression function(Keyword, Expression, Keyword)))
            {
                if (result.values.length != 3)
                    goto LruntimeError;

                Keyword l = cast(Keyword) result.values[0];
                Expression e = cast(Expression) result.values[1];
                Keyword r = cast(Keyword) result.values[2];

                result.values[0] = this.func(l, e, r);
                result.values.length = 1;
            }
            else static if (is(T : Expression function(Expression, Keyword, Expression)))
            {
                if (this.repeat == true)
                {
                    while (result.values.length != 1)
                    {
                        if (result.values.length < 3)
                            goto LruntimeError;

                        Expression l = cast(Expression) result.values[0];
                        Keyword op = cast(Keyword) result.values[1];
                        Expression r = cast(Expression) result.values[2];

                        result.values[0] = this.func(l, op, r);
                        result.values = result.values.remove(1, 2);
                    }
                }
                else
                {
                    if (result.values.length != 3)
                        goto LruntimeError;

                    Expression l = cast(Expression) result.values[0];
                    Keyword op = cast(Keyword) result.values[1];
                    Expression r = cast(Expression) result.values[2];

                    result.values[0] = this.func(l, op, r);
                    result.values.length = 1;
                }
            }
            else static if (is(T : Statement function(Keyword, Expression)))
            {
                if (result.values.length != 2)
                    goto LruntimeError;

                Keyword op = cast(Keyword) result.values[0];
                Expression s = cast(Expression) result.values[1];

                result.values[0] = this.func(op, s);
                result.values.length = 1;
            }
            else static if (is(T : Statement function(Keyword, Statement)))
            {
                if (result.values.length != 2)
                    goto LruntimeError;

                Keyword op = cast(Keyword) result.values[0];
                Statement s = cast(Statement) result.values[1];

                result.values[0] = this.func(op, s);
                result.values.length = 1;
            }
            else static if (is(T : Statement function(Expression, Keyword, Expression)))
            {
                if (result.values.length != 3)
                    goto LruntimeError;

                Expression l = cast(Expression) result.values[0];
                Keyword op = cast(Keyword) result.values[1];
                Expression r = cast(Expression) result.values[2];

                result.values[0] = this.func(l, op, r);
                result.values.length = 1;
            }
            else static if (is(T : Statement function(Statement, Keyword, Statement)))
            {
                if (this.repeat == true)
                {
                    while (result.values.length != 1)
                    {
                        if (result.values.length < 3)
                            goto LruntimeError;

                        Statement l = cast(Statement) result.values[0];
                        Keyword op = cast(Keyword) result.values[1];
                        Statement r = cast(Statement) result.values[2];

                        result.values[0] = this.func(l, op, r);
                        result.values = result.values.remove(1, 2);
                    }
                }
                else
                {
                    if (result.values.length != 3)
                        goto LruntimeError;

                    Statement l = cast(Statement) result.values[0];
                    Keyword op = cast(Keyword) result.values[1];
                    Statement r = cast(Statement) result.values[2];

                    result.values[0] = this.func(l, op, r);
                    result.values.length = 1;
                }
            }
            else static if (is(T : Statement function(Keyword, Expression, Keyword, Statement, Keyword)))
            {
                if (result.values.length != 5)
                    goto LruntimeError;

                Keyword op1 = cast(Keyword) result.values[0];
                Expression e1 = cast(Expression) result.values[1];
                Keyword op2 = cast(Keyword) result.values[2];
                Statement s1 = cast(Statement) result.values[3];
                Keyword op3 = cast(Keyword) result.values[4];

                result.values[0] = this.func(op1, e1, op2, s1, op3);
                result.values.length = 1;
            }
            else static if (is(T : Statement function(Keyword, Expression, Keyword, Statement, Statement, Keyword)))
            {
                if (result.values.length != 6)
                    goto LruntimeError;

                Keyword op1 = cast(Keyword) result.values[0];
                Expression e1 = cast(Expression) result.values[1];
                Keyword op2 = cast(Keyword) result.values[2];
                Statement s1 = cast(Statement) result.values[3];
                Statement s2 = cast(Statement) result.values[4];
                Keyword op3 = cast(Keyword) result.values[5];

                result.values[0] = this.func(op1, e1, op2, s1, s2, op3);
                result.values.length = 1;
            }
            else
                static assert(false, "Unhandled type " ~ T.stringof);
        }
        return result;

    LruntimeError:
        throw new InternalError("Result mismatch at " ~ tokens[result.pos].value);
    }
}

/// For building recursive parsers, delays getting the parser until it's applied.
class Lazy : Parser
{
    Parser parser;
    Parser function() func;

    this(Parser function() func)
    {
        this.parser = null;
        this.func = func;
    }

    override Result opCall(Token[] tokens, int pos)
    {
        if (this.parser is null)
            this.parser = this.func();
        return this.parser(tokens, pos);
    }
}

