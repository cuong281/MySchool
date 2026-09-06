import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { Spin, Result, Button } from 'antd';
import { useAuth } from '../../context/AuthContext';

interface ProtectedRouteProps {
  requiredRole?: string;
  allowedRoles?: string[];
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ requiredRole, allowedRoles }) => {
  const { isAuthenticated, isLoading, hasRole, user } = useAuth();

  if (isLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <Spin size="large" tip="Đang xác thực tài khoản..." />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requiredRole && !hasRole(requiredRole)) {
    return (
      <Result
        status="403"
        title="403"
        subTitle={`Xin lỗi, bạn không có quyền truy cập vào khu vực này (Tài khoản: ${user?.username}).`}
        extra={<Button type="primary" href="/login">Đăng nhập tài khoản khác</Button>}
      />
    );
  }

  if (allowedRoles && allowedRoles.length > 0) {
    const hasAny = allowedRoles.some((r) => hasRole(r));
    if (!hasAny) {
      return (
        <Result
          status="403"
          title="403"
          subTitle="Xin lỗi, bạn không có quyền truy cập vào chức năng này."
          extra={<Button type="primary" href="/login">Quay lại</Button>}
        />
      );
    }
  }

  return <Outlet />;
};
