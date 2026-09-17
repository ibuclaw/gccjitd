# Basic Blocks and Control Flow

gccjit provides the D wrapper structs responsible for modeling basic blocks, switch statement branches, and inline assembly within JIT-compiled functions. Basic blocks serve as the fundamental nodes in a function's Control Flow Graph (CFG), containing linear sequences of statements and concluding with explicit control flow terminators.

For details on statement emission and block terminators, see [Block: Statement Emission and Termination](8.1-statements.md). For inline assembly and switch statements, see [ExtendedAsm and Case: Inline Assembly and Switch Statements](8.2-asm-and-switch.md).

## 8.1. Block: Statement Emission and Termination

Every basic block (`JIT.Block`) in gccjitd wraps a `gcc_jit_block*` opaque pointer and supports the standard `opCast!bool` null-check convention along with upcasting to `JIT.Object`.

Within a basic block, consumers can append statement evaluations, assignments, operator assignments, function calls, and textual comments.
Every block must be terminated using one of the CFG terminator methods, such as conditional branches, unconditional jumps, returns, or multi-way switches.

For a complete breakdown of all statement building routines and termination methods, see [Block: Statement Emission and Termination](8.1-statements.md).

## 8.2. ExtendedAsm and Case: Inline Assembly and Switch Statements

Advanced control flow and machine-level integration are exposed via the `JIT.Case` and `JIT.ExtendedAsm` wrapper structs.

- `JIT.Case`: Represents individual branch targets within a multi-way switch statement terminator (`end_with_switch`)
- `JIT.ExtendedAsm`: Models extended inline assembly blocks, allowing configuration of volatility, inline flags, input/output operands, clobbers, and top-level assembly statements (gated by feature flags such as `JIT.Have_Asm_Statements`).

For detailed documentation on building switch cases and configuring inline assembly blocks, see [ExtendedAsm and Case: Inline Assembly and Switch Statements](8.2-asm-and-switch.md).