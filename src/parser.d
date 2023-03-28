module parser;

import std.conv;
import std.stdio;
import ast;
import error;
import lexer;
import token;

class Parser {

    Lexer lexer;
    Token currentToken;
    
    this(Lexer lex) {
        lexer = lex;
    }

    ProgramNode parseProgram() {
        ProgramNode program = new ProgramNode();
        BlockNode block = parseBlock();
        program.block = block;
        if (currentToken.getTokenType() == TokenType.PERIOD) {
            currentToken = lexer.nextToken();
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.PERIOD) ~
                        " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        if (currentToken.getTokenType() != TokenType.EOF) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.EOF) ~
                        " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        return program;
    }

    BlockNode parseBlock() {
        BlockNode node = new BlockNode();
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() == TokenType.CONST) {
            currentToken = lexer.nextToken();
            node.setConstDecls(parseConstDecls());
        }
        if (currentToken.getTokenType() == TokenType.VAR) {
            currentToken = lexer.nextToken();
            node.setVarDecls(parseVarDecls());
        }
        if (currentToken.getTokenType() == TokenType.PROCEDURE) {
            node.setProcDecls(parseProcDecls());
        }
        node.setStatement(parseStatement());
        return node;
    }

    ConstDeclNode[] parseConstDecls() {
        ConstDeclNode[] constDecls;
        string name = "";
        int value = 0;
        int i = 0;
        bool error = false;
        while (currentToken.getTokenType() == TokenType.IDENT) {
            name = currentToken.getLiteral();
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() != TokenType.EQUAL) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.END) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
                error = true;
            }
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.NUMBER) {
                value = to!int(currentToken.getLiteral());
            } else {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.NUMBER) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
                error = true;
            }
            if (!error) {
                ConstDeclNode decl = new ConstDeclNode(name, value);
                constDecls ~= decl;
            }
            error = false;
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.SEMICOLON) {
                currentToken = lexer.nextToken();
                break;
            } else if (currentToken.getTokenType() != TokenType.COMMA) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.COMMA) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));                
            }
            currentToken = lexer.nextToken();
        }
        writeln("ConstDecls: ", constDecls.length);
        return constDecls;
    }

    VarDeclNode[] parseVarDecls() {
        VarDeclNode[] varDecls;
        string name = "";
        int i = 0;
        while (currentToken.getTokenType() == TokenType.IDENT) {
            writeln("Parsing token: " ~ currentToken.toString());
            name = currentToken.getLiteral();
            VarDeclNode decl = new VarDeclNode(name);
            varDecls ~= decl;
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.SEMICOLON) {
                currentToken = lexer.nextToken();
                break;
            } else if (currentToken.getTokenType() != TokenType.COMMA) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.COMMA) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));                
            }
            currentToken = lexer.nextToken();
        }
        return varDecls;
    }

    ProcDeclNode[] parseProcDecls() {
        ProcDeclNode[] procDecls;
        ProcDeclNode procDecl;
        int i = 0;
        while (currentToken.getTokenType() == TokenType.PROCEDURE) {
            procDecl = parseProcDecl();
            procDecls[i++] = procDecl;
        }
        return procDecls;
    }

    ProcDeclNode parseProcDecl() {
        ProcDeclNode procDecl;
        string name = "";
        int i = 0;
        bool error = false;
        while (currentToken.getTokenType() == TokenType.IDENT) {
            
        }
        return procDecl;
    }

    StatementNode parseStatement() {
        StatementNode statNode = null; //new StatementNode();
        return statNode;
    }

}
