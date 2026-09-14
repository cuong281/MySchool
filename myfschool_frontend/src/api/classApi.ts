import { axiosClient } from './axiosClient';
import type { SchoolClassDTO } from '../types/schoolClass';
import type { StudentDTO } from '../types/grade';

export const classApi = {
  getAllClasses: async (): Promise<SchoolClassDTO[]> => {
    const response = await axiosClient.get<SchoolClassDTO[]>('/classes');
    return response.data;
  },

  getStudents: async (classId: number): Promise<StudentDTO[]> => {
    const response = await axiosClient.get<StudentDTO[]>(`/classes/${classId}/students`);
    return response.data;
  },
};
