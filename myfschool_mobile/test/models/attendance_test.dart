import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';

void main() {
  group('AttendanceRecord Tests', () {
    test('AttendanceRecord fromJson/toJson roundtrip', () {
      final json = {
        'id': 1,
        'studentId': 1,
        'studentName': 'Nguyen Van A',
        'studentCode': 'SV001',
        'classId': 1,
        'className': '10A1',
        'subjectId': 1,
        'subjectName': 'Toán học',
        'attendanceDate': '2026-09-04',
        'slotNumber': 2,
        'status': 'PRESENT',
        'note': 'Đúng giờ',
        'recordedByName': 'teacher_han',
      };

      final record = AttendanceRecord.fromJson(json);

      expect(record.id, 1);
      expect(record.studentName, 'Nguyen Van A');
      expect(record.slotNumber, 2);
      expect(record.status, 'PRESENT');
      expect(record.statusLabel, 'Có mặt');

      final serialized = record.toJson();
      expect(serialized['id'], 1);
      expect(serialized['status'], 'PRESENT');
      expect(serialized['slotNumber'], 2);
    });

    test('AttendanceRecord statusLabel mappings', () {
      final r1 = AttendanceRecord(
        studentName: 'A',
        studentCode: '001',
        className: '10A1',
        subjectName: 'Toan',
        attendanceDate: DateTime.now(),
        status: 'EXCUSED_ABSENCE',
        note: '',
        recordedByName: 'admin',
      );
      expect(r1.statusLabel, 'Nghỉ có phép');

      final r2 = AttendanceRecord(
        studentName: 'A',
        studentCode: '001',
        className: '10A1',
        subjectName: 'Toan',
        attendanceDate: DateTime.now(),
        status: 'UNEXCUSED_ABSENCE',
        note: '',
        recordedByName: 'admin',
      );
      expect(r2.statusLabel, 'Nghỉ không phép');

      final r3 = AttendanceRecord(
        studentName: 'A',
        studentCode: '001',
        className: '10A1',
        subjectName: 'Toan',
        attendanceDate: DateTime.now(),
        status: 'LATE',
        note: '',
        recordedByName: 'admin',
      );
      expect(r3.statusLabel, 'Đi muộn');
    });
  });

  group('AttendanceSummary Tests', () {
    test('AttendanceSummary fromJson/toJson roundtrip', () {
      final json = {
        'studentId': 1,
        'studentName': 'Nguyen Van A',
        'studentCode': 'SV001',
        'className': '10A1',
        'totalSessions': 20,
        'presentCount': 18,
        'excusedAbsentCount': 1,
        'unexcusedAbsentCount': 0,
        'lateCount': 1,
        'attendanceRate': 96.5,
        'statusNote': 'Chuyên cần tốt',
      };

      final summary = AttendanceSummary.fromJson(json);

      expect(summary.studentId, 1);
      expect(summary.totalSessions, 20);
      expect(summary.presentCount, 18);
      expect(summary.excusedAbsentCount, 1);
      expect(summary.unexcusedAbsentCount, 0);
      expect(summary.lateCount, 1);
      expect(summary.attendanceRate, 96.5);
      expect(summary.statusNote, 'Chuyên cần tốt');

      final serialized = summary.toJson();
      expect(serialized['totalSessions'], 20);
      expect(serialized['attendanceRate'], 96.5);
    });

    test('AttendanceSummary null fallback handling', () {
      final summary = AttendanceSummary.fromJson({});

      expect(summary.studentName, '');
      expect(summary.totalSessions, 0);
      expect(summary.presentCount, 0);
      expect(summary.attendanceRate, 100.0);
      expect(summary.statusNote, 'Chuyên cần tốt');
    });
  });
}
