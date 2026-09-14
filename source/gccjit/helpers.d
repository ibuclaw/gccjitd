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

@system unittest
{
    assert(toDString(null) is null);

    char[1] empty = ['\0'];
    auto result = toDString(empty.ptr);
    assert(result.length == 0);
    assert(result.ptr == empty.ptr);

    char[6] hello = "hello";
    result = toDString(hello.ptr);
    assert(result == "hello");
    assert(result.length == 5);
    assert(result.ptr == hello.ptr);

    char[8] embedded = ['a', 'b', '\0', 'c', 'd', '\0', '\0', '\0'];
    result = toDString(embedded.ptr);
    assert(result == "ab");
    assert(result.length == 2);

    char[4] mutable = ['a', 'b', 'c', '\0'];
    const s = toDString(mutable.ptr);
    mutable[1] = 'X';
    assert(s == "aXc");
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

@system unittest
{
    char[230] buf = void;
    auto a = SmallBuffer(10, buf);
    assert(a[] is buf[0 .. 10]);
    auto b = SmallBuffer(1000, buf);
    assert(b[] !is buf[]);
}

@system unittest
{
    char[16] buf = void;

    auto zero = SmallBuffer(0, buf);
    assert(zero.length == 0);
    assert(zero[] is buf[0 .. 0]);

    auto exact = SmallBuffer(buf.length, buf);
    assert(exact[] is buf[]);

    auto beyond = SmallBuffer(buf.length + 1, buf);
    assert(beyond.length == buf.length + 1);
    assert(beyond[] !is buf[]);
}

@system unittest
{
    char[4] buf = void;
    auto sb = SmallBuffer(1000, buf);

    foreach (i, ref c; sb)
        c = cast(char)(i % 127);

    foreach (i, c; sb)
        assert(c == cast(char)(i % 127));
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
    import core.stdc.string : memcpy;
    const len = src.length + 1;
    char[512] small = void;
    auto sb = SmallBuffer(len, small[]);
    scope ptr = sb[];

    src.length < ptr.length || abort!"Mismatched array lengths in toCStringThen";
    immutable diff = src.ptr > ptr.ptr ? src.ptr - ptr.ptr : ptr.ptr - src.ptr;
    diff >= src.length || abort!"Overlapping arrays in toCStringThen";

    memcpy(ptr.ptr, src.ptr, src.length);
    ptr[src.length] = '\0';
    return dg(ptr);
}

@system unittest
{
    assert("Hello world".toCStringThen!((v) => v == "Hello world\0"));
    assert("Hello world\0".toCStringThen!((v) => v == "Hello world\0\0"));
    assert(null.toCStringThen!((v) => v == "\0"));
    assert("abc".toCStringThen!((v) => v.length == 4));
    assert("abc".toCStringThen!((v) => false) == false);
    assert("abc".toCStringThen!((v) => 123) == 123);
}

@system unittest
{
    char[511] src;
    src[] = 'x';

    auto called = false;
    src[].toCStringThen!((v) {
        called = true;
        assert(v.length == 512);
        assert(v[0 .. 511] == src[]);
        assert(v[511] == '\0');
        return true;
    });

    assert(called);
}

@system unittest
{
    char[512] src;
    src[] = 'x';

    assert(src[].toCStringThen!((v) {
        assert(v.length == 513);
        assert(v[0 .. 512] == src[]);
        assert(v[512] == '\0');
        return true;
    }));
}

@system unittest
{
    char[5] src = "hello";

    assert(src[].toCStringThen!((v) {
        v[0] = 'X';
        assert(src[] == "hello");
        assert(v == "Xello\0");
        return true;
    }));
}

@system unittest
{
    const(char)[] src = "ab\0cd";

    assert(src.toCStringThen!((v) {
        assert(v.length == 6);
        assert(v == "ab\0cd\0");
        return true;
    }));
}

// Print message to stderr then abort runtime.
pragma(inline, true)
void abort(string msg)() @nogc nothrow
{
    import core.stdc.stdio : fputs, stderr;
    import core.stdc.stdlib : abort;
    fputs(msg.ptr, stderr);
    fputs("\n", stderr);
    abort();
}

// Get the lvalue sequence of function parameters from the
// signature in string `args`. For example, given the value
//      "const char* str, int val"
// Firstly, split the args string by comma:
//      ["const char* str", "int val"]
// Secondly, find the last occurrence of a space character in each index,
// then append the slice to the end of string to the returned array.
//      ["str", "val"]
// This relies on any `*` being next to the type, and not the arg name.
private template parameters(string args)
{
    enum parameters = () {
        string[] parts;
        {
            size_t i = 0;
            while (i < args.length)
            {
                while (i < args.length && args[i] == ',')
                    ++i;
                if (i >= args.length)
                    break;
                size_t j = i;
                while (j < args.length && args[j] != ',')
                    ++j;
                parts ~= args[i .. j];
                i = j;
            }
        }
        string names;
        foreach (part; parts)
        {
            size_t i = part.length;
            while (i > 0)
            {
                if (part[i - 1] == ' ')
                    break;
                i--;
            }
            if (names.length)
                names ~= ", ";
            names ~= part[i .. $];
        }
        return names;
    }();
}

@system unittest
{
    assert(parameters!"const char* str, int val" == "str, val");
    assert(parameters!"int a" == "a");
    assert(parameters!"int a, int b, int c" == "a, b, c");
    assert(parameters!"" == "");

    assert(parameters!",int a" == "a");
    assert(parameters!"int a," == "a");
    assert(parameters!"int a,,int b" == "a, b");
    assert(parameters!",,int a,,int b,," == "a, b");

    assert(parameters!"const char* str, void* data, int count" == "str, data, count");
}

// Get the handle of the main executable.
void* getHandle() nothrow @nogc
{
    version (Windows)
    {
        import core.sys.windows.winbase : GetModuleHandleA;
        return GetModuleHandleA(null);
    }
    else
    {
        import core.sys.posix.dlfcn : dlopen, RTLD_LAZY;
        return dlopen(null, RTLD_LAZY);
    }
}

@system unittest
{
    const handle = getHandle();
    assert(handle !is null);
}

// Lookup a symbol in the `handle` and assign it to `ptr`
void* getSymbol(void* handle, scope const char* name, void** ptr) nothrow @nogc
{
    version (Windows)
    {
        import core.sys.windows.winbase : GetProcAddress;
        alias dlsym = GetProcAddress;
    }
    else
    {
        import core.sys.posix.dlfcn : dlsym;
    }
    if (auto symbol = dlsym(handle, name))
    {
        *ptr = symbol;
        return symbol;
    }
    return null;
}

@system unittest
{
    void* ptr = cast(void*)0x1234;
    auto handle = getHandle();

    auto result = getSymbol(handle, "__definitely_not_a_real_symbol__", &ptr);
    assert(result is null);
    assert(ptr == cast(void*)0x1234);

    result = getSymbol(handle, "gcc_jit_context_acquire", &ptr);
    assert(result !is null);
    assert(ptr == result);
}

// Generate ifunc code for initialising all function pointers in gccjit.bindings.
template ifunc(string type, string name, string args)
{
    enum ifunc =
    type ~ ` function(` ~ args ~ `) c_` ~ name ~ ` = (` ~ args ~ `)
{
    import gccjit.helpers : abort, getHandle, getSymbol;
    c_` ~ name ~ ` = null;
    if (auto handle = getHandle()) {
        if (getSymbol(handle, "` ~ name ~ `", cast(void**)&c_` ~ name ~ `))
            return c_` ~ name ~ `(` ~ parameters!args ~ `);
    }
    abort!"Attempt to execute an unresolved gccjit function: ` ~ name ~ `";
    assert(0);
};
alias ` ~ name ~ ` = c_` ~ name ~ `;`;
}

@system unittest
{
    assert(ifunc!("int", "foo", "int x") ==
`int function(int x) c_foo = (int x)
{
    import gccjit.helpers : abort, getHandle, getSymbol;
    c_foo = null;
    if (auto handle = getHandle()) {
        if (getSymbol(handle, "foo", cast(void**)&c_foo))
            return c_foo(x);
    }
    abort!"Attempt to execute an unresolved gccjit function: foo";
    assert(0);
};
alias foo = c_foo;`);
}

// Generate Have_* code for check whether gccjit has the feature in the linked
// libgccjit library. Assigns found symbols to the function pointers in
// gccjit.bindings as we are looking up the symbol.
template Have(string[] names)
{
    enum Have = () {
        string code = `
        // cache lookup in a tristate: no=-1, yes=1, dunno=0
        enum : byte { Dunno = 0, No = -1, Yes = 1 }
        __gshared byte have = Dunno;
        if (have != Dunno)
            return have == Yes;
        have = No;
        import gccjit.helpers : getHandle, getSymbol;
        if (auto handle = getHandle()) {`;
        foreach (name; names)
        {
            code ~= `
            if (!getSymbol(handle, "` ~ name ~ `", cast(void**)&c_` ~ name ~ `))
                return false;`;
        }
        code ~= `
        } else
            return false;
        have = Yes;
        return true;`;
        return code;
    }();
}

@system unittest
{
    const void function() c_gcc_jit_context_acquire;
    bool haveKnownSymbol() { mixin(Have!(["gcc_jit_context_acquire"])); }

    const void function() c___definitely_missing_symbol__;
    bool haveMissingSymbol() { mixin(Have!(["__definitely_missing_symbol__"])); }

    assert(haveKnownSymbol());
    assert(haveKnownSymbol());

    assert(!haveMissingSymbol());
    assert(!haveMissingSymbol());
}
