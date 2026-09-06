import { axiosClient } from './axiosClient';
import type { AdminDashboardDTO, TeacherHomeroomDashboardDTO } from '../types/report';

export const reportApi = {
  getAdminDashboard: async (academicYear?: string, semester?: number): Promise<AdminDashboardDTO> => {
    const params: Record<string, any> = {};
    if (academicYear) params.academicYear = academicYear;
    if (semester) params.semester = semester;
    const response = await axiosClient.get<AdminDashboardDTO>('/reports/admin/dashboard', { params });
    return response.data;
  },

  getHomeroomDashboard: async (academicYear?: string, semester?: number): Promise<TeacherHomeroomDashboardDTO> => {
    const params: Record<string, any> = {};
    if (academicYear) params.academicYear = academicYear;
    if (semester) params.semester = semester;
    const response = await axiosClient.get<TeacherHomeroomDashboardDTO>('/reports/teacher/homeroom', { params });
    return response.data;
  },
};
