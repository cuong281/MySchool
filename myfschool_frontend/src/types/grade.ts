export interface GradeDTO {
  id: number;
  studentId: number;
  studentName: string;
  className: string;
  subjectCode: string;
  subjectName: string;
  attendanceScore: number | null;
  midtermScore: number | null;
  finalScore: number | null;
  averageScore: number | null;
  letterGrade: string | null;
  gpa4: number | null;
  semester: number | null;
  academicYear: string | null;
  teacherName?: string;
  lastModified?: string | null;
}

export interface UpdateGradeRequest {
  attendanceScore?: number | null;
  midtermScore?: number | null;
  finalScore?: number | null;
  semester?: number | null;
}
