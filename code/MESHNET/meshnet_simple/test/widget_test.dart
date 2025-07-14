// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshnet_simple/main.dart';

void main() {
  testWidgets('MESHNET app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MeshNetApp());

    // Verify that our app starts with the correct title.
    expect(find.text('MESHNET Emergency Chat'), findsOneWidget);
    expect(find.text('ACIL DURUM MESH NETWORK'), findsOneWidget);

    // Add a message.
    await tester.enterText(find.byType(TextField), 'Test mesajı');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify that our message appears.
    expect(find.text('Test mesajı'), findsOneWidget);
    
    // Wait for timer to complete
    await tester.pump(Duration(seconds: 3));
    
    // Verify system response appears
    expect(find.textContaining('MESHNET Sistem'), findsOneWidget);
  });
}
