/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module scopechecker;

import std.string;
import ast;
import symtable;

/**
 * Scoping rules:
 * ==============
 * I assume that PL/0 has the following scoping rules (but I need to check it with external sources):
 * - Uses static scoping
 * – All names must be declared before they are used
 * – Multiple declarations of a name are not allowed in the same scope,
 *     even for different kinds of names (const, var, procedure...)
 * - The same name can be declared in multiple nested scopes, but only once per scope
 * – The same scope is considered for a method's parameters and for the
 *     local variables declared at the beginning of the same method
 */
class ScopeChecker : AstVisitor {

    string name;

    this(string name) {
        this.name = name;
    }

    void visit(ProgramNode node) {

    }

    void visit(BlockNode node) {

    }

    void visit(ConstDeclNode node) {

    }

    void visit(VarDeclNode node) {

    }

    void visit(ProcDeclNode node) {

    }

    // abstract
    // void visit(StatementNode node) {
    //     writeln("statement");
    // }

    void visit(AssignNode node) {

    }

    void visit(CallNode node) {

    }

    void visit(ReadNode node) {

    }

    void visit(WriteNode node) {

    }

    void visit(BeginEndNode node) {

    }

    void visit(IfThenNode node) {

    }

    void visit(WhileDoNode node) {

    }

    // abstract
    // void visit(ConditionNode node) {
    //     writeln("condition");
    // }

    void visit(OddCondNode node) {

    }

    void visit(ComparisonNode node) {

    }

    void visit(ExpressionNode node) {

    }

    void visit(TermNode node) {

    }
    
    // abstract
    // void visit(FactorNode node) {
    //     writeln("factor");
    // }

    void visit(NumberNode node) {

    }

    void visit(VariableNode node) {

    }

    void visit(ParenExpNode node) {

    }

}
