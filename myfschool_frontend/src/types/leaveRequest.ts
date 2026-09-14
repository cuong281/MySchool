export type LeaveRequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface LeaveRequestDTO {
  id: number;
  requestType: string;
  fromDate: string; // YYYY-MM-DD
  toDate: string;   // YYYY-MM-DD
  reason: string;
  status: LeaveRequestStatus | string;
  adminNote?: string | null;
  studentName: string;
  studentCode: string;
  className?: string;
}

export interface UpdateLeaveRequestStatusRequest {
  status: 'APPROVED' | 'REJECTED' | 'Đã duyệt' | 'Từ chối' | string;
  adminNote?: string;
}
