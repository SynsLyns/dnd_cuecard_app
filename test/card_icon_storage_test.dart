import 'package:dnd_cuecard_app/logic/card_icon_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('CardIconStorage', () {
    test(
      'reduces a legacy Windows absolute path to a portable relative path',
      () {
        expect(
          CardIconStorage.toStoredPath(
            r'C:\Users\natha\AppData\Roaming\dnd_cuecard_app\images\038bb3268899d2fbfb878beb65be9b7b.png',
          ),
          'images/038bb3268899d2fbfb878beb65be9b7b.png',
        );
      },
    );

    test(
      'resolves a relative icon path against the current support directory',
      () {
        final supportDirectory = p.join(
          'Users',
          'current',
          'AppData',
          'Roaming',
          'dnd_cuecard_app',
        );
        expect(
          CardIconStorage.resolvePath('images/example.png', supportDirectory),
          p.join(supportDirectory, 'images', 'example.png'),
        );
      },
    );

    test('leaves unrelated paths unchanged', () {
      expect(
        CardIconStorage.toStoredPath('assets/example.png'),
        'assets/example.png',
      );
      expect(CardIconStorage.resolvePath(null, 'support'), isNull);
    });
  });
}
