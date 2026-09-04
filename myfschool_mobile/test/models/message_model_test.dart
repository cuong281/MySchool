import 'package:flutter_test/flutter_test.dart';
import 'package:myfschools/models/message_model.dart';

void main() {
  group('Message Models', () {
    test('ChatMessage fromJson/toJson roundtrip', () {
      final json = {
        'id': 101,
        'senderUserId': 1,
        'senderName': 'Admin System',
        'senderAvatar': 'https://example.com/avatar1.jpg',
        'receiverUserId': 4,
        'receiverName': 'Nguyen Van A',
        'receiverAvatar': 'https://example.com/avatar2.jpg',
        'content': 'Xin chao thay A, lich day tuan toi the nao?',
        'sentAt': '2026-09-04T10:30:00.000',
        'isRead': false,
        'isMe': true,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.id, 101);
      expect(msg.senderUserId, 1);
      expect(msg.senderName, 'Admin System');
      expect(msg.receiverUserId, 4);
      expect(msg.receiverName, 'Nguyen Van A');
      expect(msg.content, 'Xin chao thay A, lich day tuan toi the nao?');
      expect(msg.isRead, false);
      expect(msg.isMe, true);

      final out = msg.toJson();
      expect(out['id'], 101);
      expect(out['content'], 'Xin chao thay A, lich day tuan toi the nao?');
      expect(out['isMe'], true);
    });

    test('ConversationItem fromJson/toJson roundtrip', () {
      final json = {
        'targetUserId': 4,
        'targetName': 'Nguyen Van A',
        'targetRole': 'Giao vien',
        'targetAvatar': 'https://example.com/avatar2.jpg',
        'lastMessage': 'Em da hieu bai tap roi a',
        'lastMessageTime': '2026-09-04T14:20:00.000',
        'unreadCount': 2,
      };

      final item = ConversationItem.fromJson(json);

      expect(item.targetUserId, 4);
      expect(item.targetName, 'Nguyen Van A');
      expect(item.targetRole, 'Giao vien');
      expect(item.lastMessage, 'Em da hieu bai tap roi a');
      expect(item.unreadCount, 2);

      final out = item.toJson();
      expect(out['targetUserId'], 4);
      expect(out['unreadCount'], 2);
    });
  });
}
