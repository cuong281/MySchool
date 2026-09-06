import React, { useState, useEffect } from 'react';
import {
  Modal,
  Spin,
  Alert,
  Table,
  Radio,
  Input,
  Checkbox,
  Button,
  Space,
  Tag,
  Typography,
  message,
  Divider,
} from 'antd';
import {
  CheckCircleOutlined,
  ClockCircleOutlined,
  WarningOutlined,
  LockOutlined,
  SaveOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { attendanceApi } from '../../api/attendanceApi';
import type {
  AttendanceBatchItemDTO,
  AttendanceBatchRequest,
  AttendanceSheetDTO,
  AttendanceStatus,
} from '../../types/attendance';

const { Text, Title } = Typography;

interface AttendanceSheetModalProps {
  open: boolean;
  onClose: () => void;
  classId: number;
  slotNumber: number;
  subjectId?: number;
  date: string; // YYYY-MM-DD
  onSaved: () => void;
}

interface StudentRowState {
  studentId: number;
  studentName: string;
  studentCode: string;
  status: AttendanceStatus;
  note: string;
  hasApprovedLeave: boolean;
  leaveReason?: string;
  overrideLeave: boolean;
  overrideReason: string;
}

export const AttendanceSheetModal: React.FC<AttendanceSheetModalProps> = ({
  open,
  onClose,
  classId,
  slotNumber,
  subjectId,
  date,
  onSaved,
}) => {
  const queryClient = useQueryClient();
  const [rows, setRows] = useState<StudentRowState[]>([]);

  // Fetch attendance sheet
  const { data: sheet, isLoading, error } = useQuery<AttendanceSheetDTO>({
    queryKey: ['attendanceSheet', classId, slotNumber, subjectId, date],
    queryFn: () => attendanceApi.getAttendanceSheet(classId, slotNumber, subjectId, date),
    enabled: open && classId > 0 && slotNumber > 0,
  });

  // Sync rows from sheet data
  useEffect(() => {
    if (sheet && sheet.students) {
      const initialRows: StudentRowState[] = sheet.students.map((s) => ({
        studentId: s.studentId,
        studentName: s.studentName,
        studentCode: s.studentCode,
        status: s.currentStatus || (s.hasApprovedLeave ? 'EXCUSED_ABSENCE' : 'PRESENT'),
        note: s.note || '',
        hasApprovedLeave: !!s.hasApprovedLeave,
        leaveReason: s.leaveReason,
        overrideLeave: false,
        overrideReason: '',
      }));
      setRows(initialRows);
    }
  }, [sheet]);

  // Save mutation
  const saveMutation = useMutation({
    mutationFn: (payload: AttendanceBatchRequest) => attendanceApi.recordBatchAttendance(payload),
    onSuccess: () => {
      message.success('Lưu sổ điểm danh thành công!');
      queryClient.invalidateQueries({ queryKey: ['classAttendanceHistory', classId] });
      onSaved();
      onClose();
    },
    onError: (err: any) => {
      const errorMsg =
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Không thể lưu điểm danh. Vui lòng thử lại.';
      message.error(errorMsg);
    },
  });

  const handleStatusChange = (studentId: number, status: AttendanceStatus) => {
    setRows((prev) =>
      prev.map((r) => {
        if (r.studentId === studentId) {
          return {
            ...r,
            status,
            // Reset override if not present
            overrideLeave: status === 'PRESENT' ? r.overrideLeave : false,
          };
        }
        return r;
      })
    );
  };

  const handleNoteChange = (studentId: number, note: string) => {
    setRows((prev) => prev.map((r) => (r.studentId === studentId ? { ...r, note } : r)));
  };

  const handleOverrideLeaveChange = (studentId: number, overrideLeave: boolean) => {
    setRows((prev) => prev.map((r) => (r.studentId === studentId ? { ...r, overrideLeave } : r)));
  };

  const handleOverrideReasonChange = (studentId: number, overrideReason: string) => {
    setRows((prev) => prev.map((r) => (r.studentId === studentId ? { ...r, overrideReason } : r)));
  };

  const handleSetAllPresent = () => {
    setRows((prev) =>
      prev.map((r) => ({
        ...r,
        status: 'PRESENT',
        overrideLeave: r.hasApprovedLeave ? true : r.overrideLeave,
        overrideReason: r.hasApprovedLeave && !r.overrideReason ? 'Đi học thực tế' : r.overrideReason,
      }))
    );
  };

  const handleSave = () => {
    // Validate override reasons
    for (const r of rows) {
      if (r.hasApprovedLeave && r.status === 'PRESENT') {
        if (!r.overrideLeave || !r.overrideReason.trim()) {
          message.warning(
            `Học sinh ${r.studentName} có đơn xin nghỉ phép đã duyệt. Vui lòng tích chọn ghi đè và nhập lý do ghi đè!`
          );
          return;
        }
      }
    }

    const items: AttendanceBatchItemDTO[] = rows.map((r) => ({
      studentId: r.studentId,
      status: r.status,
      note: r.note.trim() || undefined,
      overrideLeave: r.overrideLeave || undefined,
      overrideReason: r.overrideReason.trim() || undefined,
    }));

    const payload: AttendanceBatchRequest = {
      classId,
      subjectId,
      slotNumber,
      attendanceDate: date, // Already in YYYY-MM-DD
      items,
    };

    saveMutation.mutate(payload);
  };

  const getLockReasonText = (reason?: string) => {
    switch (reason) {
      case 'NOT_STARTED':
        return 'Chưa đến thời gian bắt đầu tiết học';
      case 'EXPIRED_PAST_DAY':
        return 'Hệ thống đã khóa sổ buổi học của các ngày trước đó (chỉ xem)';
      case 'NO_SCHEDULE':
        return 'Không có lịch học trong thời khóa biểu cho tiết này';
      case 'FUTURE_DATE':
        return 'Không thể điểm danh cho ngày trong tương lai';
      default:
        return 'Buổi học đã khóa sổ (chỉ xem)';
    }
  };

  const canEdit = sheet?.canEdit ?? false;

  const columns = [
    {
      title: 'Mã HS',
      dataIndex: 'studentCode',
      key: 'studentCode',
      width: 100,
      render: (code: string) => <Text code>{code}</Text>,
    },
    {
      title: 'Họ và tên',
      dataIndex: 'studentName',
      key: 'studentName',
      width: 220,
      render: (name: string, record: StudentRowState) => (
        <Space orientation="vertical" size={2}>
          <Text strong>{name}</Text>
          {record.hasApprovedLeave && (
            <Tag color="warning" icon={<WarningOutlined />} style={{ fontSize: 11 }}>
              Đơn nghỉ phép: {record.leaveReason || 'Đã duyệt'}
            </Tag>
          )}
        </Space>
      ),
    },
    {
      title: 'Trạng thái điểm danh',
      key: 'status',
      width: 320,
      render: (_: any, record: StudentRowState) => (
        <Space orientation="vertical" size={6} style={{ width: '100%' }}>
          <Radio.Group
            value={record.status}
            onChange={(e) => handleStatusChange(record.studentId, e.target.value)}
            disabled={!canEdit}
            buttonStyle="solid"
            size="small"
          >
            <Radio.Button value="PRESENT">Có mặt</Radio.Button>
            <Radio.Button value="EXCUSED_ABSENCE">Có phép</Radio.Button>
            <Radio.Button value="UNEXCUSED_ABSENCE">K.Phép</Radio.Button>
            <Radio.Button value="LATE">Muộn</Radio.Button>
          </Radio.Group>

          {/* Approved Leave Override Section */}
          {record.hasApprovedLeave && record.status === 'PRESENT' && (
            <div
              style={{
                background: '#FEF3C7',
                padding: '6px 10px',
                borderRadius: 6,
                border: '1px solid #FCD34D',
                marginTop: 4,
              }}
            >
              <Checkbox
                checked={record.overrideLeave}
                onChange={(e) => handleOverrideLeaveChange(record.studentId, e.target.checked)}
                disabled={!canEdit}
                style={{ fontSize: 12, fontWeight: 600, color: '#92400E' }}
              >
                Ghi đè đơn xin nghỉ (HS thực tế có mặt)
              </Checkbox>
              {record.overrideLeave && (
                <Input
                  size="small"
                  placeholder="Lý do ghi đè (bắt buộc)..."
                  value={record.overrideReason}
                  onChange={(e) => handleOverrideReasonChange(record.studentId, e.target.value)}
                  disabled={!canEdit}
                  style={{ marginTop: 4 }}
                />
              )}
            </div>
          )}
        </Space>
      ),
    },
    {
      title: 'Ghi chú',
      key: 'note',
      render: (_: any, record: StudentRowState) => (
        <Input
          size="small"
          placeholder="Ghi chú (nếu có)..."
          value={record.note}
          onChange={(e) => handleNoteChange(record.studentId, e.target.value)}
          disabled={!canEdit}
        />
      ),
    },
  ];

  return (
    <Modal
      open={open}
      onCancel={onClose}
      width={920}
      style={{ top: 20 }}
      title={
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Title level={4} style={{ margin: 0 }}>
            Sổ Điểm Danh — Tiết {slotNumber} ({sheet?.subjectName || 'Môn học'})
          </Title>
          {!canEdit && (
            <Tag color="default" icon={<LockOutlined />}>
              Đã khóa
            </Tag>
          )}
        </div>
      }
      footer={[
        <Button key="cancel" onClick={onClose}>
          Đóng
        </Button>,
        canEdit && (
          <Button
            key="save"
            type="primary"
            icon={<SaveOutlined />}
            loading={saveMutation.isPending}
            onClick={handleSave}
          >
            Lưu điểm danh
          </Button>
        ),
      ]}
    >
      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '60px 0' }}>
          <Spin size="large" tip="Đang tải danh sách học sinh..." />
        </div>
      ) : error ? (
        <Alert
          type="error"
          message="Không thể tải sổ điểm danh"
          description={(error as any)?.message || 'Vui lòng thử lại sau.'}
          showIcon
          style={{ marginBottom: 16 }}
        />
      ) : (
        <div>
          {/* Header Info Banner */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              background: '#F8FAFC',
              padding: '12px 16px',
              borderRadius: 8,
              border: '1px solid #E2E8F0',
              marginBottom: 16,
              gap: 8,
            }}
          >
            <Space size={16} wrap>
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Ngày học:</Text>
                <br />
                <Text strong>{dayjs(date).format('DD/MM/YYYY')}</Text>
              </div>
              <Divider type="vertical" />
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Lớp:</Text>
                <br />
                <Text strong>Lớp {sheet?.className}</Text>
              </div>
              <Divider type="vertical" />
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Khung giờ:</Text>
                <br />
                <Space size={4}>
                  <ClockCircleOutlined style={{ color: '#2563EB', fontSize: 12 }} />
                  <Text strong>
                    {sheet?.startTime || '--:--'} - {sheet?.endTime || '--:--'}
                  </Text>
                </Space>
              </div>
              <Divider type="vertical" />
              <div>
                <Text type="secondary" style={{ fontSize: 12 }}>Sĩ số:</Text>
                <br />
                <Text strong>{sheet?.totalStudents || rows.length} học sinh</Text>
              </div>
            </Space>

            {canEdit && (
              <Button
                type="dashed"
                size="small"
                icon={<CheckCircleOutlined style={{ color: '#10B981' }} />}
                onClick={handleSetAllPresent}
              >
                Tất cả có mặt
              </Button>
            )}
          </div>

          {!canEdit && (
            <Alert
              type="warning"
              showIcon
              icon={<LockOutlined />}
              message="Chế độ chỉ xem"
              description={getLockReasonText(sheet?.lockReason)}
              style={{ marginBottom: 16 }}
            />
          )}

          <Table
            columns={columns}
            dataSource={rows}
            rowKey="studentId"
            pagination={false}
            size="middle"
            scroll={{ y: 440 }}
          />
        </div>
      )}
    </Modal>
  );
};
