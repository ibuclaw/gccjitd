//  A simple stack-based virtual machine to demonstrate JIT-compilation.
//
// Copyright (C) 2026 Iain Buclaw.
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

// Written by Iain Buclaw <ibuclaw@gdcproject.org>

module toyvm.main;

import gccjit;

/// Functions are compiled to this function ptr type.
alias toyvm_compiled_func = extern(C) int function(int);

enum OP
{
    /// Ops taking no operand.
    DUP,
    ROT,
    BINARY_ADD,
    BINARY_SUBTRACT,
    BINARY_MULT,
    BINARY_COMPARE_LT,
    RECURSE,
    RETURN,
    /// Ops taking an operand.
    PUSH_CONST,
    JUMP_ABS_IF_TRUE,
}

immutable opcode_names = [__traits(allMembers, OP)];
enum FIRST_UNARY_OPCODE = OP.PUSH_CONST;
enum MAX_OPS = 64;
enum MAX_STACK_DEPTH = 8;

struct toyvm_op
{
    OP code;     /// Which operation.
    int operand; /// Some opcodes take an argument.
    int linenum; /// The line number of the operation within the source file.
}

struct toyvm_function
{
    void add_op(OP code, int operand, int linenum) nothrow @nogc
    {
        assert(fn_num_ops < MAX_OPS);
        auto op = &fn_ops[fn_num_ops++];
        op.code = code;
        op.operand = operand;
        op.linenum = linenum;
    }

    void add_unary_op(OP code, string rest_of_line, int linenum)
    {
        import std.conv : to;
        import std.string : strip;
        int operand = to!int(rest_of_line.strip);
        add_op(code, operand, linenum);
    }

    static toyvm_function* parse(string filename)
    {
        import std.range : empty;
        import std.stdio : File, stderr;
        import std.string : chomp, startsWith;

        assert(!filename.empty);

        File file;
        try file = File(filename, "r");
        catch (Exception e)
        {
            static if (__traits(compiles, e.message))
                stderr.writefln("cannot open file %s: %s", filename, e.message);
            else
                stderr.writefln("cannot open file %s: %s", filename, e.msg);
            return null;
        }

        auto fn = new toyvm_function(filename);
        fn.make_function_name(filename);

        // Read the lines of the file.
        int linenum;
        foreach (line; file.byLineCopy())
        {
            // Note that this is a terrible parser. :-)
            ++linenum;
            auto text = line.chomp;

            // Lines beginning with # are comments.
            if (text.startsWith("#"))
                continue;

            // Skip blank lines.
            if (text.empty)
                continue;

        Lswitch:
            switch (text)
            {
                foreach (code; __traits(allMembers, OP)[0 .. FIRST_UNARY_OPCODE])
                {
                    // Unrolls all cases for ops taking no operand.
                    case code:
                        fn.add_op(__traits(getMember, OP, code), 0, linenum);
                        break Lswitch;
                }
                // Handle all other unary ops.
                default:
                    foreach (code; __traits(allMembers, OP)[FIRST_UNARY_OPCODE .. $])
                    {
                        auto prefix = code ~ " ";
                        if (text.startsWith(prefix))
                        {
                            fn.add_unary_op(__traits(getMember, OP, code),
                                            text[prefix.length .. $], linenum);
                            break Lswitch;
                        }
                    }
                    stderr.writefln("%s:%d: parse error", filename, linenum);
                    return null;
            }
        }

        if (fn.fn_num_ops == 0)
        {
            stderr.writefln("%s: empty program", filename);
            return null;
        }
        return fn;
    }

    int interpret(int arg) nothrow @nogc
    {
        with (toyvm_frame(&this))
        {
            push(arg);

            while (true)
            {
                assert(frm_pc < fn_num_ops);
                auto op = &fn_ops[frm_pc++];
                int x, y;

                final switch (op.code)
                {
                // Ops taking no operand.
                case OP.DUP:
                    x = pop();
                    push(x);
                    push(x);
                    break;

                case OP.ROT:
                    y = pop();
                    x = pop();
                    push(y);
                    push(x);
                    break;

                case OP.BINARY_ADD:
                    y = pop();
                    x = pop();
                    push(x + y);
                    break;

                case OP.BINARY_SUBTRACT:
                    y = pop();
                    x = pop();
                    push(x - y);
                    break;

                case OP.BINARY_MULT:
                    y = pop();
                    x = pop();
                    push(x * y);
                    break;

                case OP.BINARY_COMPARE_LT:
                    y = pop();
                    x = pop();
                    push(x < y);
                    break;

                case OP.RECURSE:
                    x = pop();
                    x = interpret(x);
                    push(x);
                    break;

                case OP.RETURN:
                    return pop();

                // Ops taking an operand.
                case OP.PUSH_CONST:
                    push(op.operand);
                    break;

                case OP.JUMP_ABS_IF_TRUE:
                    x = pop();
                    if (x)
                        frm_pc = op.operand;
                    break;
                }
            } // end of switch on op.code
        } // end of while loop
    }

