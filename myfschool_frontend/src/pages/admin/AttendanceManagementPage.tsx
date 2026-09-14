import React, { useState, useEffect } from 'react';
import {
  Typography,
  Select,
  DatePicker,
  Space,
  Tabs,
  Spin,
  Alert,
  Empty,
  Button,
  theme,
} from 'antd';
import {
  CalendarOutlined,
  RedoOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { classApi } from '../../api/classApi';
import { attendanceApi } from '../../api/attendanceApi';
import type { AttendanceClassHistoryDTO, AttendanceStudentSummaryDTO } from '../../types/attendance';
import { AttendanceOverviewCards } from '../../components/attendance/AttendanceOverviewCards';
import { SessionHistoryTable } from '../../components/attendance/SessionHistoryTable';
import { StudentRosterTable } from '../../components/attendance/StudentRosterTable';
import { AttendanceSheetModal } from '../../components/attendance/AttendanceSheetModal';
import { StudentAttendanceDrawer } from '../../components/attendance/StudentAttendanceDrawer';
import { UnrecordedAttendanceSection } from '../../components/attendance/UnrecordedAttendanceSection';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

export const AttendanceManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const [selectedClassId, setSelectedClassId] = useState<number | undefined>(undefined);
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs | null, dayjs.Dayjs | null] | null>(null);

  const queryClient = useQueryClient();

  // Sheet Modal State
  const [sheetModalConfig, setSheetModalConfig] = useState<{
    open: boolean;
    classId?: number;
    slotNumber: number;
    subjectId?: number;
    date: string;
  }>({
    open: false,
    slotNumber: 1,
    date: dayjs().format('YYYY-MM-DD'),
  });

  // Student Detail Drawer State
  const [selectedStudent, setSelectedStudent] = useState<AttendanceStudentSummaryDTO | null>(null);
  const [isStudentDrawerOpen, setIsStudentDrawerOpen] = useState(false);

  // 1. Fetch Class List
  const {
    data: classes = [],
    isLoading: isLoadingClasses,
    error: classesError,
  } = useQuery({
    queryKey: ['schoolClasses'],
    queryFn: () => classApi.getAllClasses(),
  });

  // Automatically select the first class only when the class list is not empty
  useEffect(() => {
    if (classes && classes.length > 0 && selectedClassId === undefined) {
      setSelectedClassId(classes[0].id);
    }
  }, [classes, selectedClassId]);

  // Formatted date parameters (YYYY-MM-DD)
  const startDateStr = dateRange && dateRange[0] ? dateRange[0].format('YYYY-MM-DD') : undefined;
  const endDateStr = dateRange && dateRange[1] ? dateRange[1].format('YYYY-MM-DD') : undefined;

  // 2. Fetch Class Attendance History
  const {
    data: history,
    isLoading: isLoadingHistory,
    error: historyError,
    refetch: refetchHistory,
  } = useQuery<AttendanceClassHistoryDTO>({
    queryKey: ['classAttendanceHistory', selectedClassId, startDateStr, endDateStr],
    queryFn: () => attendanceApi.getClassAttendanceHistory(selectedClassId!, startDateStr, endDateStr),
    enabled: selectedClassId !== undefined && selectedClassId > 0,
  });

  const handleOpenSheet = (
    slotNumber: number,
    subjectId?: number,
    date?: string,
    classId?: number
  ) => {
    if (classId) {
      setSelectedClassId(classId);
    }
    setSheetModalConfig({
      open: true,
      classId: classId || selectedClassId,
      slotNumber,
      subjectId,
      date: date || dayjs().format('YYYY-MM-DD'),
    });
  };

  const handleCloseSheet = () => {
    setSheetModalConfig((prev) => ({ ...prev, open: false }));
  };

  const handleViewStudentDetail = (student: AttendanceStudentSummaryDTO) => {
    setSelectedStudent(student);
    setIsStudentDrawerOpen(true);
  };

  const handleResetFilters = () => {
    setDateRange(null);
  };

  return (
    <div style={{ maxWidth: 1400, margin: '0 auto' }}>
      {/* Top Header & Filter Bar */}
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
              Quản lý Điểm danh Lớp học
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Theo dõi lịch sử chuyên cần theo buổi học và danh sách học sinh
            </Text>
          </div>

          <Space wrap size={12}>
            {/* Class Selector Dropdown */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Text strong style={{ fontSize: 13 }}>
                Chọn lớp:
              </Text>
              <Select
                loading={isLoadingClasses}
                value={selectedClassId}
                onChange={(val) => setSelectedClassId(val)}
                placeholder="Chọn lớp học"
                style={{ width: 170 }}
                options={classes.map((c) => ({
                  value: c.id,
                  label: `Lớp ${c.className}`,
                }))}
              />
            </div>

            {/* Date Range Picker */}
            <RangePicker
              value={dateRange}
              onChange={(dates) => setDateRange(dates)}
              format="DD/MM/YYYY"
              placeholder={['Từ ngày', 'Đến ngày']}
              style={{ width: 250 }}
            />

            {dateRange && (
              <Button onClick={handleResetFilters} icon={<RedoOutlined />}>
                Đặt lại ngày
              </Button>
            )}

            <Button
              type="text"
              icon={<RedoOutlined />}
              onClick={() => refetchHistory()}
              title="Tải lại dữ liệu"
            />
          </Space>
        </div>
      </div>

      {/* Unrecorded Sessions Today Section (School-wide Alert for Admin) */}
      <UnrecordedAttendanceSection
        onOpenSheet={(classId, slotNumber, subjectId, date) =>
          handleOpenSheet(slotNumber, subjectId, date, classId)
        }
      />

      {/* Main Content Area */}
      {isLoadingClasses ? (
        <div style={{ textAlign: 'center', padding: '80px 0' }}>
          <Spin size="large" tip="Đang tải danh sách lớp học..." />
        </div>
      ) : classesError ? (
        <Alert
          type="error"
          message="Lỗi kết nối máy chủ"
          description="Không thể tải danh sách lớp học từ Backend. Vui lòng kiểm tra API."
          showIcon
        />
      ) : classes.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Chưa có dữ liệu lớp học nào trong hệ thống"
        />
      ) : isLoadingHistory ? (
        <div style={{ textAlign: 'center', padding: '80px 0' }}>
          <Spin size="large" tip="Đang tải dữ liệu điểm danh..." />
        </div>
      ) : historyError ? (
        <Alert
          type="error"
          message="Không thể tải dữ liệu điểm danh"
          description={(historyError as any)?.message || 'Vui lòng kiểm tra lại quyền truy cập hoặc kết nối.'}
          showIcon
        />
      ) : history ? (
        <Space direction="vertical" size={20} style={{ width: '100%' }}>
          {/* Overview Metric Cards */}
          <AttendanceOverviewCards history={history} />

          {/* 2 Main Perspectives: [ Theo buổi học | Theo học sinh ] */}
          <Tabs
            defaultActiveKey="sessions"
            type="card"
            size="middle"
            items={[
              {
                key: 'sessions',
                label: (
                  <Space size={6}>
                    <CalendarOutlined />
                    <span>Theo buổi học ({history.sessions?.length || 0})</span>
                  </Space>
                ),
                children: (
                  <SessionHistoryTable
                    sessions={history.sessions || []}
                    onOpenSheet={handleOpenSheet}
                  />
                ),
              },
              {
                key: 'students',
                label: (
                  <Space size={6}>
                    <TeamOutlined />
                    <span>Theo học sinh ({history.studentSummaries?.length || 0})</span>
                  </Space>
                ),
                children: (
                  <StudentRosterTable
                    students={history.studentSummaries || []}
                    onViewDetail={handleViewStudentDetail}
                  />
                ),
              },
            ]}
          />
        </Space>
      ) : null}

      {/* Attendance Sheet Modal */}
      {(sheetModalConfig.classId || selectedClassId) && (
        <AttendanceSheetModal
          open={sheetModalConfig.open}
          onClose={handleCloseSheet}
          classId={sheetModalConfig.classId || selectedClassId!}
          slotNumber={sheetModalConfig.slotNumber}
          subjectId={sheetModalConfig.subjectId}
          date={sheetModalConfig.date}
          onSaved={() => {
            refetchHistory();
            queryClient.invalidateQueries({ queryKey: ['unrecordedAttendanceToday'] });
          }}
        />
      )}

      {/* Student Attendance Detail Drawer */}
      <StudentAttendanceDrawer
        open={isStudentDrawerOpen}
        onClose={() => setIsStudentDrawerOpen(false)}
        student={selectedStudent}
      />
    </div>
  );
};
