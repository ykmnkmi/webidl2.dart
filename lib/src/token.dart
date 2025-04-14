import 'package:webidl2/webidl2.dart';

final class Token {
  const Token(this.type, this.value, this.position);

  final TokenType type;

  final String value;

  final int position;

  @override
  bool operator ==(Object other) {
    return other is Token &&
        other.type == type &&
        other.value == value &&
        other.position == position;
  }

  @override
  int get hashCode {
    return Object.hash(type, value, position);
  }

  @override
  String toString() {
    return "Token($type, '${value.replaceAll("'", "\\'")}', $position)";
  }
}
