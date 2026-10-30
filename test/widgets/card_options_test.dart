import 'package:dnd_cuecard_app/app_state.dart';
import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/widgets/card_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('keeps metadata values aligned in narrow layouts', (
    tester,
  ) async {
    const width = 480.0;
    final appState = AppState();
    final controllers = CueCardFormControllers()
      ..cardTypeController.text = 'Spell'
      ..rarityController.text = 'Common'
      ..tags = [Tag(name: 'Water')];

    await tester.binding.setSurfaceSize(const Size(width, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      controllers.dispose();
      appState.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: CardOptions(
                controllers: controllers,
                onCardTypeChanged: (_) {},
                onRarityChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('RARITY'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('add-tag-input-container')))
          .height,
      36,
    );

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields, hasLength(2));
    final fieldRects = tester.getRect(find.byType(TextFormField).first);
    final rarityRect = tester.getRect(find.byType(TextFormField).last);
    expect(fieldRects.left, closeTo(rarityRect.left, 0.1));

    final dividers = tester.getRect(find.byType(Divider).first);
    final bottomDivider = tester.getRect(find.byType(Divider).last);
    final typeCenter = tester.getCenter(find.text('TYPE'));
    final tagsCenter = tester.getCenter(find.text('TAGS'));
    expect(
      dividers.center.dy - typeCenter.dy,
      closeTo(tagsCenter.dy - bottomDivider.center.dy, 0.1),
    );
  });

  testWidgets('removes redundant bottom spacing after read-only tags', (
    tester,
  ) async {
    const width = 800.0;
    final appState = AppState();
    final controllers = CueCardFormControllers()
      ..cardTypeController.text = 'Spell'
      ..rarityController.text = 'Common'
      ..tags = [Tag(name: 'Water')];

    await tester.binding.setSurfaceSize(const Size(width, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      controllers.dispose();
      appState.dispose();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: CardOptions(
                controllers: controllers,
                onCardTypeChanged: (_) {},
                onRarityChanged: (_) {},
                readOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final tagsRow = tester.getSize(
      find.byKey(const ValueKey('card-options-tags-row')),
    );
    expect(tagsRow.height, 56);
    final tagsCenter = tester.getCenter(find.text('Water'));
    final tagsLabelCenter = tester.getCenter(find.text('TAGS'));
    expect(tagsCenter.dy, closeTo(tagsLabelCenter.dy, 0.1));
  });
}
