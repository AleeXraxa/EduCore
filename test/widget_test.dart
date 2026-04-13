// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:educore/src/app/app.dart';

void main() {
  testWidgets('App shows splash then login', (WidgetTester tester) async {
    await tester.pumpWidget(const EduCoreApp());

    // Splash renders first.
    expect(find.text('EduCore'), findsOneWidget);

    // After splash delay, it should navigate to login.
    await tester.pump(const Duration(milliseconds: 5200));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
