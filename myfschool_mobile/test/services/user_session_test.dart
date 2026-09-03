import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/models/user_model.dart';

void main() {
  group('UserSession', () {
    setUp(() {
      UserSession.instance.clear();
    });

    // TC-UNIT-016
    test('setUser va fullName format', () {
      UserSession.instance.setUser({
        'userId': 1,
        'username': 'student01',
        'email': 'test@test.com',
        'firstName': 'Van A',
        'lastName': 'Nguyen',
        'phoneNumber': '0123456789',
        'roles': ['Student'],
        'studentCode': 'SV001',
        'className': '12A1',
      });

      expect(UserSession.instance.currentUser, isNotNull);
      expect(UserSession.instance.fullName, 'Nguyen Van A');
    });

    // TC-UNIT-017
    test('clear xoa session', () {
      UserSession.instance.setUser({
        'userId': 1,
        'username': 'test',
        'firstName': 'A',
        'lastName': 'B',
        'roles': ['Student'],
      });

      expect(UserSession.instance.currentUser, isNotNull);

      UserSession.instance.clear();

      expect(UserSession.instance.currentUser, isNull);
    });

    // TC-UNIT-018
    test('fullName khi currentUser null', () {
      expect(UserSession.instance.currentUser, isNull);
      expect(UserSession.instance.fullName, '');
    });

    test('fullName khi chi co lastName', () {
      UserSession.instance.setUser({
        'firstName': '',
        'lastName': 'Nguyen',
        'roles': ['Student'],
      });

      expect(UserSession.instance.fullName, 'Nguyen');
    });

    test('fullName khi chi co firstName', () {
      UserSession.instance.setUser({
        'firstName': 'Van A',
        'lastName': '',
        'roles': ['Student'],
      });

      expect(UserSession.instance.fullName, 'Van A');
    });

    test('singleton tra ve cung instance', () {
      final instance1 = UserSession.instance;
      final instance2 = UserSession.instance;

      expect(identical(instance1, instance2), true);
    });
  });
}
