import 'package:webidl2/src/type_name.dart';
import 'package:webidl2/src/visitor.dart';

/// Base class for all definitions.
abstract class Definition {
  const Definition(this.name, this.extendedAttributes);

  final String name;

  final List<ExtendedAttribute> extendedAttributes;

  /// Accept method for the visitor pattern.
  T accept<T>(Visitor<T> visitor);
}

/// WebIDL file containing multiple definitions.
class WebIdlFile {
  const WebIdlFile(this.definitions);

  final List<Definition> definitions;

  /// Accept method for the visitor pattern.
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitWebIdlFile(this);
  }
}

/// Extended attribute for various WebIDL elements.
class ExtendedAttribute {
  const ExtendedAttribute(
    this.name,
    this.value, {
    this.arguments = const <Argument>[],
  });

  final String name;

  final String value;

  final List<Argument> arguments;

  @override
  String toString() {
    if (arguments.isNotEmpty) {
      // Format with argument list: Constructor(DOMString url)
      String arguments = [
        for (Argument argument in this.arguments)
          <String>[
            if (argument.optional) 'optional',
            argument.type.toString(),
            if (argument.variadic) '...',
            argument.name,
            if (argument.defaultValue.isNotEmpty) '= ${argument.defaultValue}',
          ].join(' '),
      ].join(', ');

      return '$name($arguments)';
    }

    if (value.isNotEmpty) {
      // Format with simple value: Exposed=Window
      return '$name=$value';
    }

    // Format without value: NoInterfaceObject
    return name;
  }
}

/// Interface definition.
class Interface extends Definition {
  const Interface(
    super.name,
    super.extendedAttributes,
    this.inherits,
    this.members,
  );

  final String inherits;

  final List<InterfaceMember> members;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitInterface(this);
  }
}

/// Partial interface definition.
class PartialInterface extends Definition {
  const PartialInterface(super.name, super.extendedAttributes, this.members);

  final List<InterfaceMember> members;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitPartialInterface(this);
  }
}

/// Dictionary definition.
class Dictionary extends Definition {
  const Dictionary(
    super.name,
    super.extendedAttributes,
    this.inherits,
    this.members,
  );

  final String inherits;

  final List<DictionaryMember> members;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitDictionary(this);
  }
}

/// Enum definition.
class Enumeration extends Definition {
  const Enumeration(super.name, super.extendedAttributes, this.values);

  final List<String> values;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitEnumeration(this);
  }
}

/// Typedef definition.
class TypeDefinition extends Definition {
  const TypeDefinition(super.name, super.extendedAttributes, this.type);

  final Type type;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitTypeDefinition(this);
  }
}

/// Callback definition.
class Callback extends Definition {
  const Callback(
    super.name,
    super.extendedAttributes,
    this.returnType,
    this.arguments,
  );

  final Type returnType;

  final List<Argument> arguments;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitCallback(this);
  }
}

/// Callback interface definition.
class CallbackInterface extends Definition {
  const CallbackInterface(super.name, super.extendedAttributes, this.members);

  final List<InterfaceMember> members;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitCallbackInterface(this);
  }
}

/// Base class for all interface members.
abstract class InterfaceMember {
  const InterfaceMember(this.name, this.extendedAttributes);

  final String name;

  final List<ExtendedAttribute> extendedAttributes;

  /// Accept method for the visitor pattern.
  T accept<T>(Visitor<T> visitor);
}

/// Attribute in an interface.
class Attribute extends InterfaceMember {
  const Attribute(
    super.name,
    super.extendedAttributes,
    this.type,
    this.readonly,
  );

  final Type type;

  final bool readonly;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitAttribute(this);
  }
}

/// Operation (method) in an interface.
class Operation extends InterfaceMember {
  const Operation(
    super.name,
    super.extendedAttributes,
    this.returnType,
    this.arguments,
    this.special,
    this.isReadOnly,
  );

  final Type returnType;

  final List<Argument> arguments;

  final String special; // getter, setter, deleter, or stringifier

  final bool isReadOnly;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitOperation(this);
  }
}

/// Constant in an interface.
class Constant extends InterfaceMember {
  const Constant(super.name, super.extendedAttributes, this.type, this.value);

  final Type type;

  final String value;

  @override
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitConstant(this);
  }
}

/// Dictionary member.
class DictionaryMember {
  const DictionaryMember(
    this.name,
    this.extendedAttributes,
    this.type,
    this.isRequired,
    this.defaultValue,
  );

  final String name;

  final List<ExtendedAttribute> extendedAttributes;

  final Type type;

  final bool isRequired;

  final String defaultValue;

  /// Accept method for the visitor pattern.
  T accept<T>(Visitor<T> visitor) {
    return visitor.visitDictionaryMember(this);
  }
}

/// Function argument.
final class Argument {
  const Argument(
    this.name,
    this.extendedAttributes,
    this.type,
    this.optional,
    this.variadic,
    this.defaultValue,
  );

  final String name;

  final List<ExtendedAttribute> extendedAttributes;

  final Type type;

  final bool optional;

  final bool variadic;

  final String defaultValue;
}
