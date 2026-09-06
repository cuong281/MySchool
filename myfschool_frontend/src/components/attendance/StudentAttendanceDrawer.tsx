import React from 'react';
import { Drawer, Descriptions, Tag, Table, Progress, Typography, Card, Row, Col, Empty, Space } from 'antd';
import { UserOutlined, WarningOutlined, CalendarOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import type { AttendanceRecordDTO, AttendanceStudentSummaryDTO } from '../../types/attendance';
import { StatusTag } from '../common/StatusTag';

const { Text, Title } = Typography;

interface StudentAttendanceDrawerProps {
  open: boolean;
  onClose: () => void;
  student: AttendanceStudentSummaryDTO | null;
}

export const StudentAttendanceDrawer: React.FC<StudentAttendanceDrawerProps> = ({
  open,
  onClose,
  student,
}) => {
  if (!student) return null;

  const isCritical = student.unexcusedCount >= 3 || student.attendanceRate < 70;
  const isWarning = student.unexcusedCount >= 1 || student.lateCount >= 3 || student.attendanceRate < 85;

  let rateColor = '#10B981';
  if (student.attendanceRate < 70) rateColor = '#EF4444';
  else if (student.attendanceRate < 85) rateColor = '#F59E0B';

  const columns = [
    {
      title: 'Ngày học',
      dataIndex: 'attendanceDate',
      key: 'attendanceDate',
      width: 120,
      render: (date: string) => dayjs(date).format('DD/MM/YYYY'),
      sorter: (a: AttendanceRecordDTO, b: AttendanceRecordDTO) =>
        dayjs(a.attendanceDate).unix() - dayjs(b.attendanceDate).unix(),
      defaultSortOrder: 'descend' as const,
    },
    {
      title: 'Tiết',
      dataIndex: 'slotNumber',
      key: 'slotNumber',
      width: 80,
      render: (slot?: number) => (slot ? `Tiết ${slot}` : '--'),
    },
    {
      title: 'Môn học',
      dataIndex: 'subjectName',
      key: 'subjectName',
      render: (name?: string) => name || 'Buổi học',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 130,
      render: (status: string) => <StatusTag status={status} />,
    },
    {
      title: 'Ghi chú',
      dataIndex: 'note',
      key: 'note',
      render: (note?: string) =>
        note ? <Text type="secondary" italic>{note}</Text> : <Text type="secondary">--</Text>,
    },
    {
      title: 'Người ghi',
      dataIndex: 'recordedByName',
      key: 'recordedByName',
      width: 130,
      render: (name?: string) => name || '--',
    },
  ];

  return (
    <Drawer
      open={open}
      onClose={onClose}
      width={720}
      title={
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <UserOutlined style={{ color: '#2563EB', fontSize: 18 }} />
          <Title level={5} style={{ margin: 0 }}>
            Hồ sơ chuyên cần: {student.studentName}
          </Title>
        </div>
      }
    >
      {/* Student Info & Warning */}
      <div style={{ marginBottom: 20 }}>
        <Descriptions bordered size="small" column={{ xs: 1, sm: 2 }}>
          <Descriptions.Item label="Mã học sinh">
            <Text code strong>{student.studentCode}</Text>
          </Descriptions.Item>
          <Descriptions.Item label="Họ và tên">
            <Text strong>{student.studentName}</Text>
          </Descriptions.Item>
          <Descriptions.Item label="Tình trạng">
            {isCritical ? (
              <Tag color="error" icon={<WarningOutlined />}>
                Nguy cơ cấm thi ({student.unexcusedCount} buổi không phép)
              </Tag>
            ) : isWarning ? (
              <Tag color="warning" icon={<WarningOutlined />}>
                Cảnh báo chuyên cần
              </Tag>
            ) : (
              <Tag color="success">Chuyên cần tốt</Tag>
            )}
          </Descriptions.Item>
          <Descriptions.Item label="Tỷ lệ chuyên cần">
            <Space>
              <Progress percent={student.attendanceRate} size="small" strokeColor={rateColor} />
              <Text strong>{student.attendanceRate.toFixed(1)}%</Text>
            </Space>
          </Descriptions.Item>
        </Descriptions>
      </div>

      {/* 4 Stats Boxes */}
      <Row gutter={[12, 12]} style={{ marginBottom: 24 }}>
        <Col span={6}>
          <Card size="small" style={{ textAlign: 'center', background: '#F8FAFC' }}>
            <Text type="secondary" style={{ fontSize: 11 }}>Có mặt</Text>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#10B981' }}>
              {student.presentCount}
            </div>
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ textAlign: 'center', background: '#F8FAFC' }}>
            <Text type="secondary" style={{ fontSize: 11 }}>Có phép</Text>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#2563EB' }}>
              {student.excusedCount}
            </div>
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ textAlign: 'center', background: '#F8FAFC' }}>
            <Text type="secondary" style={{ fontSize: 11 }}>Không phép</Text>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#EF4444' }}>
              {student.unexcusedCount}
            </div>
          </Card>
        </Col>
        <Col span={6}>
          <Card size="small" style={{ textAlign: 'center', background: '#F8FAFC' }}>
            <Text type="secondary" style={{ fontSize: 11 }}>Đi muộn</Text>
            <div style={{ fontSize: 20, fontWeight: 'bold', color: '#F59E0B' }}>
              {student.lateCount}
            </div>
          </Card>
        </Col>
      </Row>

      <Title level={5} style={{ marginBottom: 12 }}>
        <CalendarOutlined style={{ marginRight: 8, color: '#2563EB' }} />
        Lịch sử điểm danh từng buổi
      </Title>

      {!student.records || student.records.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Chưa có dữ liệu điểm danh chi tiết cho học sinh này"
        />
      ) : (
        <Table
          columns={columns}
          dataSource={student.records}
          rowKey="id"
          pagination={{ pageSize: 8, showSizeChanger: false }}
          size="small"
        />
      )}
    </Drawer>
  );
};
