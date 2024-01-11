# TODO

- Add support for alias or nickname in the symbol table to allow for Pascal code generator renaming of Pascal reserved words and for C code generator renaming of symbols that are repeated in different scopes and need to be renamed when flattening the nested scopes for C code generation.
- Rework Pascal code generator to allow Pascal reserved words in the PL/0 source code and to rename them in the code generator using the symbol nickname.
- Attempt to simplify the symbol table and the scopechecker.
- Rework parser to add error recovery using the technique explained in A+DS=P book by Wirth, adding or deleting one symbol from the symbol stream coming from the lexer. After this, fix the README item about adding error recovery.
- Rework parser to add robustness as described in A+DS=P book by Wirth, no input file should cause the parser to fail with a panic.
- Implement the C code generator by flattening of the nested scopes and renaming of the possibly repeated symbols, the rest should be more or less similar to the Pascal code generator.
- Finish implementation of LLVM code generator.
- Implement a QBE code generator.
- Evaluate the possibility of a JVM (Java) bytecode generator backend.
- Evaluate the possibility of a CLR (.NET) bytecode generator backend.
- Implement an alternative lexer and parser following the Roslyn design principles (compiler as a service), complete with a language server.

~~- Rework parser to use some of the expect(), match() or eat() idioms, to hopefully enhance error handling and reporting.~~

~~- Rework AST to have just symbol table ids and not redundant names and values that are already present in the symbols, fix everything else depending on it. After this, fix the README item about reworking AST and symbol table.~~

~~- Implement Pascal code generator.~~

~~- Add examples from PL/0 User Manual.~~

~~- Add content to README, add PL/0 grammar.~~

~~- Remove symbol table creation from parser, add symbol table creation and scope checking with a scopechecker visitor.~~

~~- Setup dub based project configuration.~~

~~- Implement a prettyprinter to test the parser.~~

~~- Implement the parser to build the AST.~~

~~- Implement AST and visitor declaration.~~

~~- Implement the lexer and add examples to test it.~~

~~- Setup project and basic README.~~
