import 'dart:convert';

import 'package:webidl2/webidl2.dart';

final class Tokenizer {
  factory Tokenizer(String input) {
    return Tokenizer.fromBytes(const Utf8Encoder().convert(input));
  }

  Tokenizer.fromBytes(this.input) : _length = input.length;

  final List<int> input;

  final int _length;

  int _position = 0;

  List<Token> tokenize() {
    List<Token> tokens = <Token>[];

    while (_position < _length) {
      Token? token = _nextToken();

      if (token == null) {
        break;
      }

      tokens.add(token);
    }

    tokens.add(Token(TokenType.eof, '', _position));
    return tokens;
  }

  Token? _nextToken() {
    _skipWhitespaceAndComments();

    if (_position >= _length) {
      return null;
    }

    int start = _position;
    int byte = input[_position];

    switch (byte) {
      case 0x3D: // '='
        _position++;
        return Token(TokenType.equals, '=', start);

      case 0x2C: // ','
        _position++;
        return Token(TokenType.comma, ',', start);

      case 0x3B: // ';'
        _position++;
        return Token(TokenType.semicolon, ';', start);

      case 0x3A: // ':'
        _position++;
        return Token(TokenType.colon, ':', start);

      case 0x7B: // '{'
        _position++;
        return Token(TokenType.leftBrace, '{', start);

      case 0x7D: // '}'
        _position++;
        return Token(TokenType.rightBrace, '}', start);

      case 0x5B: // '['
        _position++;
        return Token(TokenType.extendedAttributeStart, '[', start);

      case 0x5D: // ']'
        _position++;
        return Token(TokenType.extendedAttributeEnd, ']', start);

      case 0x28: // '('
        _position++;
        return Token(TokenType.leftParen, '(', start);

      case 0x29: // ')'
        _position++;
        return Token(TokenType.rightParen, ')', start);

      case 0x2E: // '.'
        if (_position + 2 < _length &&
            input[_position + 1] == 0x2E &&
            input[_position + 2] == 0x2E) {
          _position += 3;
          return Token(TokenType.ellipsis, '...', start);
        }

        _position++;
        return Token(TokenType.dot, '.', start);

      case 0x3F: // '?'
        _position++;
        return Token(TokenType.questionMark, '?', start);

      case 0x3C: // '<'
        _position++;
        return Token(TokenType.lessThan, '<', start);

      case 0x3E: // '>'
        _position++;
        return Token(TokenType.greaterThan, '>', start);

      case 0x2A: // '*'
        _position++;
        return Token(TokenType.asterisk, '*', start);
    }

    if (_isDigit(byte) ||
        byte == /* '-' */ 0x2D ||
        byte == /* 'I' */ 0x49 ||
        byte == /* 'N' */ 0x4E) {
      return _parseNumberOrSpecial(start);
    }

    if (byte == /* '"' */ 0x22) {
      return _parseString(start);
    }

    if (_isIdentifierStart(byte)) {
      return _parseIdentifierOrKeyword(start);
    }

    _position++;
    return Token(TokenType.invalid, String.fromCharCode(byte), start);
  }

  void _skipWhitespaceAndComments() {
    while (_position < _length) {
      int byte = input[_position];

      if (_isWhitespace(byte)) {
        _position++;
      } else if (byte == /* '/' */ 0x2F &&
          _position + 1 < _length &&
          input[_position + 1] == 0x2F) {
        _position += 2;

        while (_position < _length && input[_position] != /* '\n' */ 0x0A) {
          _position++;
        }
      } else if (byte == /* '/' */ 0x2F &&
          _position + 1 < _length &&
          input[_position + 1] == /* '*' */ 0x2A) {
        _position += 2;

        while (_position + 1 < _length &&
            !(input[_position] == 0x2A && input[_position + 1] == 0x2F)) {
          _position++;
        }

        _position += 2;
      } else {
        break;
      }
    }
  }

