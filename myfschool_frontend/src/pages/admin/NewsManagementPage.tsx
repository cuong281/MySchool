import React, { useState, useMemo } from 'react';
import {
  Typography,
  Table,
  Button,
  Space,
  Input,
  Select,
  Tag,
  Card,
  Row,
  Col,
  Modal,
  Form,
  Drawer,
  Popconfirm,
  Image,
  Spin,
  Alert,
  Empty,
  Switch,
  message,
  theme,
} from 'antd';
import {
  PlusOutlined,
  SearchOutlined,
  EditOutlined,
  DeleteOutlined,
  EyeOutlined,
  RedoOutlined,
  NotificationOutlined,
  CalendarOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { newsApi } from '../../api/newsApi';
import type { NewsDTO, NewsPayload } from '../../types/news';

const { Title, Text, Paragraph } = Typography;
const { TextArea } = Input;

const CATEGORIES = ['Thông báo', 'Tin tức', 'Sự kiện', 'Khẩn cấp', 'Học tập'];

export const NewsManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const queryClient = useQueryClient();

  // Filters
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [searchText, setSearchText] = useState<string>('');

  // Modal / Drawer States
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingNews, setEditingNews] = useState<NewsDTO | null>(null);
  const [selectedNewsDetail, setSelectedNewsDetail] = useState<NewsDTO | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [form] = Form.useForm();

  // 1. Fetch News
  const {
    data: newsList = [],
    isLoading,
    error,
    refetch,
    isRefetching,
  } = useQuery<NewsDTO[]>({
    queryKey: ['adminNews'],
    queryFn: () => newsApi.getAll(),
  });

  // 2. Filtered list
  const filteredNews = useMemo(() => {
    return newsList.filter((n) => {
      if (selectedCategory !== 'ALL' && n.category !== selectedCategory) {
        return false;
      }
      if (searchText.trim()) {
        const q = searchText.toLowerCase().trim();
        const matchTitle = n.title?.toLowerCase().includes(q);
        const matchContent = n.content?.toLowerCase().includes(q);
        if (!matchTitle && !matchContent) return false;
      }
      return true;
    });
  }, [newsList, selectedCategory, searchText]);

  // Create / Update Mutation
  const saveMutation = useMutation({
    mutationFn: (payload: NewsPayload) => {
      if (editingNews) {
        return newsApi.update(editingNews.id, payload);
      }
      return newsApi.create(payload);
    },
    onSuccess: () => {
      message.success(editingNews ? 'Cập nhật bài viết thành công' : 'Đăng bài viết mới thành công');
      queryClient.invalidateQueries({ queryKey: ['adminNews'] });
      setIsModalOpen(false);
      setEditingNews(null);
      form.resetFields();
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Có lỗi xảy ra khi lưu bài viết');
    },
  });

  // Delete Mutation
  const deleteMutation = useMutation({
    mutationFn: (id: number) => newsApi.delete(id),
    onSuccess: () => {
      message.success('Đã xóa bài viết');
      queryClient.invalidateQueries({ queryKey: ['adminNews'] });
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Không thể xóa bài viết');
    },
  });

  const handleOpenCreate = () => {
    setEditingNews(null);
    form.resetFields();
    form.setFieldsValue({
      category: 'Thông báo',
      isActive: true,
      targetAudience: 'ALL',
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (record: NewsDTO) => {
    setEditingNews(record);
    form.setFieldsValue({
      title: record.title,
      category: record.category || 'Thông báo',
      imageUrl: record.imageUrl,
      content: record.content,
      isActive: true,
      targetAudience: 'ALL',
    });
    setIsModalOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      saveMutation.mutate({
        title: values.title,
        category: values.category,
        imageUrl: values.imageUrl || null,
        content: values.content,
        isActive: values.isActive ?? true,
      });
    } catch {
      // form error
    }
  };

  const handleViewDetail = (record: NewsDTO) => {
    setSelectedNewsDetail(record);
    setIsDrawerOpen(true);
  };

  const renderCategoryTag = (cat?: string | null) => {
    switch (cat) {
      case 'Khẩn cấp':
        return <Tag color="error">{cat}</Tag>;
      case 'Sự kiện':
        return <Tag color="orange">{cat}</Tag>;
      case 'Học tập':
        return <Tag color="purple">{cat}</Tag>;
      case 'Tin tức':
        return <Tag color="green">{cat}</Tag>;
      default:
        return <Tag color="blue">{cat || 'Thông báo'}</Tag>;
    }
  };

  const columns = [
    {
      title: 'Mã',
      dataIndex: 'id',
      key: 'id',
      width: 70,
      align: 'center' as const,
      render: (id: number) => <Text code>#{id}</Text>,
    },
    {
      title: 'Ảnh',
      dataIndex: 'imageUrl',
      key: 'imageUrl',
      width: 90,
      align: 'center' as const,
      render: (url?: string | null) =>
        url ? (
          <Image
            src={url}
            alt="thumb"
            width={52}
            height={38}
            style={{ objectFit: 'cover', borderRadius: 6 }}
            fallback="https://placehold.co/100x60?text=News"
          />
        ) : (
          <div
            style={{
              width: 52,
              height: 38,
              background: '#F1F5F9',
              borderRadius: 6,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#94A3B8',
              fontSize: 11,
              margin: '0 auto',
            }}
          >
            Không ảnh
          </div>
        ),
    },
    {
      title: 'Tiêu đề bài viết / thông báo',
      key: 'title',
      render: (_: any, r: NewsDTO) => (
        <div>
          <Button
            type="link"
            style={{
              padding: 0,
              fontWeight: 600,
              fontSize: 14,
              color: '#0F172A',
              textAlign: 'left',
              height: 'auto',
              whiteSpace: 'normal',
            }}
            onClick={() => handleViewDetail(r)}
          >
            {r.title}
          </Button>
          <Paragraph
            ellipsis={{ rows: 1 }}
            type="secondary"
            style={{ fontSize: 12, margin: '2px 0 0 0' }}
          >
            {r.content}
          </Paragraph>
        </div>
      ),
    },
    {
      title: 'Chuyên mục',
      dataIndex: 'category',
      key: 'category',
      width: 130,
      render: (cat: string) => renderCategoryTag(cat),
    },
    {
      title: 'Ngày đăng',
      dataIndex: 'publishedDate',
      key: 'publishedDate',
      width: 140,
      render: (dateStr?: string | null) =>
        dateStr ? (
          <Space size={4}>
            <CalendarOutlined style={{ color: '#64748B', fontSize: 12 }} />
            <Text style={{ fontSize: 12 }}>{dayjs(dateStr).format('DD/MM/YYYY')}</Text>
          </Space>
        ) : (
          <Text type="secondary">—</Text>
        ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 140,
      align: 'right' as const,
      render: (_: any, record: NewsDTO) => (
        <Space size={4}>
          <Button
            type="text"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleViewDetail(record)}
            title="Xem trước bài viết"
          />
          <Button
            type="text"
            size="small"
            icon={<EditOutlined style={{ color: '#2563EB' }} />}
            onClick={() => handleOpenEdit(record)}
            title="Chỉnh sửa bài viết"
          />
          <Popconfirm
            title="Xóa bài viết"
            description="Bạn có chắc chắn muốn xóa bài viết này không?"
            onConfirm={() => deleteMutation.mutate(record.id)}
            okText="Xóa"
            cancelText="Hủy"
            okButtonProps={{ danger: true }}
          >
            <Button
              type="text"
              size="small"
              danger
              icon={<DeleteOutlined />}
              title="Xóa bài viết"
            />
          </Popconfirm>
        </Space>
      ),
    },
  ];

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
            <Title level={4} style={{ margin: 0, color: '#0F172A' }}>
              Tin tức & Thông báo (CMS)
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Hệ thống quản lý nội dung bản tin, thông báo và truyền thông của Nhà trường
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
              onClick={handleOpenCreate}
              style={{ backgroundColor: '#2563EB' }}
            >
              Tạo bài viết mới
            </Button>
          </Space>
        </div>
      </div>

      {/* Main CMS Table Card */}
      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
        {/* Toolbar */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 12,
            marginBottom: 20,
          }}
        >
          <Space wrap size={12}>
            {/* Category Select */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Text strong style={{ fontSize: 13 }}>Chuyên mục:</Text>
              <Select
                value={selectedCategory}
                onChange={(val) => setSelectedCategory(val)}
                style={{ width: 170 }}
                options={[
                  { value: 'ALL', label: 'Tất cả chuyên mục' },
                  ...CATEGORIES.map((c) => ({ value: c, label: c })),
                ]}
              />
            </div>

            {/* Search Input */}
            <Input
              placeholder="Tìm kiếm tiêu đề, nội dung..."
              prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              style={{ width: 280 }}
              allowClear
            />
          </Space>

          <Text type="secondary">
            Tìm thấy: <strong>{filteredNews.length} bài viết</strong>
          </Text>
        </div>

        {/* Content */}
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '80px 0' }}>
            <Spin size="large" tip="Đang tải danh sách bài viết..." />
          </div>
        ) : error ? (
          <Alert
            type="error"
            message="Lỗi kết nối bài viết"
            description="Không thể tải danh sách bài viết từ Backend. Vui lòng kiểm tra lại kết nối mạng."
            showIcon
          />
        ) : filteredNews.length === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="Chưa có bài viết hoặc thông báo nào phù hợp"
            style={{ padding: '40px 0' }}
          />
        ) : (
          <Table
            columns={columns}
            dataSource={filteredNews}
            rowKey="id"
            pagination={{ pageSize: 10, showSizeChanger: true, pageSizeOptions: ['10', '20', '50'] }}
            scroll={{ x: 900 }}
          />
        )}
      </Card>

      {/* Modal: Create / Edit News Form */}
      <Modal
        title={
          <Space>
            <NotificationOutlined style={{ color: '#2563EB' }} />
            <span>{editingNews ? 'Chỉnh sửa bài viết' : 'Soạn bài viết / thông báo mới'}</span>
          </Space>
        }
        open={isModalOpen}
        onCancel={() => {
          setIsModalOpen(false);
          setEditingNews(null);
          form.resetFields();
        }}
        onOk={handleSave}
        okText={editingNews ? 'Cập nhật' : 'Xuất bản bài viết'}
        confirmLoading={saveMutation.isPending}
        width={680}
        cancelText="Hủy bỏ"
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item
            name="title"
            label="Tiêu đề bài viết"
            rules={[{ required: true, message: 'Vui lòng nhập tiêu đề bài viết' }]}
          >
            <Input placeholder="Nhập tiêu đề thông báo ngắn gọn, rõ ràng..." />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="category"
                label="Chuyên mục"
                rules={[{ required: true, message: 'Vui lòng chọn chuyên mục' }]}
              >
                <Select
                  options={CATEGORIES.map((c) => ({ value: c, label: c }))}
                  placeholder="Chọn chuyên mục"
                />
              </Form.Item>
            </Col>

            <Col span={12}>
              <Form.Item
                name="targetAudience"
                label="Đối tượng nhận"
                tooltip="Backend hiện tại lưu bài viết chung toàn trường. Gửi thông báo riêng theo vai trò: NEEDS BACKEND API"
              >
                <Select
                  defaultValue="ALL"
                  options={[
                    { value: 'ALL', label: 'Toàn trường (Công khai)' },
                    { value: 'STUDENTS', label: 'Học sinh & Phụ huynh' },
                    { value: 'TEACHERS', label: 'Giáo viên & Cán bộ' },
                  ]}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="imageUrl"
            label="Link hình ảnh đại diện (URL)"
          >
            <Input placeholder="https://example.com/banner.jpg (Để trống nếu không có)" />
          </Form.Item>

          <Form.Item
            name="content"
            label="Nội dung bài viết / thông báo"
            rules={[{ required: true, message: 'Vui lòng nhập nội dung' }]}
          >
            <TextArea
              rows={8}
              placeholder="Nội dung chi tiết của thông báo, kế hoạch giảng dạy, quy định..."
              style={{ fontSize: 14, lineHeight: 1.6 }}
            />
          </Form.Item>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0' }}>
            <div>
              <Text strong>Trạng thái hiển thị bài viết</Text>
              <div style={{ fontSize: 12, color: '#64748B' }}>
                Bật để hiển thị ngay trên ứng dụng học sinh & phụ huynh
              </div>
            </div>
            <Form.Item name="isActive" valuePropName="checked" noStyle>
              <Switch defaultChecked />
            </Form.Item>
          </div>
        </Form>
      </Modal>

      {/* Drawer: Detailed Preview of News */}
      <Drawer
        title={
          <Space>
            <NotificationOutlined style={{ color: '#2563EB' }} />
            <span>Xem trước bài viết</span>
          </Space>
        }
        width={600}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        extra={
          selectedNewsDetail && (
            <Button
              type="primary"
              icon={<EditOutlined />}
              onClick={() => {
                setIsDrawerOpen(false);
                handleOpenEdit(selectedNewsDetail);
              }}
            >
              Chỉnh sửa
            </Button>
          )
        }
      >
        {selectedNewsDetail && (
          <Space direction="vertical" size={16} style={{ width: '100%' }}>
            {selectedNewsDetail.imageUrl && (
              <Image
                src={selectedNewsDetail.imageUrl}
                alt="banner"
                style={{ width: '100%', maxHeight: 260, objectFit: 'cover', borderRadius: 12 }}
                fallback="https://placehold.co/600x260?text=MySchool+News"
              />
            )}

            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              {renderCategoryTag(selectedNewsDetail.category)}
              {selectedNewsDetail.publishedDate && (
                <Text type="secondary" style={{ fontSize: 12 }}>
                  <CalendarOutlined style={{ marginRight: 4 }} />
                  {dayjs(selectedNewsDetail.publishedDate).format('DD/MM/YYYY HH:mm')}
                </Text>
              )}
            </div>

            <Title level={4} style={{ margin: 0, color: '#0F172A' }}>
              {selectedNewsDetail.title}
            </Title>

            <div
              style={{
                background: '#F8FAFC',
                padding: '16px 20px',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                fontSize: 14,
                lineHeight: 1.8,
                color: '#334155',
                whiteSpace: 'pre-wrap',
              }}
            >
              {selectedNewsDetail.content}
            </div>

            <div style={{ padding: '8px 0', borderTop: '1px solid #F1F5F9' }}>
              <Text type="secondary" style={{ fontSize: 12 }}>
                <InfoCircleOutlined style={{ marginRight: 4 }} />
                Bài viết này được phát hành bởi Ban Giám Hiệu MySchool.
              </Text>
            </div>
          </Space>
        )}
      </Drawer>
    </div>
  );
};
