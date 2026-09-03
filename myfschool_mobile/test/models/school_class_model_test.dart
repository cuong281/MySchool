import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/school_class_model.dart';

void main() {
  group('SchoolClassModel', () {
    // TC-UNIT-013
    test('fromJson mapping chinh xac', () {
      final json = {
        'id': 1,
        'className': '12A1',
        'status': 'ACTIVE',
      };

      final schoolClass = SchoolClassModel.fromJson(json);

      expect(schoolClass.id, 1);
      expect(schoolClass.className, '12A1');
      expect(schoolClass.status, 'ACTIVE');
    });

    test('fromJson status default ACTIVE khi null', () {
      final json = {
        'id': 2,
        'className': '10B2',
        'status': null,
      };

      final schoolClass = SchoolClassModel.fromJson(json);

      expect(schoolClass.status, 'ACTIVE');
    });

    test('toJson roundtrip', () {
      final original = SchoolClassModel(
        id: 3,
        className: '11C1',
        status: 'INACTIVE',
      );

      final json = original.toJson();

      expect(json['id'], 3);
      expect(json['className'], '11C1');
      expect(json['status'], 'INACTIVE');
    });
  });
}
