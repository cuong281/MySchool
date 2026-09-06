import React, { useState, useEffect, useRef } from 'react';
import {
  Drawer,
  Input,
  Button,
  Avatar,
  Space,
  Typography,
  Tag,
  Spin,
  Empty,
  message,
} from 'antd';
import {
  SendOutlined,
  UserOutlined,
  StarFilled,
  RedoOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { messageApi } from '../../api/messageApi';
import type { MessageDTO } from '../../types/message';

const { Text } = Typography;
const { TextArea } = Input;

interface ChatDrawerProps {
  open: boolean;
  onClose: () => void;
  targetUserId: number | null;
  targetName: string;
  targetRole?: string;
  targetAvatar?: string | null;
  targetSubject?: string | null;
  isHomeroom?: boolean;
}

export const ChatDrawer: React.FC<ChatDrawerProps> = ({
  open,
  onClose,
  targetUserId,
  targetName,
  targetAvatar,
  targetSubject,
  isHomeroom,
}) => {
  const queryClient = useQueryClient();
  const [inputText, setInputText] = useState<string>('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // 1. Fetch Messages with target user
  const {
    data: messages = [],
    isLoading,
    isFetching,
    refetch,
  } = useQuery<MessageDTO[]>({
    queryKey: ['chatMessages', targetUserId],
    queryFn: () => messageApi.getMessagesWith(targetUserId!),
    enabled: open && targetUserId !== null && targetUserId > 0,
    refetchInterval: open ? 4000 : false, // Poll every 4s while drawer is open
  });

  // Mark as read when drawer opens
  useEffect(() => {
    if (open && targetUserId) {
      messageApi.markAsRead(targetUserId).catch(() => {});
    }
  }, [open, targetUserId]);

  // Scroll to bottom on messages change
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    if (open && messages.length > 0) {
      scrollToBottom();
    }
  }, [open, messages]);

  // 2. Send Message Mutation
  const sendMutation = useMutation({
    mutationFn: (content: string) =>
      messageApi.sendMessage({ receiverUserId: targetUserId!, content }),
    onSuccess: (newMessage) => {
      setInputText('');
      queryClient.setQueryData<MessageDTO[]>(['chatMessages', targetUserId], (old = []) => [
        ...old,
        newMessage,
      ]);
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
      setTimeout(scrollToBottom, 100);
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Không thể gửi tin nhắn');
    },
  });

  const handleSend = () => {
    const trimmed = inputText.trim();
    if (!trimmed || sendMutation.isPending || !targetUserId) return;
    sendMutation.mutate(trimmed);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const formatMessageTime = (dateStr: string) => {
    const d = dayjs(dateStr);
    const now = dayjs();
    if (d.isSame(now, 'day')) {
      return d.format('HH:mm');
    }
    return d.format('DD/MM HH:mm');
  };

  return (
    <Drawer
      title={
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Avatar
            size={42}
            src={targetAvatar}
            icon={<UserOutlined />}
            style={{ backgroundColor: isHomeroom ? '#F59E0B' : '#2563EB' }}
          />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Text strong style={{ fontSize: 15, color: '#0F172A' }}>
                {targetName}
              </Text>
              {isHomeroom && (
                <Tag color="warning" icon={<StarFilled />} style={{ fontSize: 10, padding: '0 4px' }}>
                  GVCN
                </Tag>
              )}
            </div>
            <div style={{ fontSize: 12, color: '#64748B' }}>
              {targetSubject ? `Bộ môn: ${targetSubject}` : 'Giáo viên trường'}
            </div>
          </div>
        </div>
      }
      placement="right"
      width={460}
      open={open}
      onClose={onClose}
      extra={
        <Button
          type="text"
          size="small"
          icon={<RedoOutlined spin={isFetching} />}
          onClick={() => refetch()}
          title="Làm mới cuộc trò chuyện"
        />
      }
      bodyStyle={{
        padding: 0,
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        backgroundColor: '#F8FAFC',
      }}
    >
      {/* Messages Container */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 20px',
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
        }}
      >
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <Spin tip="Đang tải đoạn hội thoại..." />
          </div>
        ) : messages.length === 0 ? (
          <div style={{ textAlign: 'center', margin: 'auto 0', padding: '40px 20px' }}>
            <Empty
              image={Empty.PRESENTED_IMAGE_SIMPLE}
              description={
                <div>
                  <Text strong style={{ color: '#64748B' }}>
                    Chưa có tin nhắn nào
                  </Text>
                  <div style={{ fontSize: 12, color: '#94A3B8', marginTop: 4 }}>
                    Gửi tin nhắn đầu tiên để bắt đầu trao đổi với {targetName}
                  </div>
                </div>
              }
            />
          </div>
        ) : (
          messages.map((msg, index) => {
            const isMe = msg.isMe;
            return (
              <div
                key={msg.id || index}
                style={{
                  display: 'flex',
                  justifyContent: isMe ? 'flex-end' : 'flex-start',
                  alignItems: 'flex-end',
                  gap: 8,
                }}
              >
                {!isMe && (
                  <Avatar
                    size={28}
                    src={msg.senderAvatar || targetAvatar}
                    icon={<UserOutlined />}
                    style={{ backgroundColor: '#CBD5E1', marginBottom: 4 }}
                  />
                )}
                <div
                  style={{
                    maxWidth: '75%',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: isMe ? 'flex-end' : 'flex-start',
                  }}
                >
                  <div
                    style={{
                      background: isMe ? '#2563EB' : '#FFFFFF',
                      color: isMe ? '#FFFFFF' : '#0F172A',
                      padding: '10px 14px',
                      borderRadius: isMe ? '16px 16px 2px 16px' : '16px 16px 16px 2px',
                      boxShadow: '0 1px 2px rgba(0,0,0,0.04)',
                      border: isMe ? 'none' : '1px solid #E2E8F0',
                      fontSize: 14,
                      lineHeight: 1.5,
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                    }}
                  >
                    {msg.content}
                  </div>
                  <Text
                    type="secondary"
                    style={{ fontSize: 10, marginTop: 4, padding: '0 4px' }}
                  >
                    {formatMessageTime(msg.sentAt)}
                  </Text>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Message Footer */}
      <div
        style={{
          background: '#FFFFFF',
          padding: '12px 16px',
          borderTop: '1px solid #E2E8F0',
        }}
      >
        <Space.Compact style={{ width: '100%' }}>
          <TextArea
            rows={2}
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Nhập tin nhắn... (Enter để gửi)"
            autoSize={{ minRows: 1, maxRows: 4 }}
            style={{ borderRadius: '8px 0 0 8px', resize: 'none' }}
          />
          <Button
            type="primary"
            icon={<SendOutlined />}
            onClick={handleSend}
            loading={sendMutation.isPending}
            disabled={!inputText.trim()}
            style={{
              height: 'auto',
              borderRadius: '0 8px 8px 0',
              backgroundColor: '#2563EB',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            Gửi
          </Button>
        </Space.Compact>
      </div>
    </Drawer>
  );
};
