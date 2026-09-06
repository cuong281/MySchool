export interface AdminDashboardDTO {
  academicYear: string;
  semester: number;
  totalStudents: number;
  totalTeachers: number;
  totalClasses: number;
  totalGrades: number;
  averageSchoolGpa: number | null;
  gradeDistribution: Record<string, number>;

  // Attendance stats
  totalAttendanceRecords: number;
  presentCount: number;
  excusedAbsenceCount: number;
  unexcusedAbsenceCount: number;
  lateCount: number;
  attendanceRate: number | null;

  // Leave request stats
  pendingLeaveRequests: number;
  approvedLeaveRequests: number;
  rejectedLeaveRequests: number;
  totalLeaveRequests: number;
}

export interface TeacherHomeroomDashboardDTO {
  academicYear: string;
  semester: number;
  classId: number;
  className: string;
  homeroomTeacherName: string;
  totalStudents: number;
  pendingLeaveRequests: number;
  totalLeaveRequests: number;
  attendanceRate: number | null;
  totalAttendanceRecords: number;
  presentCount: number;
  excusedAbsenceCount: number;
  unexcusedAbsenceCount: number;
  lateCount: number;
  averageClassGpa: number | null;
  gradeDistribution: Record<string, number>;
}
