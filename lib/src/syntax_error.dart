import 'package:webidl2/src/token.dart';

/// Syntax error during parsing.
class SyntaxError implements Exception {
  SyntaxError(this.message, this.token);

  final String message;

  final Token token;

  @override
  String toString() {
    return 'Syntax error at ${token.start}: $message';
  }
}
