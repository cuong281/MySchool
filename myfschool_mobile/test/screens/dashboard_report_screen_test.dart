import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfschools/screens/dashboard_report_screen.dart';
import 'package:myfschools/services/report_api.dart';
import 'package:myfschools/services/user_session.dart';

class FakeReportApi extends ReportApi {
  @override
  Future<Map<String, dynamic>?> getAdminDashboard({String? academicYear, int? semester}) async {
    if (semester == 2) {
      // Semester 2 has 0 'Yếu' to test flex: 0 safety!
      return {
        'academicYear': '2025-2026',
        'semester': 2,
        'totalStudents': 50,
        'totalTeachers': 8,
        'totalClasses': 2,
        'totalGrades': 150,
        'averageSchoolGpa': 8.32,
        'gradeDistribution': {
          'Xuất sắc': 8,
          'Giỏi': 21,
          'Khá': 17,
          'Trung bình': 4,
          'Yếu': 0, // 0 count! Must not crash Expanded(flex: 0)
        },
        'totalAttendanceRecords': 50,
        'presentCount': 47,
        'excusedAbsenceCount': 2,
        'unexcusedAbsenceCount': 1,
        'lateCount': 0,
        'attendanceRate': 94.0,
        'pendingLeaveRequests': 1,
        'approvedLeaveRequests': 13,
        'rejectedLeaveRequests': 1,
        'totalLeaveRequests': 15,
      };
    }

    // Default Semester 1
    return {
      'academicYear': '2025-2026',
      'semester': 1,
      'totalStudents': 50,
      'totalTeachers': 8,
      'totalClasses': 2,
      'totalGrades': 150,
      'averageSchoolGpa': 7.89,
      'gradeDistribution': {
        'Xuất sắc': 6,
        'Giỏi': 18,
        'Khá': 20,
        'Trung bình': 5,
        'Yếu': 1,
      },
      'totalAttendanceRecords': 50,
      'presentCount': 47,
      'excusedAbsenceCount': 2,
      'unexcusedAbsenceCount': 1,
      'lateCount': 0,
      'attendanceRate': 94.0,
      'pendingLeaveRequests': 1,
      'approvedLeaveRequests': 13,
      'rejectedLeaveRequests': 1,
      'totalLeaveRequests': 15,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserSession.instance.clear();
    ReportApi.instance = FakeReportApi();
  });

  group('DashboardReportScreen Widget Tests', () {
    testWidgets('Renders filter bar, overview cards, and handles 0 count in Segmented bar without error', (tester) async {
      await UserSession.instance.setUser({
        'userId': 1,
        'username': 'admin',
        'email': 'admin@myfschool.vn',
        'roles': ['Admin'],
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardReportScreen(),
        ),
      );

      // Loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump data load
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Báo cáo toàn trường'), findsOneWidget);

      // Verify Filter Bar: Year & Semester
      expect(find.text('Năm học 2025-2026'), findsOneWidget);
      expect(find.text('Học kỳ 1'), findsOneWidget);
      expect(find.text('Học kỳ 2'), findsOneWidget);

      // Verify Overview Cards: 50 Students, 8 Teachers, 2 Classes
      expect(find.text('Học sinh'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Giáo viên'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Lớp học'), findsOneWidget);
      expect(find.text('2'), findsWidgets);

      // Verify Attendance Today
      expect(find.text('Thống kê chuyên cần (Hôm nay)'), findsOneWidget);
      expect(find.text('94.0%'), findsOneWidget);
      expect(find.text('47'), findsOneWidget); // Present
      expect(find.text('2'), findsWidgets); // Excused & classes
      expect(find.text('1'), findsWidgets); // Unexcused & pending

      // Verify Grade Distribution in Semester 1
      expect(find.text('Thống kê học lực'), findsOneWidget);
      expect(find.text('ĐTB: 7.89'), findsOneWidget);
      expect(find.text('Xuất sắc: '), findsOneWidget);
      expect(find.text('6 (12%)'), findsOneWidget);
      expect(find.text('Giỏi: '), findsOneWidget);
      expect(find.text('18 (36%)'), findsOneWidget);

      // Verify Leave Requests
      expect(find.text('Tổng số đơn xin nghỉ'), findsOneWidget);
      expect(find.text('15 đơn'), findsOneWidget);
      expect(find.text('1 chờ duyệt'), findsOneWidget);

      // Switch to Semester 2 (Tests Note 1: flex: 0 safety and Note 2: smooth loading)
      await tester.tap(find.text('Học kỳ 2'));
      await tester.pumpAndSettle();

      // Verify updated stats for Semester 2
      expect(find.text('ĐTB: 8.32'), findsOneWidget);
      expect(find.text('8 (16%)'), findsOneWidget); // Xuất sắc
      expect(find.text('21 (42%)'), findsOneWidget); // Giỏi
      expect(find.text('17 (34%)'), findsOneWidget); // Khá
      expect(find.text('4 (8%)'), findsOneWidget); // Trung bình
      expect(find.text('0 (0%)'), findsOneWidget); // Yếu: 0 (No exception thrown!)
    });
  });
}
