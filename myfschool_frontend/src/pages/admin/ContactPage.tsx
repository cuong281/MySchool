import React, { useState, useMemo } from 'react';
import {
  Typography,
  Tabs,
  Input,
  Select,
  Row,
  Col,
  Card,
  Tag,
  Avatar,
  Space,
  Button,
  Table,
  Drawer,
  Descriptions,
  Spin,
  Alert,
  Empty,
  message,
  theme,
  Badge,
  List,
} from 'antd';
import {
  SearchOutlined,
  PhoneOutlined,
  MailOutlined,
  UserOutlined,
  EnvironmentOutlined,
  ClockCircleOutlined,
  CopyOutlined,
  EyeOutlined,
  RedoOutlined,
  StarFilled,
  ApartmentOutlined,
  SafetyCertificateOutlined,
  MessageOutlined,
  CommentOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery } from '@tanstack/react-query';
import { contactApi } from '../../api/contactApi';
import { messageApi } from '../../api/messageApi';
import type { TeacherContactDTO, SchoolDepartmentContact } from '../../types/contact';
import type { ConversationDTO } from '../../types/message';
import { ChatDrawer } from '../../components/chat/ChatDrawer';

const { Title, Text, Paragraph } = Typography;

export const ContactPage: React.FC = () => {
  const { token } = theme.useToken();

  // Filter States for Teacher Tab
  const [searchText, setSearchText] = useState<string>('');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  const [subjectFilter, setSubjectFilter] = useState<string>('ALL');

  // Selected Detail States
  const [selectedTeacher, setSelectedTeacher] = useState<TeacherContactDTO | null>(null);
  const [selectedDept, setSelectedDept] = useState<SchoolDepartmentContact | null>(null);
  const [isTeacherDrawerOpen, setIsTeacherDrawerOpen] = useState<boolean>(false);
  const [isDeptDrawerOpen, setIsDeptDrawerOpen] = useState<boolean>(false);

  // Chat Drawer State
  const [chatTarget, setChatTarget] = useState<{
    open: boolean;
    targetUserId: number | null;
    targetName: string;
    targetRole?: string;
    targetAvatar?: string | null;
    targetSubject?: string | null;
    isHomeroom?: boolean;
  }>({
    open: false,
    targetUserId: null,
    targetName: '',
  });

  // 1. Fetch Teachers
  const {
    data: teachers = [],
    isLoading: isLoadingTeachers,
    error: teachersError,
    refetch: refetchTeachers,
    isRefetching: isRefetchingTeachers,
  } = useQuery<TeacherContactDTO[]>({
    queryKey: ['teacherContacts'],
    queryFn: () => contactApi.getTeachers(),
  });

  // 2. Fetch School Departments
  const {
    data: departments = [],
    isLoading: isLoadingDepts,
  } = useQuery<SchoolDepartmentContact[]>({
    queryKey: ['schoolDepartments'],
    queryFn: () => contactApi.getSchoolDepartments(),
  });

  // 3. Fetch Recent Conversations
  const {
    data: conversations = [],
    isLoading: isLoadingConversations,
    refetch: refetchConversations,
    isRefetching: isRefetchingConversations,
  } = useQuery<ConversationDTO[]>({
    queryKey: ['conversations'],
    queryFn: () => messageApi.getConversations(),
  });

  const unreadTotal = useMemo(() => {
    return conversations.reduce((acc, curr) => acc + (curr.unreadCount || 0), 0);
  }, [conversations]);

  // Unique Subjects List
  const subjects = useMemo(() => {
    const set = new Set<string>();
    teachers.forEach((t) => {
      if (t.subjectName) {
        t.subjectName.split(',').forEach((s) => {
          const trimmed = s.trim();
          if (trimmed) set.add(trimmed);
        });
      }
    });
    return Array.from(set);
  }, [teachers]);

  // Filtered Teachers
  const filteredTeachers = useMemo(() => {
    return teachers.filter((t) => {
      // Role filter
      if (roleFilter === 'HOMEROOM' && !t.isHomeroom) return false;
      if (roleFilter === 'SUBJECT' && t.isHomeroom) return false;

      // Subject filter
      if (subjectFilter !== 'ALL') {
        if (!t.subjectName || !t.subjectName.toLowerCase().includes(subjectFilter.toLowerCase())) {
          return false;
        }
      }

      // Search text
      if (searchText.trim()) {
        const q = searchText.toLowerCase().trim();
        const matchName = t.fullName?.toLowerCase().includes(q);
        const matchEmail = t.email?.toLowerCase().includes(q);
        const matchPhone = t.phone?.toLowerCase().includes(q);
        const matchSubject = t.subjectName?.toLowerCase().includes(q);
        if (!matchName && !matchEmail && !matchPhone && !matchSubject) return false;
      }

      return true;
    });
  }, [teachers, roleFilter, subjectFilter, searchText]);

  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    message.success(`Đã sao chép ${label}: ${text}`);
  };

  const handleViewTeacher = (t: TeacherContactDTO) => {
    setSelectedTeacher(t);
    setIsTeacherDrawerOpen(true);
  };

  const handleViewDept = (dept: SchoolDepartmentContact) => {
    setSelectedDept(dept);
    setIsDeptDrawerOpen(true);
  };

  const handleOpenChat = (t: TeacherContactDTO) => {
    if (!t.userId) {
      message.warning(`Giáo viên ${t.fullName} chưa có tài khoản người dùng liên kết để gửi tin nhắn.`);
      return;
    }
    setChatTarget({
      open: true,
      targetUserId: t.userId,
      targetName: t.fullName,
      targetRole: t.isHomeroom ? 'Giáo viên Chủ nhiệm' : 'Giáo viên Bộ môn',
      targetAvatar: t.avatarUrl,
      targetSubject: t.subjectName,
      isHomeroom: t.isHomeroom,
    });
  };

  const handleOpenChatFromConversation = (conv: ConversationDTO) => {
    setChatTarget({
      open: true,
      targetUserId: conv.targetUserId,
      targetName: conv.targetName,
      targetRole: conv.targetRole,
      targetAvatar: conv.targetAvatar,
      targetSubject: null,
      isHomeroom: false,
    });
  };

  // Columns for Teacher Table View
  const teacherColumns = [
    {
      title: 'Giáo viên',
      key: 'name',
      render: (_: any, r: TeacherContactDTO) => (
        <Space size={12}>
          <Avatar
            size={40}
            src={r.avatarUrl}
            icon={<UserOutlined />}
            style={{ backgroundColor: r.isHomeroom ? '#F59E0B' : '#2563EB' }}
          />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Text strong style={{ fontSize: 14 }}>{r.fullName}</Text>
              {r.isHomeroom && (
                <Tag color="warning" icon={<StarFilled />} style={{ fontSize: 11, padding: '0 6px' }}>
                  GVCN
                </Tag>
              )}
            </div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {r.isHomeroom ? 'Giáo viên Chủ nhiệm' : 'Giáo viên Bộ môn'}
            </Text>
          </div>
        </Space>
      ),
    },
    {
      title: 'Môn giảng dạy',
      dataIndex: 'subjectName',
      key: 'subjectName',
      render: (subject?: string | null) =>
        subject ? (
          <Tag color="blue" style={{ fontWeight: 500 }}>
            {subject}
          </Tag>
        ) : (
          <Text type="secondary">Chưa phân công</Text>
        ),
    },
    {
      title: 'Email liên hệ',
      dataIndex: 'email',
      key: 'email',
      render: (email: string) => (
        <Space size={6}>
          <MailOutlined style={{ color: '#64748B' }} />
          <Text copyable={{ text: email, tooltips: ['Sao chép email', 'Đã sao chép'] }}>
            {email}
          </Text>
        </Space>
      ),
    },
    {
      title: 'Số điện thoại',
      dataIndex: 'phone',
      key: 'phone',
      render: (phone?: string | null) =>
        phone ? (
          <Space size={6}>
            <PhoneOutlined style={{ color: '#16A34A' }} />
            <Text copyable={{ text: phone, tooltips: ['Sao chép SĐT', 'Đã sao chép'] }}>
              {phone}
            </Text>
          </Space>
        ) : (
          <Text type="secondary" italic>Chưa cập nhật</Text>
        ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: () => (
        <Tag color="success">ĐANG CÔNG TÁC</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 160,
      align: 'right' as const,
      render: (_: any, r: TeacherContactDTO) => (
        <Space size={6}>
          <Button
            type="primary"
            size="small"
            ghost
            icon={<MessageOutlined />}
            onClick={() => handleOpenChat(r)}
            style={{ borderRadius: 6, fontWeight: 500 }}
          >
            Nhắn tin
          </Button>
          <Button
            type="text"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleViewTeacher(r)}
            title="Xem hồ sơ liên hệ"
          />
        </Space>
      ),
    },
  ];

  return (
    <div style={{ maxWidth: 1400, margin: '0 auto' }}>
      {/* Top Header Card */}
      <div
        style={{
          background: '#fff',
          padding: '20px 24px',
          borderRadius: 16,
          boxShadow: '0 2px 10px rgba(0,0,0,0.03)',
          marginBottom: 20,
          border: `1px solid ${token.colorBorderSecondary}`,
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 16,
          }}
        >
          <div>
            <Title level={4} style={{ margin: 0, color: '#0F172A' }}>
              Thông tin Liên lạc & Danh bạ
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Danh bạ cán bộ, giáo viên toàn trường và kênh liên hệ chính thức các phòng ban chức năng
            </Text>
          </div>

          <Button
            icon={<RedoOutlined spin={isRefetchingTeachers} />}
            onClick={() => refetchTeachers()}
          >
            Làm mới
          </Button>
        </div>
      </div>

      {/* Main Tabs Card */}
      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
        <Tabs
          defaultActiveKey="teachers"
          size="middle"
          items={[
            {
              key: 'teachers',
              label: (
                <Space size={6}>
                  <UserOutlined />
                  <span>Danh bạ Giáo viên ({teachers.length})</span>
                </Space>
              ),
              children: (
                <div>
                  {/* Filter Toolbar */}
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: 12,
                      marginBottom: 16,
                    }}
                  >
                    <Space wrap size={12}>
                      <Input
                        placeholder="Tìm theo tên, email, SĐT, bộ môn..."
                        prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                        style={{ width: 280 }}
                        allowClear
                      />

                      {/* Role Filter */}
                      <Select
                        value={roleFilter}
                        onChange={(val) => setRoleFilter(val)}
                        style={{ width: 160 }}
                        options={[
                          { value: 'ALL', label: 'Tất cả giáo viên' },
                          { value: 'HOMEROOM', label: 'GV Chủ nhiệm' },
                          { value: 'SUBJECT', label: 'GV Bộ môn' },
                        ]}
                      />

                      {/* Subject Filter */}
                      <Select
                        value={subjectFilter}
                        onChange={(val) => setSubjectFilter(val)}
                        style={{ width: 170 }}
                        options={[
                          { value: 'ALL', label: 'Tất cả bộ môn' },
                          ...subjects.map((s) => ({ value: s, label: s })),
                        ]}
                      />
                    </Space>

                    <Text type="secondary">
                      Hiển thị: <strong>{filteredTeachers.length} giáo viên</strong>
                    </Text>
                  </div>

                  {/* Content State */}
                  {isLoadingTeachers ? (
                    <div style={{ textAlign: 'center', padding: '80px 0' }}>
                      <Spin size="large" tip="Đang tải danh bạ giáo viên..." />
                    </div>
                  ) : teachersError ? (
                    <Alert
                      type="error"
                      message="Lỗi kết nối danh bạ"
                      description="Không thể tải danh sách giáo viên từ Backend."
                      showIcon
                    />
                  ) : filteredTeachers.length === 0 ? (
                    <Empty
                      image={Empty.PRESENTED_IMAGE_SIMPLE}
                      description="Không tìm thấy cán bộ hoặc giáo viên phù hợp"
                      style={{ padding: '40px 0' }}
                    />
                  ) : (
                    <Table
                      columns={teacherColumns}
                      dataSource={filteredTeachers}
                      rowKey="teacherId"
                      pagination={{ pageSize: 10, showSizeChanger: true }}
                      scroll={{ x: 850 }}
                    />
                  )}
                </div>
              ),
            },
            {
              key: 'departments',
              label: (
                <Space size={6}>
                  <ApartmentOutlined />
                  <span>Kênh Liên hệ Nhà trường ({departments.length})</span>
                </Space>
              ),
              children: (
                <div>
                  <div style={{ marginBottom: 16 }}>
                    <Text type="secondary" style={{ fontSize: 13 }}>
                      Danh sách các phòng ban chức năng, hotline hỗ trợ học vụ, y tế học đường và an ninh 24/7
                    </Text>
                  </div>

                  {isLoadingDepts ? (
                    <div style={{ textAlign: 'center', padding: '60px 0' }}>
                      <Spin tip="Đang tải thông tin phòng ban..." />
                    </div>
                  ) : (
                    <Row gutter={[16, 16]}>
                      {departments.map((dept) => (
                        <Col xs={24} md={12} lg={8} key={dept.id}>
                          <Card
                            hoverable
                            style={{
                              borderRadius: 12,
                              height: '100%',
                              display: 'flex',
                              flexDirection: 'column',
                              justifyContent: 'space-between',
                              border: '1px solid #E2E8F0',
                            }}
                            bodyStyle={{ padding: 18 }}
                            onClick={() => handleViewDept(dept)}
                          >
                            <div>
                              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <Tag color="blue" icon={<SafetyCertificateOutlined />}>
                                  {dept.department}
                                </Tag>
                                <Button
                                  type="text"
                                  size="small"
                                  icon={<EyeOutlined />}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleViewDept(dept);
                                  }}
                                />
                              </div>

                              <Title level={5} style={{ margin: '10px 0 6px 0', color: '#0F172A' }}>
                                {dept.name}
                              </Title>

                              <Paragraph
                                ellipsis={{ rows: 2 }}
                                type="secondary"
                                style={{ fontSize: 13, marginBottom: 12 }}
                              >
                                {dept.description}
                              </Paragraph>

                              <Space direction="vertical" size={6} style={{ width: '100%', fontSize: 12 }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                  <PhoneOutlined style={{ color: '#16A34A' }} />
                                  <Text strong style={{ color: '#16A34A' }}>{dept.phoneNumber}</Text>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                  <MailOutlined style={{ color: '#2563EB' }} />
                                  <Text>{dept.email}</Text>
                                </div>
                                {dept.location && (
                                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#64748B' }}>
                                    <EnvironmentOutlined />
                                    <span>{dept.location}</span>
                                  </div>
                                )}
                              </Space>
                            </div>

                            <div style={{ marginTop: 14, paddingTop: 10, borderTop: '1px solid #F1F5F9', display: 'flex', justifyContent: 'space-between' }}>
                              <Button
                                size="small"
                                icon={<CopyOutlined />}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleCopy(dept.phoneNumber, 'số hotline');
                                }}
                              >
                                Chép Hotline
                              </Button>
                              <Button
                                size="small"
                                type="primary"
                                ghost
                                icon={<MailOutlined />}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleCopy(dept.email, 'địa chỉ email');
                                }}
                              >
                                Chép Email
                              </Button>
                            </div>
                          </Card>
                        </Col>
                      ))}
                    </Row>
                  )}
                </div>
              ),
            },
            {
              key: 'conversations',
              label: (
                <Space size={6}>
                  <Badge count={unreadTotal} offset={[6, -2]} size="small">
                    <CommentOutlined />
                  </Badge>
                  <span>Hộp thư & Hội thoại ({conversations.length})</span>
                </Space>
              ),
              children: (
                <div>
                  <div
                    style={{
                      marginBottom: 16,
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: 10,
                    }}
                  >
                    <Text type="secondary" style={{ fontSize: 13 }}>
                      Danh sách các cuộc trò chuyện gần đây với các giáo viên và cán bộ nhà trường
                    </Text>
                    <Button
                      size="small"
                      icon={<RedoOutlined spin={isRefetchingConversations} />}
                      onClick={() => refetchConversations()}
                    >
                      Làm mới hộp thư
                    </Button>
                  </div>

                  {isLoadingConversations ? (
                    <div style={{ textAlign: 'center', padding: '60px 0' }}>
                      <Spin tip="Đang tải hộp thư..." />
                    </div>
                  ) : conversations.length === 0 ? (
                    <Empty
                      image={Empty.PRESENTED_IMAGE_SIMPLE}
                      description="Chưa có hội thoại nào gần đây. Hãy bấm 'Nhắn tin' tại tab Danh bạ Giáo viên để bắt đầu trao đổi."
                      style={{ padding: '40px 0' }}
                    />
                  ) : (
                    <List
                      itemLayout="horizontal"
                      dataSource={conversations}
                      renderItem={(item) => (
                        <List.Item
                          style={{
                            background: '#fff',
                            border: '1px solid #E2E8F0',
                            borderRadius: 12,
                            padding: '14px 18px',
                            marginBottom: 10,
                            cursor: 'pointer',
                            transition: 'all 0.2s ease',
                          }}
                          onClick={() => handleOpenChatFromConversation(item)}
                          actions={[
                            <Button
                              type="primary"
                              ghost
                              size="small"
                              icon={<MessageOutlined />}
                              onClick={(e) => {
                                e.stopPropagation();
                                handleOpenChatFromConversation(item);
                              }}
                            >
                              Trò chuyện
                            </Button>,
                          ]}
                        >
                          <List.Item.Meta
                            avatar={
                              <Badge count={item.unreadCount} offset={[-2, 2]}>
                                <Avatar
                                  size={44}
                                  src={item.targetAvatar}
                                  icon={<UserOutlined />}
                                  style={{ backgroundColor: '#2563EB' }}
                                />
                              </Badge>
                            }
                            title={
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                                <Text strong style={{ fontSize: 15, color: '#0F172A' }}>
                                  {item.targetName}
                                </Text>
                                <Tag color="blue" style={{ fontSize: 11 }}>
                                  {item.targetRole || 'Giáo viên'}
                                </Tag>
                                <Text type="secondary" style={{ fontSize: 12, marginLeft: 'auto', marginRight: 12 }}>
                                  {item.lastMessageTime ? dayjs(item.lastMessageTime).format('HH:mm DD/MM/YYYY') : ''}
                                </Text>
                              </div>
                            }
                            description={
                              <Paragraph
                                ellipsis={{ rows: 1 }}
                                style={{
                                  margin: 0,
                                  color: item.unreadCount > 0 ? '#0F172A' : '#64748B',
                                  fontWeight: item.unreadCount > 0 ? 600 : 400,
                                }}
                              >
                                {item.lastMessage || 'Bắt đầu cuộc trò chuyện...'}
                              </Paragraph>
                            }
                          />
                        </List.Item>
                      )}
                    />
                  )}
                </div>
              ),
            },
          ]}
        />
      </Card>

      {/* Drawer: Detailed Teacher Contact */}
      <Drawer
        title={
          <Space>
            <UserOutlined style={{ color: '#2563EB' }} />
            <span>Hồ sơ liên lạc giáo viên</span>
          </Space>
        }
        width={480}
        open={isTeacherDrawerOpen}
        onClose={() => setIsTeacherDrawerOpen(false)}
      >
        {selectedTeacher && (
          <Space direction="vertical" size={18} style={{ width: '100%' }}>
            <div
              style={{
                background: '#F8FAFC',
                padding: '16px',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                display: 'flex',
                alignItems: 'center',
                gap: 14,
              }}
            >
              <Avatar
                size={54}
                src={selectedTeacher.avatarUrl}
                icon={<UserOutlined />}
                style={{ backgroundColor: selectedTeacher.isHomeroom ? '#F59E0B' : '#2563EB' }}
              />
              <div>
                <Title level={5} style={{ margin: 0, color: '#0F172A' }}>
                  {selectedTeacher.fullName}
                </Title>
                <div style={{ marginTop: 4 }}>
                  {selectedTeacher.isHomeroom && (
                    <Tag color="warning" icon={<StarFilled />}>
                      Giáo viên Chủ nhiệm
                    </Tag>
                  )}
                  <Tag color="blue">{selectedTeacher.subjectName || 'Giáo viên'}</Tag>
                </div>
              </div>
            </div>

            <Descriptions bordered size="small" column={1}>
              <Descriptions.Item label="Họ và tên">
                <strong>{selectedTeacher.fullName}</strong>
              </Descriptions.Item>
              <Descriptions.Item label="Chuyên môn">
                {selectedTeacher.subjectName || 'Chưa cập nhật'}
              </Descriptions.Item>
              <Descriptions.Item label="Email trường cấp">
                <Space>
                  <MailOutlined style={{ color: '#2563EB' }} />
                  <Text>{selectedTeacher.email}</Text>
                  <Button
                    size="small"
                    type="text"
                    icon={<CopyOutlined />}
                    onClick={() => handleCopy(selectedTeacher.email, 'email')}
                  />
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Số điện thoại">
                {selectedTeacher.phone ? (
                  <Space>
                    <PhoneOutlined style={{ color: '#16A34A' }} />
                    <Text strong style={{ color: '#16A34A' }}>{selectedTeacher.phone}</Text>
                    <Button
                      size="small"
                      type="text"
                      icon={<CopyOutlined />}
                      onClick={() => handleCopy(selectedTeacher.phone!, 'số điện thoại')}
                    />
                  </Space>
                ) : (
                  <Text type="secondary" italic>Không hiển thị (Riêng tư)</Text>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Trạng thái tài khoản">
                <Tag color="success">HOẠT ĐỘNG</Tag>
              </Descriptions.Item>
            </Descriptions>

            <div style={{ marginTop: 8 }}>
              <Button
                type="primary"
                size="large"
                icon={<MessageOutlined />}
                onClick={() => {
                  setIsTeacherDrawerOpen(false);
                  handleOpenChat(selectedTeacher);
                }}
                style={{
                  width: '100%',
                  height: 42,
                  borderRadius: 8,
                  backgroundColor: '#2563EB',
                  fontWeight: 600,
                }}
              >
                Nhắn tin trao đổi với giáo viên
              </Button>
            </div>
          </Space>
        )}
      </Drawer>

      {/* Drawer: Detailed School Department */}
      <Drawer
        title={
          <Space>
            <ApartmentOutlined style={{ color: '#2563EB' }} />
            <span>Thông tin phòng ban: {selectedDept?.name}</span>
          </Space>
        }
        width={480}
        open={isDeptDrawerOpen}
        onClose={() => setIsDeptDrawerOpen(false)}
      >
        {selectedDept && (
          <Space direction="vertical" size={16} style={{ width: '100%' }}>
            <Descriptions bordered size="small" column={1}>
              <Descriptions.Item label="Tên phòng ban">
                <strong>{selectedDept.name}</strong>
              </Descriptions.Item>
              <Descriptions.Item label="Khối chức năng">
                <Tag color="blue">{selectedDept.department}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Số điện thoại / Hotline">
                <Space>
                  <PhoneOutlined style={{ color: '#16A34A' }} />
                  <Text strong style={{ color: '#16A34A' }}>{selectedDept.phoneNumber}</Text>
                  <Button
                    size="small"
                    type="text"
                    icon={<CopyOutlined />}
                    onClick={() => handleCopy(selectedDept.phoneNumber, 'hotline')}
                  />
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Email tiếp nhận">
                <Space>
                  <MailOutlined style={{ color: '#2563EB' }} />
                  <Text>{selectedDept.email}</Text>
                  <Button
                    size="small"
                    type="text"
                    icon={<CopyOutlined />}
                    onClick={() => handleCopy(selectedDept.email, 'email')}
                  />
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Địa điểm làm việc">
                <Space>
                  <EnvironmentOutlined style={{ color: '#64748B' }} />
                  <Text>{selectedDept.location || 'Khuôn viên trường'}</Text>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Giờ tiếp phụ huynh">
                <Space>
                  <ClockCircleOutlined style={{ color: '#F59E0B' }} />
                  <Text>{selectedDept.workingHours || 'Giờ hành chính'}</Text>
                </Space>
              </Descriptions.Item>
            </Descriptions>

            <div>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>
                Chức năng & Nhiệm vụ:
              </Text>
              <div
                style={{
                  background: '#F8FAFC',
                  padding: '12px 16px',
                  borderRadius: 8,
                  fontSize: 13,
                  lineHeight: 1.6,
                  color: '#334155',
                  border: '1px solid #E2E8F0',
                }}
              >
                {selectedDept.description}
              </div>
            </div>
          </Space>
        )}
      </Drawer>

      {/* Chat Drawer */}
      <ChatDrawer
        open={chatTarget.open}
        onClose={() => setChatTarget((prev) => ({ ...prev, open: false }))}
        targetUserId={chatTarget.targetUserId}
        targetName={chatTarget.targetName}
        targetRole={chatTarget.targetRole}
        targetAvatar={chatTarget.targetAvatar}
        targetSubject={chatTarget.targetSubject}
        isHomeroom={chatTarget.isHomeroom}
      />
    </div>
  );
};
