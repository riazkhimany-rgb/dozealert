import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/main.dart';

void main() {
  testWidgets('DozeAlert shows home and settings tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const DozeAlertApp());

    expect(find.text('DozeAlert'), findsOneWidget);
    expect(find.text('Wake up at the right stop'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });
}
