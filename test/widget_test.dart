import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store_app_x/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Splash shows T&N logo', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ManHinhChao()));

    // Kiểm tra chữ T&N xuất hiện
    expect(find.text('T&N'), findsOneWidget);
  });
}
