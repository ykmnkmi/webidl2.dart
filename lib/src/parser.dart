import 'package:webidl2/src/ast.dart';
import 'package:webidl2/src/syntax_error.dart';
import 'package:webidl2/src/token.dart';
import 'package:webidl2/src/token_type.dart';
import 'package:webidl2/src/type_name.dart';

/// Parser for WebIDL
class Parser {
  Parser(
    this.tokens, {
    this.strictMode = false,
    void Function(String, Token)? onWarning,
  }) : onWarning = onWarning ?? ((String _, Token _) {});

  final List<Token> tokens;

  int current = 0;

  final bool strictMode;

  final void Function(String, Token) onWarning;

  Token get currentToken {
    return tokens[current];
  }

  bool isAtEnd() {
    return currentToken.type == TokenType.eof;
  }

  Token advance() {
    if (!isAtEnd()) {
      current++;
    }

    return tokens[current - 1];
  }

  String consumeIdentifier(String errorMessage) {
    Token token = consume(TokenType.identifier, errorMessage);
    return token.lexeme;
  }

  Token consume(TokenType type, String errorMessage) {
    if (check(type)) {
      return advance();
    }

    throw SyntaxError(errorMessage, currentToken);
  }

  bool check(TokenType type) {
    if (isAtEnd()) {
      return false;
    }

    return currentToken.type == type;
  }

  bool match(TokenType type) {
    if (check(type)) {
      advance();
      return true;
    }

    return false;
  }

  bool matchAny(List<TokenType> types) {
    for (int i = 0; i < types.length; i++) {
      if (check(types[i])) {
        advance();
        return true;
      }
    }

    return false;
  }

  void emitWarning(String message) {
    onWarning(message, currentToken);
  }

  /// Parse the WebIDL file
  WebIdlFile parse() {
    List<Definition> definitions = <Definition>[];

    while (!isAtEnd()) {
      try {
        definitions.add(parseDefinition());
      } catch (error) {
        if (strictMode) {
          rethrow;
        }

        // Error recovery: skip to next semicolon or right brace
        while (!isAtEnd() &&
            !match(TokenType.semiColon) &&
            !match(TokenType.rightBrace)) {
          advance();
        }

        // If we stopped at a right brace, advance past it
        if (check(TokenType.rightBrace)) {
          advance();
        }

        // Emit warning about the skipped section
        emitWarning('Skipped invalid WebIDL: $error');
      }
    }

    return WebIdlFile(definitions);
  }

  Definition parseDefinition() {
    // Check for extended attributes
    List<ExtendedAttribute> attributes = parseExtendedAttributes();

    if (match(TokenType.interfaceKeyword)) {
      return parseInterface(attributes);
    }

    if (match(TokenType.partialKeyword)) {
      if (match(TokenType.interfaceKeyword)) {
        return parsePartialInterface(attributes);
      }

      throw SyntaxError("Expected 'interface' after 'partial'", currentToken);
    }

    if (match(TokenType.dictionaryKeyword)) {
      return parseDictionary(attributes);
    }

    if (match(TokenType.enumKeyword)) {
      return parseEnum(attributes);
    }

    if (match(TokenType.typeDefKeyword)) {
      return parseTypedef(attributes);
    }

    if (match(TokenType.callbackKeyword)) {
      if (match(TokenType.interfaceKeyword)) {
        return parseCallbackInterface(attributes);
      }

      return parseCallback(attributes);
    }

    throw SyntaxError('Expected definition', currentToken);
  }

  List<ExtendedAttribute> parseExtendedAttributes() {
    if (!match(TokenType.leftBracket)) {
      return <ExtendedAttribute>[];
    }

    List<ExtendedAttribute> attributes = <ExtendedAttribute>[];

    if (!check(TokenType.rightBracket)) {
      do {
        String name = consumeIdentifier('Expected attribute name');

        if (check(TokenType.leftParen)) {
          List<Argument> arguments = parseExtendedAttributeArgumentList();
          attributes.add(ExtendedAttribute(name, '', arguments: arguments));
        } else if (match(TokenType.equals)) {
          if (check(TokenType.identifier) ||
              check(TokenType.string) ||
              check(TokenType.integer) ||
              check(TokenType.float)) {
            Token token = advance();
            String value = token.lexeme;
            attributes.add(ExtendedAttribute(name, value));
          } else {
            throw SyntaxError('Expected attribute value', currentToken);
          }
        } else {
          attributes.add(ExtendedAttribute(name, ''));
        }
      } while (match(TokenType.comma));
    }

    consume(TokenType.rightBracket, "Expected ']' after extended attributes");
    return attributes;
  }

