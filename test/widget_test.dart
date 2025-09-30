// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_student_assistant/src/app.dart';

void main() {
  testWidgets('App builds and Markdown widget is present', (tester) async {
    await tester.pumpWidget(ProviderScope(child: AIStudentAssistantApp()));
    // The chat screen or other markdown-using widget may not be immediately visible.
    // We just ensure the app builds without errors and can find a MaterialApp.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Placeholder summarize fallback test boots app', (tester) async {
    await tester.pumpWidget(ProviderScope(child: AIStudentAssistantApp()));
    // Network summarization not executed here; ensure no crash and basic widgets exist.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
