/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module dpl0c;

import std.file;
import std.getopt;
import std.stdio;
import ast;
import codegenc;
import codegenllvm;
import codegenpas;
import error;
import lexer;
import parser;
import prettyprinter;
import scopechecker;
import token;

enum VERSION = "0.0.1";

void main(string[] args) {
    writefln("\nThe D PL/0 Compiler v. %s", VERSION);
    if (args.length < 3) {
        writeln("Usage: dpl0c -t|--target <target> -s|--source <sourceFileName>");
        writeln("<target> can be: c, pas, llvm");
        writeln("Example: dpl0c -t pas -s main.pas");
        writeln();
        return;
    }

    string targetLanguage;
    string sourceFileName;

    getopt(args,
        "t|target", &targetLanguage,
        "s|source", &sourceFileName
    );
    string sourceContent = readText(sourceFileName);

    Lexer lex = new Lexer(sourceContent);
    Parser parser = new Parser(lex);
    ProgramNode node = parser.parseProgram();

    PrettyPrinter printer = new PrettyPrinter(sourceFileName);
    node.accept(printer);
    //ErrorManager.printErrors();

    ScopeChecker checker = new ScopeChecker(sourceFileName);
    node.accept(checker);
    //ErrorManager.printErrors();

    if (ErrorManager.errorsFound() > 0) {
        writeln("Errors found in compilation, cannot generate source code.");
        ErrorManager.printErrors();
    } else {

        switch (targetLanguage) {
            case "pas":
                PascalCodeGenerator pascalCodeGenerator = new PascalCodeGenerator(sourceFileName);
                node.accept(pascalCodeGenerator);
                break;
            case "c":
                CCodeGenerator cCodeGenerator = new CCodeGenerator(sourceFileName);
                node.accept(cCodeGenerator);
                break;
            case "llvm":
                LLVMCodeGenerator llvmCodeGenerator = new LLVMCodeGenerator(sourceFileName);
                node.accept(llvmCodeGenerator);
                break;
            default:
                writeln("Unknown target language.");
                break;
        }
        ErrorManager.printErrors();
    }

}
