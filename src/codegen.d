/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module codegen;

import llvm;
import std.conv;
import std.stdio;
import std.string;
import ast;
import error;
import symtable;
import token;

class CodeGenerator : AstVisitor {

    string name;
    bool emitDebugInfo;

    LLVMTypeRef int32Type;
    LLVMContextRef llvmContext;
    LLVMModuleRef llvmModule;
    LLVMBuilderRef llvmBuilder;
    LLVMValueRef mainFunction;
    LLVMBasicBlockRef mainEntryBlock;
    LLVMTargetMachineRef llvmTargetMachine;

    LLVMValueRef[string] vars;

    this(string name, bool emitDebugInfo = false) {
        this.name = name;
        this.emitDebugInfo = emitDebugInfo;
    }

    void initializeLLVM() {
        LLVMInitializeNativeTarget();

        // Setup LLVM main objects
        int32Type = LLVMInt32Type();
        llvmContext = LLVMContextCreate();
        llvmModule = LLVMModuleCreateWithNameInContext((name ~ ".ll").toStringz(), llvmContext);
        llvmBuilder = LLVMCreateBuilderInContext(llvmContext);

        // Setup default triple
        char *errorMessage;
        char *triple = LLVMGetDefaultTargetTriple();
        LLVMSetTarget(llvmModule, triple);

        // Get target
        LLVMTargetRef target;
        LLVMGetTargetFromTriple(triple, &target, &errorMessage);

        // Get target machine
        LLVMTargetMachineRef machine = LLVMCreateTargetMachine(target, triple,
                                            LLVMGetHostCPUName(),
                                            LLVMGetHostCPUFeatures(),
                                            LLVMCodeGenLevelDefault,
                                            LLVMRelocDefault,
                                            LLVMCodeModelDefault);

        // Setup data layout
        LLVMTargetDataRef datalayout = LLVMCreateTargetDataLayout(machine);
        char *datalayout_str = LLVMCopyStringRepOfTargetData(datalayout);
        LLVMSetDataLayout(llvmModule, datalayout_str);
    }

    void finalizeLLVM() {
        LLVMDisposeBuilder(llvmBuilder);
        LLVMDisposeModule(llvmModule);
        LLVMDisposeTargetMachine(llvmTargetMachine);
        LLVMContextDispose(llvmContext);
    }

    void visit(ProgramNode node) {
        writeln();
        writeln("Generating code for program ", name, " :");
        initializeLLVM();

        LLVMTypeRef[] mainArgs = [LLVMInt32Type()];
        LLVMTypeRef mainFuncType = LLVMFunctionType(LLVMInt32Type(), mainArgs.ptr, cast(uint) mainArgs.length, false);
        mainFunction = LLVMAddFunction(llvmModule, "main", mainFuncType);
        mainEntryBlock = LLVMAppendBasicBlock(mainFunction, "main");
        LLVMPositionBuilderAtEnd(llvmBuilder, mainEntryBlock);

        enterScope("main");
        node.getBlock().accept(this);
        exitScope();

        LLVMPositionBuilderAtEnd(llvmBuilder, mainEntryBlock);
        LLVMBuildRet(llvmBuilder, LLVMConstInt(LLVMInt32Type(), 0, true));

        char *generatedCode = LLVMPrintModuleToString(llvmModule);
        string output = to!string(generatedCode);
        writeln(output);

        finalizeLLVM();
    }

    void visit(BlockNode node) {
        if (node.getConstDecls().length > 0) {
            foreach (index, constant; node.getConstDecls()) {
                constant.accept(this);
            }
        }
        if (node.getVarDecls().length > 0) {
            foreach (index, variable; node.getVarDecls()) {
                variable.accept(this);
            }
        }
        foreach (index, procedure; node.getProcDecls()) {
            procedure.accept(this);
        }
        node.statement.accept(this);
    }

