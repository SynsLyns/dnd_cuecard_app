import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/models/rarity.dart';
import 'package:dnd_cuecard_app/screens/cue_card_form_controllers.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:dnd_cuecard_app/widgets/cue_card/cue_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(1100, 700), const Size(390, 844)]) {
    testWidgets('cue card stays within layout at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controllers = CueCardFormControllers()
        ..titleController.text = 'Intermediate Water Magic of the Deep Currents'
        ..requirementsController.text = 'Within 30 feet'
        ..descriptionController.text =
            'A single target within range takes water damage. ' * 14
        ..notesController.text = 'The spellcaster calls on the currents. ' * 8
        ..box1Controller.text = '15ft'
        ..box2Controller.text = '∞';
      addTearDown(controllers.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: CueCardView(
                    controllers: controllers,
                    currentSelectedCardType: const CardType(
                      name: 'Water',
                      color: Color(0xFF25452E),
                    ),
                    currentSelectedRarity: const Rarity(
                      name: 'Common',
                      color: Color(0xFFC87532),
                    ),
                    image: null,
                    onImageSelected: (_) {},
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(controllers.titleController.text), findsOneWidget);
    });
  }
}
