module dpl0c;

import std.stdio;
import ast;
import error;
import lexer;
import parser;
import token;

enum VERSION = "0.0.1";

void main(string[] args) {
    writefln("\nThe D PL/0 Compiler v. %s", VERSION);

    string sourceFileName = "../examples/test.pl0";
    Lexer lex = new Lexer(sourceFileName);
    Token tok = lex.nextToken();
    while (tok.getTokenType()  != TokenType.EOF) {
        writeln("Token: ", tok.getTokenType(), " Literal: ", tok.getLiteral(),
            " Line: ", tok.getLine(), " Column: ", tok.getColumn());
        tok = lex.nextToken();
    }
    Parser parser = new Parser(lex);
    ProgramNode node = parser.parseProgram();
    ErrorManager.printErrors();
}