  Token _parseNumberOrSpecial(int start) {
    List<int> bytes = <int>[];
    bool hasMinus = false;

    if (_position < _length && input[_position] == /* '-' */ 0x2D) {
      bytes.add(0x2D);
      hasMinus = true;
      _position++;
    }

    if (_position < _length && input[_position] == /* 'I' */ 0x49) {
      bytes.add(0x49);
      _position++;

      if (_position + 6 < _length &&
          input[_position] == /* 'n' */ 0x6E &&
          input[_position + 1] == /* 'f' */ 0x66 &&
          input[_position + 2] == /* 'i' */ 0x69 &&
          input[_position + 3] == /* 'n' */ 0x6E &&
          input[_position + 4] == /* 'i' */ 0x69 &&
          input[_position + 5] == /* 't' */ 0x74 &&
          input[_position + 6] == /* 'y' */ 0x79) {
        bytes.addAll(const <int>[0x6E, 0x66, 0x69, 0x6E, 0x69, 0x74, 0x79]);
        _position += 7;

        String value = String.fromCharCodes(bytes);

        return Token(
          hasMinus ? TokenType.negativeInfinity : TokenType.infinity,
          value,
          start,
        );
      }
    }

    if (_position < _length &&
        input[_position] == /* 'N' */ 0x4E &&
        _position + 2 < _length &&
        input[_position + 1] == /* 'a' */ 0x61 &&
        input[_position + 2] == /* 'N' */ 0x4E) {
      bytes = <int>[0x4E, 0x61, 0x4E]; // Reset bytes to avoid including minus
      _position += 3;
      return Token(TokenType.nan, 'NaN', start);
    }

    bool isFloat = false;
    bool isHex = false;
    bool isOctal = false;

    if (_position < input.length && input[_position] == /* '0' */ 0x30) {
      bytes.add(0x30);
      _position++;

      if (_position < input.length &&
          (input[_position] == /* 'X' */ 0x58 ||
              input[_position] == /* 'x' */ 0x78)) {
        isHex = true;
        bytes.add(input[_position]);
        _position++;
      } else if (_position < input.length &&
          _isDigit(input[_position]) &&
          input[_position] <= /* '7' */ 0x37) {
        isOctal = true;
      }
    }

    if (isHex) {
      while (_position < input.length && _isHexDigit(input[_position])) {
        bytes.add(input[_position]);
        _position++;
      }
    } else if (isOctal) {
      while (_position < input.length &&
          _isDigit(input[_position]) &&
          input[_position] <= /* '7' */ 0x37) {
        bytes.add(input[_position]);
        _position++;
      }
    } else {
      while (_position < input.length && _isDigit(input[_position])) {
        bytes.add(input[_position]);
        _position++;
      }
      if (_position < input.length && input[_position] == /* '.' */ 0x2E) {
        isFloat = true;
        bytes.add(0x2E);
        _position++;

        while (_position < input.length && _isDigit(input[_position])) {
          bytes.add(input[_position]);
          _position++;
        }
      }
      if (_position < input.length &&
          (input[_position] == /* 'E' */ 0x45 ||
              input[_position] == /* 'e' */ 0x65)) {
        isFloat = true;
        bytes.add(input[_position]);
        _position++;

        if (_position < input.length &&
            (input[_position] == /* '+' */ 0x2B ||
                input[_position] == /* '-' */ 0x2D)) {
          bytes.add(input[_position]);
          _position++;
        }

        while (_position < input.length && _isDigit(input[_position])) {
          bytes.add(input[_position]);
          _position++;
        }
      }
    }

    String value = String.fromCharCodes(bytes);

    if (value == '-' || value == '-.') {
      return Token(TokenType.invalid, value, start);
    }

    return Token(isFloat ? TokenType.float : TokenType.integer, value, start);
  }

  Token _parseString(int start) {
    List<int> bytes = <int>[];
    _position++;

    while (_position < input.length && input[_position] != /* '"' */ 0x22) {
      if (_position + 1 < input.length &&
          input[_position] == /* '\' */ 0x5C &&
          input[_position + 1] == 0x22) {
        bytes.add(0x22);
        _position += 2;
        continue;
      }

      bytes.add(input[_position]);
      _position++;
    }

    if (_position >= input.length) {
      return Token(TokenType.invalid, String.fromCharCodes(bytes), start);
    }

    _position++;
    return Token(TokenType.string, String.fromCharCodes(bytes), start);
  }

