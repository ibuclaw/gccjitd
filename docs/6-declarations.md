# Declarations: Functions, Parameters, and Fields

## Purpose and Scope

gccjit provides D wrapper structs for JIT declarations: `JIT.Field`, `JIT.Function`, and `JIT.Parameter`.
These wrappers inherit from `JIT.Object` using the standard union and `alias this` pattern, supporting safe downcasting and the idiomatic `opCast!bool` null-checking convention.

This page provides a high-level overview of how declarations are structured and managed within the compilation context. For granular details on methods, attributes, and struct field layouts, refer to the child pages:

- [Function and Parameter Structs](6.1-function-parameters.md)
- [Field Struct and Struct Layout](6.2-fields.md)

## High-Level Overview of Declarations

Declarations represent entities that have names, types, and scopes within a compilation context. They serve as the building blocks for constructing functions, parameters, and compound types (such as structs and unions).

```mermaid
graph TD
    subgraph Code Entities
        direction TD
        Context["JIT.Context"] --> |new_function| Function["JIT.Function"]
        Function --> |get_param| JIT.Parameter
        Function --> |new_block| JIT.Block
        Function --> |new_local| JIT.LValue
        Function --> |new_temp| JIT.LValue
        Context --> |new_field| Field["JIT.Field"]
        Field --> |set_fields| JIT.Struct
    end
```

## Function Definition Workflow

Defining a function in gccjitd follows a structured workflow:

1. **Creation**: A `JIT.Function` is created via the compilation context, specifying its linkage type, name, return type, and parameter list.
2. **Parameters & Locals**: Parameters are accessed via index, and local variables or temporary variables are allocated within the function scope.
3. **Control Flow**: Basic blocks (`JIT.Block`) are added to the function to form the control flow graph.
4. **Attributes & Debugging**: Optional attributes can be attached to the function, and intermediate representations can be dumped to DOT files for inspection.

```mermaid
graph TD
    subgraph Function Building Workflow
        direction TD
        Context.new_function --> Function["JIT.Function"]
        Function --> new_block["JIT.Function.new_block"]
        Function --> JIT.Function.new_local
        Function --> JIT.Function.get_param
        new_block --> JIT.Block.add_assignment --> JIT.Function.dump_to_dot
    end
```

## Sub-Modules and Child Pages

- [Function and Parameter Structs](6.1-function-parameters.md): Covers Function methods (`new_block`, `new_local`, `new_temp`, `get_param`, `get_address`, `add_attribute`, `dump_to_dot`, and call operator overloads) and `JIT.Parameter` casting and retrieval
- [Field Struct and Struct Layout](6.2-fields.md): Covers the `JIT.Field` wrapper struct, its usage with `JIT.Context.new_field` and `JIT.Struct.set_fields`, and forward-declaration patterns for opaque structs