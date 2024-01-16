/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module prettyprinter;

import std.range;
import std.stdio;
import ast;
import token;

class PrettyPrinter : AstVisitor {

    string moduleName;
    private int indentLevel = 0;

    this(string moduleName) {
        this.moduleName = moduleName;
    }

    private void indent() {
        indentLevel++;
    }

    private void unindent() {
        indentLevel--;
    }

    private void printIndent() {
        write(repeat(' ', indentLevel * 4));
    }

    void visit(ProgramNode node) {
        writeln("Prettyprinting program ", moduleName, " :");
        node.getBlock.accept(this);
        writeln(".");
        writeln("");
    }

    void visit(BlockNode node) {
        writeln("");
        indent();
        if (node.getConstDecls().length > 0) {
            printIndent();
            writeln("const");
            indent();
            foreach (index, constant; node.getConstDecls()) {
                constant.accept(this);
                //writeln(index, ",", node.getConstDecls().length);
                if (index + 1 < node.getConstDecls().length) {
                    writeln(",");
                } else {
                    writeln(";");
                }
            }
            unindent();
            writeln("");
        }
        if (node.getVarDecls().length > 0) {
            printIndent();
            writeln("var");
            indent();
            foreach (index, variable; node.getVarDecls()) {
                variable.accept(this);
                if (index + 1 < node.getVarDecls().length) {
                    writeln(",");
                } else {
                    writeln(";");
                }
            }
            unindent();
            writeln("");
        }
        foreach (index, procedure; node.getProcDecls()) {
            procedure.accept(this);
        }
        unindent();
        node.statement.accept(this);
    }

    void visit(ConstDeclNode node) {
        printIndent();
        write(node.getIdent().getName, " = ", node.getNumber().getValue());
    }

    void visit(VarDeclNode node) {
        printIndent();
        write(node.getIdent().getName());
    }

    void visit(ProcDeclNode node) {
        printIndent();
        writeln("procedure ", node.getIdent().getName(), ";");
        node.getBlock().accept(this);
        writeln(";");
        writeln();
    }

    // abstract
    // void visit(StatementNode node) {
    //     writeln("statement");
    // }

    void visit(AssignNode node) {
        printIndent();
        write(node.getIdent().getName(), " := ");
        node.getExpression().accept(this);
    }

    void visit(CallNode node) {
        printIndent();
        write("call ", node.getIdent().getName());
    }

    void visit(ReadNode node) {
        printIndent();
        write("read ", node.getIdent().getName());
    }

    void visit(WriteNode node) {
        printIndent();
        write("write ");
        node.getExpression().accept(this);
    }

    void visit(BeginEndNode node) {
        printIndent();
        writeln("begin");
        indent();
        foreach (index, statement; node.getStatements()) {
            statement.accept(this);
            if (index + 1 < node.getStatements().length) {
                writeln(";");
            } else {
                unindent();
                writeln();
                printIndent();
                write("end");
            }
        }
    }

    void visit(IfThenNode node) {
        printIndent();
        write("if ");
        node.getCondition().accept(this);
        writeln(" then");
        indent();
        node.getStatement().accept(this);
        unindent();
    }

    void visit(WhileDoNode node) {
        printIndent();
        write("while ");
        node.getCondition().accept(this);
        writeln(" do");
        indent();
        node.getStatement().accept(this);
        unindent();
    }

    // abstract
    // void visit(ConditionNode node) {
    //     writeln("condition");
    // }

    void visit(OddCondNode node) {
        write("odd ");
        node.getExpr().accept(this);
    }

    void visit(ComparisonNode node) {
        node.getLeft().accept(this);
        switch (node.getRelOperator()) {
            case TokenType.EQUAL:
                write(" = ");
                break;
            case TokenType.NOTEQUAL:
                write(" # ");
                break;
            case TokenType.LESSER:
                write(" < ");
                break;
            case TokenType.LESSEREQ:
                write(" <= ");
                break;
            case TokenType.GREATER:
                write(" > ");
                break;
            case TokenType.GREATEREQ:
                write(" >= ");
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
                        write("+");
                    } else {
                        write(" + ");
                    }
                    break;
                case TokenType.MINUS:
                    if (index == 0) {   // Unary -
                        write("-");
                    } else {
                        write(" - ");
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
                    write(" * ");
                    break;
                case TokenType.DIV:
                    write(" / ");
                    break;
                default:
                    break;
            }
            opFactor.factor.accept(this);
        }
    }
    
    // abstract
    // void visit(FactorNode node) {
    //     writeln("factor");
    // }

    void visit(NumberNode node) {
        write(node.getValue());
    }

    void visit(IdentNode node) {
        write(node.getName());
    }

    void visit(ParenExpNode node) {
        write("( ");
        node.getExpression().accept(this);
        write(" )");
    }

}
