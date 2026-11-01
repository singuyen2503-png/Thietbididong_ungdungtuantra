import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/presentation/features/auth/login_screen.dart';
import 'package:demo_app/presentation/features/dashboard/guard_dashboard_screen.dart';
import 'package:demo_app/presentation/features/dashboard/manager_dashboard_screen.dart';

Widget _harness() =>
    const ProviderScope(child: MaterialApp(home: LoginScreen()));

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Kiểm tra render UI ban đầu (Empty State)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());

      expect(find.text('HỆ THỐNG XÁC THỰC'), findsOneWidget);
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('Nhập sai PIN hiển thị Loading rồi báo lỗi (Error State)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await _enterPin(tester, '9999');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('TỪ CHỐI TRUY CẬP'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Nút xóa bỏ chữ số vừa nhập', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await _enterPin(tester, '123');
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      await _enterPin(tester, '59');
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('TỪ CHỐI TRUY CẬP'), findsOneWidget);
    });

    testWidgets('PIN 1234 vào Dashboard Bảo vệ', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await _enterPin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(GuardDashboardScreen), findsOneWidget);
      expect(find.text('Tuyến: Tuyến Trung tâm 59'), findsOneWidget);
    });

    testWidgets('PIN 5678 vào Trung tâm Chỉ huy', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await _enterPin(tester, '5678');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(ManagerDashboardScreen), findsOneWidget);
      expect(find.text('TRUNG TÂM CHỈ HUY'), findsOneWidget);
    });

    testWidgets('PIN riêng 3456 vào đúng tài khoản Lê Văn C',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness());
      await _enterPin(tester, '3456');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(GuardDashboardScreen), findsOneWidget);
      expect(find.text('Lê Văn C'), findsOneWidget);
      expect(find.text('ĐANG ĐI TUẦN'), findsOneWidget);
    });
  });
}
