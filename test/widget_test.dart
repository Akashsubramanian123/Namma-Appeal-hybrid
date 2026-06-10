import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your isolated legal screen
import 'package:namma_appeal/legal_screen.dart'; // Adjust 'namma_appeal' if your pubspec.yaml name is different

void main() {
  testWidgets('LegalScreen renders privacy policy and terms correctly', (WidgetTester tester) async {
    // 1. Pump the isolated widget into the test environment
    await tester.pumpWidget(const MaterialApp(
      home: LegalScreen(),
    ));

    // 2. Wait for the Markdown to finish rendering
    await tester.pumpAndSettle();

    // 3. Assert that the AppBar title exists
    expect(find.text('Privacy & Terms'), findsOneWidget);

    // 4. Assert that the Markdown Body parsed the headers correctly
    expect(find.textContaining('Privacy Policy'), findsWidgets);
    expect(find.textContaining('Terms of Service'), findsWidgets);
    
    // 5. Assert that the back button is present
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}