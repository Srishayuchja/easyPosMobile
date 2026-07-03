import 'package:flutter_test/flutter_test.dart';
import 'package:easy_pos_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyPosApp());
    await tester.pump();
    expect(find.byType(EasyPosApp), findsOneWidget);
  });
}
