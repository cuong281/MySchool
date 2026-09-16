import React, { useState } from 'react';
import { Form, Input, Button, Alert } from 'antd';
import { PhoneOutlined, LockOutlined, ArrowRightOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import type { LoginRequest } from '../types/auth';

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
        width: '100%',
        display: 'flex',
        backgroundColor: '#FFFFFF',
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
      }}
    >
      {/* LEFT SIDE: Clean Minimalist Branding (No Image) */}
      <div
        style={{
          flex: '1.15',
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '48px 56px',
          background: 'linear-gradient(150deg, #0B1120 0%, #0F172A 55%, #1E293B 100%)',
          borderTopRightRadius: 28,
          borderBottomRightRadius: 28,
          overflow: 'hidden',
          minHeight: '100vh',
        }}
        className="login-hero-banner"
      >
        {/* Subtle geometric light accent */}
        <div
          style={{
            position: 'absolute',
            top: -120,
            right: -120,
            width: 360,
            height: 360,
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(249, 115, 22, 0.12) 0%, transparent 70%)',
            pointerEvents: 'none',
          }}
        />

        {/* Content Wrapper Top: Logo */}
        <div style={{ position: 'relative', zIndex: 2, display: 'flex', alignItems: 'center', gap: 14 }}>
          {/* Logo F */}
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 12,
              backgroundColor: '#F97316',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#FFFFFF',
              fontWeight: 900,
              fontSize: 22,
              boxShadow: '0 4px 14px rgba(249, 115, 22, 0.35)',
            }}
          >
            F
          </div>
          <div>
            <div
              style={{
                color: '#FFFFFF',
                fontWeight: 800,
                fontSize: 16,
                letterSpacing: '0.04em',
                lineHeight: 1.2,
              }}
            >
              FPT HIGH SCHOOL
            </div>
            <div
              style={{
                color: 'rgba(255, 255, 255, 0.65)',
                fontSize: 12,
                fontWeight: 500,
                letterSpacing: '0.02em',
              }}
            >
              Digital Learning Nexus
            </div>
          </div>
        </div>

        {/* Middle: Inspiring Title & Slogan */}
        <div style={{ position: 'relative', zIndex: 2, margin: '60px 0 40px 0', maxWidth: 540 }}>
          {/* Tagline Pill */}
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 8,
              padding: '6px 16px',
              borderRadius: 20,
              backgroundColor: 'rgba(249, 115, 22, 0.12)',
              border: '1px solid rgba(249, 115, 22, 0.35)',
              color: '#F97316',
              fontSize: 13,
              fontWeight: 600,
              marginBottom: 24,
            }}
          >
            <span style={{ fontSize: 13 }}>✦</span>
            <span>Thế hệ đổi mới sáng tạo</span>
          </div>

          {/* Heading */}
          <h1
            style={{
              fontSize: 'clamp(32px, 3.4vw, 48px)',
              fontWeight: 800,
              color: '#FFFFFF',
              lineHeight: 1.22,
              letterSpacing: '-0.02em',
              marginBottom: 20,
            }}
          >
            Định hình <span style={{ color: '#F97316' }}>tương lai</span>
            <br />
            bằng tri thức &amp;
            <br />
            công nghệ.
          </h1>

          {/* Paragraph */}
          <p
            style={{
              fontSize: 15,
              lineHeight: 1.65,
              color: 'rgba(255, 255, 255, 0.72)',
              fontWeight: 400,
              maxWidth: 480,
            }}
          >
            Cổng quản trị &amp; điều hành trường THPT FPT — nơi dữ liệu học tập chuyển đổi thành động
            lực phát triển.
          </p>
        </div>

        {/* Bottom Stats Metrics */}
        <div
          style={{
            position: 'relative',
            zIndex: 2,
            display: 'flex',
            alignItems: 'center',
            gap: 28,
            paddingTop: 24,
            borderTop: '1px solid rgba(255, 255, 255, 0.12)',
          }}
        >
          <div>
            <div style={{ fontSize: 26, fontWeight: 800, color: '#FFFFFF', lineHeight: 1.1 }}>12K+</div>
            <div style={{ fontSize: 13, color: 'rgba(255, 255, 255, 0.65)', marginTop: 4 }}>
              Học sinh
            </div>
          </div>
          <div style={{ width: 1, height: 32, backgroundColor: 'rgba(255, 255, 255, 0.15)' }} />
          <div>
            <div style={{ fontSize: 26, fontWeight: 800, color: '#FFFFFF', lineHeight: 1.1 }}>98%</div>
            <div style={{ fontSize: 13, color: 'rgba(255, 255, 255, 0.65)', marginTop: 4 }}>
              Tốt nghiệp
            </div>
          </div>
          <div style={{ width: 1, height: 32, backgroundColor: 'rgba(255, 255, 255, 0.15)' }} />
          <div>
            <div style={{ fontSize: 26, fontWeight: 800, color: '#F97316', lineHeight: 1.1 }}>#1</div>
            <div style={{ fontSize: 13, color: 'rgba(255, 255, 255, 0.65)', marginTop: 4 }}>
              Đổi mới
            </div>
          </div>
        </div>
      </div>

      {/* RIGHT SIDE: Clean White Login Form */}
      <div
        style={{
          flex: '1',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '48px 32px',
          backgroundColor: '#FFFFFF',
          minHeight: '100vh',
        }}
      >
        <div style={{ width: '100%', maxWidth: 440, margin: 'auto' }}>
          {/* Header */}
          <div style={{ marginBottom: 32 }}>
            <div
              style={{
                color: '#F97316',
                fontWeight: 700,
                fontSize: 13,
                letterSpacing: '0.08em',
                textTransform: 'uppercase',
                marginBottom: 8,
              }}
            >
              CỔNG QUẢN TRỊ
            </div>
            <h2
              style={{
                fontSize: 32,
                fontWeight: 800,
                color: '#0F172A',
                letterSpacing: '-0.02em',
                margin: 0,
                marginBottom: 8,
              }}
            >
              Đăng nhập hệ thống
            </h2>
            <p style={{ fontSize: 15, color: '#64748B', margin: 0 }}>
              Vui lòng nhập thông tin để truy cập bảng điều khiển.
            </p>
          </div>

          {/* Error Message */}
          {errorMessage && (
            <Alert
              message={errorMessage}
              type="error"
              showIcon
              closable
              onClose={() => setErrorMessage(null)}
              style={{ marginBottom: 24, borderRadius: 10 }}
            />
          )}

          {/* Form */}
          <Form layout="vertical" onFinish={onFinish} requiredMark={false}>
            {/* Phone Number Field */}
            <Form.Item
              name="phoneNumber"
              label={
                <span
                  style={{
                    fontSize: 12,
                    fontWeight: 700,
                    color: '#64748B',
                    letterSpacing: '0.04em',
                    textTransform: 'uppercase',
                  }}
                >
                  SỐ ĐIỆN THOẠI
                </span>
              }
              rules={[
                { required: true, message: 'Vui lòng nhập số điện thoại hoặc tên đăng nhập' },
              ]}
              style={{ marginBottom: 20 }}
            >
              <Input
                prefix={<PhoneOutlined style={{ color: '#94A3B8', fontSize: 16, marginRight: 8 }} />}
                placeholder="0901 234 567"
                style={{
                  height: 50,
                  borderRadius: 10,
                  borderColor: '#E2E8F0',
                  backgroundColor: '#FFFFFF',
                  fontSize: 15,
                  padding: '0 16px',
                }}
              />
            </Form.Item>

            {/* Password Field */}
            <Form.Item
              name="password"
              label={
                <span
                  style={{
                    fontSize: 12,
                    fontWeight: 700,
                    color: '#64748B',
                    letterSpacing: '0.04em',
                    textTransform: 'uppercase',
                  }}
                >
                  MẬT KHẨU
                </span>
              }
              rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
              style={{ marginBottom: 28 }}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#94A3B8', fontSize: 16, marginRight: 8 }} />}
                placeholder="••••••••"
                style={{
                  height: 50,
                  borderRadius: 10,
                  borderColor: '#E2E8F0',
                  backgroundColor: '#FFFFFF',
                  fontSize: 15,
                  padding: '0 16px',
                }}
              />
            </Form.Item>

            {/* Submit Button */}
            <Form.Item style={{ marginBottom: 0 }}>
              <Button
                type="primary"
                htmlType="submit"
                block
                loading={loading}
                style={{
                  height: 50,
                  borderRadius: 10,
                  backgroundColor: '#F97316',
                  borderColor: '#F97316',
                  fontSize: 16,
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  boxShadow: '0 4px 14px rgba(249, 115, 22, 0.35)',
                }}
              >
                <span>Đăng nhập</span>
                <ArrowRightOutlined style={{ fontSize: 14 }} />
              </Button>
            </Form.Item>
          </Form>
        </div>

        {/* Footer */}
        <div style={{ textAlign: 'center', marginTop: 32 }}>
          <span style={{ fontSize: 13, color: '#94A3B8' }}>
            Hệ thống Quản lý Điểm danh &amp; Điểm số · THPT FPT
          </span>
        </div>
      </div>

      {/* Responsive Style to hide hero on small mobile screens */}
      <style>{`
        @media (max-width: 900px) {
          .login-hero-banner {
            display: none !important;
          }
        }
      `}</style>
    </div>
  );
};
