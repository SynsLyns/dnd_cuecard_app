import 'package:dnd_cuecard_app/models/card_type.dart';
import 'package:dnd_cuecard_app/theme/app_theme.dart';
import 'package:dnd_cuecard_app/widgets/categorizable_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the selected value when the field loses focus', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Water');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 240,
                child: CategorizableDropdownMenu<CardType>(
                  label: 'Card Type',
                  controller: controller,
                  values: const [
                    CardType(name: 'Water', color: Colors.blue),
                    CardType(name: 'Fire', color: Colors.red),
                  ],
                  onValueChanged: (_) {},
                ),
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    );

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.pump();
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(controller.text, 'Water');
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
