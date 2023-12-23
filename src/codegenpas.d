/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module codegenpas;

import std.conv;
import std.range;
import std.stdio;
import std.string;
import ast;
import error;
import symtable;
import token;

class PascalCodeGenerator : AstVisitor {

    string name;
    private int indentLevel = 0;
    string sourceFileText = "";

    this(string name) {
        this.name = name;
    }

    private void indent() {
        indentLevel++;
    }

    private void unindent() {
        indentLevel--;
    }

    private void printIndent() {
        emit(to!string(repeat(' ', indentLevel * 4)));
    }

    private void emit(string text) {
        sourceFileText = sourceFileText ~ text;
    }

    void visit(ProgramNode node) {
        writeln();
        writeln("Generating Pascal code for program ", name, " :");

        string result = name[11..name.indexOf(".", 2)];
        emit("program " ~ result ~ ";\n");
        emit("\n");

        enterScope("main");
        node.getBlock().accept(this);
        exitScope();

        emit(".\n");

        // Write source to file
        //write(name ~ ".pas", sourceFileText);
        File file = File("./examples/pas/" ~ result ~ ".pas", "w");
        file.write(sourceFileText);
        file.close();
    }

    void visit(BlockNode node) {
        indent();
        if (node.getConstDecls().length > 0) {
            foreach (index, constant; node.getConstDecls()) {
                printIndent();
                emit("const ");
                constant.accept(this);
                emit(";\n");
            }
            emit("\n");
        }
        if (node.getVarDecls().length > 0) {
            printIndent();
            emit("var\n");
            indent();
            foreach (index, variable; node.getVarDecls()) {
                variable.accept(this);
                if (index + 1 < node.getVarDecls().length) {
                    emit(",\n");
                } else {
                    emit(" : integer;\n");
                }
            }
            unindent();
            emit("\n");
        }
        foreach (index, procedure; node.getProcDecls()) {
            procedure.accept(this);
        }
        unindent();
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            printIndent();
            emit("begin\n");
            indent();
        }
        node.statement.accept(this);
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            emit("\n");
            unindent();
            printIndent();
            emit("end\n");
        }
    }

    void visit(ConstDeclNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getConstName();
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            emit(symbolName ~ " = " ~ to!string(node.getConstValue()));
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(VarDeclNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getVarName();
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            printIndent();
            emit(symbolName);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(ProcDeclNode node) {
        printIndent();
        emit("procedure " ~ node.getProcName ~ "();\n");
        emit("\n");
        enterScope(node.getProcName());
        node.getBlock().accept(this);
        exitScope();
        emit(";\n");
        emit("\n");
    }

    //void visit(StatementNode node); // abstract
    
    void visit(AssignNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getIdentName();
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            printIndent();
            emit(node.getIdentName() ~ " := ");
            node.getExpression().accept(this);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(CallNode node) {
        printIndent();
        emit(node.getIdentName() ~ "()");
    }

    void visit(ReadNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getVarName();
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            printIndent();
            emit("readln(" ~ symbolName ~ ")");
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(WriteNode node) {
        printIndent();
        emit("writeln(");
        node.getExpression().accept(this);
        emit(")");
    }
    
    void visit(BeginEndNode node) {
        printIndent();
        emit("begin\n");
        indent();
        foreach (index, statement; node.getStatements()) {
            statement.accept(this);
            if (index + 1 < node.getStatements().length) {
                emit(";\n");
            } else {
                unindent();
                emit("\n");
                printIndent();
                emit("end");
            }
        }
    }

    void visit(IfThenNode node) {
        printIndent();
        emit("if ");
        node.getCondition().accept(this);
        emit(" then\n");
        indent();
        node.getStatement().accept(this);
        unindent();
    }

    void visit(WhileDoNode node) {
        printIndent();
        emit("while ");
        node.getCondition().accept(this);
        emit(" do\n");
        indent();
        node.getStatement().accept(this);
        unindent();
    }
    
    //void visit(ConditionNode node); // abstract

    void visit(OddCondNode node) {
        emit("(");
        node.getExpr().accept(this);
        emit(") mod 2 = 1");
    }

    void visit(ComparisonNode node) {
        node.getLeft().accept(this);
        switch (node.getRelOperator()) {
            case TokenType.EQUAL:
                emit(" = ");
                break;
            case TokenType.NOTEQUAL:
                emit(" <> ");
                break;
            case TokenType.LESSER:
                emit(" < ");
                break;
            case TokenType.LESSEREQ:
                emit(" <= ");
                break;
            case TokenType.GREATER:
                emit(" > ");
                break;
            case TokenType.GREATEREQ:
                emit(" >= ");
                break;
            default:
                break;
        }
        node.getRight().accept(this);
    }

    void visit(ExpressionNode node) {
        OpTermPair[] opTerms = node.getOpTerms();
        foreach (index, opTerm; opTerms) {
            switch (opTerm.operator) {
                case TokenType.PLUS:
                    if (index == 0) {   // Unary +
                        emit("+");
                    } else {
                        emit(" + ");
                    }
                    break;
                case TokenType.MINUS:
                    if (index == 0) {   // Unary -
                        emit("-");
                    } else {
                        emit(" - ");
                    }
                    break;
                default:
                    break;
            }
            opTerm.term.accept(this);
        }
    }

    void visit(TermNode node) {
        OpFactorPair[] opFactors = node.getOpFactors();
        foreach (index, opFactor; opFactors) {
            switch (opFactor.operator) {
                case TokenType.MULT:
                    emit(" * ");
                    break;
                case TokenType.DIV:
                    emit(" div ");
                    break;
                default:
                    break;
            }
            opFactor.factor.accept(this);
        }
    }

    //void visit(FactorNode node); // abstract

    void visit(NumberNode node) {
        emit(node.getValue());
    }

    void visit(VariableNode node) {
        emit(node.getVarName());
    }

    void visit(ParenExpNode node) {
        emit("( ");
        node.getExpression().accept(this);
        emit(" )");
    }

}
