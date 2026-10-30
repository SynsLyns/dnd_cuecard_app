import 'package:dnd_cuecard_app/player/player_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a campaign code from the app hash route', () {
    final uri = Uri.parse('https://cards.example.com/#/join?code=JOIN123');

    expect(campaignJoinCodeFromUri(uri), 'JOIN123');
  });

  test('does not treat an OAuth callback code as a campaign code', () {
    final uri = Uri.parse(
      'https://cards.example.com/?code=temporary-oauth-code',
    );

    expect(campaignJoinCodeFromUri(uri), isNull);
  });

  test('supports an explicit campaign join_code query parameter', () {
    final uri = Uri.parse('https://cards.example.com/?join_code=JOIN456');

    expect(campaignJoinCodeFromUri(uri), 'JOIN456');
  });
}
