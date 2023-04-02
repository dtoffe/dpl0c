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
            procDecls ~= procDecl;
        }
        return procDecls;
    }

    ProcDeclNode parseProcDecl() {
        ProcDeclNode procDecl;
        string procName = "";
        int i = 0;
        bool error = false;
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.IDENT) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType())); 
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType())); 
        }
        currentToken = lexer.nextToken();
        BlockNode block = parseBlock();
        procDecl = new ProcDeclNode(procName, block);
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType())); 
        }
        return procDecl;
    }

    StatementNode parseStatement() {
        StatementNode statNode;
        switch (currentToken.getTokenType()) {
            case TokenType.IDENT:
                statNode = parseAssign();
                break;
            case TokenType.CALL:
                statNode = parseCall();
                break;
            case TokenType.READ:
                statNode = parseRead();
                break;
            case TokenType.WRITE:
                statNode = parseWrite();
                break;
            case TokenType.BEGIN:
                statNode = parseBegin();
                break;
            case TokenType.IF:
                statNode = parseIf();
                break;
            case TokenType.WHILE:
                statNode = parseWhile();
                break;
            default:
                ErrorManager.addParserError(ErrorLevel.ERROR, "Token " ~ to!string(currentToken.getTokenType()) ~
                        " unexpected at the start of a statement.");
                break;
        }
        return statNode;
    }

    AssignNode parseAssign() {
        AssignNode assign;
        string name = "";
        name = currentToken.getLiteral();
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.EQUAL) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.EQUAL) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));

        }
        currentToken = lexer.nextToken();
        ExpressionNode exp = parseExpression();
        assign = new AssignNode(name, exp);
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        return assign;
    }

    CallNode parseCall() {
        CallNode call;
        string name = "";
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.IDENT) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        name = currentToken.getLiteral();
        call = new CallNode(name);
        return call;
    }

    ReadNode parseRead() {
        ReadNode read;
        string name = "";
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.IDENT) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        name = currentToken.getLiteral();
        read = new ReadNode(name);
        return read;
    }

    WriteNode parseWrite() {
        WriteNode write;
        ExpressionNode exp;
        // write.setName(currentToken.getLiteral());
        // currentToken = lexer.nextToken();
        // if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            
        //     ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
        //                     " expected, but found " ~ to!string(currentToken.getTokenType()));

        // }
        // currentToken = lexer.nextToken();
        // return write;
    }

    BeginNode parseBegin() {
        BeginNode begin = new BeginNode();
        begin.setName(currentToken.getLiteral());
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));

        }
        currentToken = lexer.nextToken();
        return begin;
    }

    IfNode parseIf() {
        IfNode ifNode = new IfNode();
        ifNode.setName(currentToken.getLiteral());
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.LPAREN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.LPAREN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.RPAREN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.RPAREN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.THEN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.THEN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.LBRACE) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.LBRACE) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        BlockNode block = parseBlock();
        if (currentToken.getTokenType() != TokenType.RBRACE) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.RBRACE) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.ELSE) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.ELSE) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.END) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.END) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        return ifNode;
    }

    WhileNode parseWhile() {
        WhileNode whileNode = new WhileNode();
        whileNode.setName(currentToken.getLiteral());
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.LPAREN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.LPAREN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.RPAREN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.RPAREN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.THEN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.THEN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        BlockNode block = parseBlock();
        if (currentToken.getTokenType() != TokenType.END) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.END) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()));
        }
        currentToken = lexer.nextToken();
        return whileNode;
    }

}
