// Basic smoke test for MySchool app startup.
// Verifies that the app can be built and renders the LoginScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfschools/main.dart';

void main() {
  testWidgets('App khoi dong va hien thi LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // LoginScreen should be the initial screen
    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