    void visit(ConstDeclNode node) {
        Symbol foundSymbol;
        string foundScopeName = null;
        string symbolName = node.getConstName();
        LLVMValueRef valRef;
        LLVMValueRef constValue;
        if (lookupSymbol(symbolName, foundSymbol, foundScopeName)) {
            valRef = LLVMBuildAlloca(llvmBuilder, int32Type, symbolName.toStringz());
            constValue = LLVMConstInt(int32Type, node.getConstValue(), false);
            LLVMBuildStore(llvmBuilder, constValue, valRef);
            vars[symbolName ~ foundScopeName] = valRef;
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ foundScopeName ~ "'.");
        }
    }

    void visit(VarDeclNode node) {
        Symbol foundSymbol;
        string foundScopeName = null;
        string symbolName = node.getVarName();
        LLVMValueRef valRef;
        LLVMValueRef varValue;
        if (lookupSymbol(symbolName, foundSymbol, foundScopeName)) {
            valRef = LLVMBuildAlloca(llvmBuilder, int32Type, symbolName.toStringz());
            // All vars are initialized to 0 on declaration
            varValue = LLVMConstInt(int32Type, 0, false);
            LLVMBuildStore(llvmBuilder, varValue, valRef);
            vars[symbolName ~ foundScopeName] = valRef;
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ foundScopeName ~ "'.");
        }
    }

    void visit(ProcDeclNode node) {
        LLVMTypeRef[] procArgs = [];
        LLVMTypeRef procType = LLVMFunctionType(LLVMInt32Type(), procArgs.ptr, cast(uint) procArgs.length, false);
        LLVMValueRef thisProcedure = LLVMAddFunction(llvmModule, cast(char*)node.getProcName.toStringz(), procType);
        string procName = node.getProcName ~ "_main";
        LLVMBasicBlockRef procBasicBlock = LLVMAppendBasicBlock(thisProcedure, cast(char*)procName.toStringz());
        LLVMPositionBuilderAtEnd(llvmBuilder, procBasicBlock);
        enterScope(node.getProcName());
        node.getBlock().accept(this);
        exitScope();
    }

    //void visit(StatementNode node); // abstract
    
    void visit(AssignNode node) {
        Symbol foundSymbol;
        string foundScopeName = null;
        string symbolName = node.getIdentName();
        LLVMValueRef variableRef;
        LLVMValueRef expressionValue;
        if (lookupSymbol(symbolName, foundSymbol, foundScopeName)) {
            node.getExpression().accept(this);
            variableRef = vars[symbolName ~ foundScopeName];
            expressionValue = node.getExpression.getLlvmValue();
            LLVMBuildStore(llvmBuilder, variableRef, expressionValue);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ foundScopeName ~ "'.");
        }
    }

    void visit(CallNode node) {}
    void visit(ReadNode node) {}
    void visit(WriteNode node) {}

    void visit(BeginEndNode node) {
        foreach (index, statement; node.getStatements()) {
            statement.accept(this);
        }
    }

    void visit(IfThenNode node) {}

    void visit(WhileDoNode node) {
        LLVMValueRef llvmConditionValue;
        node.getCondition().accept(this);
        llvmConditionValue = node.getCondition().getLlvmValue();

        LLVMBasicBlockRef loopConditionBlock = LLVMAppendBasicBlock(mainFunction, "loop_condition");
        LLVMBasicBlockRef loopBodyBlock = LLVMAppendBasicBlock(mainFunction, "loop_body");
        LLVMBasicBlockRef loopExitBlock = LLVMAppendBasicBlock(mainFunction, "loop_exit");
        LLVMBuildBr(llvmBuilder, loopConditionBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, loopConditionBlock);
        LLVMBuildCondBr(llvmBuilder, llvmConditionValue, loopBodyBlock, loopExitBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, loopBodyBlock);

        node.getStatement().accept(this);

        LLVMBuildBr(llvmBuilder, loopConditionBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, loopExitBlock);
    }
    
    //void visit(ConditionNode node); // abstract

    void visit(OddCondNode node) {
        LLVMValueRef llvmValue;
        node.getExpr().accept(this);
        llvmValue = node.getExpr().getLlvmValue();
        llvmValue = LLVMBuildAnd(llvmBuilder, llvmValue, LLVMConstInt(LLVMInt32Type(), 1, false), "lsb");
        node.setLlvmValue(llvmValue);
    }

    void visit(ComparisonNode node) {
        LLVMValueRef llvmValue;
        LLVMValueRef llvmLeftValue;
        LLVMValueRef llvmRightValue;
        node.getLeft().accept(this);
        llvmLeftValue = node.getLeft().getLlvmValue();
        node.getRight().accept(this);
        llvmRightValue = node.getRight().getLlvmValue();
        switch (node.getRelOperator()) {
            case TokenType.EQUAL:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntEQ, llvmLeftValue, llvmRightValue, "tmp");
                break;
            case TokenType.NOTEQUAL:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntNE, llvmLeftValue, llvmRightValue, "tmp");
                break;
            case TokenType.LESSER:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntSLT, llvmLeftValue, llvmRightValue, "tmp");
                break;
            case TokenType.LESSEREQ:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntSLE, llvmLeftValue, llvmRightValue, "tmp");
                break;
            case TokenType.GREATER:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntSGT, llvmLeftValue, llvmRightValue, "tmp");
                break;
            case TokenType.GREATEREQ:
                llvmValue = LLVMBuildICmp(llvmBuilder, LLVMIntSGE, llvmLeftValue, llvmRightValue, "tmp");
                break;
            default:
                break;
        }
        node.setLlvmValue(llvmValue);
    }

    void visit(ExpressionNode node) {
        LLVMValueRef llvmValue;
        OpTermPair[] opTerms = node.getOpTerms();
        foreach (index, opTerm; opTerms) {
            if (index == 0) {
                opTerm.term.accept(this);
                if (opTerm.operator == TokenType.MINUS) {
                    LLVMValueRef zero = LLVMConstInt(LLVMInt32Type(), 0, false);
                    llvmValue = LLVMBuildSub(llvmBuilder, zero, llvmValue, "tmp");
                } else {
                    llvmValue = opTerm.term.getLlvmValue();
                }
                node.setLlvmValue(llvmValue);
            } else {
                opTerm.term.accept(this);
                llvmValue = opTerm.term.getLlvmValue();
                switch (opTerm.operator) {
                    case TokenType.PLUS:
                        llvmValue = LLVMBuildAdd(llvmBuilder, node.getLlvmValue(), llvmValue, "tmp");
                        break;
                    case TokenType.MINUS:
                        llvmValue = LLVMBuildSub(llvmBuilder, node.getLlvmValue(), llvmValue, "tmp");
                        break;
                    default:
                        break;
                }
                node.setLlvmValue(llvmValue);
            }
        }
    }

    void visit(TermNode node) {
        LLVMValueRef llvmValue;
        OpFactorPair[] opFactors = node.getOpFactors();
        foreach (index, opFactor; opFactors) {
            if (index == 0) {
                opFactor.factor.accept(this);
                llvmValue = opFactor.factor.getLlvmValue();
                node.setLlvmValue(llvmValue);
            } else {
                opFactor.factor.accept(this);
                llvmValue = opFactor.factor.getLlvmValue();
                switch (opFactor.operator) {
                    case TokenType.MULT:
                        llvmValue = LLVMBuildMul(llvmBuilder, node.getLlvmValue(), llvmValue, "tmp");
                        break;
                    case TokenType.DIV:
                        llvmValue = LLVMBuildUDiv(llvmBuilder, node.getLlvmValue(), llvmValue, "tmp");
                        break;
                    default:
                        break;
                }
                node.setLlvmValue(llvmValue);
            }
        }
    }

    //void visit(FactorNode node); // abstract

    void visit(NumberNode node) {
        LLVMValueRef numberRef;
        numberRef = LLVMConstInt(int32Type, node.getNumberValue, true);
        node.setLlvmValue(numberRef);
    }

    void visit(VariableNode node) {
        Symbol foundSymbol;
        string foundScopeName = null;
        string symbolName = node.getVarName();
        LLVMValueRef variableRef;
        if (lookupSymbol(symbolName, foundSymbol, foundScopeName)) {
            variableRef = LLVMBuildLoad(llvmBuilder, vars[symbolName ~ foundScopeName], symbolName.toStringz());
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ foundScopeName ~ "'.");
        }
        node.setLlvmValue(variableRef);
    }

    void visit(ParenExpNode node) {
        node.getExpression().accept(this);
    }

}
