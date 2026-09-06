import { axiosClient } from './axiosClient';
import type { SchoolClassDTO } from '../types/schoolClass';

export const classApi = {
  getAllClasses: async (): Promise<SchoolClassDTO[]> => {
    const response = await axiosClient.get<SchoolClassDTO[]>('/classes');
    return response.data;
  },
};
