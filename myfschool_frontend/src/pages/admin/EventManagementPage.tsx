import React, { useState, useMemo } from 'react';
import {
  Typography,
  Calendar,
  Badge,
  Card,
  Row,
  Col,
  Button,
  Space,
  Tag,
  Drawer,
  Modal,
  Form,
  Input,
  Select,
  DatePicker,
  Descriptions,
  Spin,
  Alert,
  Empty,
  Tooltip,
  message,
  theme,
} from 'antd';
import type { Dayjs } from 'dayjs';
import dayjs from 'dayjs';
import {
  PlusOutlined,
  CalendarOutlined,
  ClockCircleOutlined,
  EnvironmentOutlined,
  TrophyOutlined,
  RedoOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { eventApi } from '../../api/eventApi';
import type { EventDTO, CreateEventRequest } from '../../types/event';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const EVENT_CATEGORIES = [
  { value: 'STEM', label: 'Khoa học công nghệ (STEM)' },
  { value: 'SEMINAR', label: 'Hội thảo / Tọa đàm (SEMINAR)' },
  { value: 'CULTURE', label: 'Văn hóa lễ hội (CULTURE)' },
  { value: 'SPORTS', label: 'Thể dục thể thao (SPORTS)' },
  { value: 'MUSIC', label: 'Văn nghệ / Âm nhạc (MUSIC)' },
  { value: 'COMPETITION', label: 'Cuộc thi học sinh giỏi (COMPETITION)' },
];

export const EventManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const queryClient = useQueryClient();

  // Selected date on calendar
  const [selectedDate, setSelectedDate] = useState<Dayjs>(dayjs());

  // Drawer / Modal States
  const [selectedEvent, setSelectedEvent] = useState<EventDTO | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);
  const [createForm] = Form.useForm();

  // 1. Fetch Events
  const {
    data: events = [],
    isLoading,
    error,
    refetch,
    isRefetching,
  } = useQuery<EventDTO[]>({
    queryKey: ['schoolEvents'],
    queryFn: () => eventApi.getAll(),
  });

  // 2. Create Mutation
  const createMutation = useMutation({
    mutationFn: (data: CreateEventRequest) => eventApi.create(data),
    onSuccess: () => {
      message.success('Tạo sự kiện trường thành công');
      queryClient.invalidateQueries({ queryKey: ['schoolEvents'] });
      setIsCreateModalOpen(false);
      createForm.resetFields();
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Không thể tạo sự kiện');
    },
  });

  const handleOpenCreateModal = () => {
    createForm.resetFields();
    createForm.setFieldsValue({
      category: 'STEM',
      startAt: dayjs().add(1, 'day').hour(8).minute(0),
      endAt: dayjs().add(1, 'day').hour(11).minute(30),
    });
    setIsCreateModalOpen(true);
  };

  const handleConfirmCreate = async () => {
    try {
      const values = await createForm.validateFields();
      createMutation.mutate({
        title: values.title,
        description: values.description || '',
        location: values.location || 'Sân trường',
        category: values.category,
        startAt: values.startAt.format('YYYY-MM-DDTHH:mm:ss'),
        endAt: values.endAt.format('YYYY-MM-DDTHH:mm:ss'),
      });
    } catch {
      // form error
    }
  };

  const handleEventClick = (event: EventDTO) => {
    setSelectedEvent(event);
    setIsDrawerOpen(true);
  };

  // Map events by date (YYYY-MM-DD)
  const eventsByDate = useMemo(() => {
    const map = new Map<string, EventDTO[]>();
    events.forEach((e) => {
      const dateKey = e.date;
      if (!map.has(dateKey)) {
        map.set(dateKey, []);
      }
      map.get(dateKey)!.push(e);
    });
    return map;
  }, [events]);

  // Upcoming Events (Status: 'Đang diễn ra' hoặc 'Sắp tới')
  const upcomingEvents = useMemo(() => {
    return events.filter((e) => e.status !== 'Đã kết thúc');
  }, [events]);

  // Events on selected calendar date
  const selectedDateEvents = useMemo(() => {
    const dateStr = selectedDate.format('YYYY-MM-DD');
    return eventsByDate.get(dateStr) || [];
  }, [eventsByDate, selectedDate]);

  // Antd Calendar cell render
  const dateCellRender = (value: Dayjs) => {
    const dateStr = value.format('YYYY-MM-DD');
    const dayEvents = eventsByDate.get(dateStr) || [];

    if (dayEvents.length === 0) return null;

    return (
      <ul style={{ listStyle: 'none', margin: 0, padding: 0 }}>
        {dayEvents.map((item) => (
          <li
            key={item.id}
            onClick={(e) => {
              e.stopPropagation();
              handleEventClick(item);
            }}
            style={{
              marginBottom: 3,
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              cursor: 'pointer',
            }}
          >
            <Badge
              color={item.color || '#2563EB'}
              text={
                <span
                  style={{
                    fontSize: 11,
                    fontWeight: 500,
                    color: item.color || '#2563EB',
                  }}
                >
                  {item.time ? `${item.time} ` : ''}{item.title}
                </span>
              }
            />
          </li>
        ))}
      </ul>
    );
  };

  const renderStatusBadge = (status: string) => {
    switch (status) {
      case 'Đang diễn ra':
        return <Tag color="success">Đang diễn ra</Tag>;
      case 'Sắp tới':
        return <Tag color="processing">Sắp tới</Tag>;
      case 'Đã kết thúc':
        return <Tag color="default">Đã kết thúc</Tag>;
      default:
        return <Tag>{status}</Tag>;
    }
  };

  return (
    <div style={{ maxWidth: 1400, margin: '0 auto' }}>
      {/* Header Card */}
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
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Title level={4} style={{ margin: 0, color: '#0F172A' }}>
                Lịch Sự kiện & Hoạt động Trường học
              </Title>
              <Tooltip title="Backend hiện tại hỗ trợ GET /api/events và POST /api/events. Chức năng Sửa/Xóa cần API cập nhật từ Backend (NEEDS BACKEND API).">
                <Tag color="blue" icon={<InfoCircleOutlined />}>
                  Calendar View
                </Tag>
              </Tooltip>
            </div>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Theo dõi lịch lễ hội, ngoại khóa, hội thảo, thi đấu thể thao theo dạng lịch tương tác
            </Text>
          </div>

          <Space size={12}>
            <Button
              icon={<RedoOutlined spin={isRefetching} />}
              onClick={() => refetch()}
            >
              Làm mới
            </Button>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleOpenCreateModal}
              style={{ backgroundColor: '#2563EB' }}
            >
              Tạo sự kiện mới
            </Button>
          </Space>
        </div>
      </div>

      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>
          <Spin size="large" tip="Đang tải lịch sự kiện trường..." />
        </div>
      ) : error ? (
        <Alert
          type="error"
          message="Lỗi kết nối sự kiện"
          description="Không thể tải dữ liệu sự kiện từ máy chủ."
          showIcon
        />
      ) : (
        <Row gutter={[20, 20]}>
          {/* Main Column: Calendar Grid */}
          <Col xs={24} xl={16}>
            <Card
              bordered={false}
              style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
            >
              <Calendar
                value={selectedDate}
                onSelect={(date) => setSelectedDate(date)}
                cellRender={(date, info) => (info.type === 'date' ? dateCellRender(date) : null)}
              />
            </Card>
          </Col>

          {/* Side Column: Selected Date & Upcoming Events */}
          <Col xs={24} xl={8}>
            <Space direction="vertical" size={16} style={{ width: '100%' }}>
              {/* Selected Day Events Card */}
              <Card
                title={
                  <Space>
                    <CalendarOutlined style={{ color: '#2563EB' }} />
                    <span>Sự kiện ngày {selectedDate.format('DD/MM/YYYY')}</span>
                  </Space>
                }
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
              >
                {selectedDateEvents.length === 0 ? (
                  <div style={{ padding: '24px 0', textAlign: 'center', color: '#94A3B8' }}>
                    Không có sự kiện nào trong ngày này
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                    {selectedDateEvents.map((item) => (
                      <div
                        key={item.id}
                        onClick={() => handleEventClick(item)}
                        style={{
                          background: '#F8FAFC',
                          border: `1px solid #E2E8F0`,
                          borderLeft: `4px solid ${item.color || '#2563EB'}`,
                          borderRadius: 8,
                          padding: '10px 12px',
                          cursor: 'pointer',
                          transition: 'all 0.2s',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Text strong style={{ fontSize: 13, color: '#0F172A' }}>
                            {item.title}
                          </Text>
                          {renderStatusBadge(item.status)}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 12, color: '#64748B', marginTop: 4 }}>
                          <span>
                            <ClockCircleOutlined style={{ marginRight: 4 }} />
                            {item.time || '08:00'}
                          </span>
                          {item.location && (
                            <span>
                              <EnvironmentOutlined style={{ marginRight: 4 }} />
                              {item.location}
                            </span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Card>

              {/* Upcoming Events Card */}
              <Card
                title={
                  <Space>
                    <TrophyOutlined style={{ color: '#F59E0B' }} />
                    <span>Sự kiện sắp diễn ra ({upcomingEvents.length})</span>
                  </Space>
                }
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
              >
                {upcomingEvents.length === 0 ? (
                  <Empty
                    image={Empty.PRESENTED_IMAGE_SIMPLE}
                    description="Hiện không có sự kiện nào sắp diễn ra"
                    style={{ padding: '20px 0' }}
                  />
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12, maxHeight: 420, overflowY: 'auto' }}>
                    {upcomingEvents.map((ev) => (
                      <div
                        key={ev.id}
                        onClick={() => handleEventClick(ev)}
                        style={{
                          background: '#FFFFFF',
                          border: '1px solid #E2E8F0',
                          borderRadius: 10,
                          padding: '12px 14px',
                          cursor: 'pointer',
                          boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <div style={{ fontWeight: 600, fontSize: 14, color: '#0F172A' }}>
                            {ev.title}
                          </div>
                          {renderStatusBadge(ev.status)}
                        </div>
                        <Paragraph
                          ellipsis={{ rows: 2 }}
                          type="secondary"
                          style={{ fontSize: 12, margin: '4px 0 8px 0' }}
                        >
                          {ev.description || 'Không có mô tả chi tiết'}
                        </Paragraph>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12, color: '#64748B' }}>
                          <Space size={4}>
                            <CalendarOutlined />
                            <span>{dayjs(ev.date).format('DD/MM/YYYY')} • {ev.time || '08:00'}</span>
                          </Space>
                          <Tag color="blue">{ev.category}</Tag>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Card>
            </Space>
          </Col>
        </Row>
      )}

      {/* Modal: Create Event */}
      <Modal
        title={
          <Space>
            <PlusOutlined style={{ color: '#2563EB' }} />
            <span>Tạo sự kiện trường học mới</span>
          </Space>
        }
        open={isCreateModalOpen}
        onCancel={() => setIsCreateModalOpen(false)}
        onOk={handleConfirmCreate}
        okText="Lưu sự kiện"
        confirmLoading={createMutation.isPending}
        cancelText="Hủy bỏ"
        width={600}
      >
        <Form form={createForm} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item
            name="title"
            label="Tên sự kiện / Hoạt động"
            rules={[{ required: true, message: 'Vui lòng nhập tên sự kiện' }]}
          >
            <Input placeholder="Ví dụ: Ngày hội STEM MySchool 2026..." />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="category"
                label="Chuyên mục"
                rules={[{ required: true, message: 'Vui lòng chọn chuyên mục' }]}
              >
                <Select
                  options={EVENT_CATEGORIES}
                  placeholder="Chọn phân loại"
                />
              </Form.Item>
            </Col>

            <Col span={12}>
              <Form.Item
                name="location"
                label="Địa điểm tổ chức"
                rules={[{ required: true, message: 'Vui lòng nhập địa điểm' }]}
              >
                <Input placeholder="Ví dụ: Hội trường A, Sân bóng..." />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="startAt"
                label="Thời gian bắt đầu"
                rules={[{ required: true, message: 'Chọn thời gian bắt đầu' }]}
              >
                <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="endAt"
                label="Thời gian kết thúc"
                rules={[{ required: true, message: 'Chọn thời gian kết thúc' }]}
              >
                <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="description"
            label="Mô tả chi tiết sự kiện"
          >
            <TextArea
              rows={4}
              placeholder="Nội dung chương trình, thành phần tham gia, kế hoạch chuẩn bị..."
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Drawer: Event Detail */}
      <Drawer
        title={
          <Space>
            <TrophyOutlined style={{ color: selectedEvent?.color || '#2563EB' }} />
            <span>Chi tiết sự kiện: {selectedEvent?.title}</span>
          </Space>
        }
        width={520}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
      >
        {selectedEvent && (
          <Space direction="vertical" size={16} style={{ width: '100%' }}>
            <div
              style={{
                background: '#F8FAFC',
                padding: '16px',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Trạng thái sự kiện</Text>
                <div style={{ marginTop: 4 }}>{renderStatusBadge(selectedEvent.status)}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <Text type="secondary" style={{ fontSize: 12 }}>Chuyên mục</Text>
                <div style={{ marginTop: 4 }}>
                  <Tag color="blue">{selectedEvent.category}</Tag>
                </div>
              </div>
            </div>

            <Descriptions bordered size="small" column={1}>
              <Descriptions.Item label="Tên sự kiện">
                <strong>{selectedEvent.title}</strong>
              </Descriptions.Item>
              <Descriptions.Item label="Ngày diễn ra">
                <Space size={6}>
                  <CalendarOutlined style={{ color: '#2563EB' }} />
                  <span>{dayjs(selectedEvent.date).format('DD/MM/YYYY')}</span>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Thời gian bắt đầu">
                <Space size={6}>
                  <ClockCircleOutlined style={{ color: '#F59E0B' }} />
                  <span>{selectedEvent.time || '08:00'}</span>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Địa điểm">
                <Space size={6}>
                  <EnvironmentOutlined style={{ color: '#10B981' }} />
                  <span>{selectedEvent.location || 'Khuôn viên trường'}</span>
                </Space>
              </Descriptions.Item>
            </Descriptions>

            <div>
              <Text strong style={{ display: 'block', marginBottom: 8 }}>
                Nội dung mô tả:
              </Text>
              <div
                style={{
                  background: '#F1F5F9',
                  padding: '14px 16px',
                  borderRadius: 10,
                  fontSize: 14,
                  lineHeight: 1.6,
                  color: '#334155',
                }}
              >
                {selectedEvent.description || 'Chưa có thông tin mô tả chi tiết cho sự kiện này.'}
              </div>
            </div>

            <Alert
              type="info"
              showIcon
              message="Chỉnh sửa & Xóa sự kiện: NEEDS BACKEND API"
              description="Backend EventController hiện tại chỉ hỗ trợ xem danh sách (GET /api/events) và tạo mới (POST /api/events). Để chỉnh sửa hoặc xóa sự kiện đã tạo, cần bổ sung endpoint PUT và DELETE ở Backend."
            />
          </Space>
        )}
      </Drawer>
    </div>
  );
};
