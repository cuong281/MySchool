import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/event_model.dart';

void main() {
  group('EventModel', () {
    // TC-UNIT-008
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 1,
        'title': 'Ky thi cuoi ky',
        'description': 'Ky thi cuoi ky hoc ki 1',
        'date': '2026-01-15',
        'time': '08:00',
        'location': 'Hoi truong A',
        'category': 'Exam',
        'status': 'Upcoming',
        'color': '#FF5733',
        'icon': 'exam',
      };

      final event = EventModel.fromJson(json);

      expect(event.id, 1);
      expect(event.title, 'Ky thi cuoi ky');
      expect(event.description, 'Ky thi cuoi ky hoc ki 1');
      expect(event.date, '2026-01-15');
      expect(event.time, '08:00');
      expect(event.location, 'Hoi truong A');
      expect(event.category, 'Exam');
      expect(event.status, 'Upcoming');
      expect(event.color, '#FF5733');
      expect(event.icon, 'exam');

      final output = event.toJson();
      expect(output['title'], 'Ky thi cuoi ky');
      expect(output['id'], 1);
    });

    test('fromJson voi null values', () {
      final json = <String, dynamic>{'id': null};

      final event = EventModel.fromJson(json);

      expect(event.id, isNull);
      expect(event.title, '');
      expect(event.description, '');
      expect(event.date, '');
      expect(event.time, '');
      expect(event.location, '');
      expect(event.category, '');
      expect(event.status, '');
      expect(event.color, '');
      expect(event.icon, '');
    });
  });
}
