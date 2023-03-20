module parser;

import ast;
import lexer;
import token;

class Parser {

    Lexer lexer;
    Token currentToken;
    
    this(Lexer lex) {
        lexer = lex;
    }

    ProgramNode parseProgram() {
        BlockNode block = parseBlock();
        //match(TokenKind.EndOfFile);
        if (currentToken.getTokenType() == TokenType.PERIOD) {
            currentToken = lexer.nextToken();
        } else {
            // log error
        }
        if (currentToken.getTokenType() != TokenType.EOF) {
            // log error
        }
        ProgramNode program = new ProgramNode();
        program.block = block;
        return program;
    }

    BlockNode parseBlock() {
        BlockNode node = new BlockNode();
        currentToken = lexer.nextToken();
        if (currentToken.getTokenType() == TokenType.CONST) {
            node.setConstDecls(parseConstDecls());
        }
        if (currentToken.getTokenType() == TokenType.VAR) {
            node.setVarDecls(parseVarDecls());
        }
        if (currentToken.getTokenType() == TokenType.PROCEDURE) {
            node.setProcDecls(parseProcDecls());
        }
        node.setStatement(parseStatement());
        return node;
    }

    ConstDeclNode[] parseConstDecls() {
         ConstDeclNode[] constDecls = new ConstDeclNode[0];
    //     if (currentToken.getTokenType() == TokenType.CONST) {
    //         currentToken = lexer.nextToken();
    //         while (currentToken.getTokenType() == TokenType.IDENT) {
                
    //             if (currentToken.getTokenType() == TokenType.IDENT) {
    //                 ConstDeclNode[] newConstDecls = new ConstDeclNode[constDecls.length + 1];
    //                 for (int i = 0; i < constDecls.length; i++) {
    //                     newConstDecls[i] = constDecls[i];
    //                 }
    //                 newConstDecls[newConstDecls.length - 1] = parseConstDecl();
    //                 constDecls = newConstDecls;
    //             } else {
    //                 break;
    //             }
                
    //         }
            
    //     }
        return constDecls;
    }

    VarDeclNode[] parseVarDecls() {
        VarDeclNode[] varDecls = new VarDeclNode[0];
        return varDecls;
    }

    ProcDeclNode[] parseProcDecls() {
        ProcDeclNode[] procDecls = new ProcDeclNode[0];
        return procDecls;
    }

    StatementNode parseStatement() {
        StatementNode statNode = null; //new StatementNode();
        return statNode;
    }

}