  // Parse argument list for extended attributes
  List<Argument> parseExtendedAttributeArgumentList() {
    consume(TokenType.leftParen, "Expected '(' for arguments");

    List<Argument> arguments = <Argument>[];

    if (!check(TokenType.rightParen)) {
      do {
        arguments.add(parseArgument());
      } while (match(TokenType.comma));
    }

    consume(TokenType.rightParen, "Expected ')' after arguments");

    return arguments;
  }

  Interface parseInterface(List<ExtendedAttribute> attributes) {
    String name = consumeIdentifier('Expected interface name');
    String inherits = '';

    if (match(TokenType.colon)) {
      inherits = consumeIdentifier('Expected inherited interface name');
    }

    consume(TokenType.leftBrace, "Expected '{' before interface body");

    List<InterfaceMember> members = <InterfaceMember>[];

    while (!check(TokenType.rightBrace) && !isAtEnd()) {
      members.add(parseInterfaceMember());
    }

    consume(TokenType.rightBrace, "Expected '}' after interface body");
    consume(TokenType.semiColon, "Expected ';' after interface definition");

    return Interface(name, attributes, inherits, members);
  }

  PartialInterface parsePartialInterface(List<ExtendedAttribute> attributes) {
    String name = consumeIdentifier('Expected interface name');

    consume(TokenType.leftBrace, "Expected '{' before interface body");

    List<InterfaceMember> members = <InterfaceMember>[];

    while (!check(TokenType.rightBrace) && !isAtEnd()) {
      members.add(parseInterfaceMember());
    }

    consume(TokenType.rightBrace, "Expected '}' after interface body");
    consume(TokenType.semiColon, "Expected ';' after interface definition");

    return PartialInterface(name, attributes, members);
  }

  Dictionary parseDictionary(List<ExtendedAttribute> attributes) {
    String name = consumeIdentifier('Expected dictionary name');
    String inherits = '';

    if (match(TokenType.colon)) {
      inherits = consumeIdentifier('Expected inherited dictionary name');
    }

    consume(TokenType.leftBrace, "Expected '{' before dictionary body");

    List<DictionaryMember> members = <DictionaryMember>[];

    while (!check(TokenType.rightBrace) && !isAtEnd()) {
      members.add(parseDictionaryMember());
    }

    consume(TokenType.rightBrace, "Expected '}' after dictionary body");
    consume(TokenType.semiColon, "Expected ';' after dictionary definition");

    return Dictionary(name, attributes, inherits, members);
  }

  Enumeration parseEnum(List<ExtendedAttribute> extAttrs) {
    String name = consumeIdentifier('Expected enum name');

    consume(TokenType.leftBrace, "Expected '{' before enum body");

    List<String> values = <String>[];

    if (!check(TokenType.rightBrace)) {
      do {
        values.add(consumeIdentifier('Expected string value in enum'));
      } while (match(TokenType.comma) && !check(TokenType.rightBrace));
    }

    consume(TokenType.rightBrace, "Expected '}' after enum body");
    consume(TokenType.semiColon, "Expected ';' after enum definition");

    return Enumeration(name, extAttrs, values);
  }

  TypeDefinition parseTypedef(List<ExtendedAttribute> extAttrs) {
    Type type = parseType();
    String name = consumeIdentifier('Expected typedef name');

    consume(TokenType.semiColon, "Expected ';' after typedef");

    return TypeDefinition(name, extAttrs, type);
  }

