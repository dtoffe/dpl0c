module pprinter;

import std.range;
import std.stdio;
import ast;
import token;

class PrettyPrinter : AstVisitor {

    string name;
    private int indentLevel = 0;

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
        write(repeat(' ', indentLevel * 4));
    }

    void visit(ProgramNode node) {
        writeln("Prettyprinting program ", name, " :");
        node.getBlock.accept(this);
        writeln(".");
        writeln("");
    }

    void visit(BlockNode node) {
        writeln("");
        if (node.getConstDecls().length > 0) {
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
        node.statement.accept(this);
    }

    void visit(ConstDeclNode node) {
        printIndent();
        write(node.getConstName(), " = ", node.getConstValue());
    }

    void visit(VarDeclNode node) {
        printIndent();
        write(node.getVarName());
    }

    void visit(ProcDeclNode node) {
        writeln("procedure ", node.getProcName(), ";");
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
        write(node.getIdentName, " := ");
        node.getExpression().accept(this);
    }

    void visit(CallNode node) {
        printIndent();
        write("call ", node.getIdentName());
    }

    void visit(ReadNode node) {
        printIndent();
        write("read ", node.getVarName());
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
                    write(" + ");
                    break;
                case TokenType.MINUS:
                    write(" - ");
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

    void visit(VariableNode node) {
        write(node.getName());
    }

    void visit(ParenExpNode node) {
        write("( ");
        node.getExpression().accept(this);
        write(" )");
    }

}
