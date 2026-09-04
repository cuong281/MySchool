import 'dart:convert';
import '../models/message_model.dart';
import 'api_client.dart';

class MessageService {
  static final MessageService instance = MessageService._init();
  MessageService._init();

  static const String _baseUrl = '${ApiClient.baseUrl}/messages';

  Future<List<ConversationItem>> getConversations() async {
    try {
      final uri = Uri.parse('$_baseUrl/conversations');
      final response = await ApiClient.instance.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => ConversationItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getMessages(int targetUserId) async {
    try {
      final uri = Uri.parse('$_baseUrl/with/$targetUserId');
      final response = await ApiClient.instance.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendMessage(int receiverUserId, String content) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await ApiClient.instance.post(
        uri,
        body: jsonEncode({
          'receiverUserId': receiverUserId,
          'content': content.trim(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatMessage.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  Future<bool> markAsRead(int targetUserId) async {
    try {
      final uri = Uri.parse('$_baseUrl/read/$targetUserId');
      final response = await ApiClient.instance.patch(uri);
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }
}
