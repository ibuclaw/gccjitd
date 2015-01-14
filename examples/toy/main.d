//  Toy interpreter.
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

module toy.main;

import toy.lex;
import toy.ast;
import toy.parse;
import toy.backend;

import std.file;

/// Main ///

void main(string[] args)
{
    if (args.length != 2)
        return;

    string input = cast(string) read(args[1]);

    auto tokens = lex(input);
    auto expr = parse(tokens);

    Backend backend = new Backend;
    expr.compile(backend);
    backend.run();
    return;
}
