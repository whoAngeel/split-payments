import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openpayments_app/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OpenPaymentsApp()));
    expect(find.byType(OpenPaymentsApp), findsOneWidget);
  });
}
