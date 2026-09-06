import React from 'react';
import { Row, Col, Card, Statistic, Progress, Typography, Space } from 'antd';
import {
  TeamOutlined,
  CalendarOutlined,
  CheckCircleOutlined,
  UserDeleteOutlined,
  ClockCircleOutlined,
} from '@ant-design/icons';
import type { AttendanceClassHistoryDTO } from '../../types/attendance';

const { Text } = Typography;

interface AttendanceOverviewCardsProps {
  history: AttendanceClassHistoryDTO;
}

export const AttendanceOverviewCards: React.FC<AttendanceOverviewCardsProps> = ({ history }) => {
  const totalAbsences = history.excusedCount + history.unexcusedCount;
  const hasSessions = history.totalSessions > 0;

  let rateStrokeColor = '#10B981'; // Green
  if (!hasSessions) {
    rateStrokeColor = '#CBD5E1'; // Neutral gray when no sessions
  } else if (history.attendanceRate < 75) {
    rateStrokeColor = '#EF4444'; // Red
  } else if (history.attendanceRate < 88) {
    rateStrokeColor = '#F59E0B'; // Orange
  }

  return (
    <Row gutter={[16, 16]}>
      {/* Card 1: Sĩ số & Số buổi học */}
      <Col xs={24} sm={12} lg={6}>
        <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
          <Space direction="vertical" size={4} style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                Tổng quan lớp học
              </Text>
              <TeamOutlined style={{ color: '#2563EB', fontSize: 18 }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <Statistic
                value={history.totalStudents}
                suffix={<span style={{ fontSize: 14, color: '#64748B' }}>học sinh</span>}
                valueStyle={{ fontWeight: 'bold', fontSize: 24, color: '#0F172A' }}
              />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
              <CalendarOutlined style={{ color: '#64748B', fontSize: 13 }} />
              <Text type="secondary" style={{ fontSize: 12 }}>
                Đã điểm danh: <strong style={{ color: '#0F172A' }}>{history.totalSessions} buổi</strong>
              </Text>
            </div>
          </Space>
        </Card>
      </Col>

      {/* Card 2: Tỷ lệ chuyên cần chung */}
      <Col xs={24} sm={12} lg={6}>
        <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
          <Space direction="vertical" size={4} style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                Tỷ lệ chuyên cần chung
              </Text>
              <CheckCircleOutlined style={{ color: rateStrokeColor, fontSize: 18 }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 }}>
              {hasSessions ? (
                <Statistic
                  value={history.attendanceRate}
                  suffix="%"
                  precision={1}
                  valueStyle={{ fontWeight: 'bold', fontSize: 24, color: '#0F172A' }}
                />
              ) : (
                <div style={{ fontWeight: 'bold', fontSize: 24, color: '#94A3B8', lineHeight: '32px' }}>
                  —
                </div>
              )}
              <Progress
                type="circle"
                percent={hasSessions ? history.attendanceRate : 0}
                size={44}
                strokeColor={rateStrokeColor}
                showInfo={false}
              />
            </div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {hasSessions ? (
                <>Có mặt: <strong>{history.presentCount} lượt</strong></>
              ) : (
                'Chưa có buổi điểm danh'
              )}
            </Text>
          </Space>
        </Card>
      </Col>

      {/* Card 3: Tổng lượt vắng */}
      <Col xs={24} sm={12} lg={6}>
        <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
          <Space direction="vertical" size={4} style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                Tổng lượt vắng học
              </Text>
              <UserDeleteOutlined style={{ color: totalAbsences > 0 ? '#EF4444' : '#64748B', fontSize: 18 }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <Statistic
                value={totalAbsences}
                suffix={<span style={{ fontSize: 14, color: '#64748B' }}>lượt</span>}
                valueStyle={{
                  fontWeight: 'bold',
                  fontSize: 24,
                  color: history.unexcusedCount > 0 ? '#EF4444' : '#0F172A',
                }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginTop: 4 }}>
              <span style={{ color: '#2563EB' }}>Có phép: {history.excusedCount}</span>
              <span style={{ color: history.unexcusedCount > 0 ? '#EF4444' : '#64748B' }}>
                Không phép: {history.unexcusedCount}
              </span>
            </div>
          </Space>
        </Card>
      </Col>

      {/* Card 4: Đi muộn */}
      <Col xs={24} sm={12} lg={6}>
        <Card bordered={false} style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
          <Space direction="vertical" size={4} style={{ width: '100%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                Tổng lượt đi muộn
              </Text>
              <ClockCircleOutlined style={{ color: history.lateCount > 0 ? '#F59E0B' : '#64748B', fontSize: 18 }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <Statistic
                value={history.lateCount}
                suffix={<span style={{ fontSize: 14, color: '#64748B' }}>lượt</span>}
                valueStyle={{
                  fontWeight: 'bold',
                  fontSize: 24,
                  color: history.lateCount > 0 ? '#F59E0B' : '#0F172A',
                }}
              />
            </div>
            <Text type="secondary" style={{ fontSize: 12, marginTop: 4 }}>
              {history.lateCount === 0 ? 'Không có học sinh đi muộn' : 'Cần nhắc nhở đúng giờ'}
            </Text>
          </Space>
        </Card>
      </Col>
    </Row>
  );
};
