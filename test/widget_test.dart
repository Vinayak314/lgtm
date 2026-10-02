import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';

void main() {
  testWidgets('app boots on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LgtmApp());
    await tester.pump();

    expect(find.text('LGTM'), findsOneWidget);
  });
}
