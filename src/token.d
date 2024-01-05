/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module token;

import std.conv;
import std.stdio;

enum TokenType {

	// Keywords
	CONST,
	VAR,
	PROCEDURE,
	CALL,
	BEGIN,
	END,
	IF,
	THEN,
	WHILE,
	DO,
	READ,  // "?" in the original PL-0 definition
	WRITE, // "!" in the original PL-0 definition
	ODD,

	// Special types
	EOF,
	INVALID,

	// Punctuation
	PERIOD,    // "."
	COMMA,     // ","
	SEMICOLON, // ";"
	LPAREN,    // "("
	RPAREN,    // ")"
	COLON,     // ":"
	ASSIGN,    // ":="

	// Relational
	EQUAL,     // "="
	NOTEQUAL,  // "#"
	LESSER,    // "<"
	LESSEREQ,  // "<="
	GREATER,   // ">"
	GREATEREQ, // ">="

	// Operators
	PLUS,  // "+"
	MINUS, // "-"
	MULT,  // "*"
	DIV,   // "/"

	// Identifiers and numeric constants
	IDENT,
	NUMBER,

    // Group markers for consume method in parser
    RELOP,      // Any relational operator
    TERMOP,     // PLUS and MINUS
    FACTOP      // MULT and DIV

}

struct Token {
    
    private TokenType tokenType;
    private string literal;
    private int line;
    private int column;
    
    this(TokenType tokenType, string literal, int line, int column) {
        this.tokenType = tokenType;
        this.literal = literal;
        this.line = line;
        this.column = column;
    }

    public TokenType getTokenType() {
        return tokenType;
    }
    
    public string getLiteral() {
        return literal;
    }
    
    public int getLine() {
        return line;
    }
    
    public int getColumn() {
        return column;
    }

}

TokenType[string] keywords;

static this() {
    keywords = [
        "const": TokenType.CONST,
        "var": TokenType.VAR,
        "procedure": TokenType.PROCEDURE,
        "call": TokenType.CALL,
        "begin": TokenType.BEGIN,
        "end": TokenType.END,
        "if": TokenType.IF,
        "then": TokenType.THEN,
        "while": TokenType.WHILE,
        "do": TokenType.DO,
        "read": TokenType.READ,
        "write": TokenType.WRITE,
        "odd": TokenType.ODD
    ];
}

TokenType lookUpIdent(string ident) {
    if (ident in keywords) {
        return keywords[ident];
    }
    return TokenType.IDENT;
}

string toString(Token token) {
    return "TokenType: " ~ to!string(token.tokenType) ~ " at line: " ~ to!string(token.getLine()) ~
                " column: " ~ to!string(token.getColumn()) ~ " lexeme: " ~ token.getLiteral();
}

TokenType tokenGroup(TokenType tokenType) {
    switch (tokenType) {
        case TokenType.EQUAL:
        case TokenType.NOTEQUAL:
        case TokenType.LESSER:
        case TokenType.LESSEREQ:
        case TokenType.GREATER:
        case TokenType.GREATEREQ:
            return TokenType.RELOP;
        case TokenType.PLUS:
        case TokenType.MINUS:
            return TokenType.TERMOP;
        case TokenType.MULT:
        case TokenType.DIV:
            return TokenType.FACTOP;
        default:
            return tokenType;
    }
}
