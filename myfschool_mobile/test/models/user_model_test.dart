import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/user_model.dart';

void main() {
  group('UserModel', () {
    // TC-UNIT-001
    test('fromMap voi du lieu day du', () {
      final map = {
        'userId': 1,
        'username': 'student01',
        'email': 'student01@test.com',
        'firstName': 'Van A',
        'lastName': 'Nguyen',
        'phoneNumber': '0123456789',
        'roles': ['Student'],
        'studentId': 10,
        'studentCode': 'SV001',
        'classId': 5,
        'className': '12A1',
      };

      final user = UserModel.fromMap(map);

      expect(user.id, 1);
      expect(user.username, 'student01');
      expect(user.email, 'student01@test.com');
      expect(user.firstName, 'Van A');
      expect(user.lastName, 'Nguyen');
      expect(user.phoneNumber, '0123456789');
      expect(user.roles, ['Student']);
      expect(user.studentId, 10);
      expect(user.studentCode, 'SV001');
      expect(user.classId, 5);
      expect(user.className, '12A1');
    });

    // TC-UNIT-002
    test('fromMap voi du lieu thieu (fallback defaults)', () {
      final map = <String, dynamic>{};

      final user = UserModel.fromMap(map);

      expect(user.id, isNull);
      expect(user.username, '');
      expect(user.email, '');
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.phoneNumber, '');
      expect(user.roles, ['Student']); // fallback when roles is null
      expect(user.studentId, isNull);
      expect(user.studentCode, '');
      expect(user.classId, isNull);
      expect(user.className, '');
    });

    // TC-UNIT-003
    test('toMap roundtrip', () {
      final original = UserModel(
        id: 1,
        username: 'user1',
        email: 'user1@test.com',
        firstName: 'First',
        lastName: 'Last',
        phoneNumber: '0900000000',
        roles: ['Student', 'Admin'],
        studentId: 5,
        studentCode: 'SV005',
        classId: 3,
        className: '10B2',
      );

      final map = original.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.firstName, original.firstName);
      expect(restored.lastName, original.lastName);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.roles, original.roles);
      expect(restored.studentCode, original.studentCode);
      expect(restored.className, original.className);
    });

    // TC-UNIT-019
    test('role getter tra roles.first hoac fallback Student', () {
      final userWithRoles = UserModel.fromMap({
        'roles': ['Admin', 'Teacher'],
      });
      expect(userWithRoles.role, 'Admin');

      final userWithEmpty = UserModel.fromMap({
        'roles': [],
      });
      expect(userWithEmpty.role, 'Student');
    });

    test('fromMap chap nhan alternative id keys', () {
      final withId = UserModel.fromMap({'id': 10});
      expect(withId.id, 10);

      final withUserID = UserModel.fromMap({'userID': 20});
      expect(withUserID.id, 20);

      final withUserId = UserModel.fromMap({'userId': 30});
      expect(withUserId.id, 30);
    });
  });
}
