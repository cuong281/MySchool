import { axiosClient } from './axiosClient';
import type { SubjectDTO } from '../types/grade';

export const subjectApi = {
  getAll: async (): Promise<SubjectDTO[]> => {
    const response = await axiosClient.get<SubjectDTO[]>('/subjects');
    return response.data;
  },
};
