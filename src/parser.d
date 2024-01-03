/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module parser;

import std.conv;
import std.stdio;
import ast;
import error;
import lexer;
import token;

/*
    Note: Consider the pros and cons of adopting the idioms in the following code.
    This is widely used in the compilers literature and it is likely that
    using this style enhances readability, extensibility and modifiability
    of the parser code.

    See also: expect(tokenType)

    Token match(TokenKind kind) {
        if (currentToken.kind == kind) {
            Token token = currentToken;
            currentToken = lexer.getNextToken();
            return token;
        } else {
            // Error handling
        }
    }

    void eat(TokenKind kind) {
        if (currentToken.kind == kind) {
            currentToken = lexer.getNextToken();
        } else {
            // Error handling
        }
    }

    Note 2: In the book Algorithms + Data Structures = Programs, N. Wirth
    presents PL/0, shows how to code a lexer and parser, and then explains
    a technique to add error recovery to the parser by adding or deleting
    one symbol whenever a production can not be parsed.
    Consider adding that technique here.
*/

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
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseProgram",
                currentToken);
        }
        if (currentToken.getTokenType() != TokenType.EOF) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.EOF) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseProgram",
                currentToken);
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
        string value = "";
        int i = 0;
        bool error = false;
        while (currentToken.getTokenType() == TokenType.IDENT) {
            name = currentToken.getLiteral();
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() != TokenType.EQUAL) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.END) ~
                    " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseConstDecls",
                    currentToken);
                error = true;
            }
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.NUMBER) {
                value = currentToken.getLiteral();
            } else {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.NUMBER) ~
                    " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseConstDecls",
                    currentToken);
                error = true;
            }
            if (!error) {
                IdentNode ident = new IdentNode(name);
                NumberNode number = new NumberNode(value);
                ConstDeclNode decl = new ConstDeclNode(ident, number);
                constDecls ~= decl;
            }
            error = false;
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.SEMICOLON) {
                currentToken = lexer.nextToken();
                break;
            } else if (currentToken.getTokenType() != TokenType.COMMA) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.COMMA) ~
                    " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseConstDecls",
                    currentToken);                
            }
            currentToken = lexer.nextToken();
        }
        return constDecls;
    }

    VarDeclNode[] parseVarDecls() {
        VarDeclNode[] varDecls;
        string name = "";
        int i = 0;
        while (currentToken.getTokenType() == TokenType.IDENT) {
            name = currentToken.getLiteral();
            IdentNode ident = new IdentNode(name);
            VarDeclNode decl = new VarDeclNode(ident);
            varDecls ~= decl;
            currentToken = lexer.nextToken();
            if (currentToken.getTokenType() == TokenType.SEMICOLON) {
                currentToken = lexer.nextToken();
                break;
            } else if (currentToken.getTokenType() != TokenType.COMMA) {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.COMMA) ~
                    " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseVarDecls",
                    currentToken);                
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
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseProcDecl",
                currentToken); 
        }
        procName = currentToken.getLiteral();
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.SEMICOLON) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseProcDecl",
                currentToken); 
        }
        BlockNode block = parseBlock();
        IdentNode ident = new IdentNode(procName);
        procDecl = new ProcDeclNode(ident, block);
        if (currentToken.getTokenType() == TokenType.SEMICOLON) {
            currentToken = lexer.nextToken();
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.SEMICOLON) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseProcDecl",
                currentToken); 
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
                statNode = parseIfThen();
                break;
            case TokenType.WHILE:
                statNode = parseWhileDo();
                break;
            default:
                ErrorManager.addParserError(ErrorLevel.ERROR, "Token " ~ to!string(currentToken.getTokenType()) ~
                    " unexpected at the start of a statement in parseStatement.", currentToken);
                break;
        }
        return statNode;
    }

    StatementNode[] parseStatements() {
        StatementNode[] statements = new StatementNode[0];
        statements ~= parseStatement();
        while (currentToken.getTokenType() == TokenType.SEMICOLON) {
            currentToken = lexer.nextToken();
            statements ~= parseStatement();
        }
        return statements;
    }

    AssignNode parseAssign() {
        AssignNode assign;
        ExpressionNode expr;
        string name = currentToken.getLiteral();
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() != TokenType.ASSIGN) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.ASSIGN) ~
                            " expected, but found " ~ to!string(currentToken.getTokenType()), currentToken);
        } else {
            currentToken = lexer.nextToken();
            expr = parseExpression();
            assign = new AssignNode(name, expr);
        }
        return assign;
    }

    CallNode parseCall() {
        CallNode call;
        string name = "";
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() == TokenType.IDENT) {
            name = currentToken.getLiteral();
            call = new CallNode(name);
            currentToken = lexer.nextToken();
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseCall",
                currentToken);
        }
        return call;
    }

    ReadNode parseRead() {
        ReadNode read;
        string name = "";
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() == TokenType.IDENT) {
            name = currentToken.getLiteral();
            read = new ReadNode(name);
            currentToken = lexer.nextToken();
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseRead",
                currentToken);
        }
        return read;
    }

    WriteNode parseWrite() {
        WriteNode write;
        ExpressionNode expr;
        currentToken = lexer.nextToken();
        expr = parseExpression();
        write = new WriteNode(expr);
        return write;
    }

    BeginEndNode parseBegin() {
        BeginEndNode beginNode;
        StatementNode stat;
        StatementNode[] stats;
        currentToken = lexer.nextToken();
        stats = parseStatements(); 
        if (currentToken.getTokenType() != TokenType.END) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.END) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()) ~ " in parseBegin",
                currentToken); 
        }
        currentToken = lexer.nextToken();
        beginNode = new BeginEndNode(stats);
        return beginNode;
    }

    IfThenNode parseIfThen() {
        IfThenNode ifThenNode;
        ConditionNode condition;
        StatementNode statement;
        currentToken = lexer.nextToken();
        condition = parseCondition();
        if (currentToken.getTokenType() == TokenType.THEN) {
            currentToken = lexer.nextToken();
            statement = parseStatement();
            ifThenNode = new IfThenNode(condition, statement);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.THEN) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()), currentToken);
        }
        return ifThenNode;
    }

    WhileDoNode parseWhileDo() {
        WhileDoNode whileDoNode;
        ConditionNode condition;
        StatementNode statement;
        currentToken = lexer.nextToken();
        condition = parseCondition();
        if (currentToken.getTokenType() == TokenType.DO) {
            currentToken = lexer.nextToken();
            statement = parseStatement();
            whileDoNode = new WhileDoNode(condition, statement);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.DO) ~
                " expected, but found " ~ to!string(currentToken.getTokenType()), currentToken);
        }
        return whileDoNode;
    }

    ConditionNode parseCondition() {
        ConditionNode condition;
        if (currentToken.getTokenType() == TokenType.ODD) {
            currentToken = lexer.nextToken();
            ExpressionNode expr = parseExpression();
            condition = new OddCondNode(expr);
        } else {
            ExpressionNode left = parseExpression();
            Token maybeRelOpToken = currentToken;
            if (currentToken.getTokenType() == TokenType.EQUAL ||
                    currentToken.getTokenType() == TokenType.NOTEQUAL ||
                    currentToken.getTokenType() == TokenType.LESSER ||
                    currentToken.getTokenType() == TokenType.LESSEREQ ||
                    currentToken.getTokenType() == TokenType.GREATER ||
                    currentToken.getTokenType() == TokenType.GREATEREQ) {
                currentToken = lexer.nextToken();
                ExpressionNode right = parseExpression();
                condition = new ComparisonNode(left, right, maybeRelOpToken.getTokenType());
            } else {
                ErrorManager.addParserError(ErrorLevel.ERROR, "Relational Operation" ~
                    " expected, but found " ~ to!string(maybeRelOpToken.getTokenType()), maybeRelOpToken);
            }
        }
        return condition;
    }

    ExpressionNode parseExpression() {
        ExpressionNode expressionNode;
        TokenType operator;
        TermNode termNode;
        // First (unary) operator is optional, if not present use INVALID token type
        if (currentToken.getTokenType() == TokenType.PLUS || currentToken.getTokenType() == TokenType.MINUS) {
            operator = currentToken.getTokenType();
            currentToken = lexer.nextToken();
        } else {
            operator = TokenType.INVALID;
        }
        termNode = parseTerm();
        expressionNode = new ExpressionNode(operator, termNode);
        // Now repeat
        while (currentToken.getTokenType() == TokenType.PLUS || currentToken.getTokenType() == TokenType.MINUS) {
            operator = currentToken.getTokenType();
            currentToken = lexer.nextToken();
            termNode = parseTerm();
            expressionNode.addOpTerm(operator, termNode);
        }
        return expressionNode;
    }

    TermNode parseTerm() {
        TermNode termNode;
        TokenType operator;
        FactorNode factorNode;
        // if (currentToken.getTokenType() == TokenType.MULT || currentToken.getTokenType() == TokenType.DIV) {
        //     operator = currentToken.getTokenType();
        //     currentToken = lexer.nextToken();
        // } else {
        //     operator = TokenType.INVALID;
        // }
        operator = TokenType.INVALID;
        factorNode = parseFactor();
        termNode = new TermNode(operator, factorNode);
        while (currentToken.getTokenType() == TokenType.MULT || currentToken.getTokenType() == TokenType.DIV) {
            operator = currentToken.getTokenType();
            currentToken = lexer.nextToken();
            factorNode = parseFactor();
            termNode.addOpFactor(operator, factorNode);
        }
        return termNode;
    }

    FactorNode parseFactor() {
        FactorNode factorNode;
        switch (currentToken.getTokenType()) {
            case TokenType.IDENT:
                factorNode = new IdentNode(currentToken.getLiteral());
                currentToken = lexer.nextToken();
                break;
            case TokenType.NUMBER:
                factorNode = new NumberNode(currentToken.getLiteral());
                currentToken = lexer.nextToken();
                break;
            case TokenType.LPAREN:
                currentToken = lexer.nextToken();
                ExpressionNode expressionNode = parseExpression();
                factorNode = new ParenExpNode(expressionNode);
                if (currentToken.getTokenType() != TokenType.RPAREN) {
                    ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.RPAREN) ~
                        " expected, but found " ~ to!string(currentToken.getTokenType()), currentToken);

                }
                currentToken = lexer.nextToken();
                break;
            default:
                ErrorManager.addParserError(ErrorLevel.ERROR, "Token " ~ to!string(currentToken.getTokenType()) ~
                    " unexpected at the start of a factor in parseFactor.", currentToken);
        }
        return factorNode;
    }

}
