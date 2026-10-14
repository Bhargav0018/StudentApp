import 'package:flutter_test/flutter_test.dart';

import 'package:portfolio/main.dart';

void main() {
  testWidgets('Student Help Community portfolio loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudentHelpPortfolioApp());

    expect(find.text('Student Help Community'), findsWidgets);

    expect(find.text('About the project'), findsOneWidget);
  });
}
