import React, { useState, useMemo } from 'react';
import { Table, Input, Radio, Space, Progress, Button, Tag, Card, Typography, Empty } from 'antd';
import { SearchOutlined, EyeOutlined, WarningOutlined } from '@ant-design/icons';
import type { AttendanceStudentSummaryDTO } from '../../types/attendance';

const { Text } = Typography;

interface StudentRosterTableProps {
  students: AttendanceStudentSummaryDTO[];
  onViewDetail: (student: AttendanceStudentSummaryDTO) => void;
}

export const StudentRosterTable: React.FC<StudentRosterTableProps> = ({
  students,
  onViewDetail,
}) => {
  const [searchText, setSearchText] = useState('');
  const [filterType, setFilterType] = useState<string>('ALL');

  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      // 1. Text filter
      if (searchText.trim()) {
        const q = searchText.toLowerCase().trim();
        const matchName = s.studentName.toLowerCase().includes(q);
        const matchCode = s.studentCode.toLowerCase().includes(q);
        if (!matchName && !matchCode) return false;
      }

      // 2. Category filter
      if (filterType === 'AT_RISK') {
        return s.unexcusedCount >= 3 || s.attendanceRate < 75;
      }
      if (filterType === 'HAS_ABSENCE') {
        return s.unexcusedCount > 0 || s.excusedCount > 0;
      }
      if (filterType === 'HAS_LATE') {
        return s.lateCount > 0;
      }

      return true;
    });
  }, [students, searchText, filterType]);

  const atRiskCount = useMemo(() => {
    return students.filter((s) => s.unexcusedCount >= 3 || s.attendanceRate < 75).length;
  }, [students]);

  const columns = [
    {
      title: 'Mã HS',
      dataIndex: 'studentCode',
      key: 'studentCode',
      width: 110,
      render: (code: string) => <Text code>{code}</Text>,
    },
    {
      title: 'Họ và tên',
      dataIndex: 'studentName',
      key: 'studentName',
      render: (name: string, record: AttendanceStudentSummaryDTO) => {
        const isCritical = record.unexcusedCount >= 3 || record.attendanceRate < 70;
        return (
          <Space direction="horizontal" size={8}>
            <Text strong>{name}</Text>
            {isCritical && (
              <Tag color="error" icon={<WarningOutlined />}>
                Nguy cơ cấm thi
              </Tag>
            )}
          </Space>
        );
      },
      sorter: (a: AttendanceStudentSummaryDTO, b: AttendanceStudentSummaryDTO) =>
        a.studentName.localeCompare(b.studentName, 'vi'),
    },
    {
      title: 'Số buổi tham gia',
      dataIndex: 'totalTrackedSessions',
      key: 'totalTrackedSessions',
      width: 130,
      align: 'center' as const,
      render: (count: number) => <Text>{count} buổi</Text>,
    },
    {
      title: 'Có mặt',
      dataIndex: 'presentCount',
      key: 'presentCount',
      width: 90,
      align: 'center' as const,
      render: (val: number) => <Tag color="success">{val}</Tag>,
    },
    {
      title: 'Có phép',
      dataIndex: 'excusedCount',
      key: 'excusedCount',
      width: 90,
      align: 'center' as const,
      render: (val: number) => (val > 0 ? <Tag color="processing">{val}</Tag> : <Text type="secondary">0</Text>),
    },
    {
      title: 'Không phép',
      dataIndex: 'unexcusedCount',
      key: 'unexcusedCount',
      width: 110,
      align: 'center' as const,
      render: (val: number) =>
        val >= 3 ? (
          <Tag color="error" style={{ fontWeight: 'bold' }}>
            {val} (Cảnh báo)
          </Tag>
        ) : val > 0 ? (
          <Tag color="error">{val}</Tag>
        ) : (
          <Text type="secondary">0</Text>
        ),
      sorter: (a: AttendanceStudentSummaryDTO, b: AttendanceStudentSummaryDTO) =>
        a.unexcusedCount - b.unexcusedCount,
    },
    {
      title: 'Đi muộn',
      dataIndex: 'lateCount',
      key: 'lateCount',
      width: 90,
      align: 'center' as const,
      render: (val: number) => (val > 0 ? <Tag color="warning">{val}</Tag> : <Text type="secondary">0</Text>),
    },
    {
      title: 'Tỷ lệ chuyên cần',
      dataIndex: 'attendanceRate',
      key: 'attendanceRate',
      width: 180,
      render: (rate: number, record: AttendanceStudentSummaryDTO) => {
        if (record.totalTrackedSessions === 0) {
          return <Text type="secondary">—</Text>;
        }

        let strokeColor = '#10B981';
        if (rate < 75) strokeColor = '#EF4444';
        else if (rate < 88) strokeColor = '#F59E0B';

        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Progress percent={rate} size="small" strokeColor={strokeColor} style={{ flex: 1 }} />
            <Text strong style={{ fontSize: 12, minWidth: 42 }}>
              {rate.toFixed(1)}%
            </Text>
          </div>
        );
      },
      sorter: (a: AttendanceStudentSummaryDTO, b: AttendanceStudentSummaryDTO) =>
        a.attendanceRate - b.attendanceRate,
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 130,
      render: (_: any, record: AttendanceStudentSummaryDTO) => (
        <Button type="link" icon={<EyeOutlined />} onClick={() => onViewDetail(record)}>
          Xem chi tiết
        </Button>
      ),
    },
  ];

  return (
    <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
      {/* Search & Filter Bar */}
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
            placeholder="Tìm theo tên, mã học sinh..."
            prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            style={{ width: 260 }}
            allowClear
          />

          <Radio.Group value={filterType} onChange={(e) => setFilterType(e.target.value)}>
            <Radio.Button value="ALL">Tất cả ({students.length})</Radio.Button>
            <Radio.Button value="AT_RISK">
              Cần lưu ý {atRiskCount > 0 && <span style={{ color: '#EF4444' }}>({atRiskCount})</span>}
            </Radio.Button>
            <Radio.Button value="HAS_ABSENCE">Có vắng học</Radio.Button>
            <Radio.Button value="HAS_LATE">Có đi muộn</Radio.Button>
          </Radio.Group>
        </Space>

        <Text type="secondary">
          Hiển thị: <strong>{filteredStudents.length} học sinh</strong>
        </Text>
      </div>

      {students.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Chưa có dữ liệu học sinh trong lớp này"
          style={{ padding: '32px 0' }}
        />
      ) : (
        <Table
          columns={columns}
          dataSource={filteredStudents}
          rowKey="studentId"
          pagination={{ pageSize: 15, showSizeChanger: false }}
          scroll={{ x: 900 }}
        />
      )}
    </Card>
  );
};
