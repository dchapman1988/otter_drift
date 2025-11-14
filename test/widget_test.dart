// Basic app widget test
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OtterDriftApp());

    // Verify app is built
    expect(find.byType(OtterDriftApp), findsOneWidget);
  });
}