  Callback parseCallback(List<ExtendedAttribute> extAttrs) {
    String name = consumeIdentifier('Expected callback name');

    consume(TokenType.equals, "Expected '=' after callback name");

    Type returnType = parseType();
    List<Argument> args = parseArgumentList();

    consume(TokenType.semiColon, "Expected ';' after callback definition");

    return Callback(name, extAttrs, returnType, args);
  }

  CallbackInterface parseCallbackInterface(List<ExtendedAttribute> extAttrs) {
    String name = consumeIdentifier('Expected interface name');

    consume(TokenType.leftBrace, "Expected '{' before interface body");

    List<InterfaceMember> members = <InterfaceMember>[];

    while (!check(TokenType.rightBrace) && !isAtEnd()) {
      members.add(parseInterfaceMember());
    }

    consume(TokenType.rightBrace, "Expected '}' after interface body");
    consume(TokenType.semiColon, "Expected ';' after interface definition");

    return CallbackInterface(name, extAttrs, members);
  }

  InterfaceMember parseInterfaceMember() {
    List<ExtendedAttribute> extAttrs = parseExtendedAttributes();

    if (match(TokenType.constKeyword)) {
      return parseConst(extAttrs);
    }

    bool readonly = match(TokenType.readOnlyKeyword);

    if (match(TokenType.attributeKeyword)) {
      return parseAttribute(extAttrs, readonly);
    }

    // Must be an operation
    return parseOperation(extAttrs, readonly);
  }

  Constant parseConst(List<ExtendedAttribute> extAttrs) {
    Type type = parseType();
    String name = consumeIdentifier('Expected constant name');

    consume(TokenType.equals, "Expected '=' after constant name");

    String value = '';

    if (check(TokenType.integer) ||
        check(TokenType.float) ||
        check(TokenType.nullKeyword) ||
        check(TokenType.trueKeyword) ||
        check(TokenType.falseKeyword)) {
      value = advance().lexeme;
    } else {
      throw SyntaxError('Expected constant value', currentToken);
    }

    consume(TokenType.semiColon, "Expected ';' after constant definition");

    return Constant(name, extAttrs, type, value);
  }

  Attribute parseAttribute(List<ExtendedAttribute> extAttrs, bool readonly) {
    Type type = parseType();
    String name = consumeIdentifier('Expected attribute name');

    consume(TokenType.semiColon, "Expected ';' after attribute definition");

    return Attribute(name, extAttrs, type, readonly);
  }

  Operation parseOperation(
    List<ExtendedAttribute> attributes,
    bool isReadOnly,
  ) {
    String special = '';

    if (matchAny([
      TokenType.getterKeyword,
      TokenType.setterKeyword,
      TokenType.deleterKeyword,
      TokenType.stringifierKeyword,
    ])) {
      Token token = tokens[current - 1];
      special = token.lexeme;
    }

    Type returnType = parseType();
    String name;

    if (check(TokenType.identifier)) {
      Token token = advance();
      name = token.lexeme;
    } else {
      name = '';
    }

    List<Argument> arguments = parseArgumentList();

    consume(TokenType.semiColon, "Expected ';' after operation definition");

    return Operation(
      name,
      attributes,
      returnType,
      arguments,
      special,
      isReadOnly,
    );
  }

  DictionaryMember parseDictionaryMember() {
    List<ExtendedAttribute> attributes = parseExtendedAttributes();
    bool isRequired = match(TokenType.requiredKeyword);

    Type type = parseType();
    String name = consumeIdentifier('Expected member name');

    String defaultValue = '';

    if (match(TokenType.equals)) {
      if (check(TokenType.integer) ||
          check(TokenType.float) ||
          check(TokenType.string) ||
          check(TokenType.nullKeyword) ||
          check(TokenType.trueKeyword) ||
          check(TokenType.falseKeyword)) {
        Token token = advance();
        defaultValue = token.lexeme;
      } else {
        throw SyntaxError('Expected default value', currentToken);
      }
    }

    consume(TokenType.semiColon, "Expected ';' after dictionary member");

    return DictionaryMember(name, attributes, type, isRequired, defaultValue);
  }

