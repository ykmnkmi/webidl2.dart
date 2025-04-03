import 'package:webidl2/src/source_position.dart';
import 'package:webidl2/src/token_type.dart';

/// Token class representing a lexical token.
class Token {
  const Token(this.type, this.lexeme, this.start, this.end);

  final TokenType type;

  final String lexeme;

  final SourcePosition start;

  final SourcePosition end;

  @override
  String toString() {
    return '$type: "$lexeme" at $start-$end';
  }
}
