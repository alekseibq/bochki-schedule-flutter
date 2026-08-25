import 'package:test/test.dart';

void main() {
  test('temporary CI failure probe', () {
    fail('Intentional failure for issue #135 CI verification.');
  });
}
