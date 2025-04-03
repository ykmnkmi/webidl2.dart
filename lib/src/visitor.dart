import 'package:webidl2/src/ast.dart';

/// Visitor interface for the WebIDL AST.
abstract class Visitor<T> {
  T visitWebIdlFile(WebIdlFile file);

  T visitInterface(Interface interface);

  T visitPartialInterface(PartialInterface partialInterface);

  T visitDictionary(Dictionary dictionary);

  T visitEnumeration(Enumeration enumDef);

  T visitTypeDefinition(TypeDefinition typedef);

  T visitCallback(Callback callback);

  T visitCallbackInterface(CallbackInterface callbackInterface);

  T visitAttribute(Attribute attribute);

  T visitOperation(Operation operation);

  T visitConstant(Constant constant);

  T visitDictionaryMember(DictionaryMember member);
}
