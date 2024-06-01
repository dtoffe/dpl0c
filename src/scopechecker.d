/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module scopechecker;

import std.algorithm.searching;
import std.conv;
import std.stdio;
import std.string;
import ast;
import error;
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

    string moduleName;

    this(string moduleName) {
        this.moduleName = moduleName;
    }

    void visit(ProgramNode node) {
        symtable.initialize();
        //symtable.enterScope("main");
        node.getBlock().accept(this);
        symtable.exitScope();
    }

    void visit(BlockNode node) {
        foreach (constDecl; node.getConstDecls()) {
            constDecl.accept(this);
        }
        foreach (varDecl; node.getVarDecls()) {
            varDecl.accept(this);
        }
        foreach (procDecl; node.getProcDecls()) {
            procDecl.accept(this);
        }
        node.getStatement().accept(this);
    }

    void visit(ConstDeclNode node) {
        string name = node.getIdent().getName();
        int value = node.getNumber().getNumberValue();
        symtable.createSymbol(name, SymbolKind.CONST, SymbolType.INTEGER, value);
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            node.getIdent().setSymbolId(foundSymbol.id);
        }
    }

    void visit(VarDeclNode node) {
        string name = node.getIdent().getName();
        symtable.createSymbol(name, SymbolKind.VAR, SymbolType.INTEGER, 0);
        Symbol foundSymbol;
        string symbolName = name;
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            node.getIdent().setSymbolId(foundSymbol.id);
        }
    }

    void visit(ProcDeclNode node) {
        string name = node.getIdent().getName();
        Symbol newSymbol = symtable.createSymbol(name, SymbolKind.PROCEDURE, SymbolType.INTEGER, 0);
        node.getIdent().setSymbolId(newSymbol.id);
        //symtable.createScope(newSymbol.id, name);
        //symtable.enterScope(node.getProcName());
        node.getBlock().accept(this);
        symtable.exitScope();
    }

    // abstract
    // void visit(StatementNode node) {
    //     writeln("statement");
    // }

    void visit(AssignNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            if (foundSymbol.kind == SymbolKind.CONST) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Constant '" ~
                        symbolName ~ "' cannot be assigned a value.");
            }
            if (foundSymbol.kind == SymbolKind.PROCEDURE) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Procedure '" ~
                        symbolName ~ "' cannot be assigned a value.");
            }
            writeln("Assign to variable: " ~ symbolName ~ " in scope: " ~ foundSymbol.getScopeName());
            if (foundSymbol.scopeId != currentScope.id) {
                int chainScopeId = currentScope.id;
                while (chainScopeId != foundSymbol.scopeId) {
                    writeln("Searching for " ~ foundSymbol.nick ~ " in scope: " ~ to!string(chainScopeId));
                    if ((scopes[chainScopeId].outerContext).find(foundSymbol.id).empty) {
                        scopes[chainScopeId].outerContext ~= foundSymbol.id;
                        writeln(foundSymbol.nick ~ " added to outer scope in scope: " ~ scopes[chainScopeId].nick);
                    }
                    chainScopeId = (scopes[chainScopeId].parent is null)
                                        ? foundSymbol.scopeId
                                        : scopes[chainScopeId].parent.id;
                }
            }
            node.getIdent().setSymbolId(foundSymbol.id);
        } else {
            ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Identifier '" ~
                    symbolName ~ "' is undeclared in the current and all enclosing scopes.");
        }
        node.getExpression().accept(this);
    }

    void visit(CallNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ( (foundSymbol = lookupSymbol(symbolName) ) !is null) {
            if (foundSymbol.kind == SymbolKind.CONST) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Constant '" ~
                        symbolName ~ "' cannot be called.");
            }
            if (foundSymbol.kind == SymbolKind.VAR) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Variable '" ~
                        symbolName ~ "' cannot be called.");
            }
            writeln("Call to procedure: " ~ symbolName ~ " in scope: " ~ foundSymbol.getScopeName());
            // if (foundSymbol.scopeId != currentScope.id) {
            //     int chainScopeId = currentScope.id;
            //     while (chainScopeId != foundSymbol.scopeId) {
            //         writeln("Searching for " ~ foundSymbol.nick ~ " in scope: " ~ to!string(chainScopeId));
            //         if ((scopes[chainScopeId].outerContext).find(foundSymbol.id).empty) {
            //             scopes[chainScopeId].outerContext ~= foundSymbol.id;
            //             writeln(foundSymbol.nick ~ " added to outer scope in scope: " ~ scopes[chainScopeId].nick);
            //         }
            //         chainScopeId = (scopes[chainScopeId].parent is null)
            //                             ? foundSymbol.scopeId
            //                             : scopes[chainScopeId].parent.id;
            //     }
            // }
            node.getIdent().setSymbolId(foundSymbol.id);
        } else {
            ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Identifier '" ~
                    symbolName ~ "' is undeclared in the current and all enclosing scopes.");
        }
    }

    void visit(ReadNode node) {
        Symbol foundSymbol;
        string symbolName = node.getIdent().getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            if (foundSymbol.kind == SymbolKind.CONST) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Constant '" ~
                        symbolName ~ "' cannot be read into.");
            }
            if (foundSymbol.kind == SymbolKind.PROCEDURE) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Procedure '" ~
                        symbolName ~ "' cannot be read into.");
            }
            writeln("Read into variable: " ~ symbolName ~ " in scope: " ~ foundSymbol.getScopeName());
            if (foundSymbol.scopeId != currentScope.id) {
                int chainScopeId = currentScope.id;
                while (chainScopeId != foundSymbol.scopeId) {
                    writeln("Searching for " ~ foundSymbol.nick ~ " in scope: " ~ to!string(chainScopeId));
                    if ((scopes[chainScopeId].outerContext).find(foundSymbol.id).empty) {
                        scopes[chainScopeId].outerContext ~= foundSymbol.id;
                        writeln(foundSymbol.nick ~ " added to outer scope in scope: " ~ scopes[chainScopeId].nick);
                    }
                    chainScopeId = (scopes[chainScopeId].parent is null)
                                        ? foundSymbol.scopeId
                                        : scopes[chainScopeId].parent.id;
                }
            }
            node.getIdent().setSymbolId(foundSymbol.id);
        } else {
            ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Identifier '" ~
                    symbolName ~ "' is undeclared in the current and all enclosing scopes.");
        }
    }

    void visit(WriteNode node) {
        node.getExpression().accept(this);
    }

    void visit(BeginEndNode node) {
        foreach ( statement; node.getStatements()) {
            statement.accept(this);
        }
    }

    void visit(IfThenNode node) {
        node.getCondition().accept(this);
        node.getStatement().accept(this);
    }

    void visit(WhileDoNode node) {
        node.getCondition().accept(this);
        node.getStatement().accept(this);
    }

    // abstract
    // void visit(ConditionNode node) {
    //     writeln("condition");
    // }

    void visit(OddCondNode node) {
        node.getExpr().accept(this);
    }

    void visit(ComparisonNode node) {
        node.getLeft().accept(this);
        node.getRight().accept(this);
    }

    void visit(ExpressionNode node) {
        OpTermPair[] opTerms = node.getOpTerms();
        foreach (OpTermPair opTerm; opTerms) {
            opTerm.term.accept(this);
        }
    }

    void visit(TermNode node) {
        OpFactorPair[] opFactors = node.getOpFactors();
        foreach (OpFactorPair opFactor; opFactors) {
            opFactor.factor.accept(this);
        }
    }
    
    // abstract
    // void visit(FactorNode node) {
    //     writeln("factor");
    // }

    void visit(NumberNode node) {

    }

    void visit(IdentNode node) {
        Symbol foundSymbol;
        string symbolName = node.getName();
        if ((foundSymbol = lookupSymbol(symbolName)) !is null) {
            if (foundSymbol.kind == SymbolKind.PROCEDURE) {
                ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Procedure '" ~
                        symbolName ~ "' cannot be part of an expression and must be CALLed.");
            }
            if (foundSymbol.kind == SymbolKind.CONST) {
                writeln("Referenced constant: " ~ symbolName ~ " in scope: " ~ foundSymbol.getScopeName());
            }
            if (foundSymbol.kind == SymbolKind.VAR) {
                writeln("Referenced variable: " ~ symbolName ~ " in scope: " ~ foundSymbol.getScopeName());
            }
            if (foundSymbol.scopeId != currentScope.id) {
                int chainScopeId = currentScope.id;
                while (chainScopeId != foundSymbol.scopeId) {
                    writeln("Searching for " ~ foundSymbol.nick ~ " in scope: " ~ to!string(chainScopeId));
                    if ((scopes[chainScopeId].outerContext).find(foundSymbol.id).empty) {
                        scopes[chainScopeId].outerContext ~= foundSymbol.id;
                        writeln(foundSymbol.nick ~ " added to outer scope in scope: " ~ scopes[chainScopeId].nick);
                    }
                    chainScopeId = (scopes[chainScopeId].parent is null)
                                        ? foundSymbol.scopeId
                                        : scopes[chainScopeId].parent.id;
                }
            }
            node.setSymbolId(foundSymbol.id);
        } else {
            ErrorManager.addScopeError(ErrorLevel.ERROR, "Error: Identifier '" ~
                    symbolName ~ "' is undeclared in the current and all enclosing scopes.");
        }
    }

    void visit(ParenExpNode node) {
        node.getExpression().accept(this);
    }

}
