import 'package:dnd_cuecard_app/player/models/player_shared_card.dart';
import 'package:dnd_cuecard_app/player/widgets/player_shared_card_tile.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final card = PlayerSharedCard.fromMap({
    'id': 'shared-card',
    'payload': {
      'title': 'Beginner Water Magic',
      'requirements': '12',
      'description': 'A single target within range takes 1d8 water damage.',
      'notes': 'The spellcaster aims a ball of water at the target.',
      'box1': '15ft',
      'box2': '∞',
      'type_name': 'Spell',
      'type_color': 4282332457,
      'rarity_name': 'Common',
      'rarity_color': 4294638330,
      'tags': ['Water'],
    },
  });

  testWidgets('shows metadata above a desktop-style expanded card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            AppTypography(
              bonaNovaSC: TextStyle(fontFamily: 'BonaNovaSC', fontSize: 20),
            ),
          ],
        ),
        home: Scaffold(
          body: ListView(
            children: [
              PlayerSharedCardTile(
                card: card,
                hasUpdated: false,
                onExpanded: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Beginner Water Magic'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Spell'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(
      find.text('A single target within range takes 1d8 water damage.'),
      findsOneWidget,
    );
    expect(
      find.text('The spellcaster aims a ball of water at the target.'),
      findsOneWidget,
    );
    expect(find.text('15ft'), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
    expect(find.byTooltip('Collapse card'), findsOneWidget);
    final iconClip = tester.widget<ClipRRect>(
      find.byKey(const ValueKey('shared-card-icon-clip-52.0')),
    );
    expect(iconClip.borderRadius, BorderRadius.circular(11));
    final expansion = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
    expect(expansion.duration, const Duration(milliseconds: 160));
  });

  testWidgets('expands without overflow at phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            AppTypography(
              bonaNovaSC: TextStyle(fontFamily: 'BonaNovaSC', fontSize: 20),
            ),
          ],
        ),
        home: Scaffold(
          body: ListView(
            children: [
              PlayerSharedCardTile(
                card: card,
                hasUpdated: false,
                onExpanded: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Beginner Water Magic'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('A single target within range takes 1d8 water damage.'),
      findsOneWidget,
    );
  });
}
