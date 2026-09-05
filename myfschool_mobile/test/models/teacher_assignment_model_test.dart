import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/teacher_assignment_model.dart';

void main() {
  group('TeacherAssignmentModel Tests', () {
    test('fromJson mapping with full data - Homeroom', () {
      final json = {
        'id': 1,
        'teacherId': 10,
        'teacherName': 'Nguyễn Ngọc Hân',
        'classId': 1,
        'className': '10A1',
        'subjectId': null,
        'subjectName': null,
        'subjectCode': null,
        'roleType': 'HOMEROOM_TEACHER',
      };

      final model = TeacherAssignmentModel.fromJson(json);

      expect(model.id, 1);
      expect(model.teacherId, 10);
      expect(model.teacherName, 'Nguyễn Ngọc Hân');
      expect(model.classId, 1);
      expect(model.className, '10A1');
      expect(model.subjectId, isNull);
      expect(model.subjectName, isNull);
      expect(model.roleType, 'HOMEROOM_TEACHER');
      expect(model.isHomeroom, isTrue);
      expect(model.isSubject, isFalse);
    });

    test('fromJson mapping with full data - Subject Teacher', () {
      final json = {
        'id': 2,
        'teacherId': 10,
        'teacherName': 'Nguyễn Ngọc Hân',
        'classId': 2,
        'className': '10A2',
        'subjectId': 1,
        'subjectName': 'Toán',
        'subjectCode': 'MATH',
        'roleType': 'SUBJECT_TEACHER',
      };

      final model = TeacherAssignmentModel.fromJson(json);

      expect(model.id, 2);
      expect(model.teacherId, 10);
      expect(model.className, '10A2');
      expect(model.subjectName, 'Toán');
      expect(model.subjectCode, 'MATH');
      expect(model.roleType, 'SUBJECT_TEACHER');
      expect(model.isHomeroom, isFalse);
      expect(model.isSubject, isTrue);
    });

    test('fromJson handles null values with fallback defaults', () {
      final model = TeacherAssignmentModel.fromJson({});

      expect(model.id, 0);
      expect(model.teacherId, isNull);
      expect(model.teacherName, '');
      expect(model.classId, 0);
      expect(model.className, '');
      expect(model.roleType, '');
      expect(model.isHomeroom, isFalse);
      expect(model.isSubject, isFalse);
    });

    test('toJson roundtrip', () {
      final original = TeacherAssignmentModel(
        id: 3,
        teacherId: 12,
        teacherName: 'Lê Văn An',
        classId: 4,
        className: '11B1',
        subjectId: 2,
        subjectName: 'Vật lý',
        subjectCode: 'PHYS',
        roleType: 'SUBJECT_TEACHER',
      );

      final json = original.toJson();
      final reconstructed = TeacherAssignmentModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.teacherId, original.teacherId);
      expect(reconstructed.teacherName, original.teacherName);
      expect(reconstructed.classId, original.classId);
      expect(reconstructed.className, original.className);
      expect(reconstructed.subjectId, original.subjectId);
      expect(reconstructed.subjectName, original.subjectName);
      expect(reconstructed.subjectCode, original.subjectCode);
      expect(reconstructed.roleType, original.roleType);
      expect(reconstructed.isSubject, isTrue);
    });
  });
}
