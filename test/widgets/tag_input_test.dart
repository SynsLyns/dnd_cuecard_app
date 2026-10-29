import 'package:dnd_cuecard_app/models/tag.dart';
import 'package:dnd_cuecard_app/widgets/tag/tag_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wraps selected tags above the add-tag input', (tester) async {
    const width = 240.0;
    final tags = [
      Tag(name: 'Water Magic'),
      Tag(name: 'Spell'),
      Tag(name: 'Common'),
      Tag(name: 'Intermediate Water Magic'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: TagInputField(selectedTags: tags, suggestions: const []),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final tag in tags) {
      expect(find.text(tag.name), findsOneWidget);
    }

    final lastTag = tester.getRect(find.text('Intermediate Water Magic'));
    final input = tester.getRect(find.byType(TextField));
    expect(lastTag.bottom, lessThanOrEqualTo(input.top));
    expect(input.width, lessThan(width));
    expect(input.width, greaterThan(width - 48));
  });
}
