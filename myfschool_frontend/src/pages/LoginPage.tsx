import React, { useState } from 'react';
import { Card, Form, Input, Button, Typography, Alert, Space } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import type { LoginRequest } from '../types/auth';

const { Title, Text } = Typography;

export const LoginPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { login } = useAuth();
  const navigate = useNavigate();

  const onFinish = async (values: LoginRequest) => {
    setLoading(true);
    setErrorMessage(null);
    try {
      await login(values.phoneNumber.trim(), values.password);
      navigate('/admin/attendance', { replace: true });
    } catch (err: any) {
      const msg =
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Đăng nhập không thành công. Vui lòng kiểm tra lại số điện thoại và mật khẩu.';
      setErrorMessage(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #F0F4F8 0%, #E2E8F0 100%)',
        padding: 16,
      }}
    >
      <Card
        style={{
          width: '100%',
          maxWidth: 420,
          borderRadius: 16,
          boxShadow: '0 10px 25px rgba(0, 0, 0, 0.05)',
        }}
        bordered={false}
      >
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div
            style={{
              width: 52,
              height: 52,
              borderRadius: 12,
              background: 'linear-gradient(135deg, #2563EB 0%, #3B82F6 100%)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#fff',
              fontWeight: 'bold',
              fontSize: 26,
              marginBottom: 12,
            }}
          >
            M
          </div>
          <Title level={3} style={{ marginBottom: 4, color: '#0F172A' }}>
            MySchool Admin
          </Title>
          <Text type="secondary">Cổng Quản trị & Điều hành Trường học</Text>
        </div>

        {errorMessage && (
          <Alert
            message={errorMessage}
            type="error"
            showIcon
            closable
            onClose={() => setErrorMessage(null)}
            style={{ marginBottom: 20 }}
          />
        )}

        <Form layout="vertical" onFinish={onFinish} requiredMark={false} size="large">
          <Form.Item
            name="phoneNumber"
            label="Số điện thoại"
            rules={[
              { required: true, message: 'Vui lòng nhập số điện thoại' },
              { pattern: /^[0-9+]{9,15}$/, message: 'Số điện thoại không đúng định dạng' },
            ]}
          >
            <Input prefix={<UserOutlined style={{ color: '#94A3B8' }} />} placeholder="Ví dụ: 0909999999" />
          </Form.Item>

          <Form.Item
            name="password"
            label="Mật khẩu"
            rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
          >
            <Input.Password prefix={<LockOutlined style={{ color: '#94A3B8' }} />} placeholder="Nhập mật khẩu" />
          </Form.Item>

          <Form.Item style={{ marginTop: 24 }}>
            <Button type="primary" htmlType="submit" block loading={loading} style={{ height: 44, fontWeight: 600 }}>
              Đăng nhập
            </Button>
          </Form.Item>
        </Form>

        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <Space direction="vertical" size={2}>
            <Text type="secondary" style={{ fontSize: 12 }}>
              Hệ thống Quản lý Điểm danh & Điểm số MySchool
            </Text>
          </Space>
        </div>
      </Card>
    </div>
  );
};
