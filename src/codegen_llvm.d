/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module codegen_llvm;

import llvm;
import std.conv;
import std.stdio;
import std.string;
import ast;
import error;
import symtable;
import token;

class LLVMCodeGenerator : AstVisitor {

    string name;
    bool emitDebugInfo;

    LLVMTypeRef int32Type;
    LLVMContextRef llvmContext;
    LLVMModuleRef llvmModule;
    LLVMBuilderRef llvmBuilder;
    LLVMValueRef mainFunction;
    LLVMValueRef currentFunction;
    LLVMBasicBlockRef mainEntryBlock;
    LLVMBasicBlockRef currentBasicBlock;
    LLVMTargetMachineRef llvmTargetMachine;

    this(string name, bool emitDebugInfo = false) {
        this.name = name;
        this.emitDebugInfo = emitDebugInfo;
    }

    void initializeLLVM() {
        LLVMInitializeNativeTarget();

        // Setup LLVM main objects
        int32Type = LLVMInt32Type();
        llvmContext = LLVMGetGlobalContext();
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

    void setupExternals() {
        // Setup external functions
        LLVMTypeRef readIntegerType = LLVMFunctionType(LLVMInt32Type(), null, 0, 0);
        LLVMValueRef readIntegerDecl = LLVMAddFunction(llvmModule, "readInteger", readIntegerType);
        LLVMTypeRef[] paramTypes = [LLVMInt32Type()];
        LLVMTypeRef writeIntegerType = LLVMFunctionType(LLVMVoidType(), paramTypes.ptr, 1, 0);
        LLVMValueRef writeIntegerDecl = LLVMAddFunction(llvmModule, "writeInteger", writeIntegerType);
    }

    void verifyModuleAndPrint() {
        LLVMVerifierFailureAction action = LLVMPrintMessageAction;
        char* error = null;
        LLVMBool result = LLVMVerifyModule(llvmModule, action, &error);
        if (result != 0) {
            writeln("Module verification failed:\n%s", error);
            LLVMDisposeMessage(error);
        } else {
            writeln("Module verification succeeded!");
        }

        char *generatedCode = LLVMPrintModuleToString(llvmModule);
        string output = to!string(generatedCode);
        writeln(output);
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
        setupExternals();

        LLVMTypeRef[] mainArgs = [LLVMInt32Type()];
        LLVMTypeRef mainFuncType = LLVMFunctionType(LLVMInt32Type(), mainArgs.ptr, cast(uint) mainArgs.length, false);
        mainFunction = LLVMAddFunction(llvmModule, "main", mainFuncType);
        mainEntryBlock = LLVMAppendBasicBlock(mainFunction, "main");
        currentBasicBlock = mainEntryBlock;
        LLVMPositionBuilderAtEnd(llvmBuilder, mainEntryBlock);

        enterScope("main");
        node.getBlock().accept(this);
        exitScope();

        LLVMBuildRet(llvmBuilder, LLVMConstInt(LLVMInt32Type(), 0, true));

        verifyModuleAndPrint();

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
        Symbol* foundSymbol;
        string symbolName = node.getConstName();
        LLVMValueRef valRef;
        LLVMValueRef constValue;
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            valRef = LLVMBuildAlloca(llvmBuilder, int32Type, symbolName.toStringz());
            constValue = LLVMConstInt(int32Type, node.getConstValue(), false);
            LLVMBuildStore(llvmBuilder, constValue, valRef);
            symbols[node.getSymbolId()].setValueRef(valRef);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(VarDeclNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getVarName();
        LLVMValueRef valRef;
        LLVMValueRef varValue;
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            valRef = LLVMBuildAlloca(llvmBuilder, int32Type, symbolName.toStringz());
            // All vars are initialized to 0 on declaration
            varValue = LLVMConstInt(int32Type, 0, false);
            LLVMBuildStore(llvmBuilder, varValue, valRef);
            symbols[node.getSymbolId()].setValueRef(valRef);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(ProcDeclNode node) {
        LLVMBasicBlockRef parentBasicBlock = currentBasicBlock;
        LLVMTypeRef[] procArgs = [];
        LLVMTypeRef procType = LLVMFunctionType(LLVMInt32Type(), procArgs.ptr, cast(uint) procArgs.length, false);
        LLVMValueRef thisProcedure = LLVMAddFunction(llvmModule, cast(char*)node.getProcName.toStringz(), procType);
        LLVMValueRef parentFunction = currentFunction;
        string procName = node.getProcName ~ "_main";
        LLVMBasicBlockRef procBasicBlock = LLVMAppendBasicBlock(thisProcedure, cast(char*)procName.toStringz());
        currentBasicBlock = procBasicBlock;
        currentFunction = thisProcedure;
        LLVMPositionBuilderAtEnd(llvmBuilder, procBasicBlock);
        enterScope(node.getProcName());
        node.getBlock().accept(this);
        exitScope();
        LLVMBuildRet(llvmBuilder, LLVMConstInt(LLVMInt32Type(), 0, true));
        currentBasicBlock = parentBasicBlock;
        currentFunction = parentFunction;
        LLVMPositionBuilderAtEnd(llvmBuilder, currentBasicBlock);
    }

    //void visit(StatementNode node); // abstract
    
    void visit(AssignNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getIdentName();
        LLVMValueRef variableRef;
        //LLVMValueRef tempRef;
        LLVMValueRef expressionValue;
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            node.getExpression().accept(this);
            variableRef = symbols[node.getSymbolId()].getValueRef();
        //    tempRef = LLVMBuildLoad(llvmBuilder, variableRef, "tmp");
            expressionValue = node.getExpression.getLlvmValue();
            LLVMBuildStore(llvmBuilder, expressionValue, variableRef);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(CallNode node) {
        LLVMValueRef[] functionArgs = null;
        LLVMValueRef calledFunction = LLVMGetNamedFunction(llvmModule, node.getIdentName().toStringz());
        LLVMValueRef callInstruction = LLVMBuildCall(llvmBuilder, calledFunction, functionArgs.ptr,
                                                    cast(uint)functionArgs.length, "");
    }

    void visit(ReadNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getVarName();
        LLVMValueRef variableRef;
        LLVMValueRef expressionValue;
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            variableRef = symbols[node.getSymbolId()].getValueRef();

            LLVMValueRef[] functionArgs = null;
            LLVMValueRef readFunction = LLVMGetNamedFunction(llvmModule, "readInteger");
            LLVMValueRef readCall = LLVMBuildCall(llvmBuilder, readFunction, functionArgs.ptr,
                                                cast(uint)functionArgs.length, "read");

            LLVMBuildStore(llvmBuilder, variableRef, readCall);
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
    }

    void visit(WriteNode node) {
        LLVMValueRef llvmExpressionValue;
        node.getExpression().accept(this);
        llvmExpressionValue = node.getExpression().getLlvmValue();
        LLVMValueRef[] functionArgs = [llvmExpressionValue];
        LLVMValueRef writeFunction = LLVMGetNamedFunction(llvmModule, "writeInteger");

        LLVMValueRef writeCall = LLVMBuildCall(llvmBuilder, writeFunction, functionArgs.ptr,
                                            cast(uint)functionArgs.length, "");
    }
    
    void visit(BeginEndNode node) {
        foreach (index, statement; node.getStatements()) {
            statement.accept(this);
        }
    }

    void visit(IfThenNode node) {
        LLVMBasicBlockRef ifConditionBlock = LLVMAppendBasicBlock(currentFunction, "if_condition");
        LLVMBasicBlockRef ifTrueBlock = LLVMAppendBasicBlock(currentFunction, "if_true");
        LLVMBasicBlockRef ifExitBlock = LLVMAppendBasicBlock(currentFunction, "if_exit");

        LLVMBuildBr(llvmBuilder, ifConditionBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, ifConditionBlock);

        LLVMValueRef llvmConditionValue;
        node.getCondition().accept(this);
        llvmConditionValue = node.getCondition().getLlvmValue();

        LLVMBuildCondBr(llvmBuilder, llvmConditionValue, ifTrueBlock, ifExitBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, ifTrueBlock);

        node.getStatement().accept(this);
        LLVMBuildBr(llvmBuilder, ifExitBlock);

        LLVMMoveBasicBlockAfter(ifExitBlock, LLVMGetInsertBlock(llvmBuilder));
        LLVMPositionBuilderAtEnd(llvmBuilder, ifExitBlock);
    }

    void visit(WhileDoNode node) {
        LLVMBasicBlockRef loopConditionBlock = LLVMAppendBasicBlock(currentFunction, "loop_condition");
        LLVMBasicBlockRef loopBodyBlock = LLVMAppendBasicBlock(currentFunction, "loop_body");
        LLVMBasicBlockRef loopExitBlock = LLVMAppendBasicBlock(currentFunction, "loop_exit");

        LLVMBuildBr(llvmBuilder, loopConditionBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, loopConditionBlock);

        LLVMValueRef llvmConditionValue;
        node.getCondition().accept(this);
        llvmConditionValue = node.getCondition().getLlvmValue();

        LLVMBuildCondBr(llvmBuilder, llvmConditionValue, loopBodyBlock, loopExitBlock);
        LLVMPositionBuilderAtEnd(llvmBuilder, loopBodyBlock);

        node.getStatement().accept(this);

        LLVMBuildBr(llvmBuilder, loopConditionBlock);
        LLVMMoveBasicBlockAfter(loopExitBlock, LLVMGetInsertBlock(llvmBuilder));
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
            }
            node.setLlvmValue(llvmValue);
        }
    }

    void visit(TermNode node) {
        LLVMValueRef llvmValue;
        OpFactorPair[] opFactors = node.getOpFactors();
        foreach (index, opFactor; opFactors) {
            if (index == 0) {
                opFactor.factor.accept(this);
                llvmValue = opFactor.factor.getLlvmValue();
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
            }
            node.setLlvmValue(llvmValue);
        }
    }

    //void visit(FactorNode node); // abstract

    void visit(NumberNode node) {
        LLVMValueRef numberRef;
        numberRef = LLVMConstInt(int32Type, node.getNumberValue, true);
        node.setLlvmValue(numberRef);
    }

    void visit(VariableNode node) {
        Symbol* foundSymbol;
        string symbolName = node.getVarName();
        LLVMValueRef variableRef;
        if ((foundSymbol = lookupSymbol(symbolName)) != null) {
            variableRef = LLVMBuildLoad(llvmBuilder, symbols[node.getSymbolId()].getValueRef(), symbolName.toStringz());
        } else {
            ErrorManager.addCodeGenError(ErrorLevel.ERROR, "Error: Symbol '" ~ symbolName ~ "' ~
                    not found in scope: '" ~ (*foundSymbol).scopeName ~ "'.");
        }
        node.setLlvmValue(variableRef);
    }

    void visit(ParenExpNode node) {
        node.getExpression().accept(this);
        node.setLlvmValue(node.getExpression().getLlvmValue());
    }

}
