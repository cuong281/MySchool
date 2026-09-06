import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from '../components/layout/ProtectedRoute';
import { AdminLayout } from '../components/layout/AdminLayout';
import { LoginPage } from '../pages/LoginPage';
import { AttendanceManagementPage } from '../pages/admin/AttendanceManagementPage';
import { LeaveRequestManagementPage } from '../pages/admin/LeaveRequestManagementPage';
import { GradeManagementPage } from '../pages/admin/GradeManagementPage';
import { SchedulePage } from '../pages/admin/SchedulePage';
import { ReportPage } from '../pages/admin/ReportPage';
import { NewsManagementPage } from '../pages/admin/NewsManagementPage';
import { EventManagementPage } from '../pages/admin/EventManagementPage';
import { ContactPage } from '../pages/admin/ContactPage';
import { Result, Button } from 'antd';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Public Route */}
      <Route path="/login" element={<LoginPage />} />

      {/* Protected Admin Routes */}
      <Route element={<ProtectedRoute allowedRoles={['ADMIN', 'TEACHER']} />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Navigate to="/admin/attendance" replace />} />
          <Route path="attendance" element={<AttendanceManagementPage />} />
          <Route path="leave-requests" element={<LeaveRequestManagementPage />} />
          <Route path="grades" element={<GradeManagementPage />} />
          <Route path="schedules" element={<SchedulePage />} />
          <Route path="reports" element={<ReportPage />} />
          <Route path="contacts" element={<ContactPage />} />
          <Route path="news" element={<NewsManagementPage />} />
          <Route path="events" element={<EventManagementPage />} />
        </Route>
      </Route>

      {/* Root redirect */}
      <Route path="/" element={<Navigate to="/admin/attendance" replace />} />

      {/* 404 Route */}
      <Route
        path="*"
        element={
          <Result
            status="404"
            title="404"
            subTitle="Trang bạn truy cập không tồn tại."
            extra={
              <Button type="primary" href="/admin/attendance">
                Trở về trang chủ
              </Button>
            }
          />
        }
      />
    </Routes>
  );
};
