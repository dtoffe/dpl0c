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

/*
 * PL/0 is case sensitive, but Pascal is not. So in PL/0 we can have for example:
 * const MAX = 100;
 * var max;
 * procedure Max;
 * and it would be valid, but in Pascal this would result in duplicate identifier error.
 * So we must ensure that the identifiers are renamed to prevent case insensitivized
 * duplicates before code generation.
 * This is done in the preProcess method by renaming the identifiers in the symbol table
 * that need to be renamed within the scope so as not to have duplicates.
 * This stage also renames identifiers that are not valid because they are reserved words
 * in Pascal.
 * Note: This stage assumes that the symbol table is already built and that there are no
 * duplicate identifiers in the PL/0 source.
 * Note 2: Pascal does not like the program name to be the same as a reserved word or an
 * identifier. I have not considered and avoided such cases in the code generator.
 */
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

    private string rename(string name) {
        return name ~ "_";
    }

    private string[] pascalKeywords = [
        "and", "array", "begin", "case", "const", "div", "do", "downto", "else", "end", "file", "for", "function",
        "goto", "if", "in", "label", "mod", "nil", "not", "of", "or", "procedure", "program", "read", "readln",
        "record", "repeat", "set", "then", "to", "type", "until", "var", "while", "with", "write", "writeln"];

    private bool isPascalKeyword(string name) {
        bool result = false;
        name = toLower(name);
        foreach (string keyword; pascalKeywords) {
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
                            || isPascalKeyword(toLower(symbols[symbolId].nick))) {
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
        writeln("Generating Pascal code for program ", name, " :");

        string result = name[11..name.indexOf(".", 2)];
        emit("program " ~ result ~ ";\n");
        emit("\n");

        preProcess();
        
        enterScope(symtable.MAIN_SCOPE);
        node.getBlock().accept(this);
        exitScope();

        emit(".\n");

        // Write source to file
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
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            emit(node.getIdent().getNick() ~ " = " ~ to!string(node.getNumber().getValue()));
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(VarDeclNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            printIndent();
            emit(node.getIdent().getNick());
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(ProcDeclNode node) {
        printIndent();
        emit("procedure " ~ node.getIdent().getNick() ~ "();\n");
        emit("\n");
        enterScope(node.getIdent().getSymbolId());
        node.getBlock().accept(this);
        exitScope();
        emit(";\n");
        emit("\n");
    }

    //void visit(StatementNode node); // abstract
    
    void visit(AssignNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            printIndent();
            emit(node.getIdent().getNick() ~ " := ");
            node.getExpression().accept(this);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
        }
    }

    void visit(CallNode node) {
        printIndent();
        emit(node.getIdent().getNick() ~ "()");
    }

    void visit(ReadNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            printIndent();
            emit("readln(" ~ node.getIdent().getNick() ~ ")");
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in current or parent scopes.");
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

    void visit(IdentNode node) {
        emit(node.getNick());
    }

    void visit(ParenExpNode node) {
        emit("( ");
        node.getExpression().accept(this);
        emit(" )");
    }

}
