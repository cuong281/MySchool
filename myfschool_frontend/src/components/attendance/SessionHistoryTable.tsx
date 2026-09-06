import React, { useState, useMemo } from 'react';
import { Table, Button, Space, Tag, Input, Select, Card, Empty, Typography } from 'antd';
import { SearchOutlined, EditOutlined, EyeOutlined, CalendarOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import type { AttendanceSessionSummaryDTO } from '../../types/attendance';

const { Text } = Typography;

interface SessionHistoryTableProps {
  sessions: AttendanceSessionSummaryDTO[];
  onOpenSheet: (slotNumber: number, subjectId?: number, date?: string) => void;
}

export const SessionHistoryTable: React.FC<SessionHistoryTableProps> = ({
  sessions,
  onOpenSheet,
}) => {
  const [searchText, setSearchText] = useState('');
  const [selectedMonth, setSelectedMonth] = useState<string>('ALL');

  const filteredSessions = useMemo(() => {
    return sessions.filter((s) => {
      // 1. Filter by month
      if (selectedMonth !== 'ALL') {
        const sessionMonth = dayjs(s.attendanceDate).month() + 1; // 1-12
        if (sessionMonth.toString() !== selectedMonth) return false;
      }
      // 2. Filter by search text (subject name or date)
      if (searchText.trim()) {
        const query = searchText.toLowerCase().trim();
        const subjectMatch = s.subjectName?.toLowerCase().includes(query);
        const dateMatch = dayjs(s.attendanceDate).format('DD/MM/YYYY').includes(query);
        const slotMatch = `tiết ${s.slotNumber}`.includes(query);
        if (!subjectMatch && !dateMatch && !slotMatch) return false;
      }
      return true;
    });
  }, [sessions, selectedMonth, searchText]);

  const columns = [
    {
      title: 'Ngày học',
      dataIndex: 'attendanceDate',
      key: 'attendanceDate',
      width: 140,
      render: (date: string) => (
        <Space orientation="horizontal" size={6}>
          <CalendarOutlined style={{ color: '#2563EB' }} />
          <Text strong>{dayjs(date).format('DD/MM/YYYY')}</Text>
        </Space>
      ),
      sorter: (a: AttendanceSessionSummaryDTO, b: AttendanceSessionSummaryDTO) =>
        dayjs(a.attendanceDate).unix() - dayjs(b.attendanceDate).unix(),
      defaultSortOrder: 'descend' as const,
    },
    {
      title: 'Tiết học',
      dataIndex: 'slotNumber',
      key: 'slotNumber',
      width: 110,
      render: (slot: number) => <Tag color="blue">Tiết {slot}</Tag>,
    },
    {
      title: 'Môn học',
      dataIndex: 'subjectName',
      key: 'subjectName',
      render: (name?: string) => <Text strong>{name || 'Chưa phân môn'}</Text>,
    },
    {
      title: 'Thống kê sĩ số phiên',
      key: 'stats',
      render: (_: any, record: AttendanceSessionSummaryDTO) => (
        <Space wrap size={[6, 6]}>
          <Tag color="success">Có mặt: {record.presentCount}</Tag>
          {record.excusedCount > 0 && <Tag color="processing">Có phép: {record.excusedCount}</Tag>}
          {record.unexcusedCount > 0 && <Tag color="error">Không phép: {record.unexcusedCount}</Tag>}
          {record.lateCount > 0 && <Tag color="warning">Muộn: {record.lateCount}</Tag>}
        </Space>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'canEdit',
      key: 'canEdit',
      width: 150,
      render: (canEdit?: boolean) =>
        canEdit ? (
          <Tag color="cyan">Có thể điểm danh</Tag>
        ) : (
          <Tag color="default">Đã khóa (Chỉ xem)</Tag>
        ),
    },
    {
      title: 'Thao tác',
      key: 'action',
      width: 140,
      render: (_: any, record: AttendanceSessionSummaryDTO) => (
        <Button
          type="link"
          icon={record.canEdit ? <EditOutlined /> : <EyeOutlined />}
          onClick={() => onOpenSheet(record.slotNumber, record.subjectId, record.attendanceDate)}
        >
          {record.canEdit ? 'Sửa điểm danh' : 'Xem chi tiết'}
        </Button>
      ),
    },
  ];

  return (
    <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
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
            placeholder="Tìm theo môn học, ngày..."
            prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 240 }}
            allowClear
          />

          <Select
            value={selectedMonth}
            onChange={setSelectedMonth}
            style={{ width: 140 }}
            options={[
              { value: 'ALL', label: 'Tất cả tháng' },
              { value: '9', label: 'Tháng 9' },
              { value: '10', label: 'Tháng 10' },
              { value: '11', label: 'Tháng 11' },
              { value: '12', label: 'Tháng 12' },
              { value: '1', label: 'Tháng 1' },
              { value: '2', label: 'Tháng 2' },
              { value: '3', label: 'Tháng 3' },
              { value: '4', label: 'Tháng 4' },
              { value: '5', label: 'Tháng 5' },
            ]}
          />
        </Space>

        <Text type="secondary">
          Tổng số: <strong>{filteredSessions.length} buổi</strong>
        </Text>
      </div>

      {sessions.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Lớp chưa có buổi học nào được điểm danh"
          style={{ padding: '32px 0' }}
        />
      ) : (
        <Table
          columns={columns}
          dataSource={filteredSessions}
          rowKey={(record) => `${record.attendanceDate}_${record.slotNumber}_${record.subjectId || 0}`}
          pagination={{ pageSize: 10, showSizeChanger: false }}
          scroll={{ x: 750 }}
        />
      )}
    </Card>
  );
};
