import 'package:webidl2/src/ast.dart';
import 'package:webidl2/src/visitor.dart';

/// A printer visitor to generate WebIDL text from the AST.
class IdlPrinter extends Visitor<void> {
  IdlPrinter({StringBuffer? buffer}) : buffer = buffer ?? StringBuffer();

  final StringBuffer buffer;

  int indentLevel = 0;

  String get result {
    return buffer.toString();
  }

  void indent() {
    indentLevel += 2;
  }

  void dedent() {
    indentLevel -= 2;
  }

  void write(String text) {
    buffer.write(text);
  }

  void writeln([String text = '']) {
    if (text.isNotEmpty) {
      buffer.write(text);
    }

    buffer.write('\n');
  }

  void writeIndent() {
    for (int i = 0; i < indentLevel; i++) {
      buffer.write(' ');
    }
  }

  String _formatExtendedAttributes(List<ExtendedAttribute> attributes) {
    if (attributes.isEmpty) {
      return '';
    }

    String mapper(ExtendedAttribute attribute) {
      if (attribute.arguments.isNotEmpty) {
        String arguments = [
          for (Argument argument in attribute.arguments)
            <String>[
              if (argument.optional) 'optional',
              argument.type.toString(),
              if (argument.variadic) '...',
              argument.name,
              if (argument.defaultValue.isNotEmpty)
                '= ${argument.defaultValue}',
            ].join(' '),
        ].join(', ');

        return '${attribute.name}($arguments)';
      }

      if (attribute.value.isNotEmpty) {
        return '${attribute.name}=${attribute.value}';
      }

      return attribute.name;
    }

    return '[${attributes.map<String>(mapper).join(', ')}] ';
  }

  @override
  void visitWebIdlFile(WebIdlFile file) {
    for (Definition definition in file.definitions) {
      definition.accept(this);
      writeln();
    }
  }

  @override
  void visitInterface(Interface interface) {
    write(_formatExtendedAttributes(interface.extendedAttributes));
    write('interface ${interface.name}');

    if (interface.inherits.isNotEmpty) {
      write(' : ${interface.inherits}');
    }

    writeln(' {');
    indent();

    for (InterfaceMember member in interface.members) {
      member.accept(this);
    }

    dedent();
    writeln('};');
  }

  @override
  void visitPartialInterface(PartialInterface partialInterface) {
    write(_formatExtendedAttributes(partialInterface.extendedAttributes));
    writeln('partial interface ${partialInterface.name} {');
    indent();

    for (InterfaceMember member in partialInterface.members) {
      member.accept(this);
    }

    dedent();
    writeln('};');
  }

  @override
  void visitDictionary(Dictionary dictionary) {
    write(_formatExtendedAttributes(dictionary.extendedAttributes));
    write('dictionary ${dictionary.name}');

    if (dictionary.inherits.isNotEmpty) {
      write(' : ${dictionary.inherits}');
    }

    writeln(' {');
    indent();

    for (DictionaryMember member in dictionary.members) {
      member.accept(this);
    }

    dedent();
    writeln('};');
  }

  @override
  void visitEnumeration(Enumeration enumeration) {
    write(_formatExtendedAttributes(enumeration.extendedAttributes));
    writeln('enum ${enumeration.name} {');
    indent();

    for (int i = 0; i < enumeration.values.length; i++) {
      writeIndent();
      write('"${enumeration.values[i]}"');

      if (i < enumeration.values.length - 1) {
        writeln(',');
      } else {
        writeln();
      }
    }

    dedent();
    writeln('};');
  }

  @override
  void visitTypeDefinition(TypeDefinition typedef) {
    write(_formatExtendedAttributes(typedef.extendedAttributes));
    writeln('typedef ${typedef.type} ${typedef.name};');
  }

  @override
  void visitCallback(Callback callback) {
    write(_formatExtendedAttributes(callback.extendedAttributes));
    write('callback ${callback.name} = ${callback.returnType} (');

    for (int i = 0; i < callback.arguments.length; i++) {
      Argument argument = callback.arguments[i];

      if (argument.optional) {
        write('optional ');
      }

      write('${argument.type} ');

      if (argument.variadic) {
        write('... ');
      }

      write(argument.name);

      if (argument.defaultValue.isNotEmpty) {
        write(' = ${argument.defaultValue}');
      }

      if (i < callback.arguments.length - 1) {
        write(', ');
      }
    }

    writeln(');');
  }

  @override
  void visitCallbackInterface(CallbackInterface callbackInterface) {
    write(_formatExtendedAttributes(callbackInterface.extendedAttributes));
    writeln('callback interface ${callbackInterface.name} {');
    indent();

    for (int i = 0; i < callbackInterface.members.length; i++) {
      callbackInterface.members[i].accept(this);
    }

    dedent();
    writeln('};');
  }

  @override
  void visitAttribute(Attribute attribute) {
    writeIndent();
    write(_formatExtendedAttributes(attribute.extendedAttributes));

    if (attribute.readonly) {
      write('readonly ');
    }

    writeln('attribute ${attribute.type} ${attribute.name};');
  }

  @override
  void visitOperation(Operation operation) {
    writeIndent();
    write(_formatExtendedAttributes(operation.extendedAttributes));

    if (operation.isReadOnly) {
      write('readonly ');
    }

    if (operation.special.isNotEmpty) {
      write('${operation.special} ');
    }

    write('${operation.returnType} ');

    if (operation.name.isNotEmpty) {
      write(operation.name);
    }

    write('(');

    for (int i = 0; i < operation.arguments.length; i++) {
      Argument argument = operation.arguments[i];

      if (argument.optional) {
        write('optional ');
      }

      write('${argument.type} ');

      if (argument.variadic) {
        write('... ');
      }

      write(argument.name);

      if (argument.defaultValue.isNotEmpty) {
        write(' = ${argument.defaultValue}');
      }

      if (i < operation.arguments.length - 1) {
        write(', ');
      }
    }

    writeln(');');
  }

  @override
  void visitConstant(Constant constant) {
    writeIndent();
    write(_formatExtendedAttributes(constant.extendedAttributes));
    writeln('const ${constant.type} ${constant.name} = ${constant.value};');
  }

  @override
  void visitDictionaryMember(DictionaryMember member) {
    writeIndent();
    write(_formatExtendedAttributes(member.extendedAttributes));

    if (member.isRequired) {
      write('required ');
    }

    write('${member.type} ${member.name}');

    if (member.defaultValue.isNotEmpty) {
      write(' = ${member.defaultValue}');
    }

    writeln(';');
  }
}
