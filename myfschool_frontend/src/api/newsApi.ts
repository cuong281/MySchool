import { axiosClient } from './axiosClient';
import type { NewsDTO, NewsPayload } from '../types/news';

export const newsApi = {
  getAll: async (): Promise<NewsDTO[]> => {
    const response = await axiosClient.get<NewsDTO[]>('/news');
    return response.data;
  },

  getById: async (id: number): Promise<NewsDTO> => {
    const response = await axiosClient.get<NewsDTO>(`/news/${id}`);
    return response.data;
  },

  create: async (data: NewsPayload): Promise<NewsDTO> => {
    const response = await axiosClient.post<NewsDTO>('/news', data);
    return response.data;
  },

  update: async (id: number, data: Partial<NewsPayload>): Promise<NewsDTO> => {
    const response = await axiosClient.put<NewsDTO>(`/news/${id}`, data);
    return response.data;
  },

  delete: async (id: number): Promise<{ success: boolean }> => {
    const response = await axiosClient.delete<{ success: boolean }>(`/news/${id}`);
    return response.data;
  },
};
