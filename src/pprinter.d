module pprinter;

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
        write(" ".repeat(indentLevel * 4));
    }

    void visit(ProgramNode node) {
        writeln("Prettyprinting program ", name, " :");
        node.block.accept(this);
        writeln(".");
    }

    void visit(BlockNode node) {
        indent();
        foreach (constant; node.constants) {
            constant.accept(this);
        }
        foreach (variable; node.variables) {
            variable.accept(this);
        }
        foreach (procedure; node.procedures) {
            procedure.accept(this);
        }
        node.statement.accept(this);
        unindent();
    }

}
