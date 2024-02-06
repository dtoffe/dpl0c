/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module codegenc;

import std.algorithm;
import std.conv;
import std.range;
import std.stdio;
import std.string;
import ast;
import error;
import symtable;
import token;

class CCodeGenerator : AstVisitor {

    string name;
    private int indentLevel = 0;
    string sourceFileText = "";
    string constSection = "";
    string varSection = "";
    string[int] procSection;

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
        emitProc(to!string(repeat(' ', indentLevel * 4)));
    }

    private void emit(string text) {
        sourceFileText = sourceFileText ~ text;
    }

    private void emitConst(string text) {
        constSection = constSection ~ text;
    }

    private void emitVar(string text) {
        varSection = varSection ~ text;
    }

    private void emitProc(string text) {
        procSection[currentScope.id] = procSection[currentScope.id] ~ text;
    }

    private string rename(string name) {
        return name ~ "_";
    }

    private string[] cKeywords = [
        "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum",
        "extern", "float", "for", "goto", "if", "int", "long", "register", "return", "void", "while"];

    private bool isCKeyword(string name) {
        bool result = false;
        name = toLower(name);
        foreach (string keyword; cKeywords) {
            if (keyword == name) {
                result = true;
                break;
            }
        }
        return result;
    }

    private void preProcess() {
        for (int symbolId = 0; symbolId < nextId; symbolId++) {
            for (int i = 0; i < symbolId; i++) {
                while (toLower(symbols[i].nick) == toLower(symbols[symbolId].nick)
                            || isCKeyword(toLower(symbols[symbolId].nick))) {
                    symbols[symbolId].nick = rename(symbols[symbolId].nick);
                }
            }
        }
        for (int symbolId = 0; symbolId < nextId; symbolId++) {
            writeln("Symbol: " ~ symbols[symbolId].name ~ "(" ~ to!string(symbolId) ~ ") -> " ~ symbols[symbolId].nick);
        }
    }

    void visit(ProgramNode node) {
        writeln();
        writeln("Generating C code for program ", name, " :");

        string result = name[11..name.indexOf(".", 2)];

        preProcess();
        
        enterScope(symtable.MAIN_SCOPE);
        node.getBlock().accept(this);
        exitScope();

        emit("#include <stdio.h>\n\n");
        emit(constSection ~ "\n");
        emit(varSection ~ "\n");
        foreach (index; procSection.keys.sort!"a < b"[1..procSection.length]) {
            emit(procSection[index] ~ "\n");
        }
        emit(procSection[0] ~ "\n");

        // Write source to file
        File file = File("./examples/c/" ~ result ~ ".c", "w");
        file.write(sourceFileText);
        file.close();
    }

    void visit(BlockNode node) {
        if (node.getConstDecls().length > 0) {
            foreach (index, constant; node.getConstDecls()) {
                emitConst("const int ");
                constant.accept(this);
                emitConst(";\n");
            }
        }
        if (node.getVarDecls().length > 0) {
            foreach (index, variable; node.getVarDecls()) {
                emitVar("int ");
                variable.accept(this);
                emitVar(";\n");
            }
        }
        foreach (index, procedure; node.getProcDecls()) {
            procedure.accept(this);
        }
        if (currentScope.id == 0) {
            procSection[currentScope.id] = "";
            emitProc("int main(int argc, char *argv[])\n");
        }
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            emitProc("{\n");
            indent();
        }
        node.statement.accept(this);
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            if (currentScope.id == 0) {
                printIndent();
                emitProc("return 0;\n");
            }
            unindent();
            printIndent();
            emitProc("}\n");
        }
    }

    void visit(ConstDeclNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            emitConst(node.getIdent().getNick() ~ " = " ~ to!string(node.getNumber().getValue()));
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(VarDeclNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            emitVar(node.getIdent().getNick());
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(ProcDeclNode node) {
        enterScope(node.getIdent().getSymbolId());
        procSection[currentScope.id] = "";
        emitProc("void " ~ node.getIdent().getNick() ~ "(void)\n");
        node.getBlock().accept(this);
        exitScope();
    }

    //void visit(StatementNode node); // abstract
    
    void visit(AssignNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            printIndent();
            emitProc(node.getIdent().getNick() ~ " = ");
            node.getExpression().accept(this);
            emitProc(";\n");
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(CallNode node) {
        printIndent();
        emitProc(node.getIdent().getNick() ~ "();\n");
    }

    void visit(ReadNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            printIndent();
            emitProc("scanf(\"%d\", &" ~ symbolName ~ ");\n");
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(WriteNode node) {
        printIndent();
        emitProc("printf(\"%d\\n\", ");
        node.getExpression().accept(this);
        emitProc(");\n");
    }
    
    void visit(BeginEndNode node) {
        printIndent();
        emitProc("{\n");
        indent();
        foreach (index, statement; node.getStatements()) {
            statement.accept(this);
            if (index + 1 >= node.getStatements().length) {
                if (currentScope.id == 0 && indentLevel == 1) {
                    printIndent();
                    emitProc("return 0;\n");
                }
                unindent();
                printIndent();
                emitProc("}\n");
            }
        }
    }

    void visit(IfThenNode node) {
        printIndent();
        emitProc("if (");
        node.getCondition().accept(this);
        emitProc(")\n");
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            indent();
        }
        node.getStatement().accept(this);
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            unindent();
        }
    }

    void visit(WhileDoNode node) {
        printIndent();
        emitProc("while (");
        node.getCondition().accept(this);
        emitProc(")\n");
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            indent();
        }
        node.getStatement().accept(this);
        if (typeid(node.statement) != typeid(BeginEndNode)) {
            unindent();
        }
    }
    
    //void visit(ConditionNode node); // abstract

    void visit(OddCondNode node) {
        emitProc("(");
        node.getExpr().accept(this);
        emitProc(") & 1");
    }

    void visit(ComparisonNode node) {
        node.getLeft().accept(this);
        switch (node.getRelOperator()) {
            case TokenType.EQUAL:
                emitProc(" == ");
                break;
            case TokenType.NOTEQUAL:
                emitProc(" != ");
                break;
            case TokenType.LESSER:
                emitProc(" < ");
                break;
            case TokenType.LESSEREQ:
                emitProc(" <= ");
                break;
            case TokenType.GREATER:
                emitProc(" > ");
                break;
            case TokenType.GREATEREQ:
                emitProc(" >= ");
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
                        emitProc("+");
                    } else {
                        emitProc(" + ");
                    }
                    break;
                case TokenType.MINUS:
                    if (index == 0) {   // Unary -
                        emitProc("-");
                    } else {
                        emitProc(" - ");
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
                    emitProc(" * ");
                    break;
                case TokenType.DIV:
                    emitProc(" / ");
                    break;
                default:
                    break;
            }
            opFactor.factor.accept(this);
        }
    }

    //void visit(FactorNode node); // abstract

    void visit(NumberNode node) {
        emitProc(node.getValue());
    }

    void visit(IdentNode node) {
        emitProc(node.getNick());
    }

    void visit(ParenExpNode node) {
        emitProc("( ");
        node.getExpression().accept(this);
        emitProc(" )");
    }

}
