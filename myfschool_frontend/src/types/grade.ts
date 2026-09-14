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

export interface GradeBatchImportItem {
  studentId?: number;
  studentCode?: string;
  studentName?: string;
  subjectId?: number;
  subjectCode?: string;
  semester?: number;
  attendanceScore?: number | null;
  midtermScore?: number | null;
  finalScore?: number | null;
  score?: number | null;
  rowNumber?: number;
}

export interface GradeBatchImportRequest {
  importType: 'IMPORT_ALL' | 'IMPORT_MIDTERM' | 'IMPORT_FINAL';
  classId: number;
  subjectId?: number;
  subjectCode?: string;
  schoolYearId?: number;
  semester?: number;
  items: GradeBatchImportItem[];
}

export interface GradeImportError {
  rowNumber?: number;
  studentId?: number;
  studentCode?: string;
  studentName?: string;
  field?: string;
  message: string;
}

export interface GradeBatchImportResponse {
  success: boolean;
  totalProcessed: number;
  createdCount: number;
  updatedCount: number;
  failedCount: number;
  errors: GradeImportError[];
}

export interface StudentDTO {
  id: number;
  studentCode: string;
  fullName: string;
  classId?: number;
  className?: string;
  gender?: string;
  dateOfBirth?: string;
}

export interface SubjectDTO {
  id: number;
  subjectCode: string;
  subjectName: string;
  isActive: boolean;
}

