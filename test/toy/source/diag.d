//  Toy interpreter error handling.
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

module toy.diag;

/// Recoverable errors in input logic.
class ParseError : Exception
{
    @safe pure nothrow this(string msg, Throwable next = null)
    {
        super(msg, next);
    }

    @safe pure nothrow this(string msg, string file, size_t line, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/// ICE in program logic.
class InternalError : Error
{
    @safe pure nothrow this(string msg, Throwable next = null)
    {
        super("ICE: " ~ msg, next);
    }

    @safe pure nothrow this(string msg, string file, size_t line, Throwable next = null)
    {
        super("ICE: " ~ msg, file, line, next);
    }
}
