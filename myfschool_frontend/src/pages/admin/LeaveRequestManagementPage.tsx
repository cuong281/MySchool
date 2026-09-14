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

const isPendingStatus = (s?: string) => s === 'PENDING' || s === 'Chờ duyệt';
const isApprovedStatus = (s?: string) => s === 'APPROVED' || s === 'Đã duyệt';
const isRejectedStatus = (s?: string) => s === 'REJECTED' || s === 'Từ chối';

export const LeaveRequestManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const queryClient = useQueryClient();

  // Filter States
  const [targetTypeFilter, setTargetTypeFilter] = useState<'ALL' | 'STUDENT' | 'TEACHER'>('ALL');
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
    mutationFn: ({ id, status, adminNote }: { id: number; status: string; adminNote?: string }) =>
      leaveRequestApi.updateStatus(id, { status, adminNote }),
    onSuccess: (_, variables) => {
      message.success(
        isApprovedStatus(variables.status) ? 'Đã duyệt đơn nghỉ phép thành công' : 'Đã từ chối đơn nghỉ phép'
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
    statusMutation.mutate({ id, status: 'Đã duyệt' });
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
          status: 'Từ chối',
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
      pending: requests.filter((r) => isPendingStatus(r.status)).length,
      approved: requests.filter((r) => isApprovedStatus(r.status)).length,
      rejected: requests.filter((r) => isRejectedStatus(r.status)).length,
    };
  }, [requests]);

  // Filtered requests
  const filteredRequests = useMemo(() => {
    return requests.filter((r) => {
      // Target type filter
      const isTeacherReq = (r as any).role === 'TEACHER' || (r as any).teacherId != null;
      if (targetTypeFilter === 'STUDENT' && isTeacherReq) return false;
      if (targetTypeFilter === 'TEACHER' && !isTeacherReq) return false;

      // Status filter
      if (statusFilter === 'PENDING' && !isPendingStatus(r.status)) return false;
      if (statusFilter === 'APPROVED' && !isApprovedStatus(r.status)) return false;
      if (statusFilter === 'REJECTED' && !isRejectedStatus(r.status)) return false;

      // Search text (student/teacher name or code)
      if (searchText.trim()) {
        const q = searchText.toLowerCase().trim();
        const displayName = ((r.studentName || (r as any).teacherName || '') as string).toLowerCase();
        const matchName = displayName.includes(q);
        const matchCode = r.studentCode?.toLowerCase().includes(q);
        const matchClass = r.className?.toLowerCase().includes(q);
        const matchReason = r.reason?.toLowerCase().includes(q);
        if (!matchName && !matchCode && !matchClass && !matchReason) return false;
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
  }, [requests, targetTypeFilter, statusFilter, searchText, dateRange]);

  const renderStatusBadge = (status: string) => {
    if (isPendingStatus(status)) {
      return (
        <Tag color="warning" icon={<ClockCircleOutlined />}>
          Chờ duyệt
        </Tag>
      );
    }
    if (isApprovedStatus(status)) {
      return (
        <Tag color="success" icon={<CheckCircleOutlined />}>
          Đã duyệt
        </Tag>
      );
    }
    if (isRejectedStatus(status)) {
      return (
        <Tag color="error" icon={<CloseCircleOutlined />}>
          Từ chối
        </Tag>
      );
    }
    return <Tag>{status}</Tag>;
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
      title: 'Người gửi / Đối tượng',
      key: 'requester',
      render: (_: any, r: LeaveRequestDTO) => {
        const isTeacherReq = (r as any).role === 'TEACHER' || (r as any).teacherId != null;
        const displayName = r.studentName || (r as any).teacherName || '—';
        return (
          <div>
            <Text strong style={{ display: 'block' }}>
              {displayName}
            </Text>
            <Space size={4}>
              {isTeacherReq ? (
                <Tag color="cyan">Giáo viên</Tag>
              ) : (
                <>
                  {r.className && <Tag color="blue">{r.className}</Tag>}
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    Mã: {r.studentCode || '—'}
                  </Text>
                </>
              )}
            </Space>
          </div>
        );
      },
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
      render: (_: any, record: LeaveRequestDTO) => {
        const displayName = record.studentName || (record as any).teacherName || 'người gửi';
        return (
          <Space size={6}>
            <Button
              type="text"
              size="small"
              icon={<EyeOutlined />}
              onClick={() => handleOpenDetail(record)}
              title="Xem chi tiết"
            />
            {isPendingStatus(record.status) && (
              <>
                <Popconfirm
                  title="Duyệt đơn nghỉ phép"
                  description={`Bạn có chắc chắn muốn duyệt đơn của ${displayName}?`}
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
        );
      },
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
            {/* Target Type Filter */}
            <Radio.Group value={targetTypeFilter} onChange={(e) => setTargetTypeFilter(e.target.value)}>
              <Radio.Button value="ALL">Tất cả</Radio.Button>
              <Radio.Button value="STUDENT">Đơn học sinh</Radio.Button>
              <Radio.Button value="TEACHER">Đơn giáo viên</Radio.Button>
            </Radio.Group>

            {/* Status Tabs */}
            <Radio.Group value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
              <Radio.Button value="ALL">Tất cả ({counts.all})</Radio.Button>
              <Radio.Button value="PENDING">Chờ duyệt ({counts.pending})</Radio.Button>
              <Radio.Button value="APPROVED">Đã duyệt ({counts.approved})</Radio.Button>
              <Radio.Button value="REJECTED">Từ chối ({counts.rejected})</Radio.Button>
            </Radio.Group>

            {/* Search Input */}
            <Input
              placeholder="Tìm theo tên, mã HS, lớp, lý do..."
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
            description={
              targetTypeFilter === 'TEACHER'
                ? 'Chưa có đơn xin nghỉ của giáo viên (Tính năng cần Backend API hỗ trợ)'
                : 'Không có đơn nghỉ phép nào phù hợp với bộ lọc hiện tại'
            }
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
          isPendingStatus(selectedRequest?.status) ? (
            <Space>
              <Button
                danger
                size="middle"
                icon={<CloseCircleOutlined />}
                onClick={() => handleOpenRejectModal(selectedRequest!.id)}
              >
                Từ chối
              </Button>
              <Popconfirm
                title="Duyệt đơn nghỉ phép"
                description={`Bạn có chắc muốn duyệt đơn này?`}
                onConfirm={() => handleApprove(selectedRequest!.id)}
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

            {(() => {
              const isTeacherReq = (selectedRequest as any).role === 'TEACHER' || (selectedRequest as any).teacherId != null;
              const displayName = selectedRequest.studentName || (selectedRequest as any).teacherName || '—';
              return (
                <Descriptions title={isTeacherReq ? 'Thông tin giáo viên' : 'Thông tin học sinh'} bordered size="small" column={1}>
                  <Descriptions.Item label="Họ và tên">
                    <strong>{displayName}</strong>
                  </Descriptions.Item>
                  <Descriptions.Item label="Đối tượng">
                    <Tag color={isTeacherReq ? 'cyan' : 'blue'}>{isTeacherReq ? 'Giáo viên' : 'Học sinh'}</Tag>
                  </Descriptions.Item>
                  {!isTeacherReq && selectedRequest.className && (
                    <Descriptions.Item label="Lớp học">
                      <Tag color="blue">{selectedRequest.className}</Tag>
                    </Descriptions.Item>
                  )}
                  {!isTeacherReq && selectedRequest.studentCode && (
                    <Descriptions.Item label="Mã học sinh">
                      <Text code>{selectedRequest.studentCode}</Text>
                    </Descriptions.Item>
                  )}
                </Descriptions>
              );
            })()}

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
            label="Lý do từ chối (bắt buộc):"
            rules={[
              {
                validator: async (_, value) => {
                  if (!value || value.trim().length === 0) {
                    throw new Error('Vui lòng nhập lý do từ chối (không được để trống)');
                  }
                },
              },
            ]}
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
