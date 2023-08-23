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
    LLVMTargetMachineRef llvmTargetMachine;

    LLVMModuleRef llvmModule;
    LLVMBuilderRef llvmBuilder;
    LLVMTypeRef integerType;

    this(string name, bool emitDebugInfo = false) {
        this.name = name;
        this.emitDebugInfo = emitDebugInfo;
    }

    void initializeLLVM() {

        LLVMInitializeNativeTarget();
        //LLVMInitializeNativeTargetAsmPrinter();
        //LLVMInitializeNativeTargetAsmParser();

        llvmContext = LLVMContextCreate();
        llvmModule = LLVMModuleCreateWithNameInContext((name ~ ".ll").toStringz(), llvmContext);
        llvmBuilder = LLVMCreateBuilderInContext(llvmContext);
        integerType = LLVMInt32Type();

        // Setup target triple
        char *errorMessage;
        char *triple = LLVMGetDefaultTargetTriple();
        LLVMTargetRef target;
        LLVMGetTargetFromTriple(triple, &target, &errorMessage);
        LLVMSetTarget(llvmModule, triple);

        // // Setup target data layout
        //     //printf("target: %s, [%s], %d, %d\n", LLVMGetTargetName(target), LLVMGetTargetDescription(target), LLVMTargetHasJIT(target), LLVMTargetHasTargetMachine(target));
        //     //printf("triple: %s\n", LLVMGetDefaultTargetTriple());
        //     //printf("features: %s\n", LLVMGetHostCPUFeatures());

            // llvmTargetMachine = LLVMCreateTargetMachine(llvmContext, "x86-64", "generic", "default", 0, 0);

        LLVMTargetMachineRef machine = LLVMCreateTargetMachine(target, triple,
                                            LLVMGetHostCPUName(),
                                            LLVMGetHostCPUFeatures(),
                                            LLVMCodeGenLevelDefault,
                                            LLVMRelocDefault,
                                            LLVMCodeModelDefault);
        LLVMTargetDataRef datalayout = LLVMCreateTargetDataLayout(machine);
        char *datalayout_str = LLVMCopyStringRepOfTargetData(datalayout);
            //printf("datalayout: %s\n", datalayout_str);
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

        char *generatedCode = LLVMPrintModuleToString(llvmModule);
        string output = to!string(generatedCode);
        writeln(output);

        finalizeLLVM();
    }

    void visit(BlockNode node) {}
    void visit(ConstDeclNode node) {}
    void visit(VarDeclNode node) {}
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