    // The main compilation hook.
    JIT.CompileResult compile()
    {
        with (compilation_state(&this))
        {
            create_context();
            create_types();
            create_locations();
            create_function(get_function_name());
            return compile();
        }
    }

    string get_function_name() const nothrow @nogc
    {
        return m_funcname;
    }

    void make_function_name(string filename) nothrow @nogc
    {
        // Copy filename to funcname.
        import std.path : stripExtension, baseName;
        m_funcname = filename.stripExtension.baseName;
    }

    string fn_filename;
    string m_funcname;
    int fn_num_ops;
    toyvm_op[MAX_OPS] fn_ops;
}

struct toyvm_frame
{
    void push(int arg) nothrow @nogc
    {
        assert(frm_cur_depth < MAX_STACK_DEPTH);
        frm_stack[frm_cur_depth++] = arg;
    }

    int pop() nothrow @nogc
    {
        assert(frm_cur_depth > 0);
        return frm_stack[--frm_cur_depth];
    }

    toyvm_function *frm_function;
    int frm_pc;
    int[MAX_STACK_DEPTH] frm_stack;
    int frm_cur_depth;
}

/// JIT compilation
struct compilation_state
{
    /// Create the context.
    void create_context() nothrow @nogc
    {
        ctxt = JIT.Context.acquire()
            .set_dump_initial_gimple(false)
            .set_dump_generated_code(false)
            .set_optimization_level(OptimizationLevel.Aggressive)
            .set_keep_intermediates(false)
            .set_dump_everything(false)
            .set_debug_info(true);
    }

    /// Create types.
    void create_types() nothrow @nogc
    {
        int_type = ctxt.get_type(CType.Int);
        bool_type = ctxt.get_type(CType.Bool);
        stack_type = ctxt.new_array_type(int_type, MAX_STACK_DEPTH);

        // The constant value 1.
        const_one = ctxt.new_rvalue_one(int_type);
    }

    /// Create locations.
    void create_locations() nothrow @nogc
    {
        foreach (pc; 0 .. toyvmfn.fn_num_ops)
        {
            op_locs[pc] = ctxt.new_location(toyvmfn.fn_filename,
                                            toyvmfn.fn_ops[pc].linenum, 0);
        }
    }