  Token _parseIdentifierOrKeyword(int start) {
    List<int> bytes = <int>[];

    while (_position < input.length && _isIdentifierChar(input[_position])) {
      bytes.add(input[_position]);
      _position++;
    }

    String value = String.fromCharCodes(bytes);

    switch (value) {
      case 'interface':
        return Token(TokenType.interface, value, start);

      case 'dictionary':
        return Token(TokenType.dictionary, value, start);

      case 'enum':
        return Token(TokenType.enumKeyword, value, start);

      case 'typedef':
        return Token(TokenType.typedef, value, start);

      case 'void':
        return Token(TokenType.voidKeyword, value, start);

      case 'async':
        return Token(TokenType.async, value, start);

      case 'attribute':
        return Token(TokenType.attribute, value, start);

      case 'callback':
        return Token(TokenType.callback, value, start);

      case 'const':
        return Token(TokenType.constKeyword, value, start);

      case 'constructor':
        return Token(TokenType.constructor, value, start);

      case 'deleter':
        return Token(TokenType.deleter, value, start);

      case 'getter':
        return Token(TokenType.getter, value, start);

      case 'includes':
        return Token(TokenType.includes, value, start);

      case 'inherit':
        return Token(TokenType.inherit, value, start);

      case 'iterable':
        return Token(TokenType.iterable, value, start);

      case 'maplike':
        return Token(TokenType.maplike, value, start);

      case 'namespace':
        return Token(TokenType.namespace, value, start);

      case 'partial':
        return Token(TokenType.partial, value, start);

      case 'required':
        return Token(TokenType.required, value, start);

      case 'setlike':
        return Token(TokenType.setlike, value, start);

      case 'setter':
        return Token(TokenType.setter, value, start);

      case 'static':
        return Token(TokenType.staticKeyword, value, start);

      case 'stringifier':
        return Token(TokenType.stringifier, value, start);

      case 'unrestricted':
        return Token(TokenType.unrestricted, value, start);

      case 'mixin':
        return Token(TokenType.mixin, value, start);

      case 'optional':
        return Token(TokenType.optional, value, start);

      case 'or':
        return Token(TokenType.or, value, start);

      case 'readonly':
        return Token(TokenType.readonly, value, start);

      case 'true':
        return Token(TokenType.booleanTrue, value, start);

      case 'false':
        return Token(TokenType.booleanFalse, value, start);

      case 'null':
        return Token(TokenType.nullLiteral, value, start);

      case 'undefined':
        return Token(TokenType.undefined, value, start);

      case 'bigint':
        return Token(TokenType.bigint, value, start);

      case 'boolean':
        return Token(TokenType.boolean, value, start);

      case 'byte':
        return Token(TokenType.byte, value, start);

      case 'double':
        return Token(TokenType.double, value, start);

      case 'float':
        return Token(TokenType.floatKeyword, value, start);

      case 'long':
        return Token(TokenType.long, value, start);

      case 'octet':
        return Token(TokenType.octet, value, start);

      case 'short':
        return Token(TokenType.short, value, start);

      case 'unsigned':
        return Token(TokenType.unsigned, value, start);

      case 'any':
        return Token(TokenType.any, value, start);

      case 'object':
        return Token(TokenType.object, value, start);

      case 'symbol':
        return Token(TokenType.symbol, value, start);

      case 'ArrayBuffer':
        return Token(TokenType.arrayBuffer, value, start);

      case 'SharedArrayBuffer':
        return Token(TokenType.sharedArrayBuffer, value, start);

      case 'DataView':
        return Token(TokenType.dataView, value, start);

      case 'Int8Array':
        return Token(TokenType.int8Array, value, start);

      case 'Int16Array':
        return Token(TokenType.int16Array, value, start);

      case 'Int32Array':
        return Token(TokenType.int32Array, value, start);

      case 'Uint8Array':
        return Token(TokenType.uint8Array, value, start);

      case 'Uint16Array':
        return Token(TokenType.uint16Array, value, start);

      case 'Uint32Array':
        return Token(TokenType.uint32Array, value, start);

      case 'Uint8ClampedArray':
        return Token(TokenType.uint8ClampedArray, value, start);

      case 'BigInt64Array':
        return Token(TokenType.bigInt64Array, value, start);

      case 'BigUint64Array':
        return Token(TokenType.bigUint64Array, value, start);

      case 'Float16Array':
        return Token(TokenType.float16Array, value, start);

      case 'Float32Array':
        return Token(TokenType.float32Array, value, start);

      case 'Float64Array':
        return Token(TokenType.float64Array, value, start);

      case 'FrozenArray':
        return Token(TokenType.frozenArray, value, start);

      case 'ObservableArray':
        return Token(TokenType.observableArray, value, start);

      case 'Promise':
        return Token(TokenType.promise, value, start);

      case 'record':
        return Token(TokenType.record, value, start);

      case 'sequence':
        return Token(TokenType.sequence, value, start);

      case 'ByteString':
        return Token(TokenType.byteString, value, start);

      case 'DOMString':
        return Token(TokenType.domString, value, start);

      case 'USVString':
        return Token(TokenType.usvString, value, start);

      default:
        return Token(TokenType.identifier, value, start);
    }
  }

  bool _isWhitespace(int byte) {
    return byte == /* ' ' */ 0x20 ||
        byte == /* '\t' */ 0x09 ||
        byte == /* '\n' */ 0x0A ||
        byte == 0x0D;
  }

  bool _isDigit(int byte) {
    return byte >= 0x30 /* '0' */ && byte <= 0x39;
  }

  bool _isHexDigit(int byte) {
    return _isDigit(byte) ||
        (byte >= 0x41 /* 'A' */ && byte <= 0x46 /* 'F' */ ) ||
        (byte >= 0x61 /* 'a' */ && byte <= 0x66 /* 'f' */ );
  }

  bool _isIdentifierStart(int byte) {
    return (byte >= 0x41 /* 'A' */ && byte <= 0x5A /* 'Z' */ ) ||
        (byte >= 0x61 /* 'a' */ && byte <= 0x7A /* 'z' */ ) ||
        byte == 0x5F /* '_' */ ||
        byte == 0x2D /* '-' */;
  }

  bool _isIdentifierChar(int byte) {
    return _isIdentifierStart(byte) || _isDigit(byte);
  }
}
