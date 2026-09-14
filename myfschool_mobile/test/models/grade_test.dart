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
      expect(grade.attendanceScore, isNull);
      expect(grade.midtermScore, isNull);
      expect(grade.finalScore, isNull);
      expect(grade.averageScore, isNull);
      expect(grade.letterGrade, isNull);
      expect(grade.gpa4, isNull);
    });

    // Case 1: Có cả Midterm + Final + Average
    test('Case 1: Co ca Midterm + Final + Average', () {
      final json = {
        'id': 1,
        'subjectName': 'Toán học',
        'midtermScore': 8.5,
        'finalScore': 9.0,
        'averageScore': 8.8,
        'letterGrade': 'A',
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, 8.5);
      expect(grade.finalScore, 9.0);
      expect(grade.averageScore, 8.8);
      expect(grade.letterGrade, 'A');
    });

    // Case 2: Có Midterm nhưng chưa có Final
    test('Case 2: Co Midterm nhung chua co Final', () {
      final json = {
        'id': 2,
        'subjectName': 'Vật lý',
        'midtermScore': 8.5,
        'finalScore': null,
        'averageScore': null,
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, 8.5);
      expect(grade.finalScore, isNull);
      expect(grade.averageScore, isNull);
    });

    // Case 3: Có Final nhưng chưa có Midterm
    test('Case 3: Co Final nhung chua co Midterm', () {
      final json = {
        'id': 3,
        'subjectName': 'Hóa học',
        'midtermScore': null,
        'finalScore': 9.0,
        'averageScore': null,
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, isNull);
      expect(grade.finalScore, 9.0);
      expect(grade.averageScore, isNull);
    });

    // Case 4: Chưa có cả Midterm và Final
    test('Case 4: Chua co ca Midterm va Final', () {
      final json = {
        'id': 4,
        'subjectName': 'Sinh học',
        'midtermScore': null,
        'finalScore': null,
        'averageScore': null,
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, isNull);
      expect(grade.finalScore, isNull);
      expect(grade.averageScore, isNull);
    });

    // Case 5: Có điểm thi nhưng chưa có Average
    test('Case 5: Co diem thi Giua ky va Cuoi ky nhung chua co Average', () {
      final json = {
        'id': 5,
        'subjectName': 'Lịch sử',
        'midtermScore': 8.5,
        'finalScore': 9.0,
        'averageScore': null,
        'letterGrade': null,
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, 8.5);
      expect(grade.finalScore, 9.0);
      expect(grade.averageScore, isNull);
      expect(grade.letterGrade, isNull);
    });

    // Case 6: Điểm = 0 phải là 0.0, không được coi là null
    test('Case 6: Diem = 0 phan biet ro voi null (0.0 giu nguyen)', () {
      final json = {
        'id': 6,
        'subjectName': 'Địa lý',
        'midtermScore': 0,
        'finalScore': 0.0,
        'averageScore': 0.0,
      };

      final grade = Grade.fromJson(json);

      expect(grade.midtermScore, 0.0);
      expect(grade.midtermScore, isNotNull);
      expect(grade.finalScore, 0.0);
      expect(grade.finalScore, isNotNull);
      expect(grade.averageScore, 0.0);
      expect(grade.averageScore, isNotNull);
    });

    // Case 7: HK1 hiển thị đúng dữ liệu HK1
    test('Case 7: HK1 giu dung du lieu semester 1 va diem thi giua/cuoi ky', () {
      final jsonHK1 = {
        'id': 101,
        'studentId': 10,
        'studentName': 'Nguyen Van A',
        'subjectCode': 'MATH',
        'subjectName': 'Toán học',
        'semester': 1,
        'academicYear': '2025-2026',
        'midtermScore': 8.5,
        'finalScore': null,
        'averageScore': null,
      };

      final gradeHK1 = Grade.fromJson(jsonHK1);

      expect(gradeHK1.semester, 1);
      expect(gradeHK1.subjectCode, 'MATH');
      expect(gradeHK1.midtermScore, 8.5);
      expect(gradeHK1.finalScore, isNull);
      expect(gradeHK1.averageScore, isNull);
    });

    // Case 8: HK2 hiển thị đúng dữ liệu HK2
    test('Case 8: HK2 giu dung du lieu semester 2 va diem thi giua/cuoi ky', () {
      final jsonHK2 = {
        'id': 102,
        'studentId': 10,
        'studentName': 'Nguyen Van A',
        'subjectCode': 'MATH',
        'subjectName': 'Toán học',
        'semester': 2,
        'academicYear': '2025-2026',
        'midtermScore': 9.0,
        'finalScore': 9.5,
        'averageScore': 9.2,
      };

      final gradeHK2 = Grade.fromJson(jsonHK2);

      expect(gradeHK2.semester, 2);
      expect(gradeHK2.subjectCode, 'MATH');
      expect(gradeHK2.midtermScore, 9.0);
      expect(gradeHK2.finalScore, 9.5);
      expect(gradeHK2.averageScore, 9.2);
    });

    // Case 9: Không làm thay đổi cấu trúc tổng thể và tính điểm cả năm
    test('Case 9: Tinh diem ca nam an toan khi chua co du diem 2 hoc ky', () {
      final hk1 = Grade(
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'MATH',
        subjectName: 'Toán học',
        semester: 1,
        academicYear: '2025-2026',
        midtermScore: 8.0,
        finalScore: 8.0,
        averageScore: 8.0,
      );

      final hk2 = Grade(
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'MATH',
        subjectName: 'Toán học',
        semester: 2,
        academicYear: '2025-2026',
        midtermScore: 9.0,
        finalScore: null,
        averageScore: null, // Chưa có điểm tổng kết HK2
      );

      // Khi HK2 chưa có averageScore, điểm tổng kết cả năm không tính bừa 0.0 mà giữ null hoặc dùng HK1
      double? annualScore;
      if (hk1.averageScore != null && hk2.averageScore != null) {
        annualScore = (hk1.averageScore! + hk2.averageScore! * 2) / 3;
      } else if (hk1.averageScore != null) {
        annualScore = hk1.averageScore;
      } else if (hk2.averageScore != null) {
        annualScore = hk2.averageScore;
      }

      expect(annualScore, 8.0);
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
