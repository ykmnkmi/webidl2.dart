import 'package:test/test.dart';
import 'package:webidl2/webidl2.dart';

void main() {
  group('Tokenizer', () {
    late Tokenizer tokenizer;

    test('tokenizes empty input', () {
      tokenizer = Tokenizer('');

      List<Token> tokens = tokenizer.tokenize();
      expect(tokens, equals([Token(TokenType.eof, '', 0)]));
    });

    test('tokenizes whitespace and comments', () {
      tokenizer = Tokenizer('  \n// Comment\n/* Multi\nline */  ');

      List<Token> tokens = tokenizer.tokenize();

      expect(tokens, equals([Token(TokenType.eof, '', 32)]));
    });

    test('tokenizes keywords', () {
      tokenizer = Tokenizer(
        <String>[
          'interface',
          'dictionary',
          'enum',
          'typedef',
          'void',
          'async',
          'attribute',
          'callback',
          'const',
          'constructor',
        ].join(' '),
      );

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.interface, 'interface', 0),
          Token(TokenType.dictionary, 'dictionary', 10),
          Token(TokenType.enumKeyword, 'enum', 21),
          Token(TokenType.typedef, 'typedef', 26),
          Token(TokenType.voidKeyword, 'void', 34),
          Token(TokenType.async, 'async', 39),
          Token(TokenType.attribute, 'attribute', 45),
          Token(TokenType.callback, 'callback', 55),
          Token(TokenType.constKeyword, 'const', 64),
          Token(TokenType.constructor, 'constructor', 70),
          Token(TokenType.eof, '', 81),
        ]),
      );
    });

    test('tokenizes type names and literals', () {
      tokenizer = Tokenizer(
        <String>[
          'boolean',
          'byte',
          'double',
          'float',
          'long',
          'octet',
          'short',
          'unsigned',
          'any',
          'object',
          'symbol',
          'Promise',
        ].join(' '),
      );

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.boolean, 'boolean', 0),
          Token(TokenType.byte, 'byte', 8),
          Token(TokenType.double, 'double', 13),
          Token(TokenType.floatKeyword, 'float', 20),
          Token(TokenType.long, 'long', 26),
          Token(TokenType.octet, 'octet', 31),
          Token(TokenType.short, 'short', 37),
          Token(TokenType.unsigned, 'unsigned', 43),
          Token(TokenType.any, 'any', 52),
          Token(TokenType.object, 'object', 56),
          Token(TokenType.symbol, 'symbol', 63),
          Token(TokenType.promise, 'Promise', 70),
          Token(TokenType.eof, '', 77),
        ]),
      );
    });

    test('tokenizes string types', () {
      tokenizer = Tokenizer('ByteString DOMString USVString');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.byteString, 'ByteString', 0),
          Token(TokenType.domString, 'DOMString', 11),
          Token(TokenType.usvString, 'USVString', 21),
          Token(TokenType.eof, '', 30),
        ]),
      );
    });

    test('tokenizes identifiers', () {
      tokenizer = Tokenizer('MyInterface x-y _constructor');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.identifier, 'MyInterface', 0),
          Token(TokenType.identifier, 'x-y', 12),
          Token(TokenType.identifier, '_constructor', 16),
          Token(TokenType.eof, '', 28),
        ]),
      );
    });

    test('tokenizes numbers', () {
      tokenizer = Tokenizer('123 -456 78.90 -12.34 0xFF 077');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.integer, '123', 0),
          Token(TokenType.integer, '-456', 4),
          Token(TokenType.float, '78.90', 9),
          Token(TokenType.float, '-12.34', 15),
          Token(TokenType.integer, '0xFF', 22),
          Token(TokenType.integer, '077', 27),
          Token(TokenType.eof, '', 30),
        ]),
      );
    });

    test('tokenizes special floats', () {
      tokenizer = Tokenizer('Infinity -Infinity NaN');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.infinity, 'Infinity', 0),
          Token(TokenType.negativeInfinity, '-Infinity', 9),
          Token(TokenType.nan, 'NaN', 19),
          Token(TokenType.eof, '', 22),
        ]),
      );
    });

    test('tokenizes strings', () {
      tokenizer = Tokenizer('"hello" "world\\""');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.string, 'hello', 0),
          Token(TokenType.string, 'world"', 8),
          Token(TokenType.eof, '', 17),
        ]),
      );
    });

    test('tokenizes punctuation', () {
      tokenizer = Tokenizer('=,;:{[]}().?<>*...');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.equals, '=', 0),
          Token(TokenType.comma, ',', 1),
          Token(TokenType.semicolon, ';', 2),
          Token(TokenType.colon, ':', 3),
          Token(TokenType.leftBrace, '{', 4),
          Token(TokenType.extendedAttributeStart, '[', 5),
          Token(TokenType.extendedAttributeEnd, ']', 6),
          Token(TokenType.rightBrace, '}', 7),
          Token(TokenType.leftParen, '(', 8),
          Token(TokenType.rightParen, ')', 9),
          Token(TokenType.dot, '.', 10),
          Token(TokenType.questionMark, '?', 11),
          Token(TokenType.lessThan, '<', 12),
          Token(TokenType.greaterThan, '>', 13),
          Token(TokenType.asterisk, '*', 14),
          Token(TokenType.ellipsis, '...', 15),
          Token(TokenType.eof, '', 18),
        ]),
      );
    });

    test('tokenizes extended attributes', () {
      tokenizer = Tokenizer('[Exposed=Window,Lazy]');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.extendedAttributeStart, '[', 0),
          Token(TokenType.identifier, 'Exposed', 1),
          Token(TokenType.equals, '=', 8),
          Token(TokenType.identifier, 'Window', 9),
          Token(TokenType.comma, ',', 15),
          Token(TokenType.identifier, 'Lazy', 16),
          Token(TokenType.extendedAttributeEnd, ']', 20),
          Token(TokenType.eof, '', 21),
        ]),
      );
    });

    test('tokenizes complex WebIDL snippet', () {
      tokenizer = Tokenizer('''
[Exposed=Window]
interface MyInterface {
  Promise<long> doSomething(DOMString name, long count);
};''');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.extendedAttributeStart, '[', 0),
          Token(TokenType.identifier, 'Exposed', 1),
          Token(TokenType.equals, '=', 8),
          Token(TokenType.identifier, 'Window', 9),
          Token(TokenType.extendedAttributeEnd, ']', 15),
          Token(TokenType.interface, 'interface', 17),
          Token(TokenType.identifier, 'MyInterface', 27),
          Token(TokenType.leftBrace, '{', 39),
          Token(TokenType.promise, 'Promise', 43),
          Token(TokenType.lessThan, '<', 50),
          Token(TokenType.long, 'long', 51),
          Token(TokenType.greaterThan, '>', 55),
          Token(TokenType.identifier, 'doSomething', 57),
          Token(TokenType.leftParen, '(', 68),
          Token(TokenType.domString, 'DOMString', 69),
          Token(TokenType.identifier, 'name', 79),
          Token(TokenType.comma, ',', 83),
          Token(TokenType.long, 'long', 85),
          Token(TokenType.identifier, 'count', 90),
          Token(TokenType.rightParen, ')', 95),
          Token(TokenType.semicolon, ';', 96),
          Token(TokenType.rightBrace, '}', 98),
          Token(TokenType.semicolon, ';', 99),
          Token(TokenType.eof, '', 100),
        ]),
      );
    });

    test('handles invalid characters', () {
      tokenizer = Tokenizer('hello @ world');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.identifier, 'hello', 0),
          Token(TokenType.invalid, '@', 6),
          Token(TokenType.identifier, 'world', 8),
          Token(TokenType.eof, '', 13),
        ]),
      );
    });

    test('handles unterminated string', () {
      tokenizer = Tokenizer('"hello');

      List<Token> tokens = tokenizer.tokenize();

      expect(
        tokens,
        equals([
          Token(TokenType.invalid, 'hello', 0),
          Token(TokenType.eof, '', 6),
        ]),
      );
    });
  });
}
