export interface LoginRequest {
  phoneNumber: string;
  password: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn?: number;
  userId: number;
  username: string;
  email?: string;
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
  roles: string[];
  studentId?: number | null;
  teacherId?: number | null;
  classId?: number | null;
  className?: string | null;
  message?: string;
}

export interface UserProfile {
  userId: number;
  username: string;
  fullName: string;
  email?: string;
  phoneNumber?: string;
  roles: string[];
  studentId?: number | null;
  teacherId?: number | null;
  classId?: number | null;
  className?: string | null;
}
