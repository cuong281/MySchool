import { axiosClient } from './axiosClient';
import type { ScheduleDayDTO } from '../types/schedule';

export const scheduleApi = {
  getByClass: async (classId: number): Promise<ScheduleDayDTO[]> => {
    const response = await axiosClient.get<ScheduleDayDTO[]>(`/schedules/class/${classId}`);
    return response.data;
  },

  getMySchedule: async (): Promise<ScheduleDayDTO[]> => {
    const response = await axiosClient.get<ScheduleDayDTO[]>('/schedules/me');
    return response.data;
  },

  getByTeacher: async (teacherId: number): Promise<ScheduleDayDTO[]> => {
    const response = await axiosClient.get<ScheduleDayDTO[]>(`/schedules/teacher/${teacherId}`);
    return response.data;
  },
};
