import { axiosClient } from './axiosClient';
import type { MessageDTO, ConversationDTO, SendMessageRequest } from '../types/message';

export const messageApi = {
  getConversations: async (): Promise<ConversationDTO[]> => {
    const response = await axiosClient.get<ConversationDTO[]>('/messages/conversations');
    return response.data;
  },

  getMessagesWith: async (targetUserId: number): Promise<MessageDTO[]> => {
    const response = await axiosClient.get<MessageDTO[]>(`/messages/with/${targetUserId}`);
    return response.data;
  },

  sendMessage: async (data: SendMessageRequest): Promise<MessageDTO> => {
    const response = await axiosClient.post<MessageDTO>('/messages', data);
    return response.data;
  },

  markAsRead: async (targetUserId: number): Promise<{ success: boolean; message: string }> => {
    const response = await axiosClient.patch<{ success: boolean; message: string }>(`/messages/read/${targetUserId}`);
    return response.data;
  },
};
