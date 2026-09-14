import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfschools/screens/create_request_screen.dart';
import 'package:myfschools/services/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserSession.instance.clear();
    await UserSession.instance.setUser({
      'userId': 1,
      'username': 'student_test',
      'email': 'student@myfschool.vn',
      'firstName': 'Nguyen',
      'lastName': 'Van A',
      'roles': ['Student'],
      'studentId': 10,
    });
  });

  Widget buildApp() {
    return const MaterialApp(
      home: CreateRequestScreen(),
    );
  }

  group('CreateRequestScreen Validation Tests', () {
    testWidgets('Trường hợp 20 dấu cách: Không tính độ dài và không cho phép gửi', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Nhập 20 khoảng trắng
      await tester.enterText(textField, '                    ');
      await tester.pump();

      // Kiểm tra: Phải hiển thị 0 / 10 ký tự tối thiểu, KHÔNG được hiện 20 / 10
      expect(find.text('0 / 10 ký tự tối thiểu'), findsOneWidget);
      expect(find.textContaining('20 / 10'), findsNothing);
      expect(find.textContaining('Đã đạt yêu cầu'), findsNothing);

      // Bấm Gửi đơn
      await tester.tap(find.text('Gửi đơn'));
      await tester.pump();

      // Kiểm tra thông báo lỗi
      expect(find.text('Vui lòng nhập lý do nghỉ học (không được để trống)'), findsOneWidget);
    });

    testWidgets('Trường hợp ít hơn 10 ký tự: Báo số ký tự cần thêm cụ thể', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Nhập "Em bị ốm" (8 ký tự)
      await tester.enterText(textField, 'Em bị ốm');
      await tester.pump();

      expect(find.text('8 / 10 ký tự (cần thêm 2 ký tự)'), findsOneWidget);
      expect(find.textContaining('Đã đạt yêu cầu'), findsNothing);

      // Bấm Gửi đơn
      await tester.tap(find.text('Gửi đơn'));
      await tester.pump();

      expect(find.text('Lý do nghỉ học cần tối thiểu 10 ký tự có nghĩa (hiện có 8 ký tự)'), findsOneWidget);
    });

    testWidgets('Trường hợp nhập chữ kèm nhiều khoảng trắng thừa: Thu gọn khoảng trắng chính xác', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // "  Em       bị ốm    " -> Chuẩn hóa là "Em bị ốm" (8 ký tự)
      await tester.enterText(textField, '  Em       bị ốm    ');
      await tester.pump();

      expect(find.text('8 / 10 ký tự (cần thêm 2 ký tự)'), findsOneWidget);
      expect(find.textContaining('Đã đạt yêu cầu'), findsNothing);
    });

    testWidgets('Trường hợp chỉ gõ ký tự đặc biệt vô nghĩa: Cảnh báo cần có chữ cái', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Nhập 15 dấu chấm
      await tester.enterText(textField, '...............');
      await tester.pump();

      expect(find.text('Vui lòng nhập lý do có nghĩa (chứa chữ cái)'), findsOneWidget);

      await tester.tap(find.text('Gửi đơn'));
      await tester.pump();

      expect(find.text('Lý do nghỉ học phải chứa chữ cái hoặc thông tin cụ thể'), findsOneWidget);
    });

    testWidgets('Trường hợp spam lặp lại 1 ký tự: Cảnh báo không được lặp ký tự', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Nhập "aaaaaaaaaaaaa"
      await tester.enterText(textField, 'aaaaaaaaaaaaa');
      await tester.pump();

      expect(find.text('Vui lòng không nhập lặp lại một ký tự'), findsOneWidget);

      await tester.tap(find.text('Gửi đơn'));
      await tester.pump();

      expect(find.text('Lý do nghỉ học không hợp lệ, vui lòng không lặp lại một ký tự'), findsOneWidget);
    });

    testWidgets('Trường hợp nhập lý do hợp lệ >= 10 ký tự: Đạt yêu cầu và hiển thị xanh', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Nhập lý do hợp lệ
      await tester.enterText(textField, 'Em bị sốt cao cần xin nghỉ học 1 ngày');
      await tester.pump();

      expect(find.textContaining('Đã đạt yêu cầu'), findsOneWidget);
      expect(find.textContaining('37 / 10 ký tự (Đã đạt yêu cầu)'), findsOneWidget);
    });
  });
}
