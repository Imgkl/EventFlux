import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App renders with Connect button', (WidgetTester tester) async {
    await tester.pumpWidget(const EventFluxDemoApp());

    expect(find.text('EventFlux SSE Demo'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });
}
