import 'package:dnd_cuecard_app/models/initiative_app_state.dart';
import 'package:dnd_cuecard_app/models/initiative_item.dart';
import 'package:dnd_cuecard_app/screens/initiative_tracker_view.dart';
import 'package:dnd_cuecard_app/theme/app_colors.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('keeps HP values and controls visible on an empty HP bar', (
    tester,
  ) async {
    final state = InitiativeAppState()
      ..initiativeItems = [
        InitiativeItem(
          name: 'Guard',
          initiative: 12,
          capacity: 1,
          cooldown: 2,
          hp: 0,
          maxHp: 24,
          toggleState: true,
          cd1State: 1,
          visibility: InitiativeVisibility.full,
        ),
      ];

    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      state.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<InitiativeAppState>.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const InitiativeTrackerView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final currentHp = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('hp-Guard-24')),
        matching: find.byType(TextField),
      ),
    );
    final maxHp = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('maxhp-Guard')),
        matching: find.byType(TextField),
      ),
    );
    expect(currentHp.decoration?.filled, isFalse);
    expect(maxHp.decoration?.filled, isFalse);
    expect(currentHp.decoration?.border, InputBorder.none);
    expect(maxHp.decoration?.border, InputBorder.none);
    expect(currentHp.style?.color, AppColors.ground);
    expect(maxHp.style?.color, AppColors.ground);
    expect(currentHp.style?.shadows, hasLength(4));
    expect(maxHp.style?.shadows, hasLength(4));
    final divider = tester.widget<Text>(find.text('/'));
    expect(divider.style?.color, AppColors.ground);
    expect(divider.style?.shadows, hasLength(4));

    final toggleCircle = tester.widget<Container>(
      find.byKey(const ValueKey('toggle-indicator-Guard')),
    );
    expect((toggleCircle.decoration! as BoxDecoration).color, Colors.orange);
    final cd1Circle = tester.widget<Container>(
      find.byKey(const ValueKey('cd1-indicator-Guard')),
    );
    expect((cd1Circle.decoration! as BoxDecoration).color, Colors.cyan);

    final healthBar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(healthBar.color, AppColors.matcha);
    expect(healthBar.backgroundColor, AppColors.sage);
    expect(find.text('Next Turn'), findsOneWidget);
  });
}
