/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module ast;

import llvm;
import std.conv;
import std.stdio;
import symtable;
import token;

abstract class AstNode {

    abstract void accept(AstVisitor visitor);

}

class ProgramNode : AstNode {

    BlockNode block;

    this() {
    }
    
    BlockNode getBlock() {
        return block;
    }
    
    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class BlockNode : AstNode {

    ConstDeclNode[] constDecls;
    VarDeclNode[] varDecls;
    ProcDeclNode[] procDecls;
    StatementNode  statement;
    
    this() {
    }
    
    ConstDeclNode[] getConstDecls() {
        return constDecls;
    }

    void setConstDecls(ConstDeclNode[] constDecls) {
        this.constDecls = constDecls;
    }
    
    VarDeclNode[] getVarDecls() {
        return varDecls;
    }
    
    void setVarDecls(VarDeclNode[] varDecls) {
        this.varDecls = varDecls;
    }

    ProcDeclNode[] getProcDecls() {
        return procDecls;
    }
    
    void setProcDecls(ProcDeclNode[] procDecls) {
        this.procDecls = procDecls;
    }

    StatementNode getStatement() {
        return statement;
    }
    
    void setStatement(StatementNode statement) {
        this.statement = statement;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ConstDeclNode : AstNode {

    IdentNode ident;
    NumberNode number;

    this(IdentNode ident, NumberNode number) {
        this.ident = ident;
        this.number = number;
    }
    
    IdentNode getIdent() {
        return ident;
    }

    NumberNode getNumber() {
        return number;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class VarDeclNode : AstNode {

    IdentNode ident;

    this(IdentNode ident) {
        this.ident = ident;
    }
    
    IdentNode getIdent() {
        return ident;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ProcDeclNode : AstNode {

    IdentNode ident;
    BlockNode block;

    this(IdentNode ident, BlockNode block) {
        this.ident = ident;
        this.block = block;
    }

    IdentNode getIdent() {
        return ident;
    }

    BlockNode getBlock() {
        return block;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

abstract class StatementNode : AstNode {

}

class AssignNode : StatementNode {

    IdentNode ident;
    ExpressionNode expression;

    this(IdentNode ident, ExpressionNode expression) {
        this.ident = ident;
        this.expression = expression;
    }

    IdentNode getIdent() {
        return ident;
    }

    ExpressionNode getExpression() {
        return expression;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class CallNode : StatementNode {

    IdentNode ident;

    this(IdentNode ident) {
        this.ident = ident;
    }

    IdentNode getIdent() {
        return ident;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ReadNode : StatementNode {

    IdentNode ident;

    this(IdentNode ident) {
        this.ident = ident;
    }

    IdentNode getIdent() {
        return ident;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class WriteNode : StatementNode {

    ExpressionNode expression;

    this(ExpressionNode expression) {
        this.expression = expression;
    }

    ExpressionNode getExpression() {
        return expression;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class BeginEndNode : StatementNode {

    StatementNode[] statements;

    this(StatementNode[] statements) {
        this.statements = statements;
    }

    StatementNode[] getStatements() {
        return statements;
    }
    
    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class IfThenNode : StatementNode {

    ConditionNode condition;
    StatementNode statement;

    this(ConditionNode condition, StatementNode statement) {
        this.condition = condition;
        this.statement = statement;
    }

    ConditionNode getCondition() {
        return condition;
    }

    StatementNode getStatement() {
        return statement;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class WhileDoNode : StatementNode {

    ConditionNode condition;
    StatementNode statement;

    this(ConditionNode condition, StatementNode statement) {
        this.condition = condition;
        this.statement = statement;
    }

    ConditionNode getCondition() {
        return condition;
    }

    StatementNode getStatement() {
        return statement;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

abstract class ValuedNode : AstNode {
    
    LLVMValueRef llvmValue;

    LLVMValueRef getLlvmValue() {
        return llvmValue;
    }

    void setLlvmValue(LLVMValueRef llvmValue) {
        this.llvmValue = llvmValue;
    }

}

abstract class ConditionNode : ValuedNode {
    
}

class OddCondNode : ConditionNode {

    ExpressionNode expr;

    this(ExpressionNode expr) {
        this.expr = expr;
    }

    ExpressionNode getExpr() {
        return expr;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ComparisonNode : ConditionNode {
    
    ExpressionNode left;
    ExpressionNode right;
    TokenType relOperator;

    this(ExpressionNode left, ExpressionNode right, TokenType relOperator) {
        this.left = left;
        this.right = right;
        this.relOperator = relOperator;
    }

    ExpressionNode getLeft() {
        return left;
    }

    ExpressionNode getRight() {
        return right;
    }

    TokenType getRelOperator() {
        return relOperator;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

struct OpTermPair {
    TokenType operator;
    TermNode term;
}

class ExpressionNode : ValuedNode {
    
    OpTermPair[] opTerms;

    this(TokenType operator, TermNode term) {
        opTerms = new OpTermPair[0];
        OpTermPair opTerm = OpTermPair(operator, term);
        this.opTerms ~= opTerm;
    }

    void addOpTerm(TokenType operator, TermNode term) {
        OpTermPair opTerm = OpTermPair(operator, term);
        this.opTerms ~= opTerm;
    }
    
    OpTermPair[] getOpTerms() {
        return opTerms;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

struct OpFactorPair {
    TokenType operator;
    FactorNode factor;
}

class TermNode : ValuedNode {

    OpFactorPair[] opFactors;
 
    this(TokenType operator, FactorNode factor) {
        this.opFactors = new OpFactorPair[0];
        OpFactorPair opFactor = OpFactorPair(operator, factor);
        this.opFactors ~= opFactor;
    }

    void addOpFactor(TokenType operator, FactorNode factor) {
        OpFactorPair opFactor = OpFactorPair(operator, factor);
        this.opFactors ~= opFactor;
    }

    OpFactorPair[] getOpFactors() {
        return opFactors;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

abstract class FactorNode : ValuedNode {

}

class NumberNode : FactorNode {

    string value;
 
    this(string value) {
        this.value = value;
    }

    string getValue() {
        return value;
    }

    int getNumberValue() {
        return to!int(value);
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class IdentNode : FactorNode {
    
    string name;
    int symbolId;

    this(string name) {
        this.name = name;
    }

    string getName() {
        return name;
    }

    int getSymbolId() {
        return symbolId;
    }

    void setSymbolId(int symbolId) {
        this.symbolId = symbolId;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ParenExpNode : FactorNode {
    
    ExpressionNode expression;

    this(ExpressionNode expression) {
        this.expression = expression;
    }

    ExpressionNode getExpression() {
        return expression;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

interface AstVisitor {

    void visit(ProgramNode node);
    void visit(BlockNode node);
    void visit(ConstDeclNode node);
    void visit(VarDeclNode node);
    void visit(ProcDeclNode node);
    //void visit(StatementNode node); // abstract
    void visit(AssignNode node);
    void visit(CallNode node);
    void visit(ReadNode node);
    void visit(WriteNode node);
    void visit(BeginEndNode node);
    void visit(IfThenNode node);
    void visit(WhileDoNode node);
    //void visit(ConditionNode node); // abstract
    void visit(OddCondNode node);
    void visit(ComparisonNode node);
    void visit(ExpressionNode node);
    void visit(TermNode node);
    //void visit(FactorNode node); // abstract
    void visit(NumberNode node);
    void visit(IdentNode node);
    void visit(ParenExpNode node);

}
