import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/grade.dart';
import 'package:myfschools/screens/grade_screen.dart';

void main() {
  Widget buildTestApp(Grade grade) {
    return MaterialApp(
      home: Scaffold(
        body: SubjectDetailSheet(grade: grade),
      ),
    );
  }

  group('SubjectDetailSheet - UI & Scoring Scenarios', () {
    // 1. Có cả Midterm + Final + Average
    testWidgets('Case 1: Co ca Midterm + Final + Average', (tester) async {
      final grade = Grade(
        id: 1,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'MAT',
        subjectName: 'Toán học',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: 9.0,
        midtermScore: 8.5,
        finalScore: 9.0,
        averageScore: 8.8,
        letterGrade: 'A',
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('CHI TIẾT MÔN HỌC'), findsOneWidget);
      expect(find.text('Toán học'), findsOneWidget);
      expect(find.text('MAT'), findsOneWidget);
      expect(find.text('Học kỳ: Học kỳ 1 (HK1)  •  Năm học: 2025-2026'), findsOneWidget);
      expect(find.text('Điểm tổng kết'), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      expect(find.text('ĐIỂM THI'), findsOneWidget);
      expect(find.text('Giữa kỳ'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('Cuối kỳ'), findsOneWidget);
      expect(find.text('9.0'), findsWidgets); // 9.0 in Cuối kỳ and Attendance

      expect(find.text('ĐIỂM THÀNH PHẦN KHÁC'), findsOneWidget);
      expect(find.text('Điểm chuyên cần'), findsOneWidget);
    });

    // 2. Có Midterm nhưng chưa có Final
    testWidgets('Case 2: Co Midterm nhung chua co Final', (tester) async {
      final grade = Grade(
        id: 2,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'PHY',
        subjectName: 'Vật lý',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: 8.0,
        midtermScore: 8.5,
        finalScore: null,
        averageScore: null,
        letterGrade: null,
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Vật lý'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget); // Giữa kỳ
      expect(find.text('Chưa có'), findsWidgets); // Cuối kỳ and Điểm tổng kết
      expect(find.text('Chưa cập nhật'), findsOneWidget); // Xếp loại
    });

    // 3. Có Final nhưng chưa có Midterm
    testWidgets('Case 3: Co Final nhung chua co Midterm', (tester) async {
      final grade = Grade(
        id: 3,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'CHM',
        subjectName: 'Hóa học',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: 8.0,
        midtermScore: null,
        finalScore: 9.0,
        averageScore: null,
        letterGrade: null,
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Hóa học'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget); // Cuối kỳ
      expect(find.text('Chưa có'), findsWidgets); // Giữa kỳ and Điểm tổng kết
    });

    // 4. Chưa có cả Midterm và Final
    testWidgets('Case 4: Chua co ca Midterm va Final', (tester) async {
      final grade = Grade(
        id: 4,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'BIO',
        subjectName: 'Sinh học',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: null,
        midtermScore: null,
        finalScore: null,
        averageScore: null,
        letterGrade: null,
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Sinh học'), findsOneWidget);
      // Điểm tổng kết, Giữa kỳ, Cuối kỳ, Chuyên cần all "Chưa có"
      expect(find.text('Chưa có'), findsNWidgets(4));
      expect(find.text('Chưa cập nhật'), findsOneWidget);
    });

    // 5. Có điểm thi nhưng chưa có Average
    testWidgets('Case 5: Co diem thi ca Giua ky va Cuoi ky nhung chua co Average', (tester) async {
      final grade = Grade(
        id: 5,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'HIS',
        subjectName: 'Lịch sử',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: 8.0,
        midtermScore: 8.5,
        finalScore: 9.0,
        averageScore: null,
        letterGrade: null,
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget); // Giữa kỳ
      expect(find.text('9.0'), findsOneWidget); // Cuối kỳ
      expect(find.text('Chưa có'), findsOneWidget); // Điểm tổng kết
      expect(find.text('Chưa cập nhật'), findsOneWidget); // Xếp loại
    });

    // 6. Điểm = 0 phải hiển thị 0.0, không được coi là null
    testWidgets('Case 6: Diem = 0 phai hien thi 0.0, khong duoc hien thi Chua co', (tester) async {
      final grade = Grade(
        id: 6,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'GEO',
        subjectName: 'Địa lý',
        semester: 1,
        academicYear: '2025-2026',
        attendanceScore: 0.0,
        midtermScore: 0.0,
        finalScore: 0.0,
        averageScore: 0.0,
        letterGrade: 'Yếu',
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Địa lý'), findsOneWidget);
      expect(find.text('0.0'), findsNWidgets(4)); // average, midterm, final, attendance
      expect(find.text('Chưa có'), findsNothing);
      expect(find.text('Yếu'), findsOneWidget);
    });

    // 7. HK1 hiển thị đúng dữ liệu HK1
    testWidgets('Case 7: HK1 hien thi dung thong tin HK1', (tester) async {
      final grade = Grade(
        id: 7,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'ENG',
        subjectName: 'Tiếng Anh',
        semester: 1,
        academicYear: '2025-2026',
        midtermScore: 7.5,
        finalScore: 8.0,
        averageScore: 7.8,
        letterGrade: 'Khá',
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Học kỳ: Học kỳ 1 (HK1)  •  Năm học: 2025-2026'), findsOneWidget);
      expect(find.text('ĐIỂM THI'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('8.0'), findsOneWidget);
    });

    // 8. HK2 hiển thị đúng dữ liệu HK2
    testWidgets('Case 8: HK2 hien thi dung thong tin HK2', (tester) async {
      final grade = Grade(
        id: 8,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'ENG',
        subjectName: 'Tiếng Anh',
        semester: 2,
        academicYear: '2025-2026',
        midtermScore: 8.5,
        finalScore: 9.0,
        averageScore: 8.8,
        letterGrade: 'Giỏi',
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Học kỳ: Học kỳ 2 (HK2)  •  Năm học: 2025-2026'), findsOneWidget);
      expect(find.text('ĐIỂM THI'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget);
    });

    // 9. Cả năm (semester == 0) hiển thị đúng cấu trúc cả năm
    testWidgets('Case 9: Ca nam (semester == 0) hien thi tong ket theo hoc ky', (tester) async {
      final grade = Grade(
        id: 9,
        studentId: 10,
        studentName: 'Nguyen Van A',
        className: '12A1',
        subjectCode: 'ENG',
        subjectName: 'Tiếng Anh',
        semester: 0,
        academicYear: '2025-2026',
        attendanceScore: 7.8, // HK1 average
        midtermScore: 8.8,    // HK2 average
        averageScore: 8.5,    // Annual average
        letterGrade: 'Giỏi',
      );

      await tester.pumpWidget(buildTestApp(grade));
      await tester.pumpAndSettle();

      expect(find.text('Học kỳ: Cả năm  •  Năm học: 2025-2026'), findsOneWidget);
      expect(find.text('ĐIỂM TỔNG KẾT THEO HỌC KỲ'), findsOneWidget);
      expect(find.text('Tổng kết HK1'), findsOneWidget);
      expect(find.text('7.8'), findsOneWidget);
      expect(find.text('Tổng kết HK2'), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget); // Annual average
    });
  });
}
