import React, { useState, useMemo } from 'react';
import {
  Typography,
  Select,
  DatePicker,
  Button,
  Space,
  Card,
  Tag,
  Drawer,
  Descriptions,
  Spin,
  Alert,
  Empty,
  Tooltip,
  theme,
} from 'antd';
import {
  CalendarOutlined,
  RedoOutlined,
  ClockCircleOutlined,
  UserOutlined,
  EnvironmentOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import weekOfYear from 'dayjs/plugin/weekOfYear';
import { useQuery } from '@tanstack/react-query';
import { classApi } from '../../api/classApi';
import { scheduleApi } from '../../api/scheduleApi';
import type { ScheduleDayDTO, SchedulePeriodDTO, DayOfWeekVN } from '../../types/schedule';

dayjs.extend(weekOfYear);

const { Title, Text } = Typography;

const DAYS_OF_WEEK: { key: DayOfWeekVN; label: string; shortLabel: string }[] = [
  { key: 'MONDAY', label: 'Thứ Hai', shortLabel: 'T2' },
  { key: 'TUESDAY', label: 'Thứ Ba', shortLabel: 'T3' },
  { key: 'WEDNESDAY', label: 'Thứ Tư', shortLabel: 'T4' },
  { key: 'THURSDAY', label: 'Thứ Năm', shortLabel: 'T5' },
  { key: 'FRIDAY', label: 'Thứ Sáu', shortLabel: 'T6' },
  { key: 'SATURDAY', label: 'Thứ Bảy', shortLabel: 'T7' },
];

const STANDARD_SLOTS = [
  { slot: 1, label: 'Tiết 1', defaultTime: '07:15 - 08:00', session: 'morning' },
  { slot: 2, label: 'Tiết 2', defaultTime: '08:05 - 08:50', session: 'morning' },
  { slot: 3, label: 'Tiết 3', defaultTime: '09:05 - 09:50', session: 'morning' },
  { slot: 4, label: 'Tiết 4', defaultTime: '09:55 - 10:40', session: 'morning' },
  { slot: 5, label: 'Tiết 5', defaultTime: '10:45 - 11:30', session: 'morning' },
  { slot: 6, label: 'Tiết 6', defaultTime: '13:00 - 13:45', session: 'afternoon' },
  { slot: 7, label: 'Tiết 7', defaultTime: '13:50 - 14:35', session: 'afternoon' },
  { slot: 8, label: 'Tiết 8', defaultTime: '14:50 - 15:35', session: 'afternoon' },
  { slot: 9, label: 'Tiết 9', defaultTime: '15:40 - 16:25', session: 'afternoon' },
  { slot: 10, label: 'Tiết 10', defaultTime: '16:30 - 17:15', session: 'afternoon' },
];

// Subject color generator
const SUBJECT_COLORS: Record<string, { bg: string; border: string; text: string }> = {
  TOAN: { bg: '#EFF6FF', border: '#BFDBFE', text: '#1D4ED8' },
  VAN: { bg: '#FFF1F2', border: '#FECDD3', text: '#BE123C' },
  ANH: { bg: '#F0FDF4', border: '#BBF7D0', text: '#15803D' },
  LY: { bg: '#FAF5FF', border: '#E9D5FF', text: '#7E22CE' },
  HOA: { bg: '#FFFBEB', border: '#FDE68A', text: '#B45309' },
  SINH: { bg: '#ECFDF5', border: '#A7F3D0', text: '#047857' },
  SU: { bg: '#FFF7ED', border: '#FED7AA', text: '#C2410C' },
  DIA: { bg: '#F5F3FF', border: '#DDD6FE', text: '#6D28D9' },
  GDCD: { bg: '#ECFEFF', border: '#A5F3FC', text: '#0E7490' },
  TIN: { bg: '#F8FAFC', border: '#CBD5E1', text: '#334155' },
};

const getSubjectStyle = (name: string) => {
  const upper = (name || '').toUpperCase();
  for (const [key, val] of Object.entries(SUBJECT_COLORS)) {
    if (upper.includes(key)) return val;
  }
  return { bg: '#F1F5F9', border: '#E2E8F0', text: '#2563EB' };
};

export const SchedulePage: React.FC = () => {
  const { token } = theme.useToken();

  const [selectedClassId, setSelectedClassId] = useState<number | undefined>(undefined);
  const [selectedWeek, setSelectedWeek] = useState<dayjs.Dayjs>(dayjs());
  const [selectedPeriod, setSelectedPeriod] = useState<SchedulePeriodDTO | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);

  // 1. Fetch Classes
  const {
    data: classes = [],
    isLoading: isLoadingClasses,
    error: classesError,
  } = useQuery({
    queryKey: ['schoolClasses'],
    queryFn: () => classApi.getAllClasses(),
  });

  React.useEffect(() => {
    if (classes && classes.length > 0 && selectedClassId === undefined) {
      setSelectedClassId(classes[0].id);
    }
  }, [classes, selectedClassId]);

  // 2. Fetch Schedule for Class
  const {
    data: scheduleDays = [],
    isLoading: isLoadingSchedule,
    error: scheduleError,
    refetch: refetchSchedule,
    isRefetching: isRefetchingSchedule,
  } = useQuery<ScheduleDayDTO[]>({
    queryKey: ['classSchedule', selectedClassId],
    queryFn: () => scheduleApi.getByClass(selectedClassId!),
    enabled: selectedClassId !== undefined && selectedClassId > 0,
  });

  // Map schedule data to a lookup grid: [dayOfWeek][slotNumber] -> SchedulePeriodDTO
  const periodGrid = useMemo(() => {
    const map = new Map<string, SchedulePeriodDTO>();
    scheduleDays.forEach((d) => {
      (d.periods || []).forEach((p) => {
        const key = `${d.dayOfWeek}_${p.slotNumber}`;
        map.set(key, p);
      });
    });
    return map;
  }, [scheduleDays]);

  // Calculate actual slots present in schedule (or default to morning slots 1-5)
  const maxSlot = useMemo(() => {
    let max = 5;
    scheduleDays.forEach((d) => {
      (d.periods || []).forEach((p) => {
        if (p.slotNumber > max) max = p.slotNumber;
      });
    });
    return max;
  }, [scheduleDays]);

  const activeSlots = useMemo(() => {
    return STANDARD_SLOTS.filter((s) => s.slot <= Math.max(maxSlot, 5));
  }, [maxSlot]);

  // Total periods in week
  const totalPeriods = useMemo(() => {
    return scheduleDays.reduce((acc, d) => acc + (d.periods?.length || 0), 0);
  }, [scheduleDays]);

  const handlePeriodClick = (period: SchedulePeriodDTO) => {
    setSelectedPeriod(period);
    setIsDrawerOpen(true);
  };

  const selectedClassName = classes.find((c) => c.id === selectedClassId)?.className || '';

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
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Title level={4} style={{ margin: 0, color: '#0F172A' }}>
                Thời khóa biểu Lớp học
              </Title>
              <Tooltip title="Backend hiện tại hỗ trợ API GET /api/schedules/class/{id}. Chức năng chỉnh sửa hoặc thêm tiết học cần API cập nhật từ Backend.">
                <Tag color="cyan" icon={<InfoCircleOutlined />}>
                  Xem thời khóa biểu
                </Tag>
              </Tooltip>
            </div>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Lịch học tuần theo từng tiết, môn học, giáo viên phụ trách và phòng học
            </Text>
          </div>

          <Space wrap size={12}>
            {/* Class Selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Text strong style={{ fontSize: 13 }}>Lớp:</Text>
              <Select
                loading={isLoadingClasses}
                value={selectedClassId}
                onChange={(val) => setSelectedClassId(val)}
                placeholder="Chọn lớp"
                style={{ width: 160 }}
                options={classes.map((c) => ({
                  value: c.id,
                  label: `Lớp ${c.className}`,
                }))}
              />
            </div>

            {/* Week Selector */}
            <DatePicker
              picker="week"
              value={selectedWeek}
              onChange={(val) => val && setSelectedWeek(val)}
              format="Tuần w, YYYY"
              style={{ width: 160 }}
            />

            <Button
              icon={<RedoOutlined spin={isRefetchingSchedule} />}
              onClick={() => refetchSchedule()}
            >
              Làm mới
            </Button>
          </Space>
        </div>
      </div>

      {/* Main Grid Calendar View */}
      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
        {/* Info summary */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 16,
            paddingBottom: 12,
            borderBottom: '1px solid #F1F5F9',
          }}
        >
          <div>
            <Text strong style={{ fontSize: 15 }}>
              Lớp {selectedClassName || '—'}
            </Text>
            <Text type="secondary" style={{ marginLeft: 12, fontSize: 13 }}>
              Tổng số tiết học trong tuần: <strong style={{ color: '#2563EB' }}>{totalPeriods} tiết</strong>
            </Text>
          </div>

          <Text type="secondary" style={{ fontSize: 12 }}>
            Nhấp vào từng tiết để xem thông tin chi tiết
          </Text>
        </div>

        {/* States */}
        {isLoadingClasses || isLoadingSchedule ? (
          <div style={{ textAlign: 'center', padding: '80px 0' }}>
            <Spin size="large" tip="Đang tải thời khóa biểu..." />
          </div>
        ) : classesError || scheduleError ? (
          <Alert
            type="error"
            message="Lỗi tải thời khóa biểu"
            description="Không thể kết nối đến máy chủ để lấy lịch học của lớp."
            showIcon
          />
        ) : totalPeriods === 0 ? (
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description="Chưa có dữ liệu thời khóa biểu cho lớp học này"
            style={{ padding: '60px 0' }}
          >
            <Tag color="warning" icon={<InfoCircleOutlined />}>
              Tạo mới / Nhập TKB: NEEDS BACKEND API (Backend chỉ có endpoint GET)
            </Tag>
          </Empty>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table
              style={{
                width: '100%',
                borderCollapse: 'collapse',
                minWidth: 800,
                tableLayout: 'fixed',
              }}
            >
              <thead>
                <tr style={{ background: '#F8FAFC', borderBottom: '2px solid #E2E8F0' }}>
                  <th
                    style={{
                      width: 100,
                      padding: '12px 8px',
                      textAlign: 'center',
                      fontSize: 13,
                      fontWeight: 600,
                      color: '#475569',
                      borderRight: '1px solid #E2E8F0',
                    }}
                  >
                    Tiết học
                  </th>
                  {DAYS_OF_WEEK.map((d) => (
                    <th
                      key={d.key}
                      style={{
                        padding: '12px 8px',
                        textAlign: 'center',
                        fontSize: 13,
                        fontWeight: 600,
                        color: '#0F172A',
                        borderRight: '1px solid #E2E8F0',
                      }}
                    >
                      <div>{d.label}</div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {activeSlots.map((slotInfo, index) => {
                  const isAfternoonStart = slotInfo.slot === 6;

                  return (
                    <React.Fragment key={slotInfo.slot}>
                      {isAfternoonStart && (
                        <tr style={{ background: '#F1F5F9' }}>
                          <td
                            colSpan={7}
                            style={{
                              padding: '6px 12px',
                              textAlign: 'center',
                              fontSize: 12,
                              fontWeight: 600,
                              color: '#64748B',
                              borderBottom: '1px solid #E2E8F0',
                            }}
                          >
                            — Buổi Chiều —
                          </td>
                        </tr>
                      )}
                      <tr
                        style={{
                          borderBottom: '1px solid #E2E8F0',
                          backgroundColor: index % 2 === 0 ? '#fff' : '#FAFAFA',
                        }}
                      >
                        {/* Slot Info Cell */}
                        <td
                          style={{
                            padding: '10px 8px',
                            textAlign: 'center',
                            borderRight: '1px solid #E2E8F0',
                            verticalAlign: 'middle',
                          }}
                        >
                          <div style={{ fontWeight: 600, fontSize: 13, color: '#0F172A' }}>
                            {slotInfo.label}
                          </div>
                          <div style={{ fontSize: 11, color: '#64748B', marginTop: 2 }}>
                            {slotInfo.defaultTime}
                          </div>
                        </td>

                        {/* 6 Day Columns */}
                        {DAYS_OF_WEEK.map((day) => {
                          const period = periodGrid.get(`${day.key}_${slotInfo.slot}`);
                          if (!period) {
                            return (
                              <td
                                key={day.key}
                                style={{
                                  padding: '8px',
                                  borderRight: '1px solid #E2E8F0',
                                  verticalAlign: 'top',
                                }}
                              >
                                <div
                                  style={{
                                    height: '100%',
                                    minHeight: 68,
                                    borderRadius: 8,
                                    border: '1px dashed #E2E8F0',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    color: '#CBD5E1',
                                    fontSize: 12,
                                  }}
                                >
                                  —
                                </div>
                              </td>
                            );
                          }

                          const style = getSubjectStyle(period.subjectName);

                          return (
                            <td
                              key={day.key}
                              style={{
                                padding: '6px',
                                borderRight: '1px solid #E2E8F0',
                                verticalAlign: 'top',
                              }}
                            >
                              <div
                                onClick={() => handlePeriodClick(period)}
                                style={{
                                  background: style.bg,
                                  border: `1px solid ${style.border}`,
                                  borderRadius: 8,
                                  padding: '8px 10px',
                                  cursor: 'pointer',
                                  transition: 'all 0.2s',
                                  boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
                                  minHeight: 68,
                                  display: 'flex',
                                  flexDirection: 'column',
                                  justifyContent: 'space-between',
                                }}
                                onMouseEnter={(e) => {
                                  e.currentTarget.style.transform = 'translateY(-1px)';
                                  e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0,0,0,0.06)';
                                }}
                                onMouseLeave={(e) => {
                                  e.currentTarget.style.transform = 'translateY(0)';
                                  e.currentTarget.style.boxShadow = '0 1px 2px rgba(0,0,0,0.02)';
                                }}
                              >
                                <div>
                                  <Text strong style={{ color: style.text, fontSize: 13, display: 'block' }}>
                                    {period.subjectName}
                                  </Text>
                                  {period.teacherName && (
                                    <div style={{ fontSize: 11, color: '#475569', marginTop: 2, display: 'flex', alignItems: 'center', gap: 4 }}>
                                      <UserOutlined style={{ fontSize: 10 }} />
                                      <span>{period.teacherName}</span>
                                    </div>
                                  )}
                                </div>

                                <div
                                  style={{
                                    display: 'flex',
                                    justifyContent: 'space-between',
                                    alignItems: 'center',
                                    marginTop: 6,
                                    fontSize: 10,
                                    color: '#64748B',
                                  }}
                                >
                                  {period.roomName ? (
                                    <span style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                      <EnvironmentOutlined />
                                      {period.roomName}
                                    </span>
                                  ) : (
                                    <span />
                                  )}
                                  {period.startTime && period.endTime && (
                                    <span>{period.startTime} - {period.endTime}</span>
                                  )}
                                </div>
                              </div>
                            </td>
                          );
                        })}
                      </tr>
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Drawer: Period Details */}
      <Drawer
        title={
          <Space>
            <CalendarOutlined style={{ color: '#2563EB' }} />
            <span>Thông tin tiết học: {selectedPeriod?.subjectName}</span>
          </Space>
        }
        width={480}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
      >
        {selectedPeriod && (
          <Space direction="vertical" size={16} style={{ width: '100%' }}>
            <Descriptions bordered size="small" column={1}>
              <Descriptions.Item label="Môn học">
                <Text strong style={{ fontSize: 15, color: '#2563EB' }}>
                  {selectedPeriod.subjectName}
                </Text>
              </Descriptions.Item>
              <Descriptions.Item label="Lớp học">
                {selectedPeriod.className || `Lớp ${selectedClassName}`}
              </Descriptions.Item>
              <Descriptions.Item label="Tiết số">
                Tiết {selectedPeriod.slotNumber}
              </Descriptions.Item>
              <Descriptions.Item label="Khung giờ">
                <Space size={4}>
                  <ClockCircleOutlined style={{ color: '#64748B' }} />
                  <span>{selectedPeriod.startTime} - {selectedPeriod.endTime}</span>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Giáo viên phụ trách">
                {selectedPeriod.teacherName || <Text type="secondary">Chưa phân công</Text>}
              </Descriptions.Item>
              <Descriptions.Item label="Phòng học">
                {selectedPeriod.roomName ? (
                  <Tag color="blue" icon={<EnvironmentOutlined />}>
                    {selectedPeriod.roomName}
                  </Tag>
                ) : (
                  <Text type="secondary">Chưa xếp phòng</Text>
                )}
              </Descriptions.Item>
            </Descriptions>

            <Alert
              type="info"
              showIcon
              message="Chỉnh sửa phân công / tiết học"
              description="Để thay đổi giáo viên hoặc phòng học cho tiết này, cần API cập nhật từ Backend (NEEDS BACKEND API)."
            />
          </Space>
        )}
      </Drawer>
    </div>
  );
};
