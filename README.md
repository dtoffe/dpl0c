# dpl0c

A PL-0 compiler written in D, featuring:

- A hand-coded scanner.
- A hand-coded recursive descent parser with precedence climbing.
- Abstract syntax tree created by the parser.
- AST traversal implemented with a Visitor pattern.
- An LLVM backend generating LLVM IR.
