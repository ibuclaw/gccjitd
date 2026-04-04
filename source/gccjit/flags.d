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

module gccjit.flags;

import gccjit.bindings;

/// Kinds of function.
enum FunctionType : gcc_jit_function_kind
{
    /// Function is defined by the client code and visible by name
    /// outside of the JIT.
    Exported = GCC_JIT_FUNCTION_EXPORTED,
    /// Function is defined by the client code, but is invisible
    /// outside of the JIT.
    Internal = GCC_JIT_FUNCTION_INTERNAL,
    /// Function is not defined by the client code; we're merely
    /// referring to it.
    Imported = GCC_JIT_FUNCTION_IMPORTED,
    /// Function is only ever inlined into other functions, and is
    /// invisible outside of the JIT.
    AlwaysInline = GCC_JIT_FUNCTION_ALWAYS_INLINE,
}

/// Kinds of global.
enum GlobalKind : gcc_jit_global_kind
{
  /// Global is defined by the client code and visible by name
  /// outside of this JIT context.
  Exported = GCC_JIT_GLOBAL_EXPORTED,
  /// Global is defined by the client code, but is invisible
  /// outside of this JIT context.  Analogous to a "static" global.
  Internal = GCC_JIT_GLOBAL_INTERNAL,
  /// Global is not defined by the client code; we're merely
  /// referring to it.  Analogous to using an "extern" global.
  Imported = GCC_JIT_GLOBAL_IMPORTED,
}

/// Standard types.
enum CType : gcc_jit_types
{
    /// C's void type.
    Void = GCC_JIT_TYPE_VOID,

    /// C's void* type.
    VoidPtr = GCC_JIT_TYPE_VOID_PTR,

    /// C++'s bool type.
    Bool = GCC_JIT_TYPE_BOOL,

    /// C's char type.
    Char = GCC_JIT_TYPE_CHAR,

    /// C's signed char type.
    SChar = GCC_JIT_TYPE_SIGNED_CHAR,

    /// C's unsigned char type.
    UChar = GCC_JIT_TYPE_UNSIGNED_CHAR,

    /// C's short type.
    Short = GCC_JIT_TYPE_SHORT,

    /// C's unsigned short type.
    UShort = GCC_JIT_TYPE_UNSIGNED_SHORT,

    /// C's int type.
    Int = GCC_JIT_TYPE_INT,

    /// C's unsigned int type.
    UInt = GCC_JIT_TYPE_UNSIGNED_INT,

    /// C's long type.
    Long = GCC_JIT_TYPE_LONG,

    /// C's unsigned long type.
    ULong = GCC_JIT_TYPE_UNSIGNED_LONG,

    /// C99's long long type.
    LongLong = GCC_JIT_TYPE_LONG_LONG,

    /// C99's unsigned long long type.
    ULongLong = GCC_JIT_TYPE_UNSIGNED_LONG_LONG,

    /// Single precision floating point type.
    Float = GCC_JIT_TYPE_FLOAT,

    /// Double precision floating point type.
    Double = GCC_JIT_TYPE_DOUBLE,

    /// Largest supported floating point type.
    LongDouble = GCC_JIT_TYPE_LONG_DOUBLE,

    /// C's const char* type.
    ConstCharPtr = GCC_JIT_TYPE_CONST_CHAR_PTR,

    /// C's size_t type.
    SizeT = GCC_JIT_TYPE_SIZE_T,

    /// C's FILE* type.
    FilePtr = GCC_JIT_TYPE_FILE_PTR,

    /// Single precision complex float type.
    ComplexFloat = GCC_JIT_TYPE_COMPLEX_FLOAT,

    /// Double precision complex float type.
    ComplexDouble = GCC_JIT_TYPE_COMPLEX_DOUBLE,

    /// Largest supported complex float type.
    ComplexLongDouble = GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE,
}

/// Kinds of unary ops.
enum UnaryOp : gcc_jit_unary_op
{
    /// Negate an arithmetic value.
    /// This is equivalent to "-(value)".
    Minus = GCC_JIT_UNARY_OP_MINUS,
    /// Bitwise negation of an integer value (one's complement).
    /// This is equivalent to "~(value)".
    BitwiseNegate = GCC_JIT_UNARY_OP_BITWISE_NEGATE,
    /// Logical negation of an arithmetic or pointer value.
    /// This is equivalent to "!(value)".
    LogicalNegate = GCC_JIT_UNARY_OP_LOGICAL_NEGATE,
}

