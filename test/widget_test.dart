// Basic app widget test
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const OtterDriftApp());

    // App should build without throwing.
    expect(find.byType(OtterDriftApp), findsOneWidget);
  });
}
