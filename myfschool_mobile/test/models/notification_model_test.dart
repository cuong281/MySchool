import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('NotificationModel fromJson/toJson roundtrip', () {
      final json = {
        'id': 101,
        'userId': 2,
        'title': 'Điểm số mới',
        'body': 'Điểm môn Toán học đã được cập nhật.',
        'type': 'GRADE_UPDATE',
        'referenceId': 49,
        'isRead': false,
        'createdAt': '2026-09-04T08:00:00.000',
        'readAt': null,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 101);
      expect(model.userId, 2);
      expect(model.title, 'Điểm số mới');
      expect(model.type, 'GRADE_UPDATE');
      expect(model.referenceId, 49);
      expect(model.isRead, false);
      expect(model.readAt, isNull);

      final serialized = model.toJson();
      expect(serialized['id'], 101);
      expect(serialized['title'], 'Điểm số mới');
      expect(serialized['isRead'], false);
    });

    test('NotificationModel copyWith updates fields correctly', () {
      final model = NotificationModel(
        id: 1,
        title: 'Title',
        body: 'Body',
        type: 'SYSTEM',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(isRead: true);
      expect(updated.id, 1);
      expect(updated.title, 'Title');
      expect(updated.isRead, true);
    });
  });
}
