import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: EFordoApp(),
      ),
    );

    expect(find.text('eFordo'), findsOneWidget);
  });
}
