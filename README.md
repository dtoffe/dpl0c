# dpl0c

A PL-0 compiler written in D, featuring:


- :heavy_check_mark: A hand-coded scanner.
- :heavy_check_mark: A hand-coded recursive descent parser.
  - There is no precedence climbing: since the language is so small, the precedence is handled by the grammar.
  - Conditions are also handled by the grammar, so there is no need for a boolean datatype.
- :heavy_check_mark: Abstract syntax tree created by the parser.
- AST traversal implemented with a Visitor pattern.
  - :heavy_check_mark: A prettyprinter visitor.
  - :heavy_check_mark: A symbol table builder and semantic checking visitor.
  - :construction: A code generation visitor.
- The code generation visitor acts as the backend, generating LLVM IR.

There is no plan for adding features to the language, as commonly done in the compiler courses where PL0 is used as target language.

I'm yet undecided about adding optimization passes.

I would love, however, adding error recovery to the parser, for example via symbol insertion of missing semicolons. But I've still got to figure out how to do it.
