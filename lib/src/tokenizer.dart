import 'package:webidl2/src/source_position.dart';
import 'package:webidl2/src/token.dart';
import 'package:webidl2/src/token_type.dart';

/// Tokenizer for WebIDL.
class Tokenizer {
  Tokenizer(this.source);

  final String source;

  int position = 0;

  int line = 1;

  int column = 1;

  bool get isAtEnd {
    return position >= source.length;
  }

  String get currentChar {
    return isAtEnd ? '' : source[position];
  }

  String peek([int offset = 0]) {
    int position = this.position + offset;
    return (position >= source.length) ? '' : source[position];
  }

  String advance() {
    String char = currentChar;
    position++;

    if (char == '\n') {
      line++;
      column = 1;
    } else {
      column++;
    }

    return char;
  }

  bool match(String expected) {
    if (isAtEnd || currentChar != expected) {
      return false;
    }

    advance();
    return true;
  }

  SourcePosition currentPosition() {
    return SourcePosition(position, line, column);
  }

  /// Tokenize the entire source into a list of tokens.
  List<Token> tokenize() {
    List<Token> tokens = <Token>[];

    while (!isAtEnd) {
      tokens.add(nextToken());
    }

    SourcePosition position = currentPosition();
    tokens.add(Token(TokenType.eof, '', position, position));
    return tokens;
  }

  /// Get the next token from the source.
  Token nextToken() {
    skipWhitespace();

    SourcePosition startPosition = currentPosition();

    if (isAtEnd) {
      return Token(TokenType.eof, '', startPosition, startPosition);
    }

    String char = currentChar;

    // Comments
    if (char == '/' && peek(1) == '/') {
      return scanLineComment(startPosition);
    }

    if (char == '/' && peek(1) == '*') {
      if (peek(2) == '*') {
        return scanDocComment(startPosition);
      }

      return scanBlockComment(startPosition);
    }

    // Punctuation
    if (char == '{') {
      return makeToken(TokenType.leftBrace, startPosition);
    }

    if (char == '}') {
      return makeToken(TokenType.rightBrace, startPosition);
    }

    if (char == '(') {
      return makeToken(TokenType.leftParen, startPosition);
    }

    if (char == ')') {
      return makeToken(TokenType.rightParen, startPosition);
    }

    if (char == '[') {
      return makeToken(TokenType.leftBracket, startPosition);
    }

    if (char == ']') {
      return makeToken(TokenType.rightBracket, startPosition);
    }

    if (char == ';') {
      return makeToken(TokenType.semiColon, startPosition);
    }

    if (char == ':') {
      return makeToken(TokenType.colon, startPosition);
    }

    if (char == ',') {
      return makeToken(TokenType.comma, startPosition);
    }

    if (char == '?') {
      return makeToken(TokenType.question, startPosition);
    }

    if (char == '=') {
      return makeToken(TokenType.equals, startPosition);
    }

    if (char == '<') {
      return makeToken(TokenType.lessThan, startPosition);
    }

    if (char == '>') {
      return makeToken(TokenType.greaterThan, startPosition);
    }

    if (char == '|') {
      return makeToken(TokenType.or, startPosition);
    }

    // Ellipsis
    if (char == '.' && peek(1) == '.' && peek(2) == '.') {
      advance();
      advance();
      advance();
      return Token(TokenType.ellipsis, '...', startPosition, currentPosition());
    }

    // Numbers
    if (isDigit(char)) {
      return scanNumber(startPosition);
    }

    // String literals
    if (char == '"' || char == "'") {
      return scanString(char, startPosition);
    }

    // Identifiers and keywords
    if (isAlpha(char) || char == '_') {
      return scanIdentifier(startPosition);
    }

    // Unknown character
    advance();
    return Token(TokenType.error, char, startPosition, currentPosition());
  }

  Token makeToken(TokenType type, SourcePosition startPosition) {
    String char = advance();
    return Token(type, char, startPosition, currentPosition());
  }

  void skipWhitespace() {
    while (!isAtEnd) {
      String char = currentChar;

      if (char == ' ' || char == '\t' || char == '\r' || char == '\n') {
        advance();
      } else {
        break;
      }
    }
  }

  Token scanLineComment(SourcePosition startPosition) {
    // Skip the "//"
    advance();
    advance();

    String text = '';

    while (!isAtEnd && currentChar != '\n') {
      text += advance();
    }

    return Token(
      TokenType.comment,
      '//$text',
      startPosition,
      currentPosition(),
    );
  }

  Token scanBlockComment(SourcePosition startPosition) {
    // Skip the "/*"
    advance();
    advance();

    String text = '';

    while (!isAtEnd && !(currentChar == '*' && peek(1) == '/')) {
      text += advance();
    }

    if (!isAtEnd) {
      // Skip the "*/"
      advance();
      advance();
    }

    return Token(
      TokenType.comment,
      '/*$text*/',
      startPosition,
      currentPosition(),
    );
  }

  Token scanDocComment(SourcePosition startPosition) {
    // Skip the "/**"
    advance();
    advance();
    advance();

    String text = '';

    while (!isAtEnd && !(currentChar == '*' && peek(1) == '/')) {
      text += advance();
    }

    if (!isAtEnd) {
      // Skip the "*/"
      advance();
      advance();
    }

    return Token(
      TokenType.documentComment,
      '/**$text*/',
      startPosition,
      currentPosition(),
    );
  }

