module error;

import std.stdio;

/** 
 * This ErrorHandler class is very loosely inspired in another one found in the source code from the book
 * "Writing Compilers and Interpreters" by Ronald Mak.
 */

enum ErrorType {
    COMPILER,
    LEXER,
    PARSER,
    SEMCHECKER,
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
    static ErrorMessage[] errors = new ErrorMessage[MAX_ERRORS];

    static this() {
    }

    static void addError(ErrorType type, ErrorLevel level, string message) {
        if (errorCount < maxErrors - 1) {
            errors[errorCount++] = new ErrorMessage(type, level, message);
        } else {
            errors[errorCount++] = new ErrorMessage(ErrorType.COMPILER, ErrorLevel.ERROR,
                                                    "Too many errors, compilation stopped.");
            printErrors();
            exit(1);
        }
    }

    static void printErrors() {
        writeln("Compiler errors:");
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

    static void addLexerError(ErrorLevel level, string message, Token token) {
        addError(ErrorType.LEXER, level, message + " at line: " + token.line + 
                " column: " + token.column + " found lexeme: " + token.lexeme + ".\n");
    }

    static void addParserError(ErrorLevel level, string message) {
        addError(ErrorType.PARSER, level, message);
    }

    static void addSemanticError() {
        addError(ErrorType.SEMCHECKER, level, message);
    }

    static void addCodeGenError() {
        addError(ErrorType.CODEGEN, level, message);
    }

}
