import React, { createContext, useContext, useState, useEffect } from 'react';
import type { UserProfile } from '../types/auth';
import { authApi } from '../api/authApi';

interface AuthContextType {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phoneNumber: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  isAdmin: boolean;
  isTeacher: boolean;
  hasRole: (role: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Restore session on mount
  useEffect(() => {
    try {
      const storedToken = localStorage.getItem('accessToken');
      const storedUser = localStorage.getItem('userData');
      if (storedToken && storedUser) {
        const parsed = JSON.parse(storedUser) as UserProfile;
        setUser(parsed);
        setIsAuthenticated(true);
      }
    } catch {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('userData');
    } finally {
      setIsLoading(false);
    }

    // Listen for session expiration dispatched by axiosClient
    const handleSessionExpired = () => {
      setUser(null);
      setIsAuthenticated(false);
    };

    window.addEventListener('auth:session_expired', handleSessionExpired);
    return () => window.removeEventListener('auth:session_expired', handleSessionExpired);
  }, []);

  const login = async (phoneNumber: string, password: string) => {
    const data = await authApi.login({ phoneNumber, password });

    localStorage.setItem('accessToken', data.accessToken);
    if (data.refreshToken) {
      localStorage.setItem('refreshToken', data.refreshToken);
    }

    const profile: UserProfile = {
      userId: data.userId,
      username: data.username,
      fullName: `${data.lastName || ''} ${data.firstName || ''}`.trim() || data.username,
      email: data.email,
      phoneNumber: data.phoneNumber,
      roles: data.roles || [],
      studentId: data.studentId,
      teacherId: data.teacherId,
      classId: data.classId,
      className: data.className,
    };

    localStorage.setItem('userData', JSON.stringify(profile));
    setUser(profile);
    setIsAuthenticated(true);
  };

  const logout = async () => {
    const refreshToken = localStorage.getItem('refreshToken') || undefined;
    try {
      await authApi.logout({ refreshToken: refreshToken || '' });
    } finally {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('userData');
      setUser(null);
      setIsAuthenticated(false);
    }
  };

  const hasRole = (role: string): boolean => {
    if (!user || !user.roles) return false;
    const target = role.toUpperCase().replace('ROLE_', '');
    return user.roles.some((r) => r.toUpperCase().replace('ROLE_', '') === target);
  };

  const isAdmin = hasRole('ADMIN');
  const isTeacher = hasRole('TEACHER');

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated,
        isLoading,
        login,
        logout,
        isAdmin,
        isTeacher,
        hasRole,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
