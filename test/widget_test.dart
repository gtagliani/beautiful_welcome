import 'package:flutter_test/flutter_test.dart';
import 'package:beautiful_welcome/main.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeautifulWelcomeApp());

    // Verify that our get started button exists.
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Welcome to\nBeautiful Flutter App'), findsOneWidget);
  });
}