/// Kinds of binary ops.
enum BinaryOp : gcc_jit_binary_op
{
    /// Addition of arithmetic values.
    /// This is equivalent to "(a) + (b)".
    Plus = GCC_JIT_BINARY_OP_PLUS,
    /// Subtraction of arithmetic values.
    /// This is equivalent to "(a) - (b)".
    Minus = GCC_JIT_BINARY_OP_MINUS,
    /// Multiplication of a pair of arithmetic values.
    /// This is equivalent to "(a) * (b)".
    Mult = GCC_JIT_BINARY_OP_MULT,
    /// Quotient of division of arithmetic values.
    /// This is equivalent to "(a) / (b)".
    Divide = GCC_JIT_BINARY_OP_DIVIDE,
    /// Remainder of division of arithmetic values.
    /// This is equivalent to "(a) % (b)".
    Modulo = GCC_JIT_BINARY_OP_MODULO,
    /// Bitwise AND.
    /// This is equivalent to "(a) & (b)".
    BitwiseAnd = GCC_JIT_BINARY_OP_BITWISE_AND,
    /// Bitwise exclusive OR.
    /// This is equivalent to "(a) ^ (b)".
    BitwiseXor = GCC_JIT_BINARY_OP_BITWISE_XOR,
    /// Bitwise inclusive OR.
    /// This is equivalent to "(a) | (b)".
    BitwiseOr = GCC_JIT_BINARY_OP_BITWISE_OR,
    /// Logical AND.
    /// This is equivalent to "(a) && (b)".
    LogicalAnd = GCC_JIT_BINARY_OP_LOGICAL_AND,
    /// Logical OR.
    /// This is equivalent to "(a) || (b)".
    LogicalOr = GCC_JIT_BINARY_OP_LOGICAL_OR,
    /// Left shift.
    /// This is equivalent to "(a) << (b)".
    LShift = GCC_JIT_BINARY_OP_LSHIFT,
    /// Right shift.
    /// This is equivalent to "(a) >> (b)".
    RShift = GCC_JIT_BINARY_OP_RSHIFT,
}

/// Kinds of comparison.
enum ComparisonOp : gcc_jit_comparison
{
    /// This is equivalent to "(a) == (b)".
    Equals = GCC_JIT_COMPARISON_EQ,
    /// This is equivalent to "(a) != (b)".
    NotEquals = GCC_JIT_COMPARISON_NE,
    /// This is equivalent to "(a) < (b)".
    LessThan = GCC_JIT_COMPARISON_LT,
    /// This is equivalent to "(a) <= (b)".
    LessThanEquals = GCC_JIT_COMPARISON_LE,
    /// This is equivalent to "(a) > (b)".
    GreaterThan = GCC_JIT_COMPARISON_GT,
    /// This is equivalent to "(a) >= (b)".
    GreaterThanEquals = GCC_JIT_COMPARISON_GE,
}

/// Kinds of ahead-of-time compilation
enum OutputKind : gcc_jit_output_kind
{
    /// Compile the context to an assembler file.
    Assembler = GCC_JIT_OUTPUT_KIND_ASSEMBLER,
    /// Compile the context to an object file.
    ObjectFile = GCC_JIT_OUTPUT_KIND_OBJECT_FILE,
    /// Compile the context to a dynamic library.
    DynamicLibrary = GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY,
    /// Compile the context to an executable.
    Executable = GCC_JIT_OUTPUT_KIND_EXECUTABLE,
}

// String options
deprecated
enum StrOption : gcc_jit_str_option
{
    ProgName = GCC_JIT_STR_OPTION_PROGNAME,
}

// Integer options
deprecated
enum IntOption : gcc_jit_int_option
{
    OptimizationLevel = GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL,
}

// Boolean options
deprecated
enum BoolOption : gcc_jit_bool_option
{
    DebugInfo = GCC_JIT_BOOL_OPTION_DEBUGINFO,
    DumpInitialTree = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE,
    DumpInitialGimple = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE,
    DumpGeneratedCode = GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE,
    DumpSummary = GCC_JIT_BOOL_OPTION_DUMP_SUMMARY,
    DumpEverything = GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING,
    SelfcheckGC = GCC_JIT_BOOL_OPTION_SELFCHECK_GC,
    KeepIntermediates = GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES,
}

/// Optimization options
enum OptimizationLevel : int
{
    /// No optimizations applied.
    None = 0,

    /// Optimizes for both speed and code size, without performing any
    /// optimizations that take a great deal of compilation time.
    Limited = 1,

    /// Performs nearly all supported optimizations that do not involve
    /// a tradeoff of code size for speed.
    Standard = 2,

    /// Turns on all optimizations at the Standard level, as well as performing
    /// the more expensive optimizations.
    Aggressive = 3,
}
