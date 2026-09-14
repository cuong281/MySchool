import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfschools/screens/admin_request_list_screen.dart';
import 'package:myfschools/services/leave_request_api.dart';
import 'package:myfschools/services/user_session.dart';

class FakeLeaveRequestApi extends LeaveRequestApi {
  List<Map<String, dynamic>> requestsData = [];
  int? lastUpdatedId;
  String? lastUpdatedStatus;
  String? lastUpdatedNote;

  FakeLeaveRequestApi(this.requestsData);

  @override
  Future<List<Map<String, dynamic>>> getAllRequests() async {
    return requestsData;
  }

  @override
  Future<bool> updateStatus(
    int requestId,
    String status, [
    dynamic processedByUserIdOrNote,
    String? adminNote,
  ]) async {
    lastUpdatedId = requestId;
    lastUpdatedStatus = status;
    if (processedByUserIdOrNote is String) {
      lastUpdatedNote = processedByUserIdOrNote;
    } else if (adminNote != null) {
      lastUpdatedNote = adminNote;
    }
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockStudentRequests = [
    {
      'id': 101,
      'status': 'Chờ duyệt',
      'requestType': 'Xin nghỉ học',
      'studentName': 'Nguyễn Văn A',
      'studentCode': 'HS2025001',
      'className': '10A1',
      'fromDate': '2026-03-20',
      'toDate': '2026-03-20',
      'reason': 'Sốt nhẹ',
      'adminNote': null,
    },
    {
      'id': 102,
      'status': 'Đã duyệt',
      'requestType': 'Xin nghỉ học',
      'studentName': 'Trần Thị B',
      'studentCode': 'HS2025002',
      'className': '10A1',
      'fromDate': '2026-03-22',
      'toDate': '2026-03-23',
      'reason': 'Việc gia đình',
      'adminNote': 'Đã liên hệ phụ huynh xác nhận',
    },
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserSession.instance.clear();
  });

  Widget buildApp() {
    return const MaterialApp(
      home: AdminRequestListScreen(),
    );
  }

  group('AdminRequestListScreen Tests - Teacher Persona', () {
    setUp(() async {
      await UserSession.instance.setUser({
        'userId': 8,
        'username': 'teacher_han',
        'roles': ['Teacher'],
        'teacherId': 1,
      });
    });

    testWidgets('1. Displays card with class info: STUDENT · 10A1 · MSHS: HS2025001', (tester) async {
      LeaveRequestApi.instance = FakeLeaveRequestApi(mockStudentRequests);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Check STUDENT tag
      expect(find.text('STUDENT'), findsNWidgets(2));
      // Check 10A1 and MSHS: HS2025001
      expect(find.text('10A1 · MSHS: HS2025001'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Xin nghỉ học'), findsNWidgets(2));
      expect(find.text('Lý do: Sốt nhẹ'), findsOneWidget);
      expect(find.text('20/03/2026 → 20/03/2026'), findsOneWidget);
    });

    testWidgets('2. Pending request shows [Từ chối] and [Duyệt], approved request hides them', (tester) async {
      LeaveRequestApi.instance = FakeLeaveRequestApi(mockStudentRequests);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // 1 Pending card, 1 Approved card -> Exactly 1 [Từ chối] and 1 [Duyệt] button
      expect(find.widgetWithText(TextButton, 'Từ chối'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Duyệt'), findsOneWidget);

      // Approved card displays note
      expect(find.text('Ghi chú: Đã liên hệ phụ huynh xác nhận'), findsOneWidget);
    });

    testWidgets('3. Teacher taps [Duyệt] -> Shows confirm dialog and calls API', (tester) async {
      final fakeApi = FakeLeaveRequestApi(mockStudentRequests);
      LeaveRequestApi.instance = fakeApi;

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap [Duyệt] on card
      await tester.tap(find.widgetWithText(TextButton, 'Duyệt'));
      await tester.pumpAndSettle();

      // Confirmation dialog shows
      expect(find.text('Duyệt đơn xin phép'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn duyệt đơn xin phép của Nguyễn Văn A?'), findsOneWidget);

      // Confirm
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Duyệt');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(fakeApi.lastUpdatedId, 101);
      expect(fakeApi.lastUpdatedStatus, 'Đã duyệt');
    });

    testWidgets('4. Teacher taps [Từ chối] -> Validates note cannot be empty or whitespace only', (tester) async {
      final fakeApi = FakeLeaveRequestApi(mockStudentRequests);
      LeaveRequestApi.instance = fakeApi;

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap [Từ chối] on card
      await tester.tap(find.widgetWithText(TextButton, 'Từ chối'));
      await tester.pumpAndSettle();

      // Rejection dialog shows
      expect(find.text('Từ chối đơn xin phép'), findsOneWidget);

      // Tap submit with empty note
      final rejectBtn = find.widgetWithText(ElevatedButton, 'Từ chối');
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập lý do từ chối (không được để trống)'), findsOneWidget);
      expect(fakeApi.lastUpdatedId, isNull);

      // Enter 20 spaces
      final textField = find.byType(TextField);
      await tester.enterText(textField, '                    ');
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập lý do từ chối (không được để trống)'), findsOneWidget);
      expect(fakeApi.lastUpdatedId, isNull);

      // Enter valid note
      await tester.enterText(textField, 'Trùng lịch thi giữa kỳ');
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(fakeApi.lastUpdatedId, 101);
      expect(fakeApi.lastUpdatedStatus, 'Từ chối');
      expect(fakeApi.lastUpdatedNote, 'Trùng lịch thi giữa kỳ');
    });
  });

  group('AdminRequestListScreen Tests - Teacher Persona Tabs', () {
    setUp(() async {
      await UserSession.instance.setUser({
        'userId': 8,
        'username': 'teacher_han',
        'roles': ['Teacher'],
        'teacherId': 1,
      });
    });

    testWidgets('5. Screen has two tabs: [Duyệt đơn] and [Đơn của tôi] with FAB on tab 2', (tester) async {
      LeaveRequestApi.instance = FakeLeaveRequestApi(mockStudentRequests);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Duyệt đơn'), findsOneWidget);
      expect(find.text('Đơn của tôi'), findsOneWidget);

      // On tab 1 (Duyệt đơn), FAB is not visible
      expect(find.byType(FloatingActionButton), findsNothing);

      // Switch to tab 2 (Đơn của tôi)
      await tester.tap(find.text('Đơn của tôi'));
      await tester.pumpAndSettle();

      // On tab 2, FloatingActionButton is visible to create a new leave request
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Tạo đơn'), findsOneWidget);
    });
  });
}
