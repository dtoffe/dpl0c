module ast;

import std.conv;
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

    string constName;
    int constValue;
    
    this(string constName, int constValue) {
        this.constName = constName;
        this.constValue = constValue;
    }
    
    string getConstName() {
        return constName;
    }

    int getConstValue() {
        return constValue;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class VarDeclNode : AstNode {

    string varName;

    this(string varName) {
        this.varName = varName;
    }
    
    string getVarName() {
        return varName;
    }
    
    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ProcDeclNode : AstNode {

    string procName;
    BlockNode block;

    this(string procName, BlockNode block) {
        this.procName = procName;
        this.block = block;
    }

    string getProcName() {
        return procName;
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

    string identName;
    ExpressionNode expression;

    this(string identName, ExpressionNode expression) {
        this.identName = identName;
        this.expression = expression;
    }

    string getIdentName() {
        return identName;
    }

    ExpressionNode getExpression() {
        return expression;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class CallNode : StatementNode {

    string identName;

    this(string identName) {
        this.identName = identName;
    }

    string getIdentName() {
        return identName;
    }
    
    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class ReadNode : StatementNode {

    string varName;

    this(string varName) {
        this.varName = varName;
    }

    string getVarName() {
        return varName;
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
    StatementNode ifStatement;
    StatementNode elseStatement;

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

class WhileDoNode : StatementNode {

    ConditionNode condition;
    StatementNode statement;

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

}

abstract class ConditionNode : AstNode {
    
}

class OddCondNode : ConditionNode {

    ExpressionNode expr;

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    ExpressionNode getExpr() {
        return expr;
    }

}

class ComparisonNode : ConditionNode {
    
    ExpressionNode left;
    ExpressionNode right;
    string operator;

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    ExpressionNode getLeft() {
        return left;
    }

    ExpressionNode getRight() {
        return right;
    }

    string getOperator() {
        return operator;
    }

}

class ExpressionNode : AstNode {
    
    struct OpTermPair {
        TokenType operator;
        TermNode term;
    }
    
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
    
    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    OpTermPair[] getOpTerms() {
        return opTerms;
    }

}

class TermNode : AstNode {

    struct OpFactorPair {
        TokenType operator;
        FactorNode factor;
    }

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

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    OpFactorPair[] getOpFactors() {
        return opFactors;
    }

}

abstract class FactorNode : AstNode {

}

class NumberNode : FactorNode {

    string value;

    this(string value) {
        this.value = value;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    string getValue() {
        return value;
    }

    int getNumberValue() {
        return to!int(value);
    }

}

class VariableNode : FactorNode {
    
    string name;

    this(string name) {
        this.name = name;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    string getName() {
        return name;
    }

}

class ParenExpNode : FactorNode {
    
    ExpressionNode expression;

    this(ExpressionNode expression) {
        this.expression = expression;
    }

    override void accept(AstVisitor visitor) {
        visitor.visit(this);
    }

    ExpressionNode getExpression() {
        return expression;
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
    void visit(VariableNode node);
    void visit(ParenExpNode node);

}
