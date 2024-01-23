/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module symtable;

import llvm;
import std.container.array;
import std.stdio;
import error;

/** 
 * I have read two distinct approaches regarding Symbol Tables:
 * 
 * - Build it to check scopes and types and then destroy as you backtrack the scopes
 * - Build it to check scopes and types and then keep the whole Symbol Table to be used
 *      by the later stages (optimizations and code generation)
 * 
 * I chose to follow the second approach because I will need it when doing code
 *      generation to reference identifiers in enclosing scopes and it makes sense
 *      to keep it if I have it built already
 */

enum SymbolKind {
	CONST,
    VAR,
    PROCEDURE
}

enum SymbolType {
    INTEGER
}

static int nextId = 0;

class Symbol {

    int id;
    string name;
    string scopeName;
    SymbolKind kind;
    SymbolType type;
    int value;  // This is the value for consts (and maybe vars?), and zero for procedures
    LLVMValueRef valueRef;

    this(string name, SymbolKind kind, SymbolType type, int value) {
        this.id = nextId++;
        this.name = name;
        this.scopeName = currentScope.name;
        this.kind = kind;
        this.type = type;
        this.value = value;
    }

    public LLVMValueRef getValueRef() {
        return this.valueRef;
    }

    public void setValueRef(LLVMValueRef valueRef) {
        this.valueRef = valueRef;
    }

}

// A struct can not contain a field of the same struct type, that's why a class is used
class Scope {
    string name;
    Symbol[string] symbolTable;
    Scope parent;
}

static Scope mainScope;

static Scope currentScope;

static Scope[string] scopes;

static Symbol[int] symbols;

static void createScope(string name) {
    if (mainScope is null) {
        mainScope = new Scope();
        mainScope.name = name;
        mainScope.parent = null;
        mainScope.symbolTable = new Symbol[string];
        currentScope = mainScope;
        scopes[mainScope.name] = mainScope;
    } else {
        Scope newScope = new Scope();
        newScope.name = currentScope.name ~ "_" ~ name;
        newScope.parent = currentScope;
        newScope.symbolTable = new Symbol[string];
        currentScope = newScope;
        scopes[newScope.name] = newScope;
    }
    writeln("Created new scope: " ~ currentScope.name);
}

static void enterScope(string name) {
    string newScopeName;
    if (currentScope is null) {
        newScopeName = name;
    } else {
        newScopeName = currentScope.name ~ "_" ~ name;
    }
    currentScope = scopes[newScopeName];
    writeln("Entered scope: " ~ currentScope.name);
}

static void exitScope() {
    writeln("Exiting scope: " ~ currentScope.name);
    currentScope = currentScope.parent;
}

static bool createSymbol(string name, SymbolKind kind, SymbolType type, int value) {
    Symbol entry = new Symbol(name, kind, type, value);
    if (!(name in currentScope.symbolTable)) {
        Symbol foundSymbol;
        if ((foundSymbol = lookupSymbol(name)) !is null) {
            ErrorManager.addScopeError(ErrorLevel.WARNING, "Warning: Local Identifier '" ~
                    name ~ "' hides another identifier declared in scope: " ~ foundSymbol.scopeName);
        }
        currentScope.symbolTable[name] = entry;
        symbols[entry.id] = entry;
        writeln("Created new symbol: " ~ name ~ " in scope: " ~ currentScope.name);
        return true;
    } else {
        ErrorManager.addScopeError(ErrorLevel.ERROR, "Warning: Identifier '" ~
                name ~ "' already declared in the current scope.");
        writeln("New symbol: '" ~ name ~ "' already declared in scope: " ~ currentScope.name);
        return false;
    }
}

static Symbol lookupSymbol(string name) {
    Scope searchScope = currentScope;
    while (searchScope !is null) {
        if (name in searchScope.symbolTable) {
            return (searchScope.symbolTable[name]);
        } else {
            searchScope = searchScope.parent;
        }
    }
    return null;
}