    /// Creating the function.
    void create_function(string funcname) nothrow
    {
        param_arg = ctxt.new_param(op_locs[0], int_type, "arg");
        fn = ctxt.new_function(op_locs[0], FunctionType.Exported,
                               int_type, funcname, false, param_arg);

        // Create stack lvalues.
        stack = fn.new_local(stack_type, "stack");
        stack_depth = fn.new_local(int_type, "stack_depth");
        x = fn.new_local(int_type, "x");
        y = fn.new_local(int_type, "y");

        // 1st pass: create blocks, one per opcode.

        // We need an entry block to do one-time initialization, so create that first.
        initial_block = fn.new_block("initial");

        // Create a block per operation.
        foreach (pc; 0 .. toyvmfn.fn_num_ops)
        {
            import std.conv : to;
            op_blocks[pc] = fn.new_block("instr" ~ to!string(pc));
        }

        // Populate the initial block.

        // stack_depth = 0
        initial_block.add_assignment(op_locs[0], stack_depth, ctxt.new_rvalue_zero(int_type));

        // PUSH (arg)
        add_push(initial_block, op_locs[0], param_arg);

        // ...and jump to insn 0
        initial_block.end_with_jump(op_locs[0], op_blocks[0]);

        // 2nd pass: fill in instructions.
        foreach (pc; 0 .. toyvmfn.fn_num_ops)
        {
            auto loc = op_locs[pc];
            auto block = op_blocks[pc];
            auto next_block = (pc + 1 < toyvmfn.fn_num_ops ? op_blocks[pc + 1] : JIT.Block());

            toyvm_op* op = &toyvmfn.fn_ops[pc];

            block.add_comment(loc, opcode_names[op.code]);

            // Handle the individual opcodes.
            final switch (op.code)
            {
            case OP.DUP:
                add_pop(block, loc, x);
                add_push(block, loc, x);
                add_push(block, loc, x);
                break;

            case OP.ROT:
                add_pop(block, loc, y);
                add_pop(block, loc, x);
                add_push(block, loc, y);
                add_push(block, loc, x);
                break;

            case OP.BINARY_ADD:
                add_pop(block, loc, y);
                add_pop(block, loc, x);
                add_push(block, loc, ctxt.new_binary_op(loc, BinaryOp.Plus, int_type, x, y));
                break;

            case OP.BINARY_SUBTRACT:
                add_pop(block, loc, y);
                add_pop(block, loc, x);
                add_push(block, loc, ctxt.new_binary_op(loc, BinaryOp.Minus, int_type, x, y));
                break;

            case OP.BINARY_MULT:
                add_pop(block, loc, y);
                add_pop(block, loc, x);
                add_push(block, loc, ctxt.new_binary_op(loc, BinaryOp.Mult, int_type, x, y));
                break;

            case OP.BINARY_COMPARE_LT:
                add_pop(block, loc, y);
                add_pop(block, loc, x);
                add_push(block, loc,
                         // cast of bool to int
                         ctxt.new_cast(loc,
                                       // (x < y) as a bool
                                       ctxt.new_comparison(loc, ComparisonOp.LessThan, x, y),
                                       int_type));
                break;

            case OP.RECURSE:
                add_pop(block, loc, x);
                add_push(block, loc, ctxt.new_call(loc, fn, x));
                break;

            case OP.RETURN:
                add_pop(block, loc, x);
                block.end_with_return(loc, x);
                break;

            // Ops taking an operand.
            case OP.PUSH_CONST:
                add_push(block, loc, ctxt.new_rvalue(int_type, op.operand));
                break;

            case OP.JUMP_ABS_IF_TRUE:
                add_pop(block, loc, x);
                block.end_with_conditional(loc,
                                           // (bool)x
                                           ctxt.new_cast(loc, x, bool_type),
                                           op_blocks[op.operand], // on_true
                                           next_block); // on_false
                break;
            } // end of switch on opcode

            // Go to the next block.
            if (op.code != OP.JUMP_ABS_IF_TRUE && op.code != OP.RETURN)
                block.end_with_jump(loc, next_block);

        } // end of loop on PC locations.
    }

    JIT.CompileResult compile() nothrow @nogc
    {
        return ctxt.compile();
    }

    /// Stack manipulation.
    void add_push(JIT.Block block, JIT.Location loc, JIT.RValue rvalue) nothrow @nogc
    {
        block
        // stack[stack_depth] = RVALUE
        .add_assignment(loc, ctxt.new_array_access(loc, stack, stack_depth), rvalue)
        // stack_depth++
        .add_assignment_op(loc, stack_depth, BinaryOp.Plus, const_one);
    }

    void add_pop(JIT.Block block, JIT.Location loc, JIT.LValue lvalue) nothrow @nogc
    {
        block
        // --stack_depth
        .add_assignment_op(loc, stack_depth, BinaryOp.Minus, const_one)
        // lvalue = stack[stack_depth]
        .add_assignment(loc, lvalue, ctxt.new_array_access(loc, stack, stack_depth));
    }

    toyvm_function* toyvmfn;
    JIT.Context ctxt;

    JIT.Type int_type;
    JIT.Type bool_type;
    JIT.Type stack_type; // int[MAX_STACK_DEPTH]

    JIT.RValue const_one;

    JIT.Function fn;
    JIT.Parameter param_arg;
    JIT.LValue stack;
    JIT.LValue stack_depth;
    JIT.LValue x;
    JIT.LValue y;

    JIT.Location[MAX_OPS] op_locs;
    JIT.Block initial_block;
    JIT.Block[MAX_OPS] op_blocks;
}

int main(string[] args)
{
    import std.conv : to;
    import std.stdio : stdout;
    if (args.length != 3)
    {
        stdout.writefln("%s FILENAME INPUT: Parse and run a .toy file", args[0]);
        return 1;
    }

    string filename = args[1];
    auto fn = toyvm_function.parse(filename);
    if (fn is null)
        return 1;

    // JIT-compilation
    auto compiler_result = fn.compile();
    auto funcname = fn.get_function_name();
    auto code = compiler_result.get_code!toyvm_compiled_func(funcname);

    auto arg = to!int(args[2]);
    if (fn.interpret(arg) != code(arg))
        return 1;

    return 0;
}
