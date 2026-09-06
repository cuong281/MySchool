export interface TeacherContactDTO {
  teacherId: number;
  userId: number | null;
  fullName: string;
  email: string;
  phone: string | null;
  avatarUrl?: string | null;
  subjectName?: string | null;
  roleType?: string | null;
  isHomeroom?: boolean;
  isPhonePublic?: boolean;
  status?: string | null;
}

export interface SchoolDepartmentContact {
  id: string;
  name: string;
  email: string;
  phoneNumber: string;
  department: string;
  location?: string;
  workingHours?: string;
  description?: string;
}
