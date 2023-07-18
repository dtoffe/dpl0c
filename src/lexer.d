module lexer;

import std.ascii;
import std.stdio;
import std.string;
import error;
import token;

class Lexer {

    string[] sourceLines;
	char currentChar;
	int line;
	int column;

    this(string sourceContent) {
        sourceLines = sourceContent.splitLines(KeepTerminator.no);
        currentChar = ' ';
        line = 0;
        column = 0;
    }

    void sayHello() {
        writeln(sourceLines[0]);
    }

    void readChar() {
        if (line >= sourceLines.length) {
            currentChar = ControlChar.nul;
        } else if (column < sourceLines[line].length) {
            currentChar = sourceLines[line][column];
            column++;
        } else {
            currentChar = ControlChar.lf;
            column = 0;
            line++;
        }
        return;
    }

    char peekNext() {
        if (line >= sourceLines.length) {
            return ControlChar.nul;
        } else if (column < sourceLines[line].length) {
            return sourceLines[line][column];
        } else {
            return ControlChar.lf;
        }
    }

    Token nextToken() {
        string literal = "";
        TokenType tokType;
        Token tok;
        skipWhitespace();

        // Keywords or Identifier
        if (isLetter(currentChar)) {
            literal = readIdent();
            tokType = lookUpIdent(literal);
        } else {
            // Number
            if (isDigit(currentChar)) {
                literal = readNumber();
                tokType = TokenType.NUMBER;
            } else {
                switch (currentChar) {
                    // Punctuation
                    case '.':
                        literal ~= currentChar;
                        tokType = TokenType.PERIOD;
                        break;
                    case ',':
                        literal ~= currentChar;
                        tokType = TokenType.COMMA;
                        break;
                    case ';':
                        literal ~= currentChar;
                        tokType = TokenType.SEMICOLON;
                        break;
                    case '(':
                        literal ~= currentChar;
                        tokType = TokenType.LPAREN;
                        break;
                    case ')':
                        literal ~= currentChar;
                        tokType = TokenType.RPAREN;
                        break;
                    case ':':
                        literal ~= currentChar;
                        if (peekNext() == '=') {
                            readChar();
                            literal = literal ~+ currentChar;
                            tokType = TokenType.ASSIGN;
                            break;
                        }
                        tokType = TokenType.COLON;
                        break;
                    // Relational
                    case '=':
                        literal ~= currentChar;
                        tokType = TokenType.EQUAL;
                        break;
                    case '#':
                        literal ~= currentChar;
                        tokType = TokenType.NOTEQUAL;
                        break;
                    case '<':
                        literal ~= currentChar;
                        if (peekNext() == '=') {
                            readChar();
                            literal = literal ~+ currentChar;
                            tokType = TokenType.LESSEREQ;
                            break;
                        }
                        tokType = TokenType.LESSER;
                        break;
                    case '>':
                        literal ~= currentChar;
                        if (peekNext() == '=') {
                            readChar();
                            literal = literal ~+ currentChar;
                            tokType = TokenType.GREATEREQ;
                            break;
                        }
                        tokType = TokenType.GREATER;
                        break;
                    // Operators
                    case '+':
                        literal ~= currentChar;
                        tokType = TokenType.PLUS;
                        break;
                    case '-':
                        literal ~= currentChar;
                        tokType = TokenType.MINUS;
                        break;
                    case '*':
                        literal ~= currentChar;
                        tokType = TokenType.MULT;
                        break;
                    case '/':
                        if (peekNext() == '/') {
                            skipWhitespace();
                        } else {
                            literal ~= currentChar;
                            tokType = TokenType.DIV;
                        }
                        break;
                    case ControlChar.nul:
                        literal = "";
                        tokType = TokenType.EOF;
                        break;
                    default:
                        literal ~= currentChar;
                        tokType = TokenType.INVALID;
                        ErrorManager.addLexerError(ErrorLevel.ERROR, "Unexpected symbol: " ~ literal, line + 1, column);
                        break;
                }
            }
        }
        tok = Token(tokType, literal, line + 1, column);
        readChar();
        return tok;
    }

private:

    void skipWhitespace() {
        while (currentChar == ' ' ||
                currentChar == '\t' ||
                currentChar == '\n' ||
                currentChar == '\r' ||
                currentChar == ControlChar.lf ||
                currentChar == '/') {
            // Skip line comments starting with "//"
            if (currentChar == '/') {
                if (peekNext() == '/') {
                    while (currentChar != ControlChar.nul && currentChar != ControlChar.lf) {
                        readChar();
                    }
                } else {
                    return;
                }
            }
            readChar();
        }
    }

    bool isLetter(char ch) {
        return ('a' <= ch && ch <= 'z') ||
                ('A' <= ch && ch <= 'Z') ||
                ch == '_';
    }

    string readIdent() {
        auto col = column;
        while (isLetter(peekNext())) {
            readChar();
        }
        return sourceLines[line][col - 1 .. column];
    }

    bool isDigit(char ch) {
        return '0' <= ch && ch <= '9';
    }

    string readNumber() {
        auto col = column;
        while (isDigit(peekNext())) {
            readChar();
        }
        return sourceLines[line][col - 1 .. column];
    }

}
