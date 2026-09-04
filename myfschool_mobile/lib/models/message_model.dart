class ChatMessage {
  final int id;
  final int senderUserId;
  final String senderName;
  final String senderAvatar;
  final int receiverUserId;
  final String receiverName;
  final String receiverAvatar;
  final String content;
  final DateTime? sentAt;
  final bool isRead;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    this.senderAvatar = '',
    required this.receiverUserId,
    required this.receiverName,
    this.receiverAvatar = '',
    required this.content,
    this.sentAt,
    this.isRead = false,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderUserId: json['senderUserId'] is int
          ? json['senderUserId']
          : int.tryParse(json['senderUserId']?.toString() ?? '0') ?? 0,
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      receiverUserId: json['receiverUserId'] is int
          ? json['receiverUserId']
          : int.tryParse(json['receiverUserId']?.toString() ?? '0') ?? 0,
      receiverName: json['receiverName'] ?? '',
      receiverAvatar: json['receiverAvatar'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'].toString()) : null,
      isRead: json['isRead'] ?? false,
      isMe: json['isMe'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderUserId': senderUserId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverUserId': receiverUserId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'content': content,
      'sentAt': sentAt?.toIso8601String(),
      'isRead': isRead,
      'isMe': isMe,
    };
  }
}

class ConversationItem {
  final int targetUserId;
  final String targetName;
  final String targetRole;
  final String targetAvatar;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ConversationItem({
    required this.targetUserId,
    required this.targetName,
    required this.targetRole,
    this.targetAvatar = '',
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      targetUserId: json['targetUserId'] is int
          ? json['targetUserId']
          : int.tryParse(json['targetUserId']?.toString() ?? '0') ?? 0,
      targetName: json['targetName'] ?? '',
      targetRole: json['targetRole'] ?? 'Người dùng',
      targetAvatar: json['targetAvatar'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime:
          json['lastMessageTime'] != null ? DateTime.tryParse(json['lastMessageTime'].toString()) : null,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetUserId': targetUserId,
      'targetName': targetName,
      'targetRole': targetRole,
      'targetAvatar': targetAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}
