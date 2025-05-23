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
  - :warning: I'm thinking of introducing error correction or recovery in the future, using the technique explained in A+DS=P book (Chapter 5) by N. Wirth.
- :heavy_check_mark: Abstract syntax tree created by the parser.
- :heavy_check_mark: A symbol table used to keep track of symbols and their scopes. The symbol table is built by the semantic checking visitor and used by all the code generation visitors.
- AST traversal implemented with a Visitor pattern.
  - :heavy_check_mark: A prettyprinter visitor to print the input source in a well formatted style.
  - :heavy_check_mark: A symbol table builder and semantic checking visitor (only scopes, because the language has only integers so there is no point in doing type checking).
  - :warning: A handful of visitors for the code generation backend (see details below).
- Code generators:
  - :heavy_check_mark: A transpiling code generator which emits Pascal source code. (Granted, reading PL/0 and emitting Pascal should count as cheating).
    - The examples are tested and run OK.
  - :heavy_check_mark: A transpiling code generator which emits C source code. (Other languages do this, so probably not cheating, or cheating not so much).
    - The examples are tested and run OK.
  - :construction: A P-Code machine code generator, using the [P-Code Machine](https://en.wikipedia.org/wiki/P-code_machine) from the book *Algorithms + Data Structures = Programs* by Niklaus Wirth (1976).
    - The P-Code machine interpreter is  implemented, basically a D translation of the P-Code machine from the book, as taken from the Wikipedia page linked above.
  - :construction: An [LLVM IR](https://llvm.org/) code generator.
    - I'm working on it right now, probably half way already.
  - :interrobang: A [QBE](https://c9x.me/compile/) code generator.
  - :interrobang: A CLR (.NET) bytecode generator ?
  - :interrobang: A JVM (Java) bytecode generator ?
  - :interrobang: An [Eigen Compiler Suite](https://ecs.openbrace.org/) backend generator ?
- :construction: Runtime library in C for the implementation of "read" and "write" (Needed for the LLVM and the QBE code generators).
- :interrobang: Alternative lexer and parser following the Roslyn design principles (compiler as a service), complete with a language server.
- :star: If the stars get properly aligned and I finally start my personal/developer blog, maybe a tutorial !!!

There is no plan for adding features to the language, as commonly done in the compiler courses where PL/0 is used as target language.

I'm yet undecided about adding optimization passes.

I would love, however, adding error recovery to the parser, for example via symbol insertion of missing semicolons. But I've still got to figure out how to do it.

## Examples

Take a look at the examples in the [examples/README.md](examples/README.md) file.

## Setup

For D language development I use the [DMD compiler](https://dlang.org/download.html) and the [Digital Mars free C++ compiler](https://www.digitalmars.com/download/freecompiler.html). I'm using VSCode with the D Programming Language (code-d) extension from the VSCode Marketplace.

The project is built with the [dub](https://code.dlang.org/) build tool:

```bash
D:\your-path> dub build
```

To compile and run the Pascal generated sources I used the [Free Pascal compiler](https://www.freepascal.org/).

```bash
D:\your-path> ./dpl0c.exe -t pas -s ./examples/calc.pl0

D:\your-path> fpc ./examples/pas/calc.pas
```

To compile and run the C generated sources I used the [Digital Mars free C++ compiler](https://www.digitalmars.com/download/freecompiler.html).

```bash
D:\your-path> ./dpl0c.exe -t c -s ./examples/calc.pl0

D:\your-path> dmc ./examples/c/calc.c
```

**Warning, LLVM code generation is still a work in progress, the LLVM IR code generator is not yet fully implemented.**

To compile and run the LLVM IR generated sources I used the [LLVM toolchain](https://llvm.org/). LLVM provides a C library API to interface from other languages called llvm-c, and there is a D language wrapper for llvm-c called [LLVM-D](https://github.com/llvm-d/llvm-d), which supports LLVM versions 3.0 to 10.0, as per its own docs, so the LLVM release you use should be compatible.

But in practice, in the downloads page for LLVM there are many varsions which do not provide a Windows build, and among those, some do not provide the needed dlls, so I used LLVM 10.0.0 release for Windows (64 bits). You must ensure that there is a LLVM-C.dll file and a LTO.dll file in your LLVM/bin folder, otherwise the build of the compiler will fail (only so silently, it will generate an executable and fail on run).

```bash
D:\your-path> ./dpl0c.exe -t llvm -s ./examples/calc.pl0

D:\your-path> llc -filetype=obj ./examples/llvm/calcmax.ll -o calcmax.o

D:\your-path> clang calcmax.o -o calcmax.exe
```

Then you can run (and test) the generated executables:

```bash
D:\your-path> ./examples/pas/calc.exe
D:\your-path> ./examples/c/calc.exe

...etc
```

## Thanks to

- TNorthover at the Discord LLVM beginners channel for his help:
  - With the correct ordering of the basic blocks in the control flow statements.
  - In helping me understand the way of implementing the scoping of the variables in nested procedures.

- The guys at the D language forum, for some general language tips at the beginning of the project.

- Walter Bright, the designer of the D language and developer of its compiler and libraries, for sharing his [wisdom regarding compiler development](https://forum.dlang.org/post/up9gir$1rd6$1@digitalmars.com):

![Persistence](docs/cauliflower.png "Persistence")
