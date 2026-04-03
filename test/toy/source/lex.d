//  Toy interpreter lexer.
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

module toy.lex;

import std.array;
import std.regex;
import std.string;

///// Tokenizer /////
enum Tag
{
    None,
    Reserved,
    Integer,
    Identifier,
}

struct Token
{
    string value;
    Tag tag;
}

Token[] token_exprs = [
    Token(`^[ \n\t]+`, Tag.None),
    Token(`^#[^\n]*`,  Tag.None),
    Token(`^\:=`,      Tag.Reserved),
    Token(`^\(`,       Tag.Reserved),
    Token(`^\)`,       Tag.Reserved),
    Token(`^;`,        Tag.Reserved),
    Token(`^\+`,       Tag.Reserved),
    Token(`^-`,        Tag.Reserved),
    Token(`^\*`,       Tag.Reserved),
    Token(`^/`,        Tag.Reserved),
    Token(`^<=`,       Tag.Reserved),
    Token(`^<`,        Tag.Reserved),
    Token(`^=>`,       Tag.Reserved),
    Token(`^>`,        Tag.Reserved),
    Token(`^=`,        Tag.Reserved),
    Token(`^!=`,       Tag.Reserved),
    Token(`^and\b`,    Tag.Reserved),
    Token(`^or\b`,     Tag.Reserved),
    Token(`^not\b`,    Tag.Reserved),
    Token(`^if\b`,     Tag.Reserved),
    Token(`^then\b`,   Tag.Reserved),
    Token(`^else\b`,   Tag.Reserved),
    Token(`^while\b`,  Tag.Reserved),
    Token(`^do\b`,     Tag.Reserved),
    Token(`^end\b`,    Tag.Reserved),
    Token(`^print\b`,  Tag.Reserved),
    Token(`^[0-9]+\b`, Tag.Integer),
    Token(`^[A-Za-z][A-Za-z0-9_]*\b`, Tag.Identifier),
];

Token[] lex(string input)
{
    int pos = 0;
    Appender!(Token[]) tokens;

Lnext:
    while (pos < input.length)
    {
        foreach (token; token_exprs)
        {
            auto match = matchFirst(input[pos .. $], regex(token.value));
            if (match)
            {
                if (token.tag != Tag.None)
                    tokens.put(Token(match[0], token.tag));
                pos += match[0].length;
                continue Lnext;
            }
        }
        throw new Exception(format("Illegal character: %s", input[pos]));
    }
    return tokens.data;
}

