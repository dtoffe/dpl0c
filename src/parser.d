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

    TokenType lookahead() {
        return currentToken.getTokenType();
    }

    Token consume(TokenType tokenType) {
        Token result = currentToken;
        if (lookahead() == tokenType || tokenGroup(lookahead()) == tokenType) {
            currentToken = lexer.nextToken();
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(tokenType) ~
                " expected, but found " ~ to!string(lookahead()) ~ " instead.",
                currentToken);
        }
        return result;
    }

    ProgramNode parseProgram() {
        ProgramNode program = new ProgramNode(new IdentNode("main"));
        // Get the first token from the input so lookahead() does not return null
        currentToken = lexer.nextToken();
        program.block = parseBlock();
        consume(TokenType.PERIOD);
        consume(TokenType.EOF);
        return program;
    }

    BlockNode parseBlock() {
        BlockNode node = new BlockNode();
        if (lookahead() == TokenType.CONST) {
            consume(TokenType.CONST);
            node.setConstDecls(parseConstDecls());
        }
        if (lookahead() == TokenType.VAR) {
            consume(TokenType.VAR);
            node.setVarDecls(parseVarDecls());
        }
        if (lookahead() == TokenType.PROCEDURE) {
            node.setProcDecls(parseProcDecls());
        }
        node.setStatement(parseStatement());
        return node;
    }

    ConstDeclNode[] parseConstDecls() {
        ConstDeclNode[] constDecls;
        Token nameToken;
        Token valueToken;
        while (lookahead() == TokenType.IDENT) {
            nameToken = consume(TokenType.IDENT);
            if (lookahead() == TokenType.EQUAL) {
                consume(TokenType.EQUAL);
                if (lookahead() == TokenType.NUMBER) {
                    valueToken = consume(TokenType.NUMBER);
                    IdentNode ident = new IdentNode(nameToken.getLiteral());
                    NumberNode number = new NumberNode(valueToken.getLiteral());
                    ConstDeclNode decl = new ConstDeclNode(ident, number);
                    constDecls ~= decl;
                } else {
                    ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.NUMBER) ~
                        " expected, but found " ~ to!string(lookahead()) ~ " instead.",
                        currentToken);                    
                }
            } else {
                ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.EQUAL) ~
                    " expected, but found " ~ to!string(lookahead()) ~ " instead.",
                    currentToken);
            }
            if (lookahead() == TokenType.SEMICOLON) {
                consume(TokenType.SEMICOLON);
                break;
            }
            consume(TokenType.COMMA);
        }
        return constDecls;
    }

    VarDeclNode[] parseVarDecls() {
        VarDeclNode[] varDecls;
        Token token;
        while (lookahead() == TokenType.IDENT) {
            token = consume(TokenType.IDENT);
            IdentNode ident = new IdentNode(token.getLiteral());
            VarDeclNode decl = new VarDeclNode(ident);
            varDecls ~= decl;
            if (lookahead() == TokenType.SEMICOLON) {
                consume(TokenType.SEMICOLON);
                break;
            }
            consume(TokenType.COMMA);
        }
        return varDecls;
    }

    ProcDeclNode[] parseProcDecls() {
        ProcDeclNode[] procDecls;
        ProcDeclNode procDecl;
        while (lookahead() == TokenType.PROCEDURE) {
            procDecl = parseProcDecl();
            procDecls ~= procDecl;
        }
        return procDecls;
    }

    ProcDeclNode parseProcDecl() {
        ProcDeclNode procDecl;
        Token token;
        consume(TokenType.PROCEDURE);
        if (lookahead() != TokenType.IDENT) {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                " expected, but found " ~ to!string(lookahead()) ~ " instead.",
                currentToken); 
        }
        token = consume(TokenType.IDENT);
        consume(TokenType.SEMICOLON);
        BlockNode block = parseBlock();
        IdentNode ident = new IdentNode(token.getLiteral());
        procDecl = new ProcDeclNode(ident, block);
        consume(TokenType.SEMICOLON);
        return procDecl;
    }

    StatementNode parseStatement() {
        StatementNode statNode;
        switch (lookahead()) {
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
                ErrorManager.addParserError(ErrorLevel.ERROR, "Token " ~ to!string(lookahead()) ~
                    " unexpected at the start of a statement in parseStatement.", currentToken);
                break;
        }
        return statNode;
    }

    StatementNode[] parseStatements() {
        StatementNode[] statements = new StatementNode[0];
        statements ~= parseStatement();
        while (lookahead() == TokenType.SEMICOLON) {
            consume(TokenType.SEMICOLON);
            statements ~= parseStatement();
        }
        return statements;
    }

    AssignNode parseAssign() {
        AssignNode assign;
        IdentNode ident;
        ExpressionNode expr;
        Token token = consume(TokenType.IDENT);
        consume(TokenType.ASSIGN);
        ident = new IdentNode(token.getLiteral());
        expr = parseExpression();
        assign = new AssignNode(ident, expr);
        return assign;
    }

    CallNode parseCall() {
        CallNode call;
        IdentNode ident;
        Token token;
        consume(TokenType.CALL);
        if (lookahead() == TokenType.IDENT) {
            token = consume(TokenType.IDENT);
            ident = new IdentNode(token.getLiteral());
            call = new CallNode(ident);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                " expected, but found " ~ to!string(lookahead()) ~ " in parseCall",
                currentToken);
        }
        return call;
    }

    ReadNode parseRead() {
        ReadNode read;
        IdentNode ident;
        Token token;
        consume(TokenType.READ);
        if (lookahead() == TokenType.IDENT) {
            token = consume(TokenType.IDENT);
            ident = new IdentNode(token.getLiteral());
            read = new ReadNode(ident);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.IDENT) ~
                " expected, but found " ~ to!string(lookahead()) ~ " in parseRead",
                currentToken);
        }
        return read;
    }

    WriteNode parseWrite() {
        WriteNode write;
        ExpressionNode expr;
        consume(TokenType.WRITE);
        expr = parseExpression();
        write = new WriteNode(expr);
        return write;
    }

    BeginEndNode parseBegin() {
        BeginEndNode beginNode;
        StatementNode[] stats;
        consume(TokenType.BEGIN);
        stats = parseStatements(); 
        consume(TokenType.END);
        beginNode = new BeginEndNode(stats);
        return beginNode;
    }

    IfThenNode parseIfThen() {
        IfThenNode ifThenNode;
        ConditionNode condition;
        StatementNode statement;
        consume(TokenType.IF);
        condition = parseCondition();
        if (lookahead() == TokenType.THEN) {
            consume(TokenType.THEN);
            statement = parseStatement();
            ifThenNode = new IfThenNode(condition, statement);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.THEN) ~
                " expected, but found " ~ to!string(lookahead()), currentToken);
        }
        return ifThenNode;
    }

    WhileDoNode parseWhileDo() {
        WhileDoNode whileDoNode;
        ConditionNode condition;
        StatementNode statement;
        consume(TokenType.WHILE);
        condition = parseCondition();
        if (lookahead() == TokenType.DO) {
            consume(TokenType.DO);
            statement = parseStatement();
            whileDoNode = new WhileDoNode(condition, statement);
        } else {
            ErrorManager.addParserError(ErrorLevel.ERROR, to!string(TokenType.DO) ~
                " expected, but found " ~ to!string(lookahead()), currentToken);
        }
        return whileDoNode;
    }

    ConditionNode parseCondition() {
        ConditionNode condition;
        Token token;
        if (lookahead() == TokenType.ODD) {
            consume(TokenType.ODD);
            ExpressionNode expr = parseExpression();
            condition = new OddCondNode(expr);
        } else {
            ExpressionNode left = parseExpression();
            if (tokenGroup(lookahead()) == TokenType.RELOP) {
                token = consume(TokenType.RELOP);
                ExpressionNode right = parseExpression();
                condition = new ComparisonNode(left, right, token.getTokenType());
            } else {
                ErrorManager.addParserError(ErrorLevel.ERROR, "Relational Operation" ~
                    " expected, but found " ~ to!string(token.getTokenType()), token);
            }
        }
        return condition;
    }

    ExpressionNode parseExpression() {
        ExpressionNode expressionNode;
        TermNode termNode;
        Token token;
        TokenType operator;
        // First (unary) operator is optional, if not present use INVALID token type
        if (tokenGroup(lookahead()) == TokenType.TERMOP) {
            token = consume(TokenType.TERMOP);
            operator = token.getTokenType();
        } else {
            operator = TokenType.INVALID;
        }
        termNode = parseTerm();
        expressionNode = new ExpressionNode(operator, termNode);
        // Now repeat
        while (tokenGroup(lookahead()) == TokenType.TERMOP) {
            token = consume(TokenType.TERMOP);
            operator = token.getTokenType();
            termNode = parseTerm();
            expressionNode.addOpTerm(operator, termNode);
        }
        return expressionNode;
    }

    TermNode parseTerm() {
        TermNode termNode;
        FactorNode factorNode;
        Token token;
        TokenType operator;
        operator = TokenType.INVALID;
        factorNode = parseFactor();
        termNode = new TermNode(operator, factorNode);
        while (tokenGroup(lookahead()) == TokenType.FACTOP) {
            token = consume(TokenType.FACTOP);
            operator = token.getTokenType();
            factorNode = parseFactor();
            termNode.addOpFactor(operator, factorNode);
        }
        return termNode;
    }

    FactorNode parseFactor() {
        FactorNode factorNode;
        Token token;
        switch (lookahead()) {
            case TokenType.IDENT:
                token = consume(TokenType.IDENT);
                factorNode = new IdentNode(token.getLiteral());
                break;
            case TokenType.NUMBER:
                token = consume(TokenType.NUMBER);
                factorNode = new NumberNode(token.getLiteral());
                break;
            case TokenType.LPAREN:
                consume(TokenType.LPAREN);
                ExpressionNode expressionNode = parseExpression();
                factorNode = new ParenExpNode(expressionNode);
                consume(TokenType.RPAREN);
                break;
            default:
                ErrorManager.addParserError(ErrorLevel.ERROR, "Token " ~ to!string(lookahead()) ~
                    " unexpected at the start of a factor in parseFactor.", currentToken);
        }
        return factorNode;
    }

}
