import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/grade.dart';

void main() {
  group('Grade', () {
    // TC-UNIT-004
    test('fromJson voi du lieu day du', () {
      final json = {
        'id': 1,
        'studentId': 10,
        'studentName': 'Nguyen Van A',
        'className': '12A1',
        'subjectCode': 'MATH',
        'subjectName': 'Toan',
        'academicYear': '2025-2026',
        'semester': 1,
        'attendanceScore': 8.5,
        'midtermScore': 7.0,
        'finalScore': 9.0,
        'averageScore': 8.2,
        'letterGrade': 'B+',
        'gpa4': 3.3,
      };

      final grade = Grade.fromJson(json);

      expect(grade.id, 1);
      expect(grade.studentId, 10);
      expect(grade.studentName, 'Nguyen Van A');
      expect(grade.className, '12A1');
      expect(grade.subjectCode, 'MATH');
      expect(grade.subjectName, 'Toan');
      expect(grade.academicYear, '2025-2026');
      expect(grade.semester, 1);
      expect(grade.attendanceScore, 8.5);
      expect(grade.midtermScore, 7.0);
      expect(grade.finalScore, 9.0);
      expect(grade.averageScore, 8.2);
      expect(grade.letterGrade, 'B+');
      expect(grade.gpa4, 3.3);
    });

    // TC-UNIT-005
    test('fromJson voi null values (fallback)', () {
      final json = <String, dynamic>{};

      final grade = Grade.fromJson(json);

      expect(grade.id, isNull);
      expect(grade.studentId, 0);
      expect(grade.studentName, '');
      expect(grade.className, '');
      expect(grade.subjectCode, '');
      expect(grade.subjectName, '');
      expect(grade.academicYear, '');
      expect(grade.semester, 1);
      expect(grade.attendanceScore, 0.0);
      expect(grade.midtermScore, 0.0);
      expect(grade.finalScore, 0.0);
      expect(grade.averageScore, 0.0);
      expect(grade.letterGrade, '');
      expect(grade.gpa4, 0.0);
    });

    // TC-UNIT-006
    test('toJson khong gui id khi null', () {
      final grade = Grade(
        id: null,
        studentId: 1,
        studentName: 'Test',
        className: '10A',
        subjectCode: 'PHY',
        subjectName: 'Vat Ly',
        academicYear: '2025-2026',
        semester: 2,
        attendanceScore: 7.0,
        midtermScore: 8.0,
        finalScore: 7.5,
      );

      final json = grade.toJson();

      expect(json.containsKey('id'), false);
      expect(json['studentId'], 1);
      expect(json['subjectCode'], 'PHY');
      expect(json['semester'], 2);
    });

    test('toJson gui id khi co gia tri', () {
      final grade = Grade(
        id: 5,
        studentId: 1,
        studentName: 'Test',
        className: '10A',
        subjectCode: 'PHY',
        subjectName: 'Vat Ly',
        academicYear: '2025-2026',
        semester: 1,
        attendanceScore: 7.0,
        midtermScore: 8.0,
        finalScore: 7.5,
      );

      final json = grade.toJson();

      expect(json['id'], 5);
    });

    // TC-UNIT-007
    test('copyWith tao ban copy chinh xac', () {
      final original = Grade(
        id: 1,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'MATH',
        subjectName: 'Toan',
        academicYear: '2025-2026',
        semester: 1,
        attendanceScore: 8.0,
        midtermScore: 7.0,
        finalScore: 9.0,
        averageScore: 8.0,
        letterGrade: 'B+',
        gpa4: 3.3,
      );

      final copy = original.copyWith(attendanceScore: 10.0, letterGrade: 'A');

      expect(copy.id, original.id);
      expect(copy.studentId, original.studentId);
      expect(copy.attendanceScore, 10.0); // changed
      expect(copy.midtermScore, 7.0);     // unchanged
      expect(copy.letterGrade, 'A');       // changed
      expect(copy.gpa4, original.gpa4);   // unchanged
    });

    test('fromJson xu ly num types tu JSON', () {
      // JSON may return int for double fields
      final json = {
        'studentId': 5,
        'semester': 2,
        'attendanceScore': 8,    // int instead of double
        'midtermScore': 7,
        'finalScore': 9,
      };

      final grade = Grade.fromJson(json);

      expect(grade.studentId, 5);
      expect(grade.attendanceScore, 8.0);
      expect(grade.midtermScore, 7.0);
      expect(grade.finalScore, 9.0);
    });

    test('toString hien thi dung format', () {
      final grade = Grade(
        id: 1,
        studentId: 10,
        studentName: 'Test',
        className: '10A',
        subjectCode: 'MATH',
        subjectName: 'Toan',
        academicYear: '2025-2026',
        semester: 1,
        attendanceScore: 8.0,
        midtermScore: 7.0,
        finalScore: 9.0,
        averageScore: 8.0,
        letterGrade: 'B+',
        gpa4: 3.3,
      );

      final str = grade.toString();
      expect(str, contains('Grade'));
      expect(str, contains('Test'));
      expect(str, contains('MATH'));
    });
  });
}
