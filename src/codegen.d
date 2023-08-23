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
import symtable;

class CodeGenerator : AstVisitor {

    string name;
    bool emitDebugInfo;

    LLVMContextRef llvmContext;
    LLVMModuleRef llvmModule;
    LLVMBuilderRef llvmBuilder;
    LLVMTypeRef integerType;
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
        integerType = LLVMInt32Type();

        // Setup triple
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
        writeln("Generating code for program ", name, " :");
        initializeLLVM();

        LLVMTypeRef[] mainArgs = [LLVMInt32Type()];
        LLVMTypeRef mainFunctionType = LLVMFunctionType(LLVMInt32Type(), mainArgs.ptr, cast(uint) mainArgs.length, false);
        LLVMValueRef mainFunction = LLVMAddFunction(llvmModule, "main", mainFunctionType);
        LLVMBasicBlockRef mainEntryBlock = LLVMAppendBasicBlock(mainFunction, "entry");
        LLVMPositionBuilderAtEnd(llvmBuilder, mainEntryBlock);

        node.getBlock().accept(this);

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
        // procs and statements...
    }

    void visit(ConstDeclNode node) {
        // Constants do not need allocated memory, they are replaced by their value
        // whenever they appear in the code
    }

    void visit(VarDeclNode node) {

    }

    void visit(ProcDeclNode node) {}
    //void visit(StatementNode node); // abstract
    void visit(AssignNode node) {}
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
    void visit(NumberNode node) {}
    void visit(VariableNode node) {}
    void visit(ParenExpNode node) {}

}
