import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/contact_model.dart';

void main() {
  group('Contact', () {
    // TC-UNIT-012
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'teacher_1',
        'name': 'Tran Thi B',
        'email': 'tranthib@school.edu.vn',
        'phoneNumber': '0987654321',
        'role': 'Giao vien',
        'subject': 'Toan',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'isTeacher': true,
      };

      final contact = Contact.fromJson(json);

      expect(contact.id, 'teacher_1');
      expect(contact.name, 'Tran Thi B');
      expect(contact.email, 'tranthib@school.edu.vn');
      expect(contact.phoneNumber, '0987654321');
      expect(contact.role, 'Giao vien');
      expect(contact.subject, 'Toan');
      expect(contact.avatarUrl, 'https://example.com/avatar.jpg');
      expect(contact.isTeacher, true);

      final output = contact.toJson();
      expect(output['name'], 'Tran Thi B');
      expect(output['isTeacher'], true);
    });

    test('fromJson voi gia tri thieu', () {
      final json = <String, dynamic>{};

      final contact = Contact.fromJson(json);

      expect(contact.id, '');
      expect(contact.name, '');
      expect(contact.email, '');
      expect(contact.phoneNumber, '');
      expect(contact.role, '');
      expect(contact.subject, '');
      expect(contact.avatarUrl, '');
      expect(contact.isTeacher, true); // default
    });

    test('fromJson isTeacher false', () {
      final json = {
        'id': 'school_1',
        'name': 'Phong Dao Tao',
        'email': 'daotao@school.edu.vn',
        'role': 'Nha truong',
        'isTeacher': false,
      };

      final contact = Contact.fromJson(json);
      expect(contact.isTeacher, false);
    });
  });
}
