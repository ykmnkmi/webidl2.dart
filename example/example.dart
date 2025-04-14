import 'package:webidl2/webidl2.dart';

void main() {
  // Example WebIDL input
  var webidlSource = '''
[Exposed=Window]
interface MyInterface {
  Promise<long> doSomething(DOMString name, long count);
};''';

  // Parse the WebIDL
  try {
    var tokenizer = Tokenizer(webidlSource);
    tokenizer.tokenize().forEach(print);
  } catch (error, trace) {
    print(error);
    print(trace);
  }
}
