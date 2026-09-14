import React from 'react';
import {
  Card,
  Table,
  Button,
  Space,
  Tag,
  Typography,
  Tooltip,
  Alert,
  Badge,
  Spin,
  message,
} from 'antd';
import {
  AlertOutlined,
  ClockCircleOutlined,
  CheckSquareOutlined,
  ReloadOutlined,
  NotificationOutlined,
  UserOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { attendanceApi } from '../../api/attendanceApi';
import type { UnrecordedAttendanceSessionDTO } from '../../types/attendance';

const { Text, Title } = Typography;

interface UnrecordedAttendanceSectionProps {
  onOpenSheet: (classId: number, slotNumber: number, subjectId?: number, date?: string) => void;
}

export const UnrecordedAttendanceSection: React.FC<UnrecordedAttendanceSectionProps> = ({
  onOpenSheet,
}) => {
  const queryClient = useQueryClient();

  // Fetch unrecorded sessions today (polling every 60s)
  const {
    data: unrecorded = [],
    isLoading,
    refetch,
    isFetching,
  } = useQuery<UnrecordedAttendanceSessionDTO[]>({
    queryKey: ['unrecordedAttendanceToday'],
    queryFn: () => attendanceApi.getUnrecordedSessionsToday(),
    refetchInterval: 60000,
  });

  // Manual trigger scan & reminder
  const scanMutation = useMutation({
    mutationFn: () => attendanceApi.scanAndRemind(),
    onSuccess: (res) => {
      message.success(
        res.remindedCount > 0
          ? `Quét thành công! Đã gửi ${res.remindedCount} thông báo nhắc nhở tới giáo viên.`
          : 'Quét hoàn tất: Không có thêm giáo viên nào cần nhắc nhở lúc này.'
      );
      queryClient.invalidateQueries({ queryKey: ['unrecordedAttendanceToday'] });
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.message || 'Không thể thực hiện quét lúc này');
    },
  });

  const lateCount = unrecorded.filter((u) => u.alertStatus === 'CANH_BAO_TRE').length;
  const expiredCount = unrecorded.filter((u) => u.alertStatus === 'QUA_HAN').length;

  const columns = [
    {
      title: 'Lớp',
      dataIndex: 'className',
      key: 'className',
      width: 100,
      render: (className: string) => (
        <Tag color="blue" style={{ fontWeight: 600, fontSize: 13, padding: '2px 8px' }}>
          {className}
        </Tag>
      ),
    },
    {
      title: 'Môn học',
      dataIndex: 'subjectName',
      key: 'subjectName',
      width: 140,
      render: (subjectName?: string) => (
        <Text strong style={{ color: '#1E293B' }}>
          {subjectName || '—'}
        </Text>
      ),
    },
    {
      title: 'Giáo viên phụ trách',
      dataIndex: 'teacherName',
      key: 'teacherName',
      width: 180,
      render: (teacherName?: string) => (
        <Space size={6}>
          <UserOutlined style={{ color: '#0EA5E9' }} />
          <Text style={{ fontWeight: 500 }}>{teacherName || 'Chưa phân công'}</Text>
        </Space>
      ),
    },
    {
      title: 'Tiết học',
      dataIndex: 'slotNumber',
      key: 'slotNumber',
      width: 90,
      render: (slot: number) => (
        <Tag color="purple" style={{ fontWeight: 500 }}>
          Tiết {slot}
        </Tag>
      ),
    },
    {
      title: 'Giờ bắt đầu',
      key: 'timeRange',
      width: 130,
      render: (_: any, record: UnrecordedAttendanceSessionDTO) => (
        <Space size={4}>
          <ClockCircleOutlined style={{ color: '#64748B', fontSize: 12 }} />
          <Text type="secondary" style={{ fontSize: 13 }}>
            {record.startTime?.slice(0, 5)} - {record.endTime?.slice(0, 5)}
          </Text>
        </Space>
      ),
    },
    {
      title: 'Tiến độ',
      key: 'progress',
      width: 120,
      render: (_: any, record: UnrecordedAttendanceSessionDTO) => {
        if (record.attendanceStatus === 'NOT_ATTENDED') {
          return <Tag color="default">Chưa điểm danh (0/{record.totalStudents})</Tag>;
        }
        return (
          <Tag color="orange">
            Một phần ({record.recordedStudents}/{record.totalStudents})
          </Tag>
        );
      },
    },
    {
      title: 'Thời gian trễ',
      dataIndex: 'delayFormatted',
      key: 'delayFormatted',
      width: 120,
      render: (delayFormatted: string, record: UnrecordedAttendanceSessionDTO) => {
        let tagColor = 'gold';
        if (record.alertStatus === 'QUA_HAN') tagColor = 'error';
        else if (record.alertStatus === 'CANH_BAO_TRE') tagColor = 'warning';

        return (
          <Tag color={tagColor} style={{ fontWeight: 600 }}>
            {record.alertStatus === 'QUA_HAN' ? 'Quá ' : 'Trễ '}
            {delayFormatted}
          </Tag>
        );
      },
    },
    {
      title: 'Trạng thái',
      key: 'status',
      width: 150,
      render: (_: any, record: UnrecordedAttendanceSessionDTO) => {
        let tagNode;
        if (record.alertStatus === 'QUA_HAN') {
          tagNode = <Tag color="error">Quá hạn</Tag>;
        } else if (record.alertStatus === 'CANH_BAO_TRE') {
          tagNode = <Tag color="warning">Cảnh báo trễ</Tag>;
        } else {
          tagNode = <Tag color="default">Chờ điểm danh</Tag>;
        }

        return (
          <Space size={4} wrap>
            {tagNode}
            {record.reminderSent && (
              <Tooltip title="Đã gửi thông báo nhắc nhở tới giáo viên phụ trách hôm nay">
                <Tag color="cyan" icon={<NotificationOutlined />}>
                  Đã nhắc
                </Tag>
              </Tooltip>
            )}
          </Space>
        );
      },
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 130,
      render: (_: any, record: UnrecordedAttendanceSessionDTO) => (
        <Button
          type="primary"
          size="small"
          icon={<CheckSquareOutlined />}
          style={{ background: '#0284C7', borderColor: '#0284C7' }}
          onClick={() =>
            onOpenSheet(
              record.classId,
              record.slotNumber,
              record.subjectId,
              dayjs().format('YYYY-MM-DD')
            )
          }
        >
          Điểm danh ngay
        </Button>
      ),
    },
  ];

  return (
    <Card
      style={{
        borderRadius: 16,
        marginBottom: 20,
        boxShadow: '0 2px 10px rgba(0,0,0,0.03)',
        border: unrecorded.length > 0 ? '1px solid #FCA5A5' : '1px solid #E2E8F0',
        background: unrecorded.length > 0 ? '#FFFDFD' : '#FFFFFF',
      }}
      bodyStyle={{ padding: '16px 20px' }}
    >
      {/* Header Bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: unrecorded.length > 0 ? 16 : 0,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 10,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: unrecorded.length > 0 ? '#FEE2E2' : '#DCFCE7',
              color: unrecorded.length > 0 ? '#DC2626' : '#16A34A',
              fontSize: 18,
            }}
          >
            {unrecorded.length > 0 ? <AlertOutlined /> : <CheckCircleOutlined />}
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Title level={5} style={{ margin: 0, color: '#0F172A' }}>
                Chưa điểm danh hôm nay
              </Title>
              {unrecorded.length > 0 ? (
                <Badge
                  count={`${unrecorded.length} buổi`}
                  style={{
                    backgroundColor: expiredCount > 0 ? '#DC2626' : '#EA580C',
                    fontWeight: 600,
                  }}
                />
              ) : (
                <Tag color="success" style={{ margin: 0 }}>
                  100% Đúng giờ
                </Tag>
              )}
            </div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {unrecorded.length > 0
                ? `Phát hiện ${unrecorded.length} buổi học đã bắt đầu nhưng chưa hoàn tất điểm danh (${lateCount} cảnh báo trễ, ${expiredCount} quá hạn).`
                : 'Tất cả các buổi học hôm nay đã được giáo viên ghi nhận điểm danh đầy đủ.'}
            </Text>
          </div>
        </div>

        <Space size={8}>
          <Button
            type="primary"
            danger
            icon={<NotificationOutlined />}
            loading={scanMutation.isPending}
            onClick={() => scanMutation.mutate()}
            disabled={unrecorded.length === 0}
          >
            Quét & Nhắc nhở
          </Button>
          <Button
            icon={<ReloadOutlined />}
            loading={isFetching}
            onClick={() => refetch()}
            title="Làm mới danh sách chưa điểm danh"
          >
            Làm mới
          </Button>
        </Space>
      </div>

      {/* Content */}
      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '30px 0' }}>
          <Spin tip="Đang kiểm tra dữ liệu điểm danh thời gian thực..." />
        </div>
      ) : unrecorded.length === 0 ? (
        <Alert
          type="success"
          showIcon
          style={{ marginTop: 12, borderRadius: 10 }}
          message="Không có buổi học nào bị trễ điểm danh"
          description="Hệ thống tự động rà soát theo thời khóa biểu thực tế mỗi 5 phút. Admin không cần phải mở từng lớp để kiểm tra."
        />
      ) : (
        <Table
          dataSource={unrecorded}
          columns={columns}
          rowKey="scheduleId"
          pagination={false}
          size="middle"
          bordered
          scroll={{ x: 950 }}
        />
      )}
    </Card>
  );
};
