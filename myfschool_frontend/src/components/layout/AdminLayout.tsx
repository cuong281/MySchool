import React, { useState } from 'react';
import { Layout, Menu, Typography, Dropdown, Avatar, Space, Button, theme } from 'antd';
import {
  CheckSquareOutlined,
  FileTextOutlined,
  BookOutlined,
  CalendarOutlined,
  BarChartOutlined,
  NotificationOutlined,
  TrophyOutlined,
  ContactsOutlined,
  LogoutOutlined,
  UserOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const { Header, Sider, Content } = Layout;
const { Text } = Typography;

export const AdminLayout: React.FC = () => {
  const [collapsed, setCollapsed] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout, isAdmin } = useAuth();
  const { token } = theme.useToken();

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const userMenuItems = [
    {
      key: 'user-info',
      label: (
        <div style={{ padding: '4px 0' }}>
          <Text strong>{user?.fullName || user?.username}</Text>
          <br />
          <Text type="secondary" style={{ fontSize: 12 }}>
            {isAdmin ? 'Quản trị viên (Admin)' : 'Giáo viên'}
          </Text>
        </div>
      ),
      disabled: true,
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Đăng xuất',
      danger: true,
      onClick: handleLogout,
    },
  ];

  const menuItems = [
    {
      type: 'group' as const,
      label: 'HỌC TẬP',
      children: [
        {
          key: '/admin/attendance',
          icon: <CheckSquareOutlined />,
          label: 'Quản lý điểm danh',
        },
        {
          key: '/admin/grades',
          icon: <BookOutlined />,
          label: 'Quản lý bảng điểm',
        },
        {
          key: '/admin/schedules',
          icon: <CalendarOutlined />,
          label: 'Thời khóa biểu',
        },
      ],
    },
    {
      type: 'group' as const,
      label: 'QUẢN LÝ',
      children: [
        {
          key: '/admin/leave-requests',
          icon: <FileTextOutlined />,
          label: 'Duyệt đơn nghỉ phép',
        },
        {
          key: '/admin/reports',
          icon: <BarChartOutlined />,
          label: 'Báo cáo & Thống kê',
        },
        {
          key: '/admin/contacts',
          icon: <ContactsOutlined />,
          label: 'Thông tin liên lạc',
        },
      ],
    },
    {
      type: 'group' as const,
      label: 'TRUYỀN THÔNG',
      children: [
        {
          key: '/admin/news',
          icon: <NotificationOutlined />,
          label: 'Tin tức & Thông báo',
        },
        {
          key: '/admin/events',
          icon: <TrophyOutlined />,
          label: 'Sự kiện trường',
        },
      ],
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        theme="light"
        width={240}
        style={{
          borderRight: `1px solid ${token.colorBorderSecondary}`,
          position: 'sticky',
          top: 0,
          height: '100vh',
          zIndex: 10,
        }}
      >
        <div
          style={{
            height: 64,
            display: 'flex',
            alignItems: 'center',
            padding: collapsed ? '0 20px' : '0 20px',
            borderBottom: `1px solid ${token.colorBorderSecondary}`,
            gap: 10,
          }}
        >
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: 8,
              background: 'linear-gradient(135deg, #2563EB 0%, #3B82F6 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#fff',
              fontWeight: 'bold',
              fontSize: 18,
            }}
          >
            M
          </div>
          {!collapsed && (
            <div>
              <Text strong style={{ fontSize: 16, color: '#0F172A', display: 'block', lineHeight: 1.2 }}>
                MySchool
              </Text>
              <Text type="secondary" style={{ fontSize: 11 }}>
                Admin Portal
              </Text>
            </div>
          )}
        </div>

        <Menu
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={handleMenuClick}
          style={{ borderRight: 0, marginTop: 12 }}
        />
      </Sider>

      <Layout>
        <Header
          style={{
            padding: '0 24px',
            background: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: `1px solid ${token.colorBorderSecondary}`,
            position: 'sticky',
            top: 0,
            zIndex: 9,
            height: 64,
          }}
        >
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            style={{ fontSize: '16px', width: 44, height: 44 }}
          />

          <Space size={16}>
            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" trigger={['click']}>
              <Space style={{ cursor: 'pointer', padding: '4px 8px', borderRadius: 8 }}>
                <Avatar
                  style={{ backgroundColor: '#2563EB' }}
                  icon={<UserOutlined />}
                />
                <div style={{ display: 'none', lineHeight: 1.2, textAlign: 'left' }} className="user-text-container">
                  <Text strong style={{ fontSize: 13, display: 'block' }}>
                    {user?.fullName || user?.username}
                  </Text>
                  <Text type="secondary" style={{ fontSize: 11 }}>
                    {isAdmin ? 'Quản trị viên' : 'Giáo viên'}
                  </Text>
                </div>
                <Text strong style={{ fontSize: 13 }}>
                  {user?.fullName || user?.username}
                </Text>
              </Space>
            </Dropdown>
          </Space>
        </Header>

        <Content
          style={{
            margin: '20px',
            minHeight: 280,
          }}
        >
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
};
