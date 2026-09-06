import { axiosClient } from './axiosClient';
import type { AuthResponse, LoginRequest, RefreshTokenRequest } from '../types/auth';

export const authApi = {
  login: async (credentials: LoginRequest): Promise<AuthResponse> => {
    const response = await axiosClient.post<AuthResponse>('/auth/login', credentials);
    return response.data;
  },

  refreshToken: async (payload: RefreshTokenRequest): Promise<AuthResponse> => {
    const response = await axiosClient.post<AuthResponse>('/auth/refresh-token', payload);
    return response.data;
  },

  logout: async (payload?: RefreshTokenRequest): Promise<{ message: string }> => {
    try {
      const response = await axiosClient.post<{ message: string }>('/auth/logout', payload || {});
      return response.data;
    } catch {
      return { message: 'Đăng xuất thành công' };
    }
  },
};
