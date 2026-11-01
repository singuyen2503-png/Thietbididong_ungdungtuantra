import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/presentation/features/management/personnel_screen.dart';

void main() {
  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PersonnelScreen())));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
  }

  testWidgets('Số điện thoại sai định dạng bị từ chối', (tester) async {
    await openForm(tester);
    await fill(tester, 'Họ và tên', 'Phạm Văn D');
    await fill(tester, 'Mã nhân viên (tài khoản)', 'guard_d');
    await fill(tester, 'Số điện thoại (10 số)', '12345');
    await fill(tester, 'Tuổi', '30');
    await tester.tap(find.text('LƯU'));
    await tester.pump();

    expect(find.text('Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0!'),
        findsOneWidget);
    expect(find.text('THÊM NHÂN SỰ MỚI'), findsOneWidget);
  });

  testWidgets('Mã nhân viên trùng bị từ chối', (tester) async {
    await openForm(tester);
    await fill(tester, 'Họ và tên', 'Phạm Văn D');
    await fill(tester, 'Mã nhân viên (tài khoản)', 'guard_a');
    await fill(tester, 'Số điện thoại (10 số)', '0912345678');
    await fill(tester, 'Tuổi', '30');
    await tester.tap(find.text('LƯU'));
    await tester.pump();

    expect(find.text('Mã nhân viên đã tồn tại!'), findsOneWidget);
  });

  testWidgets('Dữ liệu hợp lệ thêm vào danh sách', (tester) async {
    await openForm(tester);
    await fill(tester, 'Họ và tên', 'Phạm Văn D');
    await fill(tester, 'Mã nhân viên (tài khoản)', 'guard_d');
    await fill(tester, 'Số điện thoại (10 số)', '0912345678');
    await fill(tester, 'Tuổi', '30');
    await fill(tester, 'Mã PIN đăng nhập (4 số)', '4567');
    await tester.tap(find.text('LƯU'));
    await tester.pumpAndSettle();

    expect(find.text('THÊM NHÂN SỰ MỚI'), findsNothing);
    expect(find.text('Phạm Văn D'), findsOneWidget);
  });

  testWidgets('Vuốt ngang + xác nhận để xóa nhân sự', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PersonnelScreen())));

    await tester.drag(find.text('Lê Văn C'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XÓA'));
    await tester.pumpAndSettle();

    expect(find.text('Lê Văn C'), findsNothing);
  });

  testWidgets('Mã PIN trùng với bảo vệ khác bị từ chối', (tester) async {
    await openForm(tester);
    await fill(tester, 'Họ và tên', 'Phạm Văn D');
    await fill(tester, 'Mã nhân viên (tài khoản)', 'guard_d');
    await fill(tester, 'Số điện thoại (10 số)', '0912345678');
    await fill(tester, 'Tuổi', '30');
    await fill(tester, 'Mã PIN đăng nhập (4 số)', '1234');
    await tester.tap(find.text('LƯU'));
    await tester.pump();

    expect(
        find.text('Mã PIN đã được sử dụng, hãy chọn mã khác!'), findsOneWidget);
  });
}
