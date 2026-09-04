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

    test('setUser luu tru accessToken va refreshToken', () async {
      await UserSession.instance.setUser({
        'userId': 2,
        'username': 'nguyenvana',
        'roles': ['Student'],
        'accessToken': 'jwt.token.access',
        'refreshToken': 'refresh.token.value',
      });

      expect(UserSession.instance.accessToken, 'jwt.token.access');
      expect(UserSession.instance.refreshToken, 'refresh.token.value');
      expect(UserSession.instance.isAuthenticated, true);
    });

    test('updateTokens cap nhat tokens moi', () async {
      await UserSession.instance.setUser({
        'userId': 2,
        'username': 'nguyenvana',
        'roles': ['Student'],
        'accessToken': 'old.token',
        'refreshToken': 'old.refresh',
      });

      await UserSession.instance.updateTokens('new.access.token', 'new.refresh.token');

      expect(UserSession.instance.accessToken, 'new.access.token');
      expect(UserSession.instance.refreshToken, 'new.refresh.token');
    });

    test('clear xoa sach tokens va isAuthenticated thanh false', () async {
      await UserSession.instance.setUser({
        'userId': 2,
        'username': 'nguyenvana',
        'roles': ['Student'],
        'accessToken': 'token.to.clear',
        'refreshToken': 'refresh.to.clear',
      });

      expect(UserSession.instance.isAuthenticated, true);

      await UserSession.instance.clear();

      expect(UserSession.instance.accessToken, isNull);
      expect(UserSession.instance.refreshToken, isNull);
      expect(UserSession.instance.currentUser, isNull);
      expect(UserSession.instance.isAuthenticated, false);
    });
  });
}
