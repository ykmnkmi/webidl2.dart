import 'package:webidl2/webidl2.dart';

void main() {
  // Example WebIDL input
  var webidlSource = '''
[Constructor(DOMString url), Exposed=Window]
interface Example {};''';

  // Parse the WebIDL
  try {
    var result = parseWebIdl(webidlSource, strictMode: true);
    print(result.generateIdl());
  } catch (error) {
    print('Error: $error');
  }
}
