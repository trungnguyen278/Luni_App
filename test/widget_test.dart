import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luni_app/app.dart';

void main() {
  testWidgets('shows Luni login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuniApp()));
    await tester.pumpAndSettle();

    expect(find.text('Luni'), findsOneWidget);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('can sign in and show device list', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuniApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Nhà của Bạn'), findsOneWidget);
    expect(find.text('Luni Phòng khách'), findsOneWidget);
  });
}
