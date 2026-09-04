import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/schedule_model.dart';

void main() {
  group('SchedulePeriodModel', () {
    // TC-UNIT-010
    test('fromMap voi du lieu day du', () {
      final map = {
        'slotNumber': 1,
        'startTime': '07:30',
        'endTime': '08:15',
        'subjectName': 'Toan',
        'teacherName': 'Nguyen Van B',
        'roomName': 'P301',
        'classId': 1,
        'className': '10A1',
      };

      final period = SchedulePeriodModel.fromMap(map);

      expect(period.slotNumber, 1);
      expect(period.startTime, '07:30');
      expect(period.endTime, '08:15');
      expect(period.subjectName, 'Toan');
      expect(period.teacherName, 'Nguyen Van B');
      expect(period.roomName, 'P301');
      expect(period.classId, 1);
      expect(period.className, '10A1');
    });

    test('fromMap voi du lieu thieu', () {
      final map = <String, dynamic>{};

      final period = SchedulePeriodModel.fromMap(map);

      expect(period.slotNumber, 0);
      expect(period.startTime, '');
      expect(period.endTime, '');
      expect(period.subjectName, '');
      expect(period.teacherName, '');
      expect(period.roomName, isNull);
    });
  });

  group('ScheduleDayModel', () {
    // TC-UNIT-011
    test('fromMap voi periods list', () {
      final map = {
        'dayOfWeek': 'Monday',
        'periods': [
          {
            'slotNumber': 1,
            'startTime': '07:30',
            'endTime': '08:15',
            'subjectName': 'Toan',
            'teacherName': 'Teacher A',
            'roomName': 'P101',
          },
          {
            'slotNumber': 2,
            'startTime': '08:20',
            'endTime': '09:05',
            'subjectName': 'Van',
            'teacherName': 'Teacher B',
            'roomName': 'P102',
          },
        ],
      };

      final day = ScheduleDayModel.fromMap(map);

      expect(day.dayOfWeek, 'Monday');
      expect(day.periods.length, 2);
      expect(day.periods[0].subjectName, 'Toan');
      expect(day.periods[1].subjectName, 'Van');
    });

    test('fromMap voi periods rong', () {
      final map = {
        'dayOfWeek': 'Sunday',
        'periods': [],
      };

      final day = ScheduleDayModel.fromMap(map);

      expect(day.dayOfWeek, 'Sunday');
      expect(day.periods, isEmpty);
    });

    test('fromMap voi periods null', () {
      final map = {
        'dayOfWeek': 'Saturday',
      };

      final day = ScheduleDayModel.fromMap(map);

      expect(day.dayOfWeek, 'Saturday');
      expect(day.periods, isEmpty);
    });
  });
}
