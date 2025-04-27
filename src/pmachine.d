/* The MIT License (MIT)
 * Copyright (c) 2023 Alejandro Daniel Toffetti
 * You can find the complete text of the license in the file LICENSE at the root of this project.
 */
module pmachine;

import std.conv;
import std.stdio;

/*
 Example p-code machine (source: https://en.wikipedia.org/wiki/P-code_machine#Example_machine)

 Niklaus Wirth specified a simple p-code machine in the 1976 book Algorithms + Data Structures = Programs.
 The machine had 3 registers - a program counter p, a base register b, and a top-of-stack register t.
 There were 8 instructions:

    lit 0, a : load constant a
    opr 0, a : execute operation a (13 operations: RETURN, 5 math functions, and 7 comparison functions)
    lod l, a : load variable l, a
    sto l, a : store variable l, a
    cal l, a : call procedure a at level l
    int 0, a : increment t-register by a
    jmp 0, a : jump to a
    jpc 0, a : jump conditional to a

 This machine was used to run Wirth's PL/0, a Pascal subset compiler used to teach compiler development.
 */

const VERSION = "0.0.1";

const stacksize = 500;
const max_address = 2047;      // {maximum address}
const max_level = 3;           // {maximum depth of block nesting}
const max_instruction = 2000;  // {size of code array} (200 in the original Wirth code)

enum Opcode {lit, opr, lod, sto, cal, inc /* See comment below */, jmp, jpc}
/* 'int' in the original code, since it is short for "increment t-register",
    but 'int' is a reserved word in D, so I use 'inc' instead. */

struct Instruction {
    opcode func;
    short levl;
    short addr;
}

int program_register;
int base_register;
int topstack_register;
Instruction instruction_register;
int[stacksize] stack;
Instruction[] code; // [max_instruction]

int base(int level) {
    int newbase;
    newbase = base_register;
    while (level > 0) {
      newbase = stack[newbase];
      level = level - 1;
    }
    return newbase;
}

int ord(bool b) {
    return b ? 1 : 0;
}

bool odd(int x) {
    return x % 2 != 0;
}

void interpret() {
    writeln("Starting PL/0 interpreter...");
    topstack_register = 0;
    base_register = 1;
    program_register = 0;
    stack[1] = 0;
    stack[2] = 0;
    stack[3] = 0;
    do {
        instruction_register = code[program_register];
        program_register = program_register + 1;
        switch (instruction_register.func) {
            case Opcode.lit: { // load constant
                topstack_register = topstack_register + 1;
                stack[topstack_register] = instruction_register.addr; break; }
            case Opcode.opr: { // execute operation
                switch (instruction_register.addr) {
                    case 0: { // return
                        topstack_register = base_register - 1;
                        program_register = stack[topstack_register + 3];
                        base_register = stack[topstack_register + 2];
                        break;}
                    case 1: { // unary minus
                        stack[topstack_register] = -stack[topstack_register];
                        break; }
                    case 2: { // addition
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = stack[topstack_register] + stack[topstack_register + 1];
                        break; }
                    case 3: { // subtraction
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = stack[topstack_register] - stack[topstack_register + 1];
                        break; }
                    case 4: { // multiplication
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = stack[topstack_register] * stack[topstack_register + 1];
                        break; }
                    case 5: { // division
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = stack[topstack_register] / stack[topstack_register + 1];
                        break; }
                    case 6: { // odd
                        stack[topstack_register] = ord(odd(stack[topstack_register]));
                        break; }
                    case 8: { // equal
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] == stack[topstack_register + 1]);
                        break; }
                    case 9: { // not equal
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] != stack[topstack_register + 1]);
                        break; }
                    case 10: { // less than
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] < stack[topstack_register + 1]);
                        break; }
                    case 11: { // greater than or equal
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] >= stack[topstack_register + 1]);
                        break; }
                    case 12: { // greater than  
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] > stack[topstack_register + 1]);
                        break; }
                    case 13: { // less than or equal
                        topstack_register = topstack_register - 1;
                        stack[topstack_register] = ord(stack[topstack_register] <= stack[topstack_register + 1]);
                        break; }
                    default: {
                        writeln("unknown operation code: ", instruction_register.addr);
                        break;
                    }
                }
                break; }
            case Opcode.lod: { // load variable
                topstack_register = topstack_register + 1;
                stack[topstack_register] = stack[base(instruction_register.levl) + instruction_register.addr]; break; }
            case Opcode.sto: { // store variable
                stack[base(instruction_register.levl) + instruction_register.addr] = stack[topstack_register];
                writeln(stack[topstack_register]);
                topstack_register = topstack_register - 1; break; }
            case Opcode.cal: { // call procedure
                stack[topstack_register + 1] = base(instruction_register.levl);
                stack[topstack_register + 2] = base_register;
                stack[topstack_register + 3] = program_register;
                base_register = topstack_register + 1;
                program_register = instruction_register.addr; break; }
            case Opcode.inc: { // increment t-register
                topstack_register = topstack_register + instruction_register.addr; break; }
            case Opcode.jmp: { // jump
                program_register = instruction_register.addr; break; }
            case Opcode.jpc: { // jump conditional
                if (stack[topstack_register] == 0) {
                    program_register = instruction_register.addr;
                }
                topstack_register = topstack_register - 1; break; }
            default:
                writeln("unknown instruction");
                break;
        }
    } while (program_register > 0);
    writeln("...ending PL/0 interpreter");
}

void readPCode(const string pcodeFileName)
{
    File pcodeFile = File(pcodeFileName, "r");
    int i = 0;
    opcode f;
    short l;
    short a;
    while (!pcodeFile.eof())
    {
        string opcodeStr;
        pcodeFile.readf("%s %s %s", &opcodeStr, &l, &a);
        f = to!opcode(opcodeStr);
        if (f < Opcode.lit || f > Opcode.jpc)
        {
            writeln("Error: Invalid opcode at position ", i);
            return;
        }
        if (l < 0 || l > max_level)
        {
            writeln("Error: Invalid level at position ", i);
            return;
        }
        if (a < 0 || a > max_address)
        {
            writeln("Error: Invalid address at position ", i);
            return;
        }
        code ~= Instruction(f, l, a);
        i++;
        if (i > max_instruction)
        {
            writeln("Error: Too many instructions");
            return;
        }
    }
    pcodeFile.close();
}

void main(string[] args) {

    writefln("\nThe P-Code Machine v. %s", VERSION);

    if (args.length < 1) {
        writeln("Usage: pmachine <pcodeFileName>");
        writeln("Example: pmachine pcode.p");
        writeln();
        return;
    }

    string pcodeFileName = args[0];
    writefln("\nLoading program from file %s", pcodeFileName);
    readPCode(pcodeFileName);
    writefln("\nStarting P Machine interpreter");
    interpret();

}
