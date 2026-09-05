import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/attendance_history_model.dart';

void main() {
  group('AttendanceHistoryModel Tests', () {
    test('AttendanceClassHistoryModel fromJson parses complete data correctly', () {
      final json = {
        'classId': 1,
        'className': '10A1',
        'attendanceRate': 94.5,
        'totalSessions': 20,
        'presentCount': 18,
        'excusedCount': 1,
        'unexcusedCount': 1,
        'lateCount': 0,
        'sessions': [
          {
            'attendanceDate': '2026-09-04',
            'slotNumber': 1,
            'subjectId': 2,
            'subjectName': 'Văn học',
            'presentCount': 24,
            'excusedCount': 1,
            'unexcusedCount': 0,
            'lateCount': 0,
            'totalCount': 25,
            'canEdit': false,
            'absentStudents': ['Nguyễn Văn An (Có phép)']
          }
        ],
        'atRiskStudents': [
          {
            'studentId': 3,
            'studentName': 'Lê Văn C',
            'studentCode': 'HS2025003',
            'unexcusedCount': 3,
            'rate': 68.0,
            'warningNote': 'Nghỉ không phép 3 buổi (Tỷ lệ: 68.0%)'
          }
        ]
      };

      final model = AttendanceClassHistoryModel.fromJson(json);

      expect(model.classId, 1);
      expect(model.className, '10A1');
      expect(model.attendanceRate, 94.5);
      expect(model.totalSessions, 20);
      expect(model.presentCount, 18);
      expect(model.excusedCount, 1);
      expect(model.unexcusedCount, 1);
      expect(model.lateCount, 0);

      expect(model.sessions.length, 1);
      final s = model.sessions[0];
      expect(s.attendanceDate, '2026-09-04');
      expect(s.slotNumber, 1);
      expect(s.subjectName, 'Văn học');
      expect(s.presentCount, 24);
      expect(s.canEdit, isFalse);
      expect(s.absentStudents, contains('Nguyễn Văn An (Có phép)'));

      expect(model.atRiskStudents.length, 1);
      final risk = model.atRiskStudents[0];
      expect(risk.studentId, 3);
      expect(risk.studentName, 'Lê Văn C');
      expect(risk.unexcusedCount, 3);
      expect(risk.rate, 68.0);
      expect(risk.warningNote, contains('Nghỉ không phép 3 buổi'));
    });
  });
}
