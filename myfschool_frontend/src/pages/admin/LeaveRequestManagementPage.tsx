import React, { useState, useMemo } from 'react';
import {
  Typography,
  Table,
  Tag,
  Button,
  Space,
  Input,
  Radio,
  DatePicker,
  Card,
  Modal,
  Form,
  Drawer,
  Descriptions,
  Popconfirm,
  message,
  Alert,
  Spin,
  Empty,
  theme,
} from 'antd';
import {
  SearchOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  EyeOutlined,
  RedoOutlined,
  CalendarOutlined,
  FileTextOutlined,
  ClockCircleOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import isBetween from 'dayjs/plugin/isBetween';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { leaveRequestApi } from '../../api/leaveRequestApi';
import type { LeaveRequestDTO } from '../../types/leaveRequest';

dayjs.extend(isBetween);
dayjs.extend(customParseFormat);

const { Title, Text, Paragraph } = Typography;
const { RangePicker } = DatePicker;
const { TextArea } = Input;

export const LeaveRequestManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const queryClient = useQueryClient();

  // Filter States
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchText, setSearchText] = useState<string>('');
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs | null, dayjs.Dayjs | null] | null>(null);

  // Drawer / Modal States
  const [selectedRequest, setSelectedRequest] = useState<LeaveRequestDTO | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [isRejectModalOpen, setIsRejectModalOpen] = useState<boolean>(false);
  const [rejectingRequestId, setRejectingRequestId] = useState<number | null>(null);
  const [rejectForm] = Form.useForm();

  // 1. Fetch Leave Requests
  const {
    data: requests = [],
    isLoading,
    error,
    refetch,
    isRefetching,
  } = useQuery<LeaveRequestDTO[]>({
    queryKey: ['leaveRequests'],
    queryFn: () => leaveRequestApi.getAll(),
  });

  // 2. Mutation for status update
  const statusMutation = useMutation({
    mutationFn: ({ id, status, adminNote }: { id: number; status: 'APPROVED' | 'REJECTED'; adminNote?: string }) =>
      leaveRequestApi.updateStatus(id, { status, adminNote }),
    onSuccess: (_, variables) => {
      message.success(
        variables.status === 'APPROVED' ? 'Đã duyệt đơn nghỉ phép thành công' : 'Đã từ chối đơn nghỉ phép'
      );
      queryClient.invalidateQueries({ queryKey: ['leaveRequests'] });
      // If drawer is open with the current request, update it
      if (selectedRequest && selectedRequest.id === variables.id) {
        setSelectedRequest((prev) => (prev ? { ...prev, status: variables.status, adminNote: variables.adminNote } : null));
      }
      setIsRejectModalOpen(false);
      rejectForm.resetFields();
      setRejectingRequestId(null);
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Có lỗi xảy ra khi xử lý đơn nghỉ phép');
    },
  });

  const handleApprove = (id: number) => {
    statusMutation.mutate({ id, status: 'APPROVED' });
  };

  const handleOpenRejectModal = (id: number) => {
    setRejectingRequestId(id);
    setIsRejectModalOpen(true);
  };

  const handleConfirmReject = async () => {
    try {
      const values = await rejectForm.validateFields();
      if (rejectingRequestId) {
        statusMutation.mutate({
          id: rejectingRequestId,
          status: 'REJECTED',
          adminNote: values.adminNote,
        });
      }
    } catch {
      // form validation failed
    }
  };

  const handleOpenDetail = (record: LeaveRequestDTO) => {
    setSelectedRequest(record);
    setIsDrawerOpen(true);
  };

  // Status counts for tabs
  const counts = useMemo(() => {
    return {
      all: requests.length,
      pending: requests.filter((r) => r.status === 'PENDING').length,
      approved: requests.filter((r) => r.status === 'APPROVED').length,
      rejected: requests.filter((r) => r.status === 'REJECTED').length,
    };
  }, [requests]);

  // Filtered requests
  const filteredRequests = useMemo(() => {
    return requests.filter((r) => {
      // Status filter
      if (statusFilter !== 'ALL' && r.status !== statusFilter) {
        return false;
      }

      // Search text (student name or code)
      if (searchText.trim()) {
        const q = searchText.toLowerCase().trim();
        const matchName = r.studentName?.toLowerCase().includes(q);
        const matchCode = r.studentCode?.toLowerCase().includes(q);
        const matchReason = r.reason?.toLowerCase().includes(q);
        if (!matchName && !matchCode && !matchReason) return false;
      }

      // Date range filter (overlap check)
      if (dateRange && dateRange[0] && dateRange[1]) {
        const start = dateRange[0].startOf('day');
        const end = dateRange[1].endOf('day');
        const reqFrom = dayjs(r.fromDate);
        const reqTo = dayjs(r.toDate);

        // Check if [reqFrom, reqTo] overlaps with [start, end]
        const isOverlap =
          reqFrom.isBefore(end.add(1, 'day')) && reqTo.isAfter(start.subtract(1, 'day'));
        if (!isOverlap) return false;
      }

      return true;
    });
  }, [requests, statusFilter, searchText, dateRange]);

  const renderStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return (
          <Tag color="warning" icon={<ClockCircleOutlined />}>
            Chờ duyệt
          </Tag>
        );
      case 'APPROVED':
        return (
          <Tag color="success" icon={<CheckCircleOutlined />}>
            Đã duyệt
          </Tag>
        );
      case 'REJECTED':
        return (
          <Tag color="error" icon={<CloseCircleOutlined />}>
            Từ chối
          </Tag>
        );
      default:
        return <Tag>{status}</Tag>;
    }
  };

  const getRequestTypeLabel = (type: string) => {
    switch (type) {
      case 'SICK_LEAVE':
        return 'Nghỉ ốm';
      case 'PERSONAL':
        return 'Việc gia đình';
      case 'OFFICIAL':
        return 'Nghỉ công việc';
      default:
        return type || 'Khác';
    }
  };

  const columns = [
    {
      title: 'Mã đơn',
      dataIndex: 'id',
      key: 'id',
      width: 85,
      render: (id: number) => <Text strong style={{ color: '#2563EB' }}>#{id}</Text>,
    },
    {
      title: 'Học sinh',
      key: 'student',
      render: (_: any, r: LeaveRequestDTO) => (
        <div>
          <Text strong style={{ display: 'block' }}>
            {r.studentName || '—'}
          </Text>
          <Text type="secondary" style={{ fontSize: 12 }}>
            Mã: {r.studentCode || '—'}
          </Text>
        </div>
      ),
    },
    {
      title: 'Loại đơn',
      dataIndex: 'requestType',
      key: 'requestType',
      width: 130,
      render: (type: string) => <Tag color="blue">{getRequestTypeLabel(type)}</Tag>,
    },
    {
      title: 'Thời gian nghỉ',
      key: 'dates',
      width: 200,
      render: (_: any, r: LeaveRequestDTO) => {
        const from = dayjs(r.fromDate);
        const to = dayjs(r.toDate);
        const diffDays = to.diff(from, 'day') + 1;
        return (
          <div>
            <Space size={4}>
              <CalendarOutlined style={{ color: '#64748B' }} />
              <Text>{from.format('DD/MM/YYYY')} - {to.format('DD/MM/YYYY')}</Text>
            </Space>
            <div style={{ fontSize: 12, color: '#64748B', marginTop: 2 }}>
              ({diffDays} ngày)
            </div>
          </div>
        );
      },
    },
    {
      title: 'Lý do nghỉ',
      dataIndex: 'reason',
      key: 'reason',
      ellipsis: true,
      render: (reason: string) => (
        <span title={reason}>
          {reason || '—'}
        </span>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: string) => renderStatusBadge(status),
    },
    {
      title: 'Ghi chú xử lý',
      dataIndex: 'adminNote',
      key: 'adminNote',
      width: 180,
      ellipsis: true,
      render: (note: string | null) =>
        note ? <Text type="secondary" italic>{note}</Text> : <Text type="secondary">—</Text>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 190,
      align: 'right' as const,
      render: (_: any, record: LeaveRequestDTO) => (
        <Space size={6}>
          <Button
            type="text"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleOpenDetail(record)}
            title="Xem chi tiết"
          />
          {record.status === 'PENDING' && (
            <>
              <Popconfirm
                title="Duyệt đơn nghỉ phép"
                description={`Bạn có chắc chắn muốn duyệt đơn của ${record.studentName}?`}
                onConfirm={() => handleApprove(record.id)}
                okText="Duyệt"
                cancelText="Hủy"
                okButtonProps={{ loading: statusMutation.isPending }}
              >
                <Button
                  type="primary"
                  size="small"
                  icon={<CheckCircleOutlined />}
                  style={{ backgroundColor: '#10B981' }}
                >
                  Duyệt
                </Button>
              </Popconfirm>

              <Button
                danger
                size="small"
                icon={<CloseCircleOutlined />}
                onClick={() => handleOpenRejectModal(record.id)}
              >
                Từ chối
              </Button>
            </>
          )}
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
              Duyệt Đơn Xin Nghỉ Phép
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Quản lý và tiếp nhận các yêu cầu nghỉ phép của học sinh toàn trường
            </Text>
          </div>

          <Button
            icon={<RedoOutlined spin={isRefetching} />}
            onClick={() => refetch()}
          >
            Làm mới
          </Button>
        </div>
      </div>

      {/* Main Table Card */}
      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
        {/* Filter Toolbar */}
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
            {/* Status Tabs */}
            <Radio.Group value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
              <Radio.Button value="ALL">Tất cả ({counts.all})</Radio.Button>
              <Radio.Button value="PENDING">
                Chờ duyệt {counts.pending > 0 && <Tag color="warning" style={{ marginLeft: 4 }}>{counts.pending}</Tag>}
              </Radio.Button>
              <Radio.Button value="APPROVED">Đã duyệt ({counts.approved})</Radio.Button>
              <Radio.Button value="REJECTED">Từ chối ({counts.rejected})</Radio.Button>
            </Radio.Group>

            {/* Search Input */}
            <Input
              placeholder="Tìm theo tên, mã HS, lý do..."
              prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              style={{ width: 260 }}
              allowClear
            />

            {/* Date Range Filter */}
            <RangePicker
              value={dateRange}
              onChange={(dates) => setDateRange(dates)}
              format="DD/MM/YYYY"
              placeholder={['Từ ngày', 'Đến ngày']}
              style={{ width: 250 }}
            />

            {dateRange && (
              <Button onClick={() => setDateRange(null)}>
                Xóa lọc ngày
              </Button>
            )}
          </Space>

          <Text type="secondary">
            Tìm thấy: <strong>{filteredRequests.length} đơn</strong>
          </Text>
        </div>

        {/* Content Table or Feedback */}
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '80px 0' }}>
            <Spin size="large" tip="Đang tải danh sách đơn nghỉ phép..." />
          </div>
        ) : error ? (
          <Alert
            type="error"
            message="Lỗi kết nối máy chủ"
            description="Không thể tải danh sách đơn nghỉ phép từ backend. Vui lòng kiểm tra lại kết nối mạng hoặc phiên đăng nhập."
            showIcon
          />
        ) : filteredRequests.length === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="Không có đơn nghỉ phép nào phù hợp với bộ lọc hiện tại"
            style={{ padding: '40px 0' }}
          />
        ) : (
          <Table
            columns={columns}
            dataSource={filteredRequests}
            rowKey="id"
            pagination={{ pageSize: 10, showSizeChanger: true, pageSizeOptions: ['10', '20', '50'] }}
            scroll={{ x: 950 }}
          />
        )}
      </Card>

      {/* Drawer: Detailed Leave Request */}
      <Drawer
        title={
          <Space>
            <FileTextOutlined style={{ color: '#2563EB' }} />
            <span>Chi tiết đơn nghỉ phép #{selectedRequest?.id}</span>
          </Space>
        }
        width={560}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        extra={
          selectedRequest?.status === 'PENDING' ? (
            <Space>
              <Button
                danger
                size="middle"
                icon={<CloseCircleOutlined />}
                onClick={() => handleOpenRejectModal(selectedRequest.id)}
              >
                Từ chối
              </Button>
              <Popconfirm
                title="Duyệt đơn nghỉ phép"
                description={`Bạn có chắc muốn duyệt đơn này?`}
                onConfirm={() => handleApprove(selectedRequest.id)}
                okText="Duyệt ngay"
                cancelText="Hủy"
              >
                <Button
                  type="primary"
                  size="middle"
                  icon={<CheckCircleOutlined />}
                  style={{ backgroundColor: '#10B981' }}
                  loading={statusMutation.isPending}
                >
                  Duyệt đơn
                </Button>
              </Popconfirm>
            </Space>
          ) : null
        }
      >
        {selectedRequest && (
          <Space direction="vertical" size={20} style={{ width: '100%' }}>
            <div
              style={{
                background: '#F8FAFC',
                padding: '16px 20px',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Trạng thái hiện tại</Text>
                <div style={{ marginTop: 4 }}>{renderStatusBadge(selectedRequest.status)}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <Text type="secondary" style={{ fontSize: 12 }}>Loại đơn</Text>
                <div style={{ marginTop: 4 }}>
                  <Tag color="blue">{getRequestTypeLabel(selectedRequest.requestType)}</Tag>
                </div>
              </div>
            </div>

            <Descriptions title="Thông tin học sinh" bordered size="small" column={1}>
              <Descriptions.Item label="Họ và tên">
                <strong>{selectedRequest.studentName}</strong>
              </Descriptions.Item>
              <Descriptions.Item label="Mã học sinh">
                <Text code>{selectedRequest.studentCode}</Text>
              </Descriptions.Item>
            </Descriptions>

            <Descriptions title="Thời gian xin nghỉ" bordered size="small" column={1}>
              <Descriptions.Item label="Từ ngày">
                {dayjs(selectedRequest.fromDate).format('DD/MM/YYYY')}
              </Descriptions.Item>
              <Descriptions.Item label="Đến ngày">
                {dayjs(selectedRequest.toDate).format('DD/MM/YYYY')}
              </Descriptions.Item>
              <Descriptions.Item label="Tổng số ngày">
                <strong>{dayjs(selectedRequest.toDate).diff(dayjs(selectedRequest.fromDate), 'day') + 1} ngày</strong>
              </Descriptions.Item>
            </Descriptions>

            <div>
              <Text strong style={{ display: 'block', marginBottom: 8 }}>
                Lý do xin nghỉ từ phụ huynh / học sinh:
              </Text>
              <div
                style={{
                  background: '#F1F5F9',
                  padding: '14px 16px',
                  borderRadius: 8,
                  fontSize: 14,
                  lineHeight: 1.6,
                  color: '#334155',
                }}
              >
                {selectedRequest.reason}
              </div>
            </div>

            {selectedRequest.adminNote && (
              <div>
                <Text strong style={{ display: 'block', marginBottom: 8, color: '#EF4444' }}>
                  Ghi chú xử lý của Nhà trường:
                </Text>
                <div
                  style={{
                    background: '#FEF2F2',
                    padding: '12px 16px',
                    borderRadius: 8,
                    fontSize: 13,
                    color: '#991B1B',
                    border: '1px solid #FEE2E2',
                  }}
                >
                  {selectedRequest.adminNote}
                </div>
              </div>
            )}
          </Space>
        )}
      </Drawer>

      {/* Modal: Nhập lý do từ chối */}
      <Modal
        title={
          <Space>
            <WarningOutlined style={{ color: '#EF4444' }} />
            <span>Từ chối đơn xin nghỉ phép</span>
          </Space>
        }
        open={isRejectModalOpen}
        onCancel={() => {
          setIsRejectModalOpen(false);
          rejectForm.resetFields();
          setRejectingRequestId(null);
        }}
        onOk={handleConfirmReject}
        okText="Xác nhận từ chối"
        okButtonProps={{ danger: true, loading: statusMutation.isPending }}
        cancelText="Hủy bỏ"
      >
        <Paragraph type="secondary">
          Vui lòng nhập lý do từ chối để thông báo cho học sinh và phụ huynh được rõ.
        </Paragraph>
        <Form form={rejectForm} layout="vertical">
          <Form.Item
            name="adminNote"
            label="Lý do từ chối"
            rules={[{ required: true, message: 'Vui lòng nhập lý do từ chối đơn' }]}
          >
            <TextArea
              rows={4}
              placeholder="Ví dụ: Ngày nghỉ trùng với kỳ thi giữa kỳ bắt buộc, hoặc giấy tờ chưa đủ hợp lệ..."
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};
