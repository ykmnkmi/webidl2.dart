/// Base class for type names.
abstract class TypeName {
  const TypeName();
}

/// Simple type (like long, DOMString, etc.).
class SimpleType implements TypeName {
  const SimpleType(this.name);

  final String name;

  @override
  String toString() {
    return name;
  }
}

/// Sequence type (like sequence&lt;long&gt;).
class SequenceType implements TypeName {
  const SequenceType(this.elementType);

  final Type elementType;

  @override
  String toString() {
    return 'sequence<$elementType>';
  }
}

/// Promise type (like Promise&lt;void&gt;).
class PromiseType implements TypeName {
  const PromiseType(this.valueType);

  final Type valueType;

  @override
  String toString() {
    return 'Promise<$valueType>';
  }
}

/// Record type (like record&lt;DOMString, long&gt;).
class RecordType implements TypeName {
  const RecordType(this.keyType, this.valueType);

  final Type keyType;

  final Type valueType;

  @override
  String toString() {
    return 'record<$keyType, $valueType>';
  }
}

/// Union type (like (long or DOMString)).
class UnionType implements TypeName {
  const UnionType(this.memberTypes);

  final List<Type> memberTypes;

  @override
  String toString() {
    return '(${memberTypes.join(' or ')})';
  }
}

/// Type representation.
class Type {
  const Type(this.name, this.nullable);

  final TypeName name;

  final bool nullable;

  @override
  String toString() {
    return nullable ? '$name?' : name.toString();
  }
}
