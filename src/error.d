/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module error;

import std.conv;
import std.stdio;
import token;

/** 
 * This ErrorHandler class is very loosely inspired in another one found in the source code from the book
 * "Writing Compilers and Interpreters" by Ronald Mak.
 */

enum ErrorType {
    COMPILER,
    LEXER,
    PARSER,
    SCOPE,
    TYPE,
    CODEGEN
}

enum ErrorLevel {
    ERROR,
    WARNING,
    INFO
}

struct ErrorMessage {
    ErrorType type;
    ErrorLevel level;
    string message;
}

static class ErrorManager {

    static uint MAX_ERRORS = 20;
    static uint errorCount = 0;
    static ErrorMessage[] errors;

    static this() {
        errors = new ErrorMessage[MAX_ERRORS];
    }

    static int errorsFound() {
        int count = 0;
        foreach (error; errors[0..errorCount]) {
            if (error.level == ErrorLevel.ERROR) {
                count = count + 1;
            }
        }
        return count;
    }

    static void addError(ErrorType type, ErrorLevel level, string message) {
        if (errorCount < MAX_ERRORS - 1) {
            errors[errorCount++] = ErrorMessage(type, level, message);
        } else {
            errors[errorCount++] = ErrorMessage(ErrorType.COMPILER, ErrorLevel.ERROR,
                                                    "Too many errors, compilation stopped.");
            printErrors();
            //exit(1);
        }
    }

    static void printErrors() {
        if (errorCount > 0) {
            writeln("Compiler messages:");
        }
        foreach (error; errors[0..errorCount]) {
            writeln(error.type, ": ", error.level, ": ", error.message);
        }
    }

    static void clearErrors() {
        errorCount = 0;
    }

    static void addCompilerError(ErrorLevel level, string message) {
        addError(ErrorType.COMPILER, level, message);
    }

    static void addLexerError(ErrorLevel level, string message, int line, int column) {
        addError(ErrorType.LEXER, level, message ~ " TokenType: " ~ to!string(TokenType.INVALID) ~
                " at line: " ~ to!string(line) ~ " column: " ~ to!string(column) ~ ".\n");
    }

    static void addParserError(ErrorLevel level, string message, Token token) {
        addError(ErrorType.PARSER, level, message ~
                " at line: " ~ to!string(token.getLine()) ~ " column: " ~ to!string(token.getColumn()) ~
                " lexeme: " ~ to!string(token.getLiteral()) ~ ".\n");
    }

    static void addScopeError(ErrorLevel level, string message) {
        addError(ErrorType.SCOPE, level, message);
    }

    static void addCodeGenError(ErrorLevel level, string message) {
        addError(ErrorType.CODEGEN, level, message);
    }

}
