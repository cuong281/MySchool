import { axiosClient } from './axiosClient';
import type {
  AttendanceBatchRequest,
  AttendanceClassHistoryDTO,
  AttendanceRecordDTO,
  AttendanceSheetDTO,
} from '../types/attendance';

export const attendanceApi = {
  // Lấy lịch sử điểm danh lớp
  getClassAttendanceHistory: async (
    classId: number,
    startDate?: string,
    endDate?: string
  ): Promise<AttendanceClassHistoryDTO> => {
    const params: Record<string, string> = {};
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;

    const response = await axiosClient.get<AttendanceClassHistoryDTO>(
      `/attendance/class/${classId}/history`,
      { params: Object.keys(params).length ? params : undefined }
    );
    return response.data;
  },

  // Lấy sổ điểm danh chi tiết theo tiết học
  getAttendanceSheet: async (
    classId: number,
    slotNumber: number,
    subjectId?: number,
    attendanceDate?: string
  ): Promise<AttendanceSheetDTO> => {
    const params: Record<string, string | number> = { slotNumber };
    if (subjectId != null) params.subjectId = subjectId;
    if (attendanceDate) params.attendanceDate = attendanceDate;

    const response = await axiosClient.get<AttendanceSheetDTO>(
      `/attendance/class/${classId}/sheet`,
      { params }
    );
    return response.data;
  },

  // Ghi nhận điểm danh hàng loạt (Batch)
  recordBatchAttendance: async (
    payload: AttendanceBatchRequest
  ): Promise<AttendanceRecordDTO[]> => {
    const response = await axiosClient.post<AttendanceRecordDTO[]>(
      '/attendance/batch',
      payload
    );
    return response.data;
  },

  // Lấy lịch sử điểm danh của một học sinh cụ thể
  getStudentAttendance: async (
    studentId: number
  ): Promise<AttendanceRecordDTO[]> => {
    const response = await axiosClient.get<AttendanceRecordDTO[]>(
      `/attendance/student/${studentId}`
    );
    return response.data;
  },
};
