import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/attendance_sheet_model.dart';

void main() {
  group('AttendanceSheetModel Tests', () {
    test('AttendanceSheetModel fromJson parses complete data correctly', () {
      final json = {
        'classId': 1,
        'className': '10A1',
        'subjectId': 10,
        'subjectName': 'Toán học',
        'slotNumber': 2,
        'startTime': '07:50:00',
        'endTime': '08:35:00',
        'attendanceDate': '2026-09-05',
        'canEdit': true,
        'lockReason': null,
        'totalStudents': 2,
        'students': [
          {
            'studentId': 1,
            'studentName': 'Nguyễn Văn An',
            'studentCode': 'HS2025001',
            'currentStatus': 'PRESENT',
            'hasApprovedLeave': false,
            'leaveRequestId': null,
            'leaveReason': null,
            'note': 'Đi học đầy đủ'
          },
          {
            'studentId': 2,
            'studentName': 'Trần Thị Bình',
            'studentCode': 'HS2025002',
            'currentStatus': 'EXCUSED_ABSENCE',
            'hasApprovedLeave': true,
            'leaveRequestId': 15,
            'leaveReason': 'Nghỉ ốm sốt xuất huyết',
            'note': null
          }
        ]
      };

      final model = AttendanceSheetModel.fromJson(json);

      expect(model.classId, 1);
      expect(model.className, '10A1');
      expect(model.subjectId, 10);
      expect(model.subjectName, 'Toán học');
      expect(model.slotNumber, 2);
      expect(model.startTime, '07:50:00');
      expect(model.endTime, '08:35:00');
      expect(model.attendanceDate, '2026-09-05');
      expect(model.canEdit, isTrue);
      expect(model.lockReason, isNull);
      expect(model.totalStudents, 2);
      expect(model.students.length, 2);

      final s1 = model.students[0];
      expect(s1.studentId, 1);
      expect(s1.studentName, 'Nguyễn Văn An');
      expect(s1.studentCode, 'HS2025001');
      expect(s1.currentStatus, 'PRESENT');
      expect(s1.hasApprovedLeave, isFalse);
      expect(s1.leaveRequestId, isNull);
      expect(s1.note, 'Đi học đầy đủ');
      expect(s1.overrideLeave, isFalse);
      expect(s1.overrideReason, isNull);

      final s2 = model.students[1];
      expect(s2.studentId, 2);
      expect(s2.hasApprovedLeave, isTrue);
      expect(s2.leaveRequestId, 15);
      expect(s2.leaveReason, 'Nghỉ ốm sốt xuất huyết');
    });

    test('AttendanceBatchRequest and AttendanceBatchItem toJson', () {
      final items = [
        AttendanceBatchItem(
          studentId: 1,
          status: 'PRESENT',
          note: 'Học tốt',
          overrideLeave: false,
        ),
        AttendanceBatchItem(
          studentId: 2,
          status: 'PRESENT',
          overrideLeave: true,
          overrideReason: 'Học sinh đi học bù theo yêu cầu',
        ),
      ];

      final req = AttendanceBatchRequest(
        classId: 1,
        subjectId: 10,
        slotNumber: 2,
        attendanceDate: '2026-09-05',
        items: items,
      );

      final json = req.toJson();

      expect(json['classId'], 1);
      expect(json['subjectId'], 10);
      expect(json['slotNumber'], 2);
      expect(json['attendanceDate'], '2026-09-05');
      expect(json['items'], hasLength(2));

      final itemJson0 = json['items'][0] as Map<String, dynamic>;
      expect(itemJson0['studentId'], 1);
      expect(itemJson0['status'], 'PRESENT');
      expect(itemJson0['note'], 'Học tốt');
      expect(itemJson0['overrideLeave'], isFalse);
      expect(itemJson0.containsKey('overrideReason'), isFalse);

      final itemJson1 = json['items'][1] as Map<String, dynamic>;
      expect(itemJson1['studentId'], 2);
      expect(itemJson1['status'], 'PRESENT');
      expect(itemJson1['overrideLeave'], isTrue);
      expect(itemJson1['overrideReason'], 'Học sinh đi học bù theo yêu cầu');
    });

    test('LeaveConflictError fromJson parsing', () {
      final json = {
        'status': 409,
        'error': 'CONFLICT_APPROVED_LEAVE',
        'message': 'Học sinh đã có đơn nghỉ phép',
        'studentId': 5,
        'leaveRequestId': 20,
      };

      final error = LeaveConflictError.fromJson(json);

      expect(error.status, 409);
      expect(error.error, 'CONFLICT_APPROVED_LEAVE');
      expect(error.message, 'Học sinh đã có đơn nghỉ phép');
      expect(error.studentId, 5);
      expect(error.leaveRequestId, 20);
    });
  });
}
