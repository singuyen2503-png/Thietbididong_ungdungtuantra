import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/presentation/features/incident/incident_report_screen.dart';
import 'package:demo_app/presentation/state/manager_state.dart';

void main() {
  late ProviderContainer container;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
        overrides: [currentGuardIdProvider.overrideWith((ref) => 'p3')]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IncidentReportScreen())));
  }

  testWidgets('Thiếu tiêu đề / mô tả bị từ chối', (tester) async {
    await open(tester);
    await tester.tap(find.text('TRUYỀN TIN CẢNH BÁO'));
    await tester.pump();
    expect(
        find.text('CẢNH BÁO: Vui lòng nhập Tiêu đề và Mô tả!'), findsOneWidget);
  });

  testWidgets('Mức KHẨN CẤP bắt buộc có ảnh', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Cháy kho');
    await tester.enterText(find.byType(TextField).at(1), 'Khói ở kho B');
    await tester.tap(find.text('KHẨN CẤP'));
    await tester.tap(find.text('TRUYỀN TIN CẢNH BÁO'));
    await tester.pump();
    expect(find.text('LỖI: Mức độ KHẨN CẤP bắt buộc phải đính kèm hình ảnh!'),
        findsOneWidget);
  });

  testWidgets('Báo cáo hợp lệ ghi đúng tên bảo vệ đang đăng nhập',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Cửa kho mở');
    await tester.enterText(
        find.byType(TextField).at(1), 'Cửa kho C không khóa');
    await tester.tap(find.text('TRUYỀN TIN CẢNH BÁO'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final incident = container.read(incidentsProvider).first;
    expect(incident.title, 'Cửa kho mở');
    expect(incident.reportedBy, 'Lê Văn C');
    expect(incident.imageBase64, isNull);
  });
}
