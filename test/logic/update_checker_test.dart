import 'package:dnd_cuecard_app/logic/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UpdateChecker.isVersionNewer', () {
    test('compares major, minor, and patch numerically', () {
      expect(UpdateChecker.isVersionNewer('1.10.0', '1.9.9'), isTrue);
      expect(UpdateChecker.isVersionNewer('2.0.0', '1.99.99'), isTrue);
      expect(UpdateChecker.isVersionNewer('1.2.4', '1.2.3'), isTrue);
      expect(UpdateChecker.isVersionNewer('1.2.3', '1.2.4'), isFalse);
    });

    test('ignores a build number and fourth version segment', () {
      expect(UpdateChecker.isVersionNewer('0.0.2.4', '0.0.2+3'), isFalse);
      expect(UpdateChecker.isVersionNewer('0.0.3.0', '0.0.2+3'), isTrue);
    });

    test('rejects malformed versions', () {
      expect(UpdateChecker.isVersionNewer('1.2', '1.1.9'), isFalse);
      expect(UpdateChecker.isVersionNewer('1.x.3', '1.1.2'), isFalse);
    });
  });

  group('UpdateChecker.checkForUpdate', () {
    test('returns a newer hosted version', () async {
      final checker = UpdateChecker(
        client: MockClient((request) async {
          expect(request.url, Uri.parse(latestJsonUrl));
          return http.Response('{"version":"0.0.3"}', 200);
        }),
        currentVersion: () async => '0.0.2',
      );
      addTearDown(checker.dispose);

      expect(await checker.checkForUpdate(), '0.0.3');
    });

    test('ignores network errors', () async {
      final checker = UpdateChecker(
        client: MockClient((_) async => throw http.ClientException('offline')),
        currentVersion: () async => '0.0.2',
      );
      addTearDown(checker.dispose);

      expect(await checker.checkForUpdate(), isNull);
    });
  });
}
