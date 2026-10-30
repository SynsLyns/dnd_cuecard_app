import 'package:dnd_cuecard_app/player/models/player_initiative.dart';
import 'package:dnd_cuecard_app/player/widgets/player_initiative_panel.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders read-only desktop-style initiative at phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final encounter = PlayerInitiativeEncounter(
      combatants: [
        const PlayerInitiativeCombatant(
          name: 'Guard',
          initiative: 18,
          visibility: 'full',
          healthStatus: 'Down',
          isCurrent: true,
          hp: 0,
          maxHp: 24,
          exhaustion: 2,
          concentration: true,
          reactionUsed: false,
          capacity: 2,
          cooldown: 3,
          cooldownTimers: [0, 2],
        ),
        const PlayerInitiativeCombatant(
          name: 'Hidden Details',
          initiative: 10,
          visibility: 'limited',
          healthStatus: 'Bloodied',
          isCurrent: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlayerInitiativePanel(encounter: encounter, compact: true),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Current turn'), findsOneWidget);
    expect(find.text('0 / 24 HP'), findsOneWidget);
    expect(find.text('Bloodied'), findsOneWidget);
    expect(find.text('Hidden Details'), findsOneWidget);
    expect(find.text('Exhaustion  2'), findsOneWidget);
    expect(find.text('Cooldown 3 turns'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(IconButton), findsNothing);

    final healthBar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(healthBar.value, 0);
    expect(healthBar.color, AppColors.rule);
    expect(healthBar.backgroundColor, AppColors.sage);

    final currentTurnCard = tester.widget<Container>(
      find.byKey(const ValueKey('initiative-card-Guard')),
    );
    expect((currentTurnCard.decoration! as BoxDecoration).border, isNotNull);
  });
}
