module dpl0c;

import std.file;
import std.stdio;
import ast;
import error;
import lexer;
import parser;
import prettyprinter;
import token;

enum VERSION = "0.0.1";

void main(string[] args) {
    writefln("\nThe D PL/0 Compiler v. %s", VERSION);
    if (args.length < 2) {
        writeln("Usage: dpl0c <sourceFileName>");
        writeln();
        return;
    }
    string sourceFileName = args[1];
    string sourceContent = readText(sourceFileName);

    Lexer lex = new Lexer(sourceContent);
    Parser parser = new Parser(lex);
    ProgramNode node = parser.parseProgram();

    PrettyPrinter printer = new PrettyPrinter(sourceFileName);
    node.accept(printer);
    ErrorManager.printErrors();
}
