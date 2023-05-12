module pprinter;

import std.range;
import std.stdio;
import ast;

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
        node.getBlock.accept(this);
        writeln(";");
        writeln();
    }

    void visit(StatementNode node) {
        writeln("statement");
    }

    void visit(AssignNode node) {
        indent();
    }

    void visit(CallNode node) {
        writeln("call ", node.getIdentName());
    }

    void visit(ReadNode node) {
        writeln("read ", node.getVarName());
    }

    void visit(WriteNode node) {
        indent();
    }

    void visit(BeginEndNode node) {
        indent();
    }

    void visit(IfThenNode node) {
        indent();
    }

    void visit(WhileDoNode node) {
        indent();
    }

    void visit(ExpressionNode node) {
        indent();
    }

    void visit(NumberNode node) {
        indent();
    }

    void visit(VariableNode node) {
        indent();
    }

    void visit(BinaryOpNode node) {
        indent();
    }

    void visit(ConditionNode node) {
        indent();
    }

}
