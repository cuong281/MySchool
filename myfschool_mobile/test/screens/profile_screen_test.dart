import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfschools/screens/profilepage.dart';
import 'package:myfschools/services/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserSession.instance.clear();
  });

  group('ProfileScreen Tests', () {
    testWidgets('ProfileScreen renders cleanly for Admin without mock data or clipping', (tester) async {
      await UserSession.instance.setUser({
        'userId': 1,
        'username': 'admin',
        'email': 'admin@myfschool.vn',
        'firstName': '',
        'lastName': '',
        'phoneNumber': '0909999999',
        'roles': ['Admin'],
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump();

      // Verify title and admin role badge
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.text('Quản trị viên'), findsWidgets);
      expect(find.text('@admin'), findsOneWidget);

      // Verify Admin specific account section
      expect(find.text('Thông tin tài khoản'), findsOneWidget);
      expect(find.text('admin@myfschool.vn'), findsOneWidget);
      expect(find.text('0909999999'), findsOneWidget);

      // Ensure NO student mock strings are present
      expect(find.text('MS Hsinh'), findsNothing);
      expect(find.text('Thông tin học tập'), findsNothing);
      expect(find.text('FPT HN – Hòa Lạc'), findsNothing);
      expect(find.text('K17 (2021–2025)'), findsNothing);
      expect(find.text('Chưa cập nhật'), findsNothing);
    });

    testWidgets('ProfileScreen renders cleanly for Teacher without student mock data', (tester) async {
      await UserSession.instance.setUser({
        'userId': 8,
        'username': 'teacher_han',
        'email': 'han@myfschool.vn',
        'firstName': 'Ngoc Han',
        'lastName': 'Nguyen',
        'phoneNumber': '0901000001',
        'roles': ['Teacher'],
        'teacherId': 1,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump();

      // Verify Teacher role badge and name
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.text('Giáo viên'), findsWidgets);
      expect(find.text('@teacher_han'), findsOneWidget);
      expect(find.text('Nguyen Ngoc Han'), findsWidgets);

      // Verify Teacher work section
      expect(find.text('Thông tin công tác'), findsOneWidget);
      expect(find.text('GV001'), findsOneWidget);
      expect(find.text('han@myfschool.vn'), findsOneWidget);

      // Ensure NO student mock strings are present
      expect(find.text('MS Hsinh'), findsNothing);
      expect(find.text('Thông tin học tập'), findsNothing);
      expect(find.text('FPT HN – Hòa Lạc'), findsNothing);
      expect(find.text('K17 (2021–2025)'), findsNothing);
    });

    testWidgets('ProfileScreen renders cleanly for Student without hardcoded mock data', (tester) async {
      await UserSession.instance.setUser({
        'userId': 2,
        'username': 'student_a',
        'email': 'nguyenvana@myfschool.vn',
        'firstName': 'Van A',
        'lastName': 'Nguyen',
        'phoneNumber': '0901111111',
        'roles': ['Student'],
        'studentId': 1,
        'studentCode': 'HS2025001',
        'classId': 1,
        'className': '10A1',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pump();

      // Verify Student role badge, name, studentCode
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.text('Học sinh'), findsWidgets);
      expect(find.text('@student_a'), findsOneWidget);
      expect(find.text('Nguyen Van A'), findsWidgets);

      // Verify Student info
      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('HS2025001'), findsOneWidget);
      expect(find.text('nguyenvana@myfschool.vn'), findsOneWidget);
      expect(find.text('10A1'), findsWidgets);

      // Ensure NO fake campus or mock K17
      expect(find.text('FPT HN – Hòa Lạc'), findsNothing);
      expect(find.text('K17 (2021–2025)'), findsNothing);
      expect(find.text('Chưa cập nhật'), findsNothing);
    });
  });
}
