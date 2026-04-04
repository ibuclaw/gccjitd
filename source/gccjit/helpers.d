/// A D API for libgccjit, purely as struct wrapper functions.
/// Copyright (C) 2014-2026 Iain Buclaw.

/// This file is part of gccjitd.

/// This program is free software: you can redistribute it and/or modify
/// it under the terms of the GNU General Public License as published by
/// the Free Software Foundation, either version 3 of the License, or
/// (at your option) any later version.

/// This program is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU General Public License for more details.

/// You should have received a copy of the GNU General Public License
/// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module gccjit.helpers;

package(gccjit):

// Slices a `\0`-terminated C-string, excluding the terminator
string toDString (inout(char)* s) pure nothrow @nogc
{
    import core.stdc.string : strlen;
    return s ? cast(string)s[0 .. strlen(s)] : null;
}

// Given a raw memory area `chunk` (but already typed as an Exception `T`),
// constructs an object of `class` type `T` at that address. The constructor
// is passed the arguments `Args`.
// Returns: The newly constructed object.
private T emplaceException(T, Args...)(T chunk, auto ref Args args)
    if (is(T : Exception))
{
    static assert(!__traits(isAbstractClass, T), T.stringof ~
        " is abstract and it can't be emplaced");

    // Initialize the object in its pre-ctor state
    static if (__traits(compiles, __traits(initSymbol, T)))
        const initializer = __traits(initSymbol, T);
    else
        const initializer = typeid(T).initializer[];
    () @trusted { (cast(void*) chunk)[0 .. initializer.length] = cast(void[]) initializer[]; }();

    // Call the ctor if any
    static if (is(typeof(chunk.__ctor(args))))
    {
        // T defines a genuine constructor accepting args
        // Go the classic route: write .init first, then call ctor
        chunk.__ctor(args);
    }
    else
    {
        static assert(args.length == 0 && !is(typeof(&T.__ctor)),
            "Don't know how to initialize an object of type "
            ~ T.stringof ~ " with arguments " ~ typeof(args).stringof);
    }
    return chunk;
}

// TLS storage shared for all exceptions, chaining might create circular reference
private align(2 * size_t.sizeof) void[256] _store;

T staticException(T, Args...)(auto ref Args args)
    if (is(T : Exception))
{
    // pure hack, what we actually need is @noreturn and allow to call that in pure functions
    static T get()
    {
        static assert(__traits(classInstanceSize, T) <= _store.length,
                      T.stringof ~ " is too large for staticException()");

        return cast(T) _store.ptr;
    }
    auto res = (cast(T function() @trusted pure nothrow @nogc) &get)();
    emplaceException(res, args);
    return res;
}

// Defines a temporary array of `char`s using a fixed-length buffer as back
// store. If the length of the buffer suffices, it is readily used. Otherwise,
// `malloc` is used to allocate memory for the array and `free` is used for
// deallocation in the destructor.

// This type is meant to use exclusively as an automatic variable. It is not
// default constructible or copyable.
private struct SmallBuffer
{
    import core.stdc.stdlib : malloc, free;

    private char[] _extent;
    private bool needsFree;

nothrow:
@nogc:

    @disable this(); // no default ctor
    @disable this(ref const SmallBuffer); // noncopyable, nonassignable

    // Construct a SmallBuffer
    // Params:
    //  len = number of elements in array
    //  buffer = slice to use as backing-store, if len will fit in it
    scope this(size_t len, return scope char[] buffer)
    {
        if (len <= buffer.length)
        {
            _extent = buffer[0 .. len];
        }
        else
        {
            assert(len < size_t.max / (2 * char.sizeof));
            _extent = (cast(typeof(_extent.ptr)) malloc(len * char.sizeof))[0 .. len];
            _extent.ptr || assert(0, "Out of memory.");
            needsFree = true;
        }
        assert(length == len);
    }

    ~this()
    {
        if (needsFree)
            free(_extent.ptr);
    }

    // Force accesses to extent to be scoped.
    scope inout extent()
    {
        return _extent;
    }

    alias extent this;
}

unittest
{
    char[230] buf = void;
    auto a = SmallBuffer(10, buf);
    assert(a[] is buf[0 .. 10]);
    auto b = SmallBuffer(1000, buf);
    assert(b[] !is buf[]);
}

// Copy the content of `src` into a C-string ('\0' terminated) then call `dg`
// The intent of this function is to provide an allocation-less
// way to call a C function using a D slice.
// The function internally allocates a buffer if needed, but frees it on exit.
// Note:
//   The argument to `dg` is `scope`. To keep the data around after `dg` exits,
//   one has to copy it.
// Params:
//   src = Slice to use to call the C function
//   dg  = Delegate to call afterwards
// Returns:
//   The return value of `T`
auto toCStringThen(alias dg)(const(char)[] src) nothrow
{
    const len = src.length + 1;
    char[512] small = void;
    auto sb = SmallBuffer(len, small[]);
    scope ptr = sb[];
    ptr[0 .. src.length] = src[];
    ptr[src.length] = '\0';
    return dg(ptr);
}

unittest
{
    assert("Hello world".toCStringThen!((v) => v == "Hello world\0"));
    assert("Hello world\0".toCStringThen!((v) => v == "Hello world\0\0"));
    assert(null.toCStringThen!((v) => v == "\0"));
}
