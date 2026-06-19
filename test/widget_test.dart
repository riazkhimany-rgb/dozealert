import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/main.dart';

void main() {
  testWidgets('DozeAlert shows home and settings tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const DozeAlertApp());
    await tester.pumpAndSettle();

    expect(find.text('DozeAlert'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('No destination selected'), findsOneWidget);
    expect(find.text('Choose Destination'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start Monitoring'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Wake-Up Radius'), findsOneWidget);
    expect(find.text('1000m'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start Monitoring'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });
}
