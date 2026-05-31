import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luni_app/app.dart';

void main() {
  // The login screen shows an always-animating LuniFace (in the wordmark), so
  // we use bounded pumps rather than pumpAndSettle, and dispose the tree at the
  // end so no ticker/timer is left pending.
  Future<void> bootLogin(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuniApp()));
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 400)); // ScreenIn settle
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('shows Luni login screen', (WidgetTester tester) async {
    await bootLogin(tester);

    expect(find.text('Luni'), findsOneWidget);
    expect(find.text('Chào mừng\ntrở lại'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('signing in with empty fields shows a validation error',
      (WidgetTester tester) async {
    await bootLogin(tester);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pump(); // run the (synchronous) validation + rebuild
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Nhập email và mật khẩu để đăng nhập.'),
      findsOneWidget,
    );

    await teardown(tester);
  });
}
