import 'package:flutter_test/flutter_test.dart';
import 'package:solana_idl_example/main.dart';

void main() {
  testWidgets('builds two generated instructions', (tester) async {
    await tester.pumpWidget(const GeneratorExampleApp());
    await tester.tap(find.text('Build instructions'));
    await tester.pump();
    expect(find.textContaining('Application transaction: 2'), findsOneWidget);
  });
}
