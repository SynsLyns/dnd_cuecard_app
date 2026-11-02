import 'package:dnd_cuecard_app/widgets/app_version_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the app version in a translucent bottom-left overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppVersionOverlay(
          versionLoader: () async => '0.0.2+3',
          child: const Scaffold(body: Text('App content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('v0.0.2+3'), findsOneWidget);
    final position = tester.widget<Positioned>(find.byType(Positioned));
    expect(position.left, 8);
    expect(position.bottom, 8);

    final label = tester.widget<Text>(find.text('v0.0.2+3'));
    expect(label.style?.color?.a, closeTo(0.45, 0.01));
    expect(
      find.ancestor(
        of: find.text('v0.0.2+3'),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
  });
}
