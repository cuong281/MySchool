import { axiosClient } from './axiosClient';
import type { LeaveRequestDTO, UpdateLeaveRequestStatusRequest } from '../types/leaveRequest';

export const leaveRequestApi = {
  getAll: async (): Promise<LeaveRequestDTO[]> => {
    const response = await axiosClient.get<LeaveRequestDTO[]>('/leave-requests');
    return response.data;
  },

  updateStatus: async (id: number, data: UpdateLeaveRequestStatusRequest): Promise<{ message: string; status: string }> => {
    const response = await axiosClient.patch<{ message: string; status: string }>(`/leave-requests/${id}/status`, data);
    return response.data;
  },
};
