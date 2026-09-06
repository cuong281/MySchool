import { axiosClient } from './axiosClient';
import type { GradeDTO } from '../types/grade';

export const gradeApi = {
  getAll: async (): Promise<GradeDTO[]> => {
    const response = await axiosClient.get<GradeDTO[]>('/grades');
    return response.data;
  },

  getByClass: async (classId: number): Promise<GradeDTO[]> => {
    const response = await axiosClient.get<GradeDTO[]>(`/grades/class/${classId}`);
    return response.data;
  },

  getById: async (id: number): Promise<GradeDTO> => {
    const response = await axiosClient.get<GradeDTO>(`/grades/${id}`);
    return response.data;
  },

  update: async (id: number, data: Partial<GradeDTO>): Promise<GradeDTO> => {
    const response = await axiosClient.put<GradeDTO>(`/grades/${id}`, data);
    return response.data;
  },

  create: async (data: Partial<GradeDTO>): Promise<GradeDTO> => {
    const response = await axiosClient.post<GradeDTO>('/grades', data);
    return response.data;
  },

  delete: async (id: number): Promise<{ success: boolean }> => {
    const response = await axiosClient.delete<{ success: boolean }>(`/grades/${id}`);
    return response.data;
  },
};
