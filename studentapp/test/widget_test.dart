import 'package:flutter_test/flutter_test.dart';

import 'package:studentapp/main.dart';

void main() {
  testWidgets('Student Help Community App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentHelpCommunityApp());

    expect(find.text('Student Help'), findsOneWidget);
  });
}
