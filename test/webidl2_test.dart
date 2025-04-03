import 'package:test/test.dart';
import 'package:webidl2/webidl2.dart';

void main() {
  group('Tokenizer Tests', () {
    test('tokenizes basic tokens correctly', () {
      var source = 'interface Example {};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token for easier comparison
      tokens.removeLast();

      expect(tokens.length, 5);
      expect(tokens[0].type, TokenType.interfaceKeyword);
      expect(tokens[0].lexeme, 'interface');
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].lexeme, 'Example');
      expect(tokens[2].type, TokenType.leftBrace);
      expect(tokens[3].type, TokenType.rightBrace);
      expect(tokens[4].type, TokenType.semiColon);
    });

    test('tokenizes string literals correctly', () {
      var source = '"test string" \'another string\'';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 2);
      expect(tokens[0].type, TokenType.string);
      expect(tokens[0].lexeme, 'test string');
      expect(tokens[1].type, TokenType.string);
      expect(tokens[1].lexeme, 'another string');
    });

    test('tokenizes numbers correctly', () {
      var source = '123 45.67';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 2);
      expect(tokens[0].type, TokenType.integer);
      expect(tokens[0].lexeme, '123');
      expect(tokens[1].type, TokenType.float);
      expect(tokens[1].lexeme, '45.67');
    });

    test('tokenizes comments correctly', () {
      var source = '// Line comment\n/* Block comment */\n/** Doc comment */';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 3);
      expect(tokens[0].type, TokenType.comment);
      expect(tokens[0].lexeme.startsWith('//'), true);
      expect(tokens[1].type, TokenType.comment);
      expect(tokens[1].lexeme.startsWith('/*'), true);
      expect(tokens[2].type, TokenType.documentComment);
      expect(tokens[2].lexeme.startsWith('/**'), true);
    });

    test('tokenizes keywords correctly', () {
      var source =
          'interface partial dictionary enum callback typedef implements const';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 8);
      expect(tokens[0].type, TokenType.interfaceKeyword);
      expect(tokens[1].type, TokenType.partialKeyword);
      expect(tokens[2].type, TokenType.dictionaryKeyword);
      expect(tokens[3].type, TokenType.enumKeyword);
      expect(tokens[4].type, TokenType.callbackKeyword);
      expect(tokens[5].type, TokenType.typeDefKeyword);
      expect(tokens[6].type, TokenType.implementsKeyword);
      expect(tokens[7].type, TokenType.constKeyword);
    });

    test('tracks source positions correctly', () {
      var source = 'interface\nExample\n{\n};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      // interface
      expect(tokens[0].start.line, 1);
      expect(tokens[0].start.column, 1);
      expect(tokens[0].start.offset, 0);
      expect(tokens[0].end.line, 1);
      expect(tokens[0].end.column, 10); // After "interface"
      expect(tokens[0].end.offset, 9);

      // Example
      expect(tokens[1].start.line, 2);
      expect(tokens[1].start.column, 1);
      expect(tokens[1].start.offset, 10);
      expect(tokens[1].end.line, 2);
      expect(tokens[1].end.column, 8); // After "Example"
      expect(tokens[1].end.offset, 17);

      // {
      expect(tokens[2].start.line, 3);
      expect(tokens[2].start.column, 1);
      expect(tokens[2].start.offset, 18);
      expect(tokens[2].end.line, 3);
      expect(tokens[2].end.column, 2); // After "{"
      expect(tokens[2].end.offset, 19);

      // }
      expect(tokens[3].start.line, 4);
      expect(tokens[3].start.column, 1);
      expect(tokens[3].start.offset, 20);
      expect(tokens[3].end.line, 4);
      expect(tokens[3].end.column, 2); // After "}"
      expect(tokens[3].end.offset, 21);
    });

    test('handles multi-line content correctly', () {
      var source = 'interface Test {\n  attribute DOMString name;\n};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Find the attribute token
      var attribute = tokens.firstWhere(
        (token) => token.type == TokenType.attributeKeyword,
      );

      expect(attribute.start.line, 2);
      expect(attribute.start.column, 3);
      expect(attribute.lexeme, 'attribute');
    });

    test('tokenizes string literals with correct positions', () {
      var source = '"hello world"';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 1);
      expect(tokens[0].type, TokenType.string);
      expect(tokens[0].lexeme, 'hello world');
      expect(tokens[0].start.offset, 0);
      expect(tokens[0].end.offset, 13); // After closing quote
    });

    test('tokenizes comments with correct positions', () {
      var source = '// Line comment\n/* Block comment */';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Remove EOF token
      tokens.removeLast();

      expect(tokens.length, 2);
      expect(tokens[0].type, TokenType.comment);
      expect(tokens[0].start.line, 1);
      expect(tokens[0].end.line, 1);

      expect(tokens[1].type, TokenType.comment);
      expect(tokens[1].start.line, 2);
      expect(tokens[1].end.line, 2);
    });
  });

  group('Source Mapping Tests', () {
    test('captures correct source range for interface', () {
      var source = 'interface Example {};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Interface token
      expect(tokens[0].start.offset, 0);
      expect(tokens[0].end.offset, 9);

      // Name token
      expect(tokens[1].start.offset, 10);
      expect(tokens[1].end.offset, 17);

      // Left brace
      expect(tokens[2].start.offset, 18);
      expect(tokens[2].end.offset, 19);
    });

    test('handles extended attributes source mapping', () {
      var source = '[Constructor] interface Example {};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Left bracket
      expect(tokens[0].type, TokenType.leftBracket);
      expect(tokens[0].start.offset, 0);

      // Constructor identifier
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].lexeme, 'Constructor');
      expect(tokens[1].start.offset, 1);

      // Right bracket
      expect(tokens[2].type, TokenType.rightBracket);
      expect(tokens[2].start.offset, 12);

      // Interface keyword
      expect(tokens[3].type, TokenType.interfaceKeyword);
      expect(tokens[3].start.offset, 14);
    });

    test('captures source position for complex constructs', () {
      var source =
          'dictionary Options {\n  required DOMString name;\n  long timeout = 1000;\n};';
      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();

      // Find required token
      var requiredToken = tokens.firstWhere(
        (t) => t.type == TokenType.requiredKeyword,
      );
      expect(requiredToken.start.line, 2);
      expect(requiredToken.start.column, 3);

      // Find timeout identifier token
      var timeoutToken = tokens.firstWhere(
        (t) => t.type == TokenType.identifier && t.lexeme == 'timeout',
      );
      expect(timeoutToken.start.line, 3);

      // Find integer value token
      var intToken = tokens.firstWhere((t) => t.type == TokenType.integer);
      expect(intToken.lexeme, '1000');
      expect(intToken.start.line, 3);
    });
  });

  group('Parser Tests', () {
    test('parses basic interface correctly', () {
      var source = '''
        interface Example {
          attribute DOMString test;
          void method();
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<Interface>());

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.name, 'Example');
      expect(interface.inherits, '');
      expect(interface.members.length, 2);

      expect(interface.members[0], isA<Attribute>());
      var attr = interface.members[0] as Attribute;
      expect(attr.name, 'test');
      expect(attr.readonly, false);

      expect(interface.members[1], isA<Operation>());
      var op = interface.members[1] as Operation;
      expect(op.name, 'method');
      expect(op.arguments.length, 0);
    });

    test('parses interface with inheritance correctly', () {
      var source = 'interface Child : Parent {};';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<Interface>());

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.name, 'Child');
      expect(interface.inherits, 'Parent');
    });

    test('parses interface with extended attributes correctly', () {
      var source = '[Constructor, NoInterfaceObject] interface Example {};';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.extendedAttributes.length, 2);
      expect(interface.extendedAttributes[0].name, 'Constructor');
      expect(interface.extendedAttributes[0].value, '');
      expect(interface.extendedAttributes[1].name, 'NoInterfaceObject');
      expect(interface.extendedAttributes[1].value, '');
    });

    test('parses extended attributes with values correctly', () {
      var source =
          '[Constructor(DOMString url), Exposed=Window] interface Example {};';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.extendedAttributes.length, 2);
      expect(interface.extendedAttributes[0].name, 'Constructor');
      expect(interface.extendedAttributes[0].value, '');
      expect(interface.extendedAttributes[1].name, 'Exposed');
      expect(interface.extendedAttributes[1].value, 'Window');
    });

    test('parses dictionary correctly', () {
      var source = '''
        dictionary Options {
          DOMString title;
          boolean active = false;
          required long id;
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<Dictionary>());

      var dict = webidlFile.definitions[0] as Dictionary;
      expect(dict.name, 'Options');
      expect(dict.members.length, 3);

      expect(dict.members[0].name, 'title');
      expect(dict.members[0].isRequired, false);
      expect(dict.members[0].defaultValue, '');

      expect(dict.members[1].name, 'active');
      expect(dict.members[1].isRequired, false);
      expect(dict.members[1].defaultValue, 'false');

      expect(dict.members[2].name, 'id');
      expect(dict.members[2].isRequired, true);
      expect(dict.members[2].defaultValue, '');
    });

    test('parses enum correctly', () {
      var source = '''
        enum Status {
          "pending",
          "active",
          "suspended",
          "closed"
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<Enumeration>());

      var enumDef = webidlFile.definitions[0] as Enumeration;
      expect(enumDef.name, 'Status');
      expect(enumDef.values.length, 4);
      expect(enumDef.values, ['pending', 'active', 'suspended', 'closed']);
    });

    test('parses typedef correctly', () {
      var source = 'typedef sequence<DOMString> StringList;';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<TypeDefinition>());

      var typedef = webidlFile.definitions[0] as TypeDefinition;
      expect(typedef.name, 'StringList');
      expect(typedef.type.name, isA<SequenceType>());
    });

    test('parses callback correctly', () {
      var source = 'callback EventHandler = void (Event event);';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      expect(webidlFile.definitions.length, 1);
      expect(webidlFile.definitions[0], isA<Callback>());

      var callback = webidlFile.definitions[0] as Callback;
      expect(callback.name, 'EventHandler');
      expect(callback.returnType.name.toString(), 'void');
      expect(callback.arguments.length, 1);
      expect(callback.arguments[0].name, 'event');
    });

    test('parses operation with arguments correctly', () {
      var source = '''
        interface Example {
          void method(DOMString arg1, optional boolean arg2 = true);
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      var operation = interface.members[0] as Operation;
      expect(operation.name, 'method');
      expect(operation.arguments.length, 2);

      expect(operation.arguments[0].name, 'arg1');
      expect(operation.arguments[0].type.name.toString(), 'DOMString');
      expect(operation.arguments[0].optional, false);

      expect(operation.arguments[1].name, 'arg2');
      expect(operation.arguments[1].type.name.toString(), 'boolean');
      expect(operation.arguments[1].optional, true);
      expect(operation.arguments[1].defaultValue, 'true');
    });

    test('parses readonly attributes correctly', () {
      var source = '''
        interface Example {
          readonly attribute DOMString id;
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      var attribute = interface.members[0] as Attribute;
      expect(attribute.name, 'id');
      expect(attribute.readonly, true);
    });

    test('parses special operations correctly', () {
      var source = '''
        interface Example {
          getter any getItem(DOMString key);
          setter void setItem(DOMString key, any value);
          deleter void removeItem(DOMString key);
          stringifier DOMString toString();
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.members.length, 4);

      expect((interface.members[0] as Operation).special, 'getter');
      expect((interface.members[1] as Operation).special, 'setter');
      expect((interface.members[2] as Operation).special, 'deleter');
      expect((interface.members[3] as Operation).special, 'stringifier');
    });

    test('parses constants correctly', () {
      var source = '''
        interface Example {
          const unsigned long MAX_LENGTH = 1024;
          const boolean ENABLED = true;
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.members.length, 2);

      var const1 = interface.members[0] as Constant;
      expect(const1.name, 'MAX_LENGTH');
      expect(const1.type.name.toString(), 'unsigned long');
      expect(const1.value, '1024');

      var const2 = interface.members[1] as Constant;
      expect(const2.name, 'ENABLED');
      expect(const2.type.name.toString(), 'boolean');
      expect(const2.value, 'true');
    });

    test('parses complex types correctly', () {
      var source = '''
        interface Example {
          sequence<DOMString> getList();
          Promise<any> fetchData();
          record<DOMString, any> getProperties();
          (long or DOMString) getIdentifier();
          sequence<Promise<DOMString>> getNames();
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var interface = webidlFile.definitions[0] as Interface;
      expect(interface.members.length, 5);

      // sequence<DOMString>
      var op1 = interface.members[0] as Operation;
      expect(op1.returnType.name, isA<SequenceType>());

      // Promise<any>
      var op2 = interface.members[1] as Operation;
      expect(op2.returnType.name, isA<PromiseType>());

      // record<DOMString, any>
      var op3 = interface.members[2] as Operation;
      expect(op3.returnType.name, isA<RecordType>());

      // (long or DOMString)
      var op4 = interface.members[3] as Operation;
      expect(op4.returnType.name, isA<UnionType>());

      // sequence<Promise<DOMString>>
      var op5 = interface.members[4] as Operation;
      expect(op5.returnType.name, isA<SequenceType>());
      var seqType = op5.returnType.name as SequenceType;
      expect(seqType.elementType.name, isA<PromiseType>());
    });
  });

  group('IDL Printer Tests', () {
    test('prints interface correctly', () {
      var source = 'interface Example { attribute DOMString name; };';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var printer = IdlPrinter();
      webidlFile.accept(printer);
      var output = printer.result;

      expect(output.contains('interface Example'), true);
      expect(output.contains('attribute DOMString name'), true);
    });

    test('prints extended attributes correctly', () {
      var source = '[Constructor, Exposed=Window] interface Example {};';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var printer = IdlPrinter();
      webidlFile.accept(printer);
      var output = printer.result;

      expect(output.contains('[Constructor, Exposed=Window]'), true);
    });

    test('prints dictionary correctly', () {
      var source = '''
        dictionary Options {
          DOMString title = "Default";
          required long id;
        };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var printer = IdlPrinter();
      webidlFile.accept(printer);
      var output = printer.result;

      expect(output.contains('dictionary Options'), true);
      expect(output.contains('DOMString title = "Default"'), true);
      expect(output.contains('required long id'), true);
    });

    test('prints enum correctly', () {
      var source = 'enum Status { "active", "inactive" };';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      var printer = IdlPrinter();
      webidlFile.accept(printer);
      var output = printer.result;

      expect(output.contains('enum Status'), true);
      expect(output.contains('"active"'), true);
      expect(output.contains('"inactive"'), true);
    });
  });

  group('Integration Tests', () {
    test('process complex WebIDL document', () {
      var source = '''
        // WebIDL for DOM
        [Constructor(DOMString type, optional EventInit eventInitDict)]
        interface Event {
          readonly attribute DOMString type;
          readonly attribute EventTarget? target;
          readonly attribute EventTarget? currentTarget;

          const unsigned short NONE = 0;
          const unsigned short CAPTURING_PHASE = 1;
          const unsigned short AT_TARGET = 2;
          const unsigned short BUBBLING_PHASE = 3;
          readonly attribute unsigned short eventPhase;

          void stopPropagation();
          void stopImmediatePropagation();

          readonly attribute boolean bubbles;
          readonly attribute boolean cancelable;
          void preventDefault();
          readonly attribute boolean defaultPrevented;

          [Deprecated]
          readonly attribute boolean returnValue;
          [Deprecated]
          void initEvent(DOMString type, boolean bubbles, boolean cancelable);

          readonly attribute boolean isTrusted;
          readonly attribute DOMTimeStamp timeStamp;
        };

        dictionary EventInit {
          boolean bubbles = false;
          boolean cancelable = false;
          boolean composed = false;
        };

        [Constructor]
        interface EventTarget {
          void addEventListener(DOMString type, EventListener? callback, optional (AddEventListenerOptions or boolean) options);
          void removeEventListener(DOMString type, EventListener? callback, optional (EventListenerOptions or boolean) options);
          boolean dispatchEvent(Event event);
        };

        callback interface EventListener {
          void handleEvent(Event event);
        };

        dictionary EventListenerOptions {
          boolean capture = false;
        };

        dictionary AddEventListenerOptions : EventListenerOptions {
          boolean passive = false;
          boolean once = false;
        };

        enum TouchType {
          "direct",
          "stylus"
        };

        typedef sequence<TouchType> TouchTypeList;
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      // Verify interfaces
      var interfaces = webidlFile.definitions.whereType<Interface>().toList();
      expect(interfaces.length, 2);
      expect(interfaces[0].name, 'Event');
      expect(interfaces[1].name, 'EventTarget');

      // Verify dictionaries
      var dictionaries =
          webidlFile.definitions.whereType<Dictionary>().toList();
      expect(dictionaries.length, 3);
      expect(dictionaries[0].name, 'EventInit');
      expect(dictionaries[1].name, 'EventListenerOptions');
      expect(dictionaries[2].name, 'AddEventListenerOptions');
      expect(dictionaries[2].inherits, 'EventListenerOptions');

      // Verify callback interface
      var callbackInterfaces =
          webidlFile.definitions.whereType<CallbackInterface>().toList();
      expect(callbackInterfaces.length, 1);
      expect(callbackInterfaces[0].name, 'EventListener');

      // Verify enum
      var enums = webidlFile.definitions.whereType<Enumeration>().toList();
      expect(enums.length, 1);
      expect(enums[0].name, 'TouchType');
      expect(enums[0].values.length, 2);

      // Verify typedef
      var typedefs =
          webidlFile.definitions.whereType<TypeDefinition>().toList();
      expect(typedefs.length, 1);
      expect(typedefs[0].name, 'TouchTypeList');

      // Test round-trip printing
      var printer = IdlPrinter();
      webidlFile.accept(printer);
      var output = printer.result;

      // Verify printed output contains expected elements
      expect(output.contains('interface Event'), true);
      expect(output.contains('interface EventTarget'), true);
      expect(output.contains('dictionary EventInit'), true);
      expect(output.contains('callback interface EventListener'), true);
      expect(output.contains('enum TouchType'), true);
      expect(
        output.contains('typedef sequence<TouchType> TouchTypeList'),
        true,
      );
    });
  });

  group('Error Handling Tests', () {
    test('handles syntax errors gracefully', () {
      var source = 'interface Example { attribute missing; };';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);

      expect(() => parser.parse(), throwsA(isA<SyntaxError>()));
    });

    test('recovers from errors and continues parsing', () {
      var source = '''
        interface Good1 { attribute DOMString name; };
        interface Bad { attribute missing; };
        interface Good2 { attribute DOMString name; };
      ''';

      var tokenizer = Tokenizer(source);
      var tokens = tokenizer.tokenize();
      var parser = Parser(tokens);
      var webidlFile = parser.parse();

      // Should find the two good interfaces
      expect(webidlFile.definitions.length, 2);
      expect((webidlFile.definitions[0] as Interface).name, 'Good1');
      expect((webidlFile.definitions[1] as Interface).name, 'Good2');
    });
  });

  group('API Tests', () {
    test('parseWebIdl function parses valid WebIDL', () {
      var source = '''
        interface Example {
          attribute DOMString name;
          void method();
        };
      ''';

      var result = parseWebIdl(source);

      expect(result.file.definitions.length, 1);
      expect(result.file.definitions[0], isA<Interface>());
      expect(result.warnings.isEmpty, true);

      var interface = result.file.definitions[0] as Interface;
      expect(interface.name, 'Example');
      expect(interface.members.length, 2);
    });

    test('parseWebIdl handles syntax errors gracefully in non-strict mode', () {
      var source = '''
        interface Good {};
        interface Bad { attribute missing; };
        interface AlsoGood {};
      ''';

      var result = parseWebIdl(source);

      // Should skip the bad interface but parse the good ones
      expect(result.file.definitions.length, 2);
      expect(result.file.definitions[0].name, 'Good');
      expect(result.file.definitions[1].name, 'AlsoGood');
      expect(result.warnings.isNotEmpty, true);
    });

    test('parseWebIdl throws SyntaxError in strict mode', () {
      var source = 'interface Bad { attribute missing; };';

      expect(
        () => parseWebIdl(source, strictMode: true),
        throwsA(isA<SyntaxError>()),
      );
    });

    test('generateIdl produces valid WebIDL from parsed AST', () {
      var source = 'interface Example { attribute DOMString name; };';

      var result = parseWebIdl(source);
      var generated = result.generateIdl();

      // Parse the generated output to verify it's valid
      var reparsed = parseWebIdl(generated);

      expect(reparsed.file.definitions.length, 1);
      expect(reparsed.file.definitions[0], isA<Interface>());
      expect((reparsed.file.definitions[0] as Interface).name, 'Example');
    });

    test('parseWebIdl handles complex WebIDL documents', () {
      var source = '''
        // WebIDL for DOM Events
        [Constructor(DOMString type, optional EventInit eventInitDict)]
        interface Event {
          readonly attribute DOMString type;
          readonly attribute EventTarget? target;
          readonly attribute EventTarget? currentTarget;

          const unsigned short NONE = 0;
          const unsigned short CAPTURING_PHASE = 1;
          const unsigned short AT_TARGET = 2;
          const unsigned short BUBBLING_PHASE = 3;

          void stopPropagation();
          void preventDefault();
        };

        dictionary EventInit {
          boolean bubbles = false;
          boolean cancelable = false;
        };

        callback EventListener = void (Event event);
      ''';

      var result = parseWebIdl(source);

      expect(result.file.definitions.length, 3);
      expect(result.file.definitions[0], isA<Interface>());
      expect(result.file.definitions[1], isA<Dictionary>());
      expect(result.file.definitions[2], isA<Callback>());
    });

    test('parseWebIdl preserves comments in output', () {
      var source = '''
        // Interface comment
        interface Example {
          // Attribute comment
          attribute DOMString name;
        };
      ''';

      var result = parseWebIdl(source);
      var generated = result.generateIdl();

      // The printer doesn't currently preserve comments, but we could extend it
      // This test is a placeholder for that future functionality
      expect(generated.contains('interface Example'), true);
    });

    test('parseWebIdl handles warnings with callback', () {
      var source = '''
        interface Example {
          attribute DOMString name;
          // This semicolon is missing but we'll recover
          attribute DOMString id
        };
      ''';

      var warnings = <String>[];

      // This would throw in strict mode, but we'll recover in non-strict mode
      expect(() {
        var result = parseWebIdl(source, strictMode: false);
        warnings.addAll(result.warnings.map((w) => w.toString()));
      }, returnsNormally);

      expect(warnings.isNotEmpty, true);
    });
  });
}
