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

class CodeGenerator : AstVisitor {

    string name;
    bool emitDebugInfo;
    // int annMDKind;

    LLVMContextRef llvmContext;
    LLVMModuleRef llvmModule;
    LLVMBuilderRef llvmBuilder;
    LLVMTypeRef int32Type;
    LLVMTargetMachineRef llvmTargetMachine;


    this(string name, bool emitDebugInfo = false) {
        this.name = name;
        this.emitDebugInfo = emitDebugInfo;
    }

    void initializeLLVM() {
        LLVMInitializeNativeTarget();

        // Setup LLVM main objects
        llvmContext = LLVMContextCreate();
        llvmModule = LLVMModuleCreateWithNameInContext((name ~ ".ll").toStringz(), llvmContext);
        llvmBuilder = LLVMCreateBuilderInContext(llvmContext);
        int32Type = LLVMInt32Type();
        // annMDKind = LLVMGetMDKindID(("llvm.annotation").toStringz(), "llvm.annotation".length);

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
        LLVMValueRef mainFunction = LLVMAddFunction(llvmModule, "main", mainFuncType);
        LLVMBasicBlockRef mainEntryBlock = LLVMAppendBasicBlock(mainFunction, "main");
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
            node.setLLVMValue(valRef);
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
        LLVMValueRef constValue;
        if (lookupSymbol(symbolName, foundSymbol, foundScopeName)) {
            valRef = LLVMBuildAlloca(llvmBuilder, int32Type, symbolName.toStringz());
            node.setLLVMValue(valRef);
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

    }

    void visit(CallNode node) {}
    void visit(ReadNode node) {}
    void visit(WriteNode node) {}
    void visit(BeginEndNode node) {}
    void visit(IfThenNode node) {}
    void visit(WhileDoNode node) {}
    //void visit(ConditionNode node); // abstract
    void visit(OddCondNode node) {}
    void visit(ComparisonNode node) {}
    void visit(ExpressionNode node) {}
    void visit(TermNode node) {}

    //void visit(FactorNode node); // abstract

    void visit(NumberNode node) {
        node.setLLVMValue(LLVMConstInt(LLVMInt32Type(), node.getNumberValue, true));
    }

    void visit(VariableNode node) {
        //node.setLLVMValue(LLVMGetNamedValue(llvmModule, cast(char*)node.getName.toStringz()));
    }

    void visit(ParenExpNode node) {
        node.getExpression().accept(this);
    }

}
