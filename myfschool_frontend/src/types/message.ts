export interface MessageDTO {
  id: number;
  senderUserId: number;
  senderName: string;
  senderAvatar?: string | null;
  receiverUserId: number;
  receiverName: string;
  receiverAvatar?: string | null;
  content: string;
  sentAt: string; // ISO string
  isRead: boolean;
  isMe: boolean;
}

export interface ConversationDTO {
  targetUserId: number;
  targetName: string;
  targetRole: string;
  targetAvatar?: string | null;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
}

export interface SendMessageRequest {
  receiverUserId: number;
  content: string;
}
