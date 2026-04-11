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

module gccjit.timer;

package(gccjit):

import gccjit.bindings;
import gccjit.context;
import gccjit.helpers;

import core.stdc.stdio : FILE;

/// Struct wrapper for gcc_jit_timer
/// This API endpoint was added in LIBGCCJIT_ABI_4; you can test for
/// its presence using `if (JIT.Have_Timing_API)`.
struct Timer
{
    ///
    this(bool start_timer) nothrow @nogc
    {
        if (start_timer)
            m_start(this);
    }

    ///
    this(gcc_jit_timer* timer) pure nothrow @nogc
    {
        m_timer = timer;
        m_constructed = true;
    }

    /// Returns the internal gcc_jit_timer object.
    gcc_jit_timer* get_timer() nothrow @nogc
    {
        m_start(this);
        return m_timer;
    }

    /// Push the given item onto the timing stack.
    void push(string item_name)() nothrow @nogc
    {
        m_start(this);
        gcc_jit_timer_push(m_timer, item_name.ptr);
    }

    /// Pop the top item from the timing stack.
    void pop(string item_name)() nothrow @nogc
    {
        m_start(this);
        gcc_jit_timer_pop(m_timer, item_name.ptr);
    }

    /// Print timing information to the given stream about activity since
    /// the timer was started.
    void print(FILE* f_out) nothrow @nogc
    {
        m_start(this);
        gcc_jit_timer_print(m_timer, f_out);
    }

    /// Release a JIT.Timer instance
    void release() nothrow @nogc
    {
        m_start(this);
        gcc_jit_timer_release(m_timer);
        m_timer = null;
    }

private:
    gcc_jit_timer* m_timer = null;

    // Internal handling of dealing with default construction
    // using a runtime-only value, as ideally we should start
    // timing the moment the object is created.
    bool m_constructed = false;

    pragma(inline, true)
    static void m_start()(ref Timer t) nothrow @nogc
    {
        if (!t.m_constructed)
        {
            t.m_timer = gcc_jit_timer_new();
            t.m_constructed = true;
        }
    }

}

/// Convenience type for handling the starting/stopping of the JIT.Timer
struct AutoTime(string item_name)
{
    @disable this(); // no default ctor

    ///
    this(Timer t) nothrow @nogc
    {
        Timer.m_start(t);
        timer = t;
        timer.push!item_name();
    }

    ///
    this(Context ctxt) nothrow @nogc
    {
        timer = ctxt.timer();
        timer.push!item_name();
    }

    ~this() nothrow @nogc
    {
        timer.pop!item_name();
    }

private:
    Timer timer;
}
