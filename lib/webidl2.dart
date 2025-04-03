import 'package:webidl2/src/ast.dart';
import 'package:webidl2/src/idl_printer.dart';
import 'package:webidl2/src/parser.dart';
import 'package:webidl2/src/token.dart';
import 'package:webidl2/src/tokenizer.dart';

export 'package:webidl2/src/ast.dart';
export 'package:webidl2/src/idl_printer.dart';
export 'package:webidl2/src/parser.dart';
export 'package:webidl2/src/source_position.dart';
export 'package:webidl2/src/syntax_error.dart';
export 'package:webidl2/src/token.dart';
export 'package:webidl2/src/token_type.dart';
export 'package:webidl2/src/tokenizer.dart';
export 'package:webidl2/src/type_name.dart';
export 'package:webidl2/src/visitor.dart';

/// Parse WebIDL source code and return an AST.
///
/// Example:
/// ```dart
/// final source = 'interface Example { attribute DOMString name; };';
/// final result = parseWebIdl(source);
/// ```
///
/// Returns a [ParseResult] containing the parsed WebIDL file and any warnings.
/// Throws [SyntaxError] if the source contains syntax errors.
WebIdlParseResult parseWebIdl(String source, {bool strictMode = false}) {
  List<ParseWarning> warnings = <ParseWarning>[];

  // Create tokenizer and parser
  Tokenizer tokenizer = Tokenizer(source);
  List<Token> tokens = tokenizer.tokenize();

  // Configure parser
  void onWarning(String message, Token token) {
    warnings.add(ParseWarning(message, token));
  }

  Parser parser = Parser(tokens, strictMode: strictMode, onWarning: onWarning);

  // Parse the file
  WebIdlFile webIdlFile = parser.parse();
  return WebIdlParseResult(webIdlFile, warnings);
}

/// Result of parsing WebIDL source
class WebIdlParseResult {
  WebIdlParseResult(this.file, this.warnings);

  /// The parsed WebIDL file
  final WebIdlFile file;

  /// Any warnings that occurred during parsing
  final List<ParseWarning> warnings;

  /// Generate WebIDL source from the AST
  String generateIdl() {
    IdlPrinter printer = IdlPrinter();
    file.accept(printer);
    return printer.result;
  }
}

/// Warning during parsing
class ParseWarning {
  ParseWarning(this.message, this.token);

  final String message;

  final Token token;

  @override
  String toString() {
    return 'Warning at ${token.start}: $message';
  }
}
