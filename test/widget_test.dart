import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestureappflutter/main.dart';

void main() {
  testWidgets('VolumeTilt shows initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.textContaining('Volume: 50'), findsOneWidget);  // Iniziale 0.5
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Tilt X: 0.0'), findsOneWidget);
  });
}