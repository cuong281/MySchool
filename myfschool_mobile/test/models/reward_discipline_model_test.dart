import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/reward_discipline_model.dart';

void main() {
  group('RewardDisciplineModel', () {
    // TC-UNIT-014
    test('fromJson voi nested user object', () {
      final json = {
        'id': 1,
        'user': {
          'id': 10,
          'username': 'student01',
          'className': '12A1',
        },
        'type': 'REWARD',
        'content': 'Dat giai nhat cuoc thi Toan',
        'date': '2026-03-15',
        'decisionNumber': 'QD-001',
      };

      final model = RewardDisciplineModel.fromJson(json);

      expect(model.id, 1);
      expect(model.userId, 10);
      expect(model.userName, 'student01');
      expect(model.className, '12A1');
      expect(model.type, 'REWARD');
      expect(model.content, 'Dat giai nhat cuoc thi Toan');
      expect(model.date, '2026-03-15');
      expect(model.decisionNumber, 'QD-001');
    });

    test('fromJson khi user null', () {
      final json = {
        'id': 2,
        'user': null,
        'type': 'DISCIPLINE',
        'content': 'Vi pham noi quy',
        'date': '2026-04-01',
      };

      final model = RewardDisciplineModel.fromJson(json);

      expect(model.userId, 0);
      expect(model.userName, 'N/A');
      expect(model.className, 'N/A');
    });

    test('fromJson voi gia tri thieu', () {
      final json = <String, dynamic>{
        'user': null,
      };

      final model = RewardDisciplineModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.type, '');
      expect(model.content, '');
      expect(model.date, '');
      expect(model.decisionNumber, isNull);
    });

    test('toJson khong gui userName va className', () {
      final model = RewardDisciplineModel(
        id: 1,
        userId: 10,
        type: 'REWARD',
        content: 'Test',
        date: '2026-01-01',
        userName: 'student01',
        className: '12A1',
      );

      final json = model.toJson();

      expect(json.containsKey('userName'), false);
      expect(json.containsKey('className'), false);
      expect(json['userId'], 10);
      expect(json['type'], 'REWARD');
    });
  });
}
