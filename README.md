# dpl0c

[![built with Codeium](https://codeium.com/badges/main)](https://codeium.com)

A [PL/0](https://en.wikipedia.org/wiki/PL/0) compiler written in [D language](https://dlang.org/). This is the grammar of the PL/0 language:

``` EBNF
program = block "." ;

block = [ "const" ident "=" number { "," ident "=" number } ";" ]
        [ "var" ident { "," ident } ";" ]
        { "procedure" ident ";" block ";" }
        statement ;

statement = [ ident ":=" expression
            | "call" ident 
            | "read" ident                                      //   | "?" ident 
            | "write" expression                                //   | "!" expression 
            | "begin" statement { ";" statement } "end" 
            | "if" condition "then" statement 
            | "while" condition "do" statement ] ;

condition = "odd" expression |
            expression ( "=" | "#" | "<" | "<=" | ">" | ">=" ) expression ;

expression = [ "+" | "-" ] term { ( "+" | "-" ) term } ;

term = factor { ( "*" | "/" ) factor } ;

factor = ident | number | "(" expression ")" ;

ident = letter { letter | digit } ;

number = digit { digit } ;

letter = "a" | "b" | ... | "y" | "z" | "A" | "B" | ... | "Y" | "Z" ;

digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
```

Comments start with "//", on its own line or after a statement, and go until the end of the line.

The compiler is written in D and features:

- :heavy_check_mark: A hand-coded scanner.
- :heavy_check_mark: A hand-coded recursive descent parser.
  - There is no precedence climbing: since the language is so small, the precedence is handled by the grammar.
  - Conditions are also handled by the grammar, so there is no need for a boolean datatype.
- :heavy_check_mark: Abstract syntax tree created by the parser.
- :warning: A symbol table used to keep track of variables and their scopes, built by the semantic checking visitor and used by the code generation visitor.
- :information_source: (Note: currently I'm reworking the symbol table and evaluating possible links with the AST.)
- AST traversal implemented with a Visitor pattern.
  - :heavy_check_mark: A prettyprinter visitor.
  - :warning: A symbol table builder and semantic checking visitor.
  - :construction: A handful of visitors for the code generation backend.
- Code generators:
  - :construction: A transpiling code generator which emits Pascal source code. (Granted, reading PL/0 and emitting Pascal should count as cheating).
  - :construction: An [LLVM IR](https://llvm.org/) code generator (almost finished).
  - :interrobang: A transpiling code generator which emits C source code. (Other languages do this, so probably not cheating, or cheating not so much).
  - :interrobang: A [QBE](https://c9x.me/compile/) code generator.
  - :interrobang: Maybe I consider adding a CLR bytecode generator and a JVM bytecode generator in the future, just for learning purposes.
- :construction: Runtime library in C for the implementation of "read" and "write".

There is no plan for adding features to the language, as commonly done in the compiler courses where PL/0 is used as target language.

I'm yet undecided about adding optimization passes.

I would love, however, adding error recovery to the parser, for example via symbol insertion of missing semicolons. But I've still got to figure out how to do it.

## Examples

Take a look at the examples in the [examples/README.md](examples/README.md) file.

## Thanks to

- The guys at the D language forum, for some general language tips at the beginning of the project.
- TNorthover at the Discord LLVM beginners channel for his help:
  - With the correct ordering of the basic blocks in the control flow statements.
  - In helping me understand the way of implementing the scoping of the variables in nested procedures.