  List<Argument> parseArgumentList() {
    consume(TokenType.leftParen, "Expected '(' for arguments");

    List<Argument> arguments = <Argument>[];

    if (!check(TokenType.rightParen)) {
      do {
        arguments.add(parseArgument());
      } while (match(TokenType.comma));
    }

    consume(TokenType.rightParen, "Expected ')' after arguments");

    return arguments;
  }

  Argument parseArgument() {
    List<ExtendedAttribute> attributes = parseExtendedAttributes();

    bool optional = match(TokenType.optionalKeyword);
    Type type = parseType();
    bool variadic = match(TokenType.ellipsis);

    String name = consumeIdentifier('Expected argument name');

    String defaultValue = '';

    if (match(TokenType.equals)) {
      if (check(TokenType.integer) ||
          check(TokenType.float) ||
          check(TokenType.string) ||
          check(TokenType.nullKeyword) ||
          check(TokenType.trueKeyword) ||
          check(TokenType.falseKeyword)) {
        Token token = advance();
        defaultValue = token.lexeme;
      } else {
        throw SyntaxError('Expected default value', currentToken);
      }
    }

    return Argument(name, attributes, type, optional, variadic, defaultValue);
  }

  Type parseType() {
    bool nullable = false;

    TypeName typeName;

    if (match(TokenType.sequenceType)) {
      // Sequence type
      consume(TokenType.lessThan, "Expected '<' after 'sequence'");

      Type elementType = parseType();

      consume(TokenType.greaterThan, "Expected '>' to close sequence type");

      typeName = SequenceType(elementType);
    } else if (match(TokenType.promiseType)) {
      // Promise type
      consume(TokenType.lessThan, "Expected '<' after 'Promise'");

      Type valueType = parseType();

      consume(TokenType.greaterThan, "Expected '>' to close Promise type");

      typeName = PromiseType(valueType);
    } else if (match(TokenType.recordType)) {
      // Record type
      consume(TokenType.lessThan, "Expected '<' after 'record'");

      Type keyType = parseType();

      consume(TokenType.comma, "Expected ',' between key and value types");

      Type valueType = parseType();

      consume(TokenType.greaterThan, "Expected '>' to close record type");

      typeName = RecordType(keyType, valueType);
    } else {
      // Simple or union type
      typeName = parseSimpleType();

      // Check for union type
      if (match(TokenType.or)) {
        List<Type> unionTypes = <Type>[Type(typeName, false)];

        do {
          Type memberType = parseType();
          unionTypes.add(memberType);
        } while (match(TokenType.or));

        typeName = UnionType(unionTypes);
      }
    }

    // Check for nullable
    nullable = match(TokenType.question);

    return Type(typeName, nullable);
  }

  TypeName parseSimpleType() {
    // Handle unsigned long/short types
    if (match(TokenType.unsignedType)) {
      if (match(TokenType.longType)) {
        if (match(TokenType.longType)) {
          return SimpleType('unsigned long long');
        }

        return SimpleType('unsigned long');
      }

      if (match(TokenType.shortType)) {
        return SimpleType('unsigned short');
      }

      throw SyntaxError(
        "Expected 'long' or 'short' after 'unsigned'",
        currentToken,
      );
    }

    // Handle long long type
    if (match(TokenType.longType)) {
      if (match(TokenType.longType)) {
        return SimpleType('long long');
      }

      return SimpleType('long');
    }

    // Handle other primitive types
    if (matchAny(<TokenType>[
      TokenType.shortType,
      TokenType.floatType,
      TokenType.doubleType,
      TokenType.booleanType,
      TokenType.byteType,
      TokenType.octetType,
      TokenType.voidType,
      TokenType.anyType,
      TokenType.objectType,
      TokenType.symbolType,
    ])) {
      Token token = tokens[current - 1];
      return SimpleType(token.lexeme);
    }

    // Handle identifier type (custom type)
    if (check(TokenType.identifier)) {
      Token token = advance();
      return SimpleType(token.lexeme);
    }

    throw SyntaxError('Expected type', currentToken);
  }
}