  Token scanNumber(SourcePosition startPosition) {
    String number = '';
    bool isFloat = false;

    // Consume integer part
    while (!isAtEnd && isDigit(currentChar)) {
      number += advance();
    }

    // Look for decimal part
    if (currentChar == '.' && isDigit(peek(1))) {
      isFloat = true;
      number += advance(); // Consume the '.'

      // Consume fractional part
      while (!isAtEnd && isDigit(currentChar)) {
        number += advance();
      }
    }

    // Look for exponent part
    if ((currentChar == 'e' || currentChar == 'E') &&
        (isDigit(peek(1)) ||
            ((peek(1) == '+' || peek(1) == '-') && isDigit(peek(2))))) {
      isFloat = true;
      number += advance(); // Consume 'e' or 'E'

      if (currentChar == '+' || currentChar == '-') {
        number += advance();
      }

      // Consume exponent
      while (!isAtEnd && isDigit(currentChar)) {
        number += advance();
      }
    }

    TokenType type = isFloat ? TokenType.float : TokenType.integer;
    return Token(type, number, startPosition, currentPosition());
  }

  Token scanString(String quote, SourcePosition startPosition) {
    String value = '';

    // Skip the opening quote
    advance();

    while (!isAtEnd && currentChar != quote) {
      if (currentChar == '\\') {
        advance(); // Skip the backslash

        // Handle escape sequences
        if (isAtEnd) {
          break;
        }

        switch (currentChar) {
          case 'n':
            value += '\n';
            break;

          case 'r':
            value += '\r';
            break;

          case 't':
            value += '\t';
            break;

          case '\\':
            value += '\\';
            break;

          case '"':
            value += '"';
            break;

          case "'":
            value += "'";
            break;

          default:
            value += currentChar;
        }

        advance();
      } else {
        value += advance();
      }
    }

    // Skip the closing quote if not at end
    if (!isAtEnd) {
      advance();
    }

    return Token(TokenType.string, value, startPosition, currentPosition());
  }

  Token scanIdentifier(SourcePosition startPosition) {
    String identifier = '';

    while (!isAtEnd && (isAlphaNumeric(currentChar) || currentChar == '_')) {
      identifier += advance();
    }

    // Check for keywords
    TokenType type = getKeywordType(identifier);
    return Token(type, identifier, startPosition, currentPosition());
  }
}

TokenType getKeywordType(String identifier) {
  switch (identifier) {
    case 'interface':
      return TokenType.interfaceKeyword;

    case 'partial':
      return TokenType.partialKeyword;

    case 'dictionary':
      return TokenType.dictionaryKeyword;

    case 'enum':
      return TokenType.enumKeyword;

    case 'callback':
      return TokenType.callbackKeyword;

    case 'typedef':
      return TokenType.typeDefKeyword;

    case 'implements':
      return TokenType.implementsKeyword;

    case 'const':
      return TokenType.constKeyword;

    case 'null':
      return TokenType.nullKeyword;

    case 'true':
      return TokenType.trueKeyword;

    case 'false':
      return TokenType.falseKeyword;

    case 'static':
      return TokenType.staticKeyword;

    case 'stringifier':
      return TokenType.stringifierKeyword;

    case 'attribute':
      return TokenType.attributeKeyword;

    case 'readonly':
      return TokenType.readOnlyKeyword;

    case 'inherit':
      return TokenType.inheritKeyword;

    case 'getter':
      return TokenType.getterKeyword;

    case 'setter':
      return TokenType.setterKeyword;

    case 'deleter':
      return TokenType.deleterKeyword;

    case 'required':
      return TokenType.requiredKeyword;

    case 'optional':
      return TokenType.optionalKeyword;

    // Type keywords
    case 'unsigned':
      return TokenType.unsignedType;

    case 'short':
      return TokenType.shortType;

    case 'long':
      return TokenType.longType;

    case 'float':
      return TokenType.floatType;

    case 'double':
      return TokenType.doubleType;

    case 'boolean':
      return TokenType.booleanType;

    case 'byte':
      return TokenType.byteType;

    case 'octet':
      return TokenType.octetType;

    case 'void':
      return TokenType.voidType;

    case 'any':
      return TokenType.anyType;

    case 'object':
      return TokenType.objectType;

    case 'symbol':
      return TokenType.symbolType;

    case 'Promise':
      return TokenType.promiseType;

    case 'sequence':
      return TokenType.sequenceType;

    case 'record':
      return TokenType.recordType;

    default:
      return TokenType.identifier;
  }
}

bool isDigit(String char) {
  return char.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
      char.codeUnitAt(0) <= '9'.codeUnitAt(0);
}

bool isAlpha(String char) {
  return (char.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
          char.codeUnitAt(0) <= 'z'.codeUnitAt(0)) ||
      (char.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
          char.codeUnitAt(0) <= 'Z'.codeUnitAt(0));
}

bool isAlphaNumeric(String char) {
  return isAlpha(char) || isDigit(char);
}
