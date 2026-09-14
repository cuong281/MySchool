export type AttendanceStatus = 'PRESENT' | 'EXCUSED_ABSENCE' | 'UNEXCUSED_ABSENCE' | 'LATE';

export interface AttendanceRecordDTO {
  id: number;
  studentId: number;
  studentName: string;
  studentCode: string;
  classId?: number;
  className?: string;
  subjectId?: number;
  subjectName?: string;
  attendanceDate: string; // LocalDate format: "YYYY-MM-DD"
  slotNumber?: number;
  status: AttendanceStatus;
  note?: string;
  recordedByName?: string;
}

export interface AttendanceSessionSummaryDTO {
  attendanceDate: string; // LocalDate format: "YYYY-MM-DD"
  slotNumber: number;
  subjectId?: number;
  subjectName?: string;
  presentCount: number;
  excusedCount: number;
  unexcusedCount: number;
  lateCount: number;
  totalCount: number;
  canEdit?: boolean;
  absentStudents?: string[];
}

export interface AttendanceStudentSummaryDTO {
  studentId: number;
  studentName: string;
  studentCode: string;
  presentCount: number;
  excusedCount: number;
  unexcusedCount: number;
  lateCount: number;
  totalTrackedSessions: number;
  attendanceRate: number;
  isAtRisk?: boolean;
  warningNote?: string;
  records?: AttendanceRecordDTO[];
}

export interface AttendanceClassHistoryDTO {
  classId: number;
  className: string;
  totalStudents: number;
  attendanceRate: number;
  totalSessions: number;
  presentCount: number;
  excusedCount: number;
  unexcusedCount: number;
  lateCount: number;
  sessions: AttendanceSessionSummaryDTO[];
  atRiskStudents?: Array<{
    studentId: number;
    studentName: string;
    studentCode: string;
    unexcusedCount: number;
    rate: number;
    warningNote: string;
  }>;
  studentSummaries: AttendanceStudentSummaryDTO[];
}

export interface AttendanceSheetStudentDTO {
  studentId: number;
  studentName: string;
  studentCode: string;
  currentStatus?: AttendanceStatus;
  hasApprovedLeave?: boolean;
  leaveRequestId?: number;
  leaveReason?: string;
  note?: string;
}

export interface AttendanceSheetDTO {
  classId: number;
  className: string;
  subjectId?: number;
  subjectName?: string;
  slotNumber: number;
  startTime?: string; // LocalTime format: "HH:mm"
  endTime?: string;   // LocalTime format: "HH:mm"
  attendanceDate: string; // LocalDate format: "YYYY-MM-DD"
  canEdit: boolean;
  lockReason?: string; // "NOT_STARTED" | "EXPIRED_PAST_DAY" | "NO_SCHEDULE" | "FUTURE_DATE"
  totalStudents: number;
  students: AttendanceSheetStudentDTO[];
}

export interface AttendanceBatchItemDTO {
  studentId: number;
  status: AttendanceStatus;
  note?: string;
  overrideLeave?: boolean;
  overrideReason?: string;
}

export interface AttendanceBatchRequest {
  classId: number;
  subjectId?: number;
  slotNumber: number;
  attendanceDate: string; // LocalDate format: "YYYY-MM-DD"
  items: AttendanceBatchItemDTO[];
}

export interface UnrecordedAttendanceSessionDTO {
  scheduleId: number;
  classId: number;
  className: string;
  subjectId?: number;
  subjectName?: string;
  teacherId?: number;
  teacherName?: string;
  slotNumber: number;
  startTime?: string;
  endTime?: string;
  totalStudents: number;
  recordedStudents: number;
  delayMinutes: number;
  delayFormatted: string;
  attendanceStatus: 'NOT_ATTENDED' | 'PARTIALLY_ATTENDED';
  alertStatus: 'CHUA_TRE' | 'CANH_BAO_TRE' | 'QUA_HAN';
  alertStatusLabel: string;
  reminderSent: boolean;
}
