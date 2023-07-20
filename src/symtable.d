/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module symtable;

import std.container.array;
import std.stdio;

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

struct SymbolEntry {
    string name;
    SymbolKind kind;
    SymbolType type;
}

class Scope {

    string name;
    
    SymbolEntry[string] symbolTable;
    
    Scope parent;

}

static Scope mainScope;

static Scope currentScope;

static Scope[string] scopes;

static void createScope(string name) {
    if (mainScope is null) {
        mainScope = new Scope();
        mainScope.name = name;
        mainScope.parent = null;
        mainScope.symbolTable = new SymbolEntry[string];
        currentScope = mainScope;
        scopes[mainScope.name] = mainScope;
    } else {
        Scope newScope = new Scope();
        newScope.name = currentScope.name ~ "_" ~ name;
        newScope.parent = currentScope;
        newScope.symbolTable = new SymbolEntry[string];
        currentScope = newScope;
        scopes[newScope.name] = newScope;
    }
}

static void enterScope(string name) {
    string newScopeName = currentScope.name ~ "_" ~ name;
    currentScope = scopes[newScopeName];
}

static void exitScope() {
    currentScope = currentScope.parent;
}

static bool createSymbol(string name, SymbolKind kind, SymbolType type) {
    SymbolEntry entry = SymbolEntry(name, kind, type);
    if (!(name in currentScope.symbolTable)) {
        if (lookupSymbol(name)) {
            writeln("Warning: Local Identifier '", name, "' hides another identifier declared in an enclosing scope.");
        }
        currentScope.symbolTable[name] = entry;
        return true;
    } else {
        writeln("Error: Identifier '", name, "' already declared in the current scope.");
        return false;
    }
}

static bool lookupSymbol(string name) {
    Scope searchScope = currentScope;
    while (searchScope !is null) {
        if (name in searchScope.symbolTable) {
            return true;
        } else {
            searchScope = searchScope.parent;
        }
    }
    return false;
}
