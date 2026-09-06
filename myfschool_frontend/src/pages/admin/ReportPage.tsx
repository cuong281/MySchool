import React, { useState, useMemo } from 'react';
import {
  Typography,
  Select,
  Row,
  Col,
  Card,
  Statistic,
  Progress,
  Table,
  Tag,
  Space,
  Button,
  Alert,
  Spin,
  Empty,
  theme,
} from 'antd';
import {
  TeamOutlined,
  BookOutlined,
  CheckCircleOutlined,
  RedoOutlined,
  TrophyOutlined,
  WarningOutlined,
  InfoCircleOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { reportApi } from '../../api/reportApi';
import { classApi } from '../../api/classApi';
import { attendanceApi } from '../../api/attendanceApi';
import type { AdminDashboardDTO } from '../../types/report';
import type { AttendanceStudentSummaryDTO } from '../../types/attendance';

const { Title, Text } = Typography;

export const ReportPage: React.FC = () => {
  const { token } = theme.useToken();

  const [academicYear, setAcademicYear] = useState<string>('2025-2026');
  const [semester, setSemester] = useState<number | undefined>(1);
  const [watchlistClassId, setWatchlistClassId] = useState<number | undefined>(undefined);

  // 1. Fetch Admin Dashboard Stats
  const {
    data: dashboard,
    isLoading: isLoadingDashboard,
    error: dashboardError,
    refetch: refetchDashboard,
    isRefetching: isRefetchingDashboard,
  } = useQuery<AdminDashboardDTO>({
    queryKey: ['adminDashboard', academicYear, semester],
    queryFn: () => reportApi.getAdminDashboard(academicYear, semester),
  });

  // 2. Fetch Classes for Watchlist Selector
  const { data: classes = [] } = useQuery({
    queryKey: ['schoolClasses'],
    queryFn: () => classApi.getAllClasses(),
  });

  React.useEffect(() => {
    if (classes && classes.length > 0 && watchlistClassId === undefined) {
      setWatchlistClassId(classes[0].id);
    }
  }, [classes, watchlistClassId]);

  // 3. Fetch Class Attendance for Watchlist
  const {
    data: classHistory,
    isLoading: isLoadingClassHistory,
  } = useQuery({
    queryKey: ['classAttendanceForWatchlist', watchlistClassId],
    queryFn: () => attendanceApi.getClassAttendanceHistory(watchlistClassId!),
    enabled: watchlistClassId !== undefined && watchlistClassId > 0,
  });

  // Filter at-risk students in selected class
  const atRiskStudents: AttendanceStudentSummaryDTO[] = useMemo(() => {
    if (!classHistory || !classHistory.studentSummaries) return [];
    return classHistory.studentSummaries.filter(
      (s) => s.unexcusedCount >= 3 || (s.totalTrackedSessions > 0 && s.attendanceRate < 75)
    );
  }, [classHistory]);

  // Grade Distribution Calculation
  const gradeDistributionData = useMemo(() => {
    if (!dashboard || !dashboard.gradeDistribution) return [];
    const total = Object.values(dashboard.gradeDistribution).reduce((a, b) => a + b, 0);
    return Object.entries(dashboard.gradeDistribution).map(([grade, count]) => ({
      grade,
      count,
      percent: total > 0 ? Number(((count / total) * 100).toFixed(1)) : 0,
    }));
  }, [dashboard]);

  const watchlistColumns = [
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
      render: (name: string) => <Text strong>{name}</Text>,
    },
    {
      title: 'Không phép',
      dataIndex: 'unexcusedCount',
      key: 'unexcusedCount',
      width: 120,
      align: 'center' as const,
      render: (val: number) => (
        <Tag color="error" style={{ fontWeight: 'bold' }}>
          {val} buổi
        </Tag>
      ),
    },
    {
      title: 'Có phép',
      dataIndex: 'excusedCount',
      key: 'excusedCount',
      width: 100,
      align: 'center' as const,
      render: (val: number) => <Tag color="processing">{val} buổi</Tag>,
    },
    {
      title: 'Đi muộn',
      dataIndex: 'lateCount',
      key: 'lateCount',
      width: 100,
      align: 'center' as const,
      render: (val: number) => (val > 0 ? <Tag color="warning">{val}</Tag> : '0'),
    },
    {
      title: 'Tỷ lệ chuyên cần',
      dataIndex: 'attendanceRate',
      key: 'attendanceRate',
      width: 180,
      render: (rate: number, record: AttendanceStudentSummaryDTO) => {
        if (record.totalTrackedSessions === 0) return <Text type="secondary">—</Text>;
        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Progress
              percent={rate}
              size="small"
              strokeColor={rate < 75 ? '#EF4444' : '#F59E0B'}
              style={{ flex: 1 }}
            />
            <Text strong style={{ fontSize: 12, minWidth: 42, color: rate < 75 ? '#EF4444' : '#0F172A' }}>
              {rate.toFixed(1)}%
            </Text>
          </div>
        );
      },
    },
    {
      title: 'Mức độ cảnh báo',
      key: 'severity',
      width: 160,
      render: (_: any, r: AttendanceStudentSummaryDTO) => {
        if (r.unexcusedCount >= 3) {
          return (
            <Tag color="red" icon={<WarningOutlined />}>
              Nguy cơ cấm thi
            </Tag>
          );
        }
        return (
          <Tag color="orange" icon={<WarningOutlined />}>
            Chuyên cần thấp
          </Tag>
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
              Báo cáo & Thống kê Quản trị
            </Title>
            <Text type="secondary" style={{ fontSize: 13 }}>
              Bảng phân tích dữ liệu tổng thể về đào tạo, chuyên cần và học lực toàn trường
            </Text>
          </div>

          <Space wrap size={12}>
            {/* Academic Year */}
            <Select
              value={academicYear}
              onChange={(val) => setAcademicYear(val)}
              style={{ width: 140 }}
              options={[
                { value: '2025-2026', label: 'Năm 2025-2026' },
                { value: '2024-2025', label: 'Năm 2024-2025' },
              ]}
            />

            {/* Semester */}
            <Select
              value={semester}
              onChange={(val) => setSemester(val)}
              style={{ width: 120 }}
              options={[
                { value: 1, label: 'Học kỳ 1' },
                { value: 2, label: 'Học kỳ 2' },
              ]}
            />

            <Button
              icon={<RedoOutlined spin={isRefetchingDashboard} />}
              onClick={() => refetchDashboard()}
            >
              Cập nhật
            </Button>
          </Space>
        </div>
      </div>

      {isLoadingDashboard ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>
          <Spin size="large" tip="Đang tổng hợp số liệu báo cáo..." />
        </div>
      ) : dashboardError ? (
        <Alert
          type="error"
          message="Lỗi kết nối báo cáo"
          description="Không thể tải số liệu báo cáo quản trị từ Backend. Vui lòng kiểm tra lại quyền truy cập hoặc kết nối."
          showIcon
        />
      ) : dashboard ? (
        <Space direction="vertical" size={20} style={{ width: '100%' }}>
          {/* Section 1: Top KPI Cards */}
          <Row gutter={[16, 16]}>
            <Col xs={24} sm={12} lg={6}>
              <Card bordered={false} style={{ borderRadius: 14, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                    Quy mô học sinh
                  </Text>
                  <TeamOutlined style={{ color: '#2563EB', fontSize: 18 }} />
                </div>
                <div style={{ marginTop: 8 }}>
                  <Statistic
                    value={dashboard.totalStudents}
                    suffix={<span style={{ fontSize: 13, color: '#64748B' }}>học sinh</span>}
                    valueStyle={{ fontWeight: 'bold', fontSize: 26, color: '#0F172A' }}
                  />
                </div>
                <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                  Tổng số lớp: <strong>{dashboard.totalClasses} lớp</strong>
                </Text>
              </Card>
            </Col>

            <Col xs={24} sm={12} lg={6}>
              <Card bordered={false} style={{ borderRadius: 14, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                    Đội ngũ giáo viên
                  </Text>
                  <BookOutlined style={{ color: '#0EA5E9', fontSize: 18 }} />
                </div>
                <div style={{ marginTop: 8 }}>
                  <Statistic
                    value={dashboard.totalTeachers}
                    suffix={<span style={{ fontSize: 13, color: '#64748B' }}>giáo viên</span>}
                    valueStyle={{ fontWeight: 'bold', fontSize: 26, color: '#0F172A' }}
                  />
                </div>
                <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                  Phân công giảng dạy toàn trường
                </Text>
              </Card>
            </Col>

            <Col xs={24} sm={12} lg={6}>
              <Card bordered={false} style={{ borderRadius: 14, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                    Điểm GPA trung bình
                  </Text>
                  <TrophyOutlined style={{ color: '#F59E0B', fontSize: 18 }} />
                </div>
                <div style={{ marginTop: 8 }}>
                  {dashboard.averageSchoolGpa !== null && dashboard.averageSchoolGpa !== undefined ? (
                    <Statistic
                      value={dashboard.averageSchoolGpa}
                      precision={2}
                      suffix={<span style={{ fontSize: 13, color: '#64748B' }}>/ 4.0</span>}
                      valueStyle={{ fontWeight: 'bold', fontSize: 26, color: '#0F172A' }}
                    />
                  ) : (
                    <div style={{ fontWeight: 'bold', fontSize: 26, color: '#94A3B8' }}>—</div>
                  )}
                </div>
                <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                  Tổng đầu điểm: <strong>{dashboard.totalGrades} bản ghi</strong>
                </Text>
              </Card>
            </Col>

            <Col xs={24} sm={12} lg={6}>
              <Card bordered={false} style={{ borderRadius: 14, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Text type="secondary" style={{ fontSize: 13, fontWeight: 500 }}>
                    Tỷ lệ chuyên cần
                  </Text>
                  <CheckCircleOutlined style={{ color: '#10B981', fontSize: 18 }} />
                </div>
                <div style={{ marginTop: 8 }}>
                  {dashboard.attendanceRate !== null && dashboard.attendanceRate !== undefined && dashboard.totalAttendanceRecords > 0 ? (
                    <Statistic
                      value={dashboard.attendanceRate}
                      precision={1}
                      suffix="%"
                      valueStyle={{ fontWeight: 'bold', fontSize: 26, color: '#10B981' }}
                    />
                  ) : (
                    <div style={{ fontWeight: 'bold', fontSize: 26, color: '#94A3B8' }}>—</div>
                  )}
                </div>
                <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                  Tổng lượt điểm danh: <strong>{dashboard.totalAttendanceRecords}</strong>
                </Text>
              </Card>
            </Col>
          </Row>

          {/* Section 2: Attendance Detail & Leave Requests */}
          <Row gutter={[16, 16]}>
            {/* Chuyên cần toàn trường */}
            <Col xs={24} lg={12}>
              <Card
                title={
                  <Space>
                    <CheckCircleOutlined style={{ color: '#2563EB' }} />
                    <span>Thống kê Chuyên cần Toàn trường</span>
                  </Space>
                }
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
              >
                <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                      <Text>Có mặt đúng giờ ({dashboard.presentCount} lượt)</Text>
                      <Text strong>
                        {dashboard.totalAttendanceRecords > 0
                          ? ((dashboard.presentCount / dashboard.totalAttendanceRecords) * 100).toFixed(1)
                          : 0}%
                      </Text>
                    </div>
                    <Progress
                      percent={
                        dashboard.totalAttendanceRecords > 0
                          ? Number(((dashboard.presentCount / dashboard.totalAttendanceRecords) * 100).toFixed(1))
                          : 0
                      }
                      strokeColor="#10B981"
                      showInfo={false}
                    />
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                      <Text>Nghỉ có phép ({dashboard.excusedAbsenceCount} lượt)</Text>
                      <Text strong style={{ color: '#2563EB' }}>
                        {dashboard.totalAttendanceRecords > 0
                          ? ((dashboard.excusedAbsenceCount / dashboard.totalAttendanceRecords) * 100).toFixed(1)
                          : 0}%
                      </Text>
                    </div>
                    <Progress
                      percent={
                        dashboard.totalAttendanceRecords > 0
                          ? Number(((dashboard.excusedAbsenceCount / dashboard.totalAttendanceRecords) * 100).toFixed(1))
                          : 0
                      }
                      strokeColor="#3B82F6"
                      showInfo={false}
                    />
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                      <Text>Nghỉ không phép ({dashboard.unexcusedAbsenceCount} lượt)</Text>
                      <Text strong style={{ color: '#EF4444' }}>
                        {dashboard.totalAttendanceRecords > 0
                          ? ((dashboard.unexcusedAbsenceCount / dashboard.totalAttendanceRecords) * 100).toFixed(1)
                          : 0}%
                      </Text>
                    </div>
                    <Progress
                      percent={
                        dashboard.totalAttendanceRecords > 0
                          ? Number(((dashboard.unexcusedAbsenceCount / dashboard.totalAttendanceRecords) * 100).toFixed(1))
                          : 0
                      }
                      strokeColor="#EF4444"
                      showInfo={false}
                    />
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                      <Text>Đi muộn ({dashboard.lateCount} lượt)</Text>
                      <Text strong style={{ color: '#F59E0B' }}>
                        {dashboard.totalAttendanceRecords > 0
                          ? ((dashboard.lateCount / dashboard.totalAttendanceRecords) * 100).toFixed(1)
                          : 0}%
                      </Text>
                    </div>
                    <Progress
                      percent={
                        dashboard.totalAttendanceRecords > 0
                          ? Number(((dashboard.lateCount / dashboard.totalAttendanceRecords) * 100).toFixed(1))
                          : 0
                      }
                      strokeColor="#F59E0B"
                      showInfo={false}
                    />
                  </div>
                </div>
              </Card>
            </Col>

            {/* Phân bố học lực & Đơn xin nghỉ */}
            <Col xs={24} lg={12}>
              <Card
                title={
                  <Space>
                    <TrophyOutlined style={{ color: '#F59E0B' }} />
                    <span>Phân bố Điểm & Đơn xin nghỉ phép</span>
                  </Space>
                }
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
              >
                <div style={{ marginBottom: 16 }}>
                  <Text strong style={{ display: 'block', marginBottom: 8 }}>
                    Phổ điểm chữ toàn trường ({dashboard.totalGrades} bài đánh giá):
                  </Text>
                  {gradeDistributionData.length === 0 ? (
                    <Text type="secondary">Chưa có dữ liệu phân bố điểm</Text>
                  ) : (
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      {gradeDistributionData.map((item) => (
                        <div
                          key={item.grade}
                          style={{
                            flex: '1 1 80px',
                            background: '#F8FAFC',
                            padding: '10px 12px',
                            borderRadius: 10,
                            textAlign: 'center',
                            border: '1px solid #E2E8F0',
                          }}
                        >
                          <div style={{ fontSize: 16, fontWeight: 'bold', color: '#0F172A' }}>
                            {item.grade}
                          </div>
                          <div style={{ fontSize: 14, color: '#2563EB', fontWeight: 600, marginTop: 2 }}>
                            {item.count}
                          </div>
                          <div style={{ fontSize: 11, color: '#64748B' }}>{item.percent}%</div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div style={{ borderTop: '1px solid #F1F5F9', paddingTop: 16 }}>
                  <Text strong style={{ display: 'block', marginBottom: 10 }}>
                    Tình hình tiếp nhận đơn xin nghỉ ({dashboard.totalLeaveRequests} đơn):
                  </Text>
                  <Row gutter={[12, 12]}>
                    <Col span={8}>
                      <div
                        style={{
                          background: '#FEF3C7',
                          padding: '12px',
                          borderRadius: 10,
                          textAlign: 'center',
                        }}
                      >
                        <div style={{ fontSize: 12, color: '#92400E' }}>Chờ duyệt</div>
                        <div style={{ fontSize: 20, fontWeight: 'bold', color: '#B45309' }}>
                          {dashboard.pendingLeaveRequests}
                        </div>
                      </div>
                    </Col>
                    <Col span={8}>
                      <div
                        style={{
                          background: '#DCFCE7',
                          padding: '12px',
                          borderRadius: 10,
                          textAlign: 'center',
                        }}
                      >
                        <div style={{ fontSize: 12, color: '#166534' }}>Đã duyệt</div>
                        <div style={{ fontSize: 20, fontWeight: 'bold', color: '#15803D' }}>
                          {dashboard.approvedLeaveRequests}
                        </div>
                      </div>
                    </Col>
                    <Col span={8}>
                      <div
                        style={{
                          background: '#FEE2E2',
                          padding: '12px',
                          borderRadius: 10,
                          textAlign: 'center',
                        }}
                      >
                        <div style={{ fontSize: 12, color: '#991B1B' }}>Từ chối</div>
                        <div style={{ fontSize: 20, fontWeight: 'bold', color: '#B91C1C' }}>
                          {dashboard.rejectedLeaveRequests}
                        </div>
                      </div>
                    </Col>
                  </Row>
                </div>
              </Card>
            </Col>
          </Row>

          {/* Section 3: Class-by-Class Attendance Trend (Requirement: If API not sufficient -> Note NEEDS BACKEND API) */}
          <Card
            title={
              <Space>
                <InfoCircleOutlined style={{ color: '#0EA5E9' }} />
                <span>Biểu đồ Chuyên cần theo từng Lớp học</span>
              </Space>
            }
            bordered={false}
            style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
          >
            <Alert
              type="info"
              showIcon
              message="NEEDS BACKEND API: Biểu đồ chuỗi thời gian so sánh giữa các lớp"
              description="Backend ReportController hiện tại chỉ cung cấp báo cáo tổng hợp toàn trường (AdminDashboardDTO) hoặc lớp chủ nhiệm cụ thể (TeacherHomeroomDashboardDTO). Để vẽ biểu đồ cột/đường so sánh tỷ lệ chuyên cần của tất cả các lớp qua từng tuần, cần backend bổ sung endpoint GET /api/reports/classes-attendance-comparison."
            />
          </Card>

          {/* Section 4: Watchlist Table - Học sinh cần chú ý */}
          <Card
            title={
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
                <Space>
                  <WarningOutlined style={{ color: '#EF4444' }} />
                  <span>Danh sách Học sinh cần Chú ý (Nguy cơ cấm thi / Chuyên cần thấp)</span>
                </Space>

                <Space size={8}>
                  <Text style={{ fontSize: 13 }}>Xem theo lớp:</Text>
                  <Select
                    value={watchlistClassId}
                    onChange={(val) => setWatchlistClassId(val)}
                    style={{ width: 150 }}
                    options={classes.map((c) => ({
                      value: c.id,
                      label: `Lớp ${c.className}`,
                    }))}
                  />
                </Space>
              </div>
            }
            bordered={false}
            style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}
          >
            <div style={{ marginBottom: 12 }}>
              <Text type="secondary" style={{ fontSize: 12 }}>
                * Tiêu chí: Học sinh có từ <strong>3 buổi vắng không phép</strong> trở lên hoặc tỷ lệ chuyên cần <strong>dưới 75%</strong>.
              </Text>
            </div>

            {isLoadingClassHistory ? (
              <div style={{ textAlign: 'center', padding: '40px 0' }}>
                <Spin tip="Đang kiểm tra dữ liệu chuyên cần lớp..." />
              </div>
            ) : atRiskStudents.length === 0 ? (
              <Empty
                image={Empty.PRESENTED_IMAGE_SIMPLE}
                description="Lớp này không có học sinh nào thuộc diện cảnh báo nguy cơ"
                style={{ padding: '30px 0' }}
              />
            ) : (
              <Table
                columns={watchlistColumns}
                dataSource={atRiskStudents}
                rowKey="studentId"
                pagination={false}
                scroll={{ x: 800 }}
              />
            )}
          </Card>
        </Space>
      ) : null}
    </div>
  );
};
