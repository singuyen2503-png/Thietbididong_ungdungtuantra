import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:demo_app/presentation/features/management/route_list_screen.dart';

void main() {
  testWidgets('Mở lộ trình hiển thị mã QR cho từng điểm', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RouteListScreen())));
    expect(find.text('Tuyến tuần tra mẫu'), findsOneWidget);

    await tester.tap(find.text('Tuyến tuần tra mẫu'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsNWidgets(3));
    expect(find.text('Mã: nhà kho'), findsOneWidget);
    expect(find.text('3. Hành Lang'), findsOneWidget);
  });

  testWidgets('Không cho xóa lộ trình đang có lịch tuần tra', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RouteListScreen())));
    await tester.drag(find.text('Tuyến tuần tra mẫu'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Lộ trình đang được dùng trong lịch tuần tra, không thể xóa!'),
        findsOneWidget);
    expect(find.text('Tuyến tuần tra mẫu'), findsOneWidget);
  });
}
