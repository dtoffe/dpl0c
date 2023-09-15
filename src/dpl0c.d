/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module dpl0c;

import std.file;
import std.stdio;
import ast;
import codegen;
import error;
import lexer;
import parser;
import prettyprinter;
import scopechecker;
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
    //ErrorManager.printErrors();

    ScopeChecker checker = new ScopeChecker(sourceFileName);
    node.accept(checker);
    ErrorManager.printErrors();

    CodeGenerator codeGenerator = new CodeGenerator(sourceFileName, false);
    node.accept(codeGenerator);
    // ErrorManager.printErrors();

}
