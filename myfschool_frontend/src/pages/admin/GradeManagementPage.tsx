import React, { useState, useMemo, useEffect } from 'react';
import {
  Typography,
  Select,
  Input,
  Table,
  Button,
  Space,
  Card,
  Tag,
  Modal,
  Form,
  InputNumber,
  Drawer,
  Spin,
  Alert,
  Empty,
  message,
  theme,
  Tabs,
  Upload,
  Row,
  Col,
  Statistic,
  Progress,
  Divider,
} from 'antd';
import {
  SearchOutlined,
  EditOutlined,
  EyeOutlined,
  RedoOutlined,
  BookOutlined,
  UserOutlined,
  DownloadOutlined,
  UploadOutlined,
  InboxOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  FileExcelOutlined,
  TableOutlined,
  AppstoreOutlined,
} from '@ant-design/icons';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import * as XLSX from 'xlsx';
import { classApi } from '../../api/classApi';
import { gradeApi } from '../../api/gradeApi';
import type { GradeDTO } from '../../types/grade';

const { Title, Text } = Typography;

interface ParsedExcelRow {
  rowIndex: number;
  studentId: number;
  studentName: string;
  attendanceScore: number | null;
  midtermScore: number | null;
  finalScore: number | null;
  predictedAverage: number | null;
  isValid: boolean;
  errors: string[];
}

export const GradeManagementPage: React.FC = () => {
  const { token } = theme.useToken();
  const queryClient = useQueryClient();

  // Active Tab
  const [activeTab, setActiveTab] = useState<string>('overview');

  // Filters (Shared & Tab-Specific)
  const [selectedClassId, setSelectedClassId] = useState<number | undefined>(undefined);
  const [selectedSubject, setSelectedSubject] = useState<string>('MATH');
  const [selectedSemester, setSelectedSemester] = useState<number>(1);
  const [searchText, setSearchText] = useState<string>('');

  // Edit Modal State
  const [editingGrade, setEditingGrade] = useState<GradeDTO | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState<boolean>(false);
  const [editForm] = Form.useForm();

  // Student Detail Drawer State
  const [drawerStudentId, setDrawerStudentId] = useState<number | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [drawerSemesterFilter, setDrawerSemesterFilter] = useState<'ALL' | 1 | 2>('ALL');

  // Excel Import Tab State
  const [importClassId, setImportClassId] = useState<number | undefined>(undefined);
  const [importSubject, setImportSubject] = useState<string>('MATH');
  const [importSemester, setImportSemester] = useState<number>(1);
  const [uploadedFileName, setUploadedFileName] = useState<string>('');
  const [parsedRows, setParsedRows] = useState<ParsedExcelRow[]>([]);
  const [isImporting, setIsImporting] = useState<boolean>(false);
  const [importProgress, setImportProgress] = useState<{ current: number; total: number } | null>(null);

  // 1. Fetch Classes
  const {
    data: classes = [],
    isLoading: isLoadingClasses,
  } = useQuery({
    queryKey: ['schoolClasses'],
    queryFn: () => classApi.getAllClasses(),
  });

  // Auto select first class when classes are loaded
  useEffect(() => {
    if (classes.length > 0) {
      if (selectedClassId === undefined) {
        setSelectedClassId(classes[0].id);
      }
      if (importClassId === undefined) {
        setImportClassId(classes[0].id);
      }
    }
  }, [classes, selectedClassId, importClassId]);

  // Keep importClassId in sync with selectedClassId if user switches class
  useEffect(() => {
    if (selectedClassId) {
      setImportClassId(selectedClassId);
    }
  }, [selectedClassId]);

  // 2. Fetch Grades for Selected Class
  const {
    data: grades = [],
    isLoading: isLoadingGrades,
    error: gradesError,
    refetch: refetchGrades,
    isRefetching: isRefetchingGrades,
  } = useQuery<GradeDTO[]>({
    queryKey: ['classGrades', selectedClassId],
    queryFn: () => gradeApi.getByClass(selectedClassId!),
    enabled: selectedClassId !== undefined && selectedClassId > 0,
  });

  // Unique subjects derived from grades of this class
  const subjects = useMemo(() => {
    const map = new Map<string, string>();
    grades.forEach((g) => {
      if (g.subjectCode) {
        map.set(g.subjectCode, g.subjectName || g.subjectCode);
      }
    });
    return Array.from(map.entries()).map(([code, name]) => ({ code, name }));
  }, [grades]);

  // Set default subject when subjects are loaded
  useEffect(() => {
    if (subjects.length > 0) {
      const exists = subjects.some((s) => s.code === selectedSubject);
      if (!exists) {
        setSelectedSubject(subjects[0].code);
      }
      const importExists = subjects.some((s) => s.code === importSubject);
      if (!importExists) {
        setImportSubject(subjects[0].code);
      }
    }
  }, [subjects, selectedSubject, importSubject]);

  // Unique student list in class (sorted by studentId)
  const studentsInClass = useMemo(() => {
    const map = new Map<number, { studentId: number; studentName: string; className: string }>();
    grades.forEach((g) => {
      if (g.studentId && !map.has(g.studentId)) {
        map.set(g.studentId, {
          studentId: g.studentId,
          studentName: g.studentName,
          className: g.className,
        });
      }
    });
    return Array.from(map.values()).sort((a, b) => a.studentId - b.studentId);
  }, [grades]);

  // ==========================================
  // TAB 1: TỔNG QUAN HỌC SINH (1 HS = 1 DÒNG)
  // ==========================================
  const studentOverviewData = useMemo(() => {
    return studentsInClass
      .map((student) => {
        const studentGrades = grades.filter((g) => g.studentId === student.studentId);

        // Subject averages across available semesters
        const subjectAverages: Record<string, number | null> = {};
        const subjectGpas: Record<string, number | null> = {};

        subjects.forEach((subj) => {
          const match = studentGrades.filter(
            (g) => g.subjectCode === subj.code && g.averageScore !== null && g.averageScore !== undefined
          );
          if (match.length > 0) {
            const avg = match.reduce((sum, item) => sum + item.averageScore!, 0) / match.length;
            subjectAverages[subj.code] = Math.round(avg * 100) / 100;

            const validGpas = match.filter((g) => g.gpa4 !== null && g.gpa4 !== undefined);
            if (validGpas.length > 0) {
              subjectGpas[subj.code] = validGpas.reduce((sum, item) => sum + item.gpa4!, 0) / validGpas.length;
            } else {
              subjectGpas[subj.code] = null;
            }
          } else {
            subjectAverages[subj.code] = null;
            subjectGpas[subj.code] = null;
          }
        });

        // Overall Average across all subjects
        const validSubjectAvgs = Object.values(subjectAverages).filter((v): v is number => v !== null);
        const overallAverage =
          validSubjectAvgs.length > 0
            ? Math.round((validSubjectAvgs.reduce((a, b) => a + b, 0) / validSubjectAvgs.length) * 100) / 100
            : null;

        // Overall GPA
        const validSubjectGpas = Object.values(subjectGpas).filter((v): v is number => v !== null);
        const overallGpa =
          validSubjectGpas.length > 0
            ? Math.round((validSubjectGpas.reduce((a, b) => a + b, 0) / validSubjectGpas.length) * 100) / 100
            : null;

        return {
          studentId: student.studentId,
          studentName: student.studentName,
          className: student.className,
          subjectAverages,
          overallAverage,
          overallGpa,
          rawGrades: studentGrades,
        };
      })
      .filter((row) => {
        if (!searchText.trim()) return true;
        const q = searchText.toLowerCase().trim();
        return row.studentName.toLowerCase().includes(q) || String(row.studentId).includes(q);
      });
  }, [studentsInClass, grades, subjects, searchText]);

  // ==========================================
  // TAB 2: THEO MÔN (1 HS = 1 DÒNG VỚI 3 THÀNH PHẦN)
  // ==========================================
  const subjectGradesData = useMemo(() => {
    return grades
      .filter((g) => {
        if (selectedSubject && g.subjectCode !== selectedSubject) return false;
        if (selectedSemester && g.semester !== selectedSemester) return false;
        if (searchText.trim()) {
          const q = searchText.toLowerCase().trim();
          return g.studentName.toLowerCase().includes(q) || String(g.studentId).includes(q);
        }
        return true;
      })
      .sort((a, b) => a.studentId - b.studentId);
  }, [grades, selectedSubject, selectedSemester, searchText]);

  // ==========================================
  // MUTATION: CẬP NHẬT ĐIỂM
  // ==========================================
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<GradeDTO> }) => gradeApi.update(id, data),
    onSuccess: () => {
      message.success('Cập nhật điểm thành công');
      queryClient.invalidateQueries({ queryKey: ['classGrades', selectedClassId] });
      setIsEditModalOpen(false);
      setEditingGrade(null);
      editForm.resetFields();
    },
    onError: (err: any) => {
      message.error(err?.response?.data?.error || 'Không thể cập nhật điểm');
    },
  });

  const handleOpenEdit = (record: GradeDTO) => {
    setEditingGrade(record);
    editForm.setFieldsValue({
      attendanceScore: record.attendanceScore,
      midtermScore: record.midtermScore,
      finalScore: record.finalScore,
    });
    setIsEditModalOpen(true);
  };

  const handleSaveEdit = async () => {
    try {
      const values = await editForm.validateFields();
      if (editingGrade) {
        updateMutation.mutate({
          id: editingGrade.id,
          data: {
            attendanceScore: values.attendanceScore ?? null,
            midtermScore: values.midtermScore ?? null,
            finalScore: values.finalScore ?? null,
          },
        });
      }
    } catch {
      // form validation failed
    }
  };

  const handleOpenStudentDrawer = (studentId: number) => {
    setDrawerStudentId(studentId);
    setDrawerSemesterFilter('ALL');
    setIsDrawerOpen(true);
  };

  // Selected Student in Drawer
  const selectedStudentInDrawer = useMemo(() => {
    if (!drawerStudentId) return null;
    return studentsInClass.find((s) => s.studentId === drawerStudentId) || null;
  }, [drawerStudentId, studentsInClass]);

  const studentGradesInDrawer = useMemo(() => {
    if (!drawerStudentId) return [];
    return grades.filter((g) => {
      if (g.studentId !== drawerStudentId) return false;
      if (drawerSemesterFilter !== 'ALL' && g.semester !== drawerSemesterFilter) return false;
      return true;
    });
  }, [grades, drawerStudentId, drawerSemesterFilter]);

  // Drawer overall stats for this student
  const drawerStudentStats = useMemo(() => {
    if (!drawerStudentId) return { totalSubjects: 0, avgScore: '—', gpa: '—' };
    const allStudentGrades = grades.filter((g) => g.studentId === drawerStudentId);
    const validScores = allStudentGrades.filter((g) => g.averageScore !== null && g.averageScore !== undefined);
    const validGpas = allStudentGrades.filter((g) => g.gpa4 !== null && g.gpa4 !== undefined);

    const avgScore =
      validScores.length > 0
        ? (validScores.reduce((s, i) => s + i.averageScore!, 0) / validScores.length).toFixed(2)
        : '—';
    const gpa =
      validGpas.length > 0
        ? (validGpas.reduce((s, i) => s + i.gpa4!, 0) / validGpas.length).toFixed(2)
        : '—';

    return {
      totalSubjects: new Set(allStudentGrades.map((g) => g.subjectCode)).size,
      avgScore,
      gpa,
    };
  }, [drawerStudentId, grades]);

  // ==========================================
  // TAB 3: EXCEL IMPORT LOGIC
  // ==========================================

  // Tải file mẫu Excel
  const handleDownloadTemplate = () => {
    const currentClass = classes.find((c) => c.id === importClassId);
    const className = currentClass ? currentClass.className : 'Class';
    const subjName = subjects.find((s) => s.code === importSubject)?.name || importSubject;

    // Pre-populate with students in this class
    const templateData = studentsInClass.map((s, idx) => ({
      STT: idx + 1,
      StudentID: s.studentId,
      StudentName: s.studentName,
      'Chuyên cần': '',
      'Giữa kỳ': '',
      'Cuối kỳ': '',
    }));

    const ws = XLSX.utils.json_to_sheet(templateData);
    // Set column widths
    ws['!cols'] = [
      { wch: 6 }, // STT
      { wch: 12 }, // StudentID
      { wch: 25 }, // StudentName
      { wch: 14 }, // Chuyên cần
      { wch: 14 }, // Giữa kỳ
      { wch: 14 }, // Cuối kỳ
    ];

    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'BangDiem');
    const fileName = `Mau_Nhap_Diem_${className}_${subjName}_HK${importSemester}.xlsx`;
    XLSX.writeFile(wb, fileName);
    message.success(`Đã tải xuống file mẫu: ${fileName}`);
  };

  // Tải file mẫu có sẵn dữ liệu điểm hợp lệ (25 HS lớp 10A1)
  const handleDownloadFilledSample = () => {
    const students = [
      { STT: 1, StudentID: 1, StudentName: 'Nguyen Van A', 'Chuyên cần': 9.0, 'Giữa kỳ': 9.0, 'Cuối kỳ': 10.0 },
      { STT: 2, StudentID: 2, StudentName: 'Tran Thi B', 'Chuyên cần': 8.5, 'Giữa kỳ': 8.0, 'Cuối kỳ': 9.0 },
      { STT: 3, StudentID: 3, StudentName: 'Le Van C', 'Chuyên cần': 9.5, 'Giữa kỳ': 8.5, 'Cuối kỳ': 9.0 },
      { STT: 4, StudentID: 7, StudentName: 'Nguyen Thuy Duong', 'Chuyên cần': 10.0, 'Giữa kỳ': 9.5, 'Cuối kỳ': 9.5 },
      { STT: 5, StudentID: 8, StudentName: 'Tran Bich Huong', 'Chuyên cần': 8.0, 'Giữa kỳ': 8.5, 'Cuối kỳ': 8.5 },
      { STT: 6, StudentID: 9, StudentName: 'Le Quoc Dung', 'Chuyên cần': 7.5, 'Giữa kỳ': 8.0, 'Cuối kỳ': 8.0 },
      { STT: 7, StudentID: 10, StudentName: 'Pham Quynh Anh', 'Chuyên cần': 9.0, 'Giữa kỳ': 9.0, 'Cuối kỳ': 9.5 },
      { STT: 8, StudentID: 11, StudentName: 'Hoang Phuoc Nam', 'Chuyên cần': 8.5, 'Giữa kỳ': 7.5, 'Cuối kỳ': 8.5 },
      { STT: 9, StudentID: 12, StudentName: 'Phan Mai Phuong', 'Chuyên cần': 9.0, 'Giữa kỳ': 9.0, 'Cuối kỳ': 9.0 },
      { STT: 10, StudentID: 13, StudentName: 'Vu Duc Minh', 'Chuyên cần': 8.0, 'Giữa kỳ': 8.0, 'Cuối kỳ': 8.5 },
      { STT: 11, StudentID: 14, StudentName: 'Vo Hoang Bach', 'Chuyên cần': 9.0, 'Giữa kỳ': 8.5, 'Cuối kỳ': 9.0 },
      { STT: 12, StudentID: 15, StudentName: 'Dang Phuong Thao', 'Chuyên cần': 9.5, 'Giữa kỳ': 9.0, 'Cuối kỳ': 9.5 },
      { STT: 13, StudentID: 16, StudentName: 'Bui Minh Huy', 'Chuyên cần': 8.0, 'Giữa kỳ': 7.5, 'Cuối kỳ': 8.0 },
      { STT: 14, StudentID: 17, StudentName: 'Do Tra My', 'Chuyên cần': 9.0, 'Giữa kỳ': 9.5, 'Cuối kỳ': 9.0 },
      { STT: 15, StudentID: 18, StudentName: 'Ho Cong Tri', 'Chuyên cần': 8.5, 'Giữa kỳ': 8.0, 'Cuối kỳ': 8.5 },
      { STT: 16, StudentID: 19, StudentName: 'Ngo Dang Khoa', 'Chuyên cần': 8.0, 'Giữa kỳ': 8.5, 'Cuối kỳ': 8.0 },
      { STT: 17, StudentID: 20, StudentName: 'Duong Huu Tuong', 'Chuyên cần': 9.0, 'Giữa kỳ': 8.0, 'Cuối kỳ': 8.5 },
      { STT: 18, StudentID: 21, StudentName: 'Ly My Hanh', 'Chuyên cần': 9.5, 'Giữa kỳ': 9.0, 'Cuối kỳ': 9.0 },
      { STT: 19, StudentID: 22, StudentName: 'Nguyen Kim Ngan', 'Chuyên cần': 10.0, 'Giữa kỳ': 9.5, 'Cuối kỳ': 10.0 },
      { STT: 20, StudentID: 23, StudentName: 'Tran Bao Long', 'Chuyên cần': 8.0, 'Giữa kỳ': 8.5, 'Cuối kỳ': 8.0 },
      { STT: 21, StudentID: 24, StudentName: 'Le Thu Ha', 'Chuyên cần': 9.0, 'Giữa kỳ': 8.5, 'Cuối kỳ': 9.0 },
      { STT: 22, StudentID: 25, StudentName: 'Pham Tuan Anh', 'Chuyên cần': 8.5, 'Giữa kỳ': 8.0, 'Cuối kỳ': 8.5 },
      { STT: 23, StudentID: 26, StudentName: 'Hoang Thanh Hang', 'Chuyên cần': 9.0, 'Giữa kỳ': 9.0, 'Cuối kỳ': 9.5 },
      { STT: 24, StudentID: 27, StudentName: 'Phan Bao Tram', 'Chuyên cần': 9.5, 'Giữa kỳ': 9.5, 'Cuối kỳ': 9.0 },
      { STT: 25, StudentID: 28, StudentName: 'Vu Van Hai', 'Chuyên cần': 8.0, 'Giữa kỳ': 7.5, 'Cuối kỳ': 8.0 }
    ];
    const ws = XLSX.utils.json_to_sheet(students);
    ws['!cols'] = [{ wch: 6 }, { wch: 12 }, { wch: 25 }, { wch: 14 }, { wch: 14 }, { wch: 14 }];
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'BangDiem');
    XLSX.writeFile(wb, 'Bang_Diem_Lop_10A1_Hop_Le.xlsx');
    message.success('Đã tải xuống file mẫu có sẵn điểm hợp lệ: Bang_Diem_Lop_10A1_Hop_Le.xlsx');
  };

  // Upload & Parse File Excel
  const handleFileUpload = (file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const rawJson: any[] = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

        if (!rawJson || rawJson.length < 2) {
          message.error('File Excel không có dữ liệu hoặc không đúng định dạng');
          return;
        }

        // Header Row (Row 0)
        const headerRow: string[] = (rawJson[0] || []).map((h: any) => String(h || '').trim().toLowerCase());

        // Find column indices
        const findColIndex = (keywords: string[]) => {
          return headerRow.findIndex((col) => keywords.some((kw) => col.includes(kw)));
        };

        const studentIdIdx = findColIndex(['studentid', 'student id', 'mã hs', 'ma hs', 'mã học sinh', 'ma hoc sinh', 'id']);
        const studentNameIdx = findColIndex(['studentname', 'student name', 'tên học sinh', 'ten hoc sinh', 'họ và tên', 'ho va ten', 'tên']);
        const attendanceIdx = findColIndex(['chuyên cần', 'chuyen can', 'chuyencan', 'cc', 'attendance']);
        const midtermIdx = findColIndex(['giữa kỳ', 'giua ky', 'giuaky', 'gk', 'midterm']);
        const finalIdx = findColIndex(['cuối kỳ', 'cuoi ky', 'cuoiky', 'ck', 'final']);

        if (studentIdIdx === -1) {
          message.error('Không tìm thấy cột StudentID hoặc Mã học sinh trong file Excel');
          return;
        }

        const validStudentIdSet = new Set(studentsInClass.map((s) => s.studentId));
        const seenStudentIds = new Set<number>();
        const parsed: ParsedExcelRow[] = [];

        // Parse rows starting from row 1
        for (let i = 1; i < rawJson.length; i++) {
          const row = rawJson[i];
          if (!row || row.length === 0 || row.every((c: any) => c === null || c === undefined || c === '')) {
            continue; // Skip empty row
          }

          const rawId = row[studentIdIdx];
          const rawName = studentNameIdx !== -1 ? String(row[studentNameIdx] || '').trim() : '';
          const rawAttendance = attendanceIdx !== -1 ? row[attendanceIdx] : null;
          const rawMidterm = midtermIdx !== -1 ? row[midtermIdx] : null;
          const rawFinal = finalIdx !== -1 ? row[finalIdx] : null;

          const errors: string[] = [];
          const studentIdNum = Number(rawId);

          if (isNaN(studentIdNum) || studentIdNum <= 0) {
            errors.push(`Mã học sinh '${rawId}' không hợp lệ`);
          } else {
            if (!validStudentIdSet.has(studentIdNum)) {
              errors.push(`Mã HS ${studentIdNum} không thuộc danh sách lớp đã chọn`);
            }
            if (seenStudentIds.has(studentIdNum)) {
              errors.push(`Mã HS ${studentIdNum} bị trùng lặp trong file`);
            }
            seenStudentIds.add(studentIdNum);
          }

          // Validate Attendance Score
          let attendanceScore: number | null = null;
          if (rawAttendance !== null && rawAttendance !== undefined && rawAttendance !== '') {
            const n = Number(rawAttendance);
            if (isNaN(n) || n < 0 || n > 10) {
              errors.push(`Điểm chuyên cần (${rawAttendance}) phải từ 0 đến 10`);
            } else {
              attendanceScore = Math.round(n * 10) / 10;
            }
          }

          // Validate Midterm Score
          let midtermScore: number | null = null;
          if (rawMidterm !== null && rawMidterm !== undefined && rawMidterm !== '') {
            const n = Number(rawMidterm);
            if (isNaN(n) || n < 0 || n > 10) {
              errors.push(`Điểm giữa kỳ (${rawMidterm}) phải từ 0 đến 10`);
            } else {
              midtermScore = Math.round(n * 10) / 10;
            }
          }

          // Validate Final Score
          let finalScore: number | null = null;
          if (rawFinal !== null && rawFinal !== undefined && rawFinal !== '') {
            const n = Number(rawFinal);
            if (isNaN(n) || n < 0 || n > 10) {
              errors.push(`Điểm cuối kỳ (${rawFinal}) phải từ 0 đến 10`);
            } else {
              finalScore = Math.round(n * 10) / 10;
            }
          }

          // Compute predicted average matching Backend formula: (attendance + 2*midterm + 3*final) / 6
          let predictedAverage: number | null = null;
          if (attendanceScore !== null && midtermScore !== null && finalScore !== null) {
            predictedAverage =
              Math.round(((attendanceScore + midtermScore * 2.0 + finalScore * 3.0) / 6.0) * 10.0) / 10.0;
          }

          // Match student name from roster if not in file
          const matchedStudent = studentsInClass.find((s) => s.studentId === studentIdNum);
          const finalStudentName = rawName || matchedStudent?.studentName || `Học sinh #${studentIdNum}`;

          parsed.push({
            rowIndex: i + 1,
            studentId: studentIdNum,
            studentName: finalStudentName,
            attendanceScore,
            midtermScore,
            finalScore,
            predictedAverage,
            isValid: errors.length === 0,
            errors,
          });
        }

        setUploadedFileName(file.name);
        setParsedRows(parsed);

        const errorCount = parsed.filter((r) => !r.isValid).length;
        if (errorCount > 0) {
          message.warning(`Đã đọc ${parsed.length} dòng. Có ${errorCount} dòng dữ liệu chưa hợp lệ.`);
        } else {
          message.success(`Đã đọc và xác thực thành công ${parsed.length} dòng dữ liệu.`);
        }
      } catch (err: any) {
        message.error('Không thể đọc file Excel: ' + (err.message || 'Lỗi không xác định'));
      }
    };
    reader.readAsArrayBuffer(file);
    return false; // Prevent default upload
  };

  // Tải danh sách dòng lỗi ra file Excel
  const handleDownloadErrorRows = () => {
    const errorRows = parsedRows.filter((r) => !r.isValid);
    if (errorRows.length === 0) {
      message.info('Không có dòng lỗi nào.');
      return;
    }

    const exportData = errorRows.map((r) => ({
      'Dòng Excel': r.rowIndex,
      StudentID: r.studentId,
      StudentName: r.studentName,
      'Chuyên cần': r.attendanceScore ?? '',
      'Giữa kỳ': r.midtermScore ?? '',
      'Cuối kỳ': r.finalScore ?? '',
      'Lý do lỗi': r.errors.join('; '),
    }));

    const ws = XLSX.utils.json_to_sheet(exportData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'DanhSachLoi');
    XLSX.writeFile(wb, `Danh_sach_dong_loi_${uploadedFileName || 'import'}.xlsx`);
    message.success('Đã tải xuống danh sách dòng lỗi.');
  };

  // Thực hiện Import điểm vào Backend
  const handleExecuteImport = async () => {
    const validRows = parsedRows.filter((r) => r.isValid);
    if (validRows.length === 0) {
      message.error('Không có dòng dữ liệu hợp lệ nào để nhập.');
      return;
    }

    setIsImporting(true);
    setImportProgress({ current: 0, total: validRows.length });

    let successCount = 0;
    let failCount = 0;
    const failedStudentIds: number[] = [];

    for (let idx = 0; idx < validRows.length; idx++) {
      const row = validRows[idx];
      setImportProgress({ current: idx + 1, total: validRows.length });

      // Find existing GradeDTO for this student + subject + semester
      const existingGrade = grades.find(
        (g) => g.studentId === row.studentId && g.subjectCode === importSubject && g.semester === importSemester
      );

      try {
        if (existingGrade) {
          // Update existing grade via PUT /api/grades/{id}
          await gradeApi.update(existingGrade.id, {
            attendanceScore: row.attendanceScore,
            midtermScore: row.midtermScore,
            finalScore: row.finalScore,
          });
          successCount++;
        } else {
          // If grade doesn't exist yet, try to create via POST /api/grades
          await gradeApi.create({
            studentId: row.studentId,
            subjectCode: importSubject,
            semester: importSemester,
            attendanceScore: row.attendanceScore,
            midtermScore: row.midtermScore,
            finalScore: row.finalScore,
          });
          successCount++;
        }
      } catch (err) {
        failCount++;
        failedStudentIds.push(row.studentId);
      }
    }

    setIsImporting(false);
    setImportProgress(null);

    // Refresh class grades
    queryClient.invalidateQueries({ queryKey: ['classGrades', selectedClassId] });

    if (failCount === 0) {
      Modal.success({
        title: 'Nhập điểm hoàn tất',
        content: `Đã cập nhật thành công điểm cho toàn bộ ${successCount} học sinh vào hệ thống.`,
        okText: 'Xem bảng điểm ngay',
        onOk: () => {
          setSelectedSubject(importSubject);
          setSelectedSemester(importSemester);
          setActiveTab('bySubject');
          setParsedRows([]);
          setUploadedFileName('');
        },
      });
    } else {
      Modal.warning({
        title: 'Nhập điểm hoàn tất một phần',
        content: `Cập nhật thành công ${successCount} học sinh. Có ${failCount} học sinh bị lỗi (Mã HS: ${failedStudentIds.join(', ')}).`,
        okText: 'Đóng',
      });
    }
  };

  // Helper renderers
  const renderLetterGradeTag = (grade: string | null) => {
    if (!grade) return <Text type="secondary">—</Text>;
    let color = 'default';
    if (grade.startsWith('A')) color = 'success';
    else if (grade.startsWith('B')) color = 'processing';
    else if (grade.startsWith('C')) color = 'warning';
    else if (grade.startsWith('D') || grade.startsWith('F')) color = 'error';
    return (
      <Tag color={color} style={{ fontWeight: 600, minWidth: 28, textAlign: 'center' }}>
        {grade}
      </Tag>
    );
  };

  const formatScore = (val: number | null | undefined) => {
    if (val === null || val === undefined) return <Text type="secondary">—</Text>;
    return (
      <span style={{ fontWeight: 600, color: val < 5.0 ? '#EF4444' : val >= 8.0 ? '#10B981' : '#0F172A' }}>
        {val.toFixed(1)}
      </span>
    );
  };

  const formatAverageScore = (val: number | null | undefined) => {
    if (val === null || val === undefined) return <Text type="secondary">—</Text>;
    return (
      <span
        style={{
          fontSize: 13,
          fontWeight: 700,
          color: val >= 8.0 ? '#10B981' : val < 5.0 ? '#EF4444' : '#2563EB',
        }}
      >
        {val.toFixed(2)}
      </span>
    );
  };

  // ==========================================
  // TABLE COLUMNS CONFIGURATION
  // ==========================================

  // Tab 1: Tổng quan học sinh Columns
  const overviewColumns: any[] = [
    {
      title: 'STT',
      key: 'stt',
      width: 55,
      align: 'center' as const,
      render: (_: any, __: any, index: number) => index + 1,
      fixed: 'left',
    },
    {
      title: 'Mã HS',
      dataIndex: 'studentId',
      key: 'studentId',
      width: 80,
      align: 'center' as const,
      fixed: 'left',
      render: (id: number) => <Tag color="blue">#{id}</Tag>,
      sorter: (a: any, b: any) => a.studentId - b.studentId,
    },
    {
      title: 'Học sinh',
      key: 'studentName',
      width: 180,
      fixed: 'left',
      render: (_: any, r: any) => (
        <Space size={6}>
          <UserOutlined style={{ color: '#2563EB' }} />
          <Button
            type="link"
            style={{ padding: 0, fontWeight: 600, color: '#0F172A' }}
            onClick={() => handleOpenStudentDrawer(r.studentId)}
          >
            {r.studentName}
          </Button>
        </Space>
      ),
      sorter: (a: any, b: any) => a.studentName.localeCompare(b.studentName, 'vi'),
    },
    // Dynamic Columns for each subject: ONLY show Điểm TB
    ...subjects.map((subj) => ({
      title: subj.name,
      key: `subj_${subj.code}`,
      width: 105,
      align: 'center' as const,
      render: (_: any, r: any) => {
        const val = r.subjectAverages[subj.code];
        return formatAverageScore(val);
      },
      sorter: (a: any, b: any) => (a.subjectAverages[subj.code] || 0) - (b.subjectAverages[subj.code] || 0),
    })),
    {
      title: 'Điểm TB',
      dataIndex: 'overallAverage',
      key: 'overallAverage',
      width: 100,
      align: 'center' as const,
      fixed: 'right',
      render: (val: number | null) => (
        <Tag color={val && val >= 8.0 ? 'success' : val && val < 5 ? 'error' : 'blue'} style={{ fontWeight: 700, fontSize: 13 }}>
          {val !== null ? val.toFixed(2) : '—'}
        </Tag>
      ),
      sorter: (a: any, b: any) => (a.overallAverage || 0) - (b.overallAverage || 0),
    },
    {
      title: 'GPA',
      dataIndex: 'overallGpa',
      key: 'overallGpa',
      width: 85,
      align: 'center' as const,
      fixed: 'right',
      render: (val: number | null) => (
        <span style={{ fontWeight: 700, color: '#475569' }}>
          {val !== null ? val.toFixed(2) : '—'}
        </span>
      ),
      sorter: (a: any, b: any) => (a.overallGpa || 0) - (b.overallGpa || 0),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 90,
      align: 'center' as const,
      fixed: 'right',
      render: (_: any, r: any) => (
        <Button
          type="primary"
          size="small"
          ghost
          icon={<EyeOutlined />}
          onClick={() => handleOpenStudentDrawer(r.studentId)}
        >
          Chi tiết
        </Button>
      ),
    },
  ];

  // Tab 2: Theo Môn Columns
  const subjectColumns = [
    {
      title: 'STT',
      key: 'stt',
      width: 55,
      align: 'center' as const,
      render: (_: any, __: any, index: number) => index + 1,
    },
    {
      title: 'Mã HS',
      dataIndex: 'studentId',
      key: 'studentId',
      width: 85,
      align: 'center' as const,
      render: (id: number) => <Tag color="blue">#{id}</Tag>,
      sorter: (a: GradeDTO, b: GradeDTO) => a.studentId - b.studentId,
    },
    {
      title: 'Học sinh',
      key: 'studentName',
      width: 200,
      render: (_: any, r: GradeDTO) => (
        <Space size={6}>
          <UserOutlined style={{ color: '#2563EB' }} />
          <Button
            type="link"
            style={{ padding: 0, fontWeight: 600, color: '#0F172A' }}
            onClick={() => handleOpenStudentDrawer(r.studentId)}
          >
            {r.studentName}
          </Button>
        </Space>
      ),
      sorter: (a: GradeDTO, b: GradeDTO) => a.studentName.localeCompare(b.studentName, 'vi'),
    },
    {
      title: 'Chuyên cần (10%)',
      dataIndex: 'attendanceScore',
      key: 'attendanceScore',
      width: 140,
      align: 'center' as const,
      render: (val: number | null) => formatScore(val),
    },
    {
      title: 'Giữa kỳ (40%)',
      dataIndex: 'midtermScore',
      key: 'midtermScore',
      width: 130,
      align: 'center' as const,
      render: (val: number | null) => formatScore(val),
    },
    {
      title: 'Cuối kỳ (50%)',
      dataIndex: 'finalScore',
      key: 'finalScore',
      width: 130,
      align: 'center' as const,
      render: (val: number | null) => formatScore(val),
    },
    {
      title: 'Điểm TB',
      dataIndex: 'averageScore',
      key: 'averageScore',
      width: 110,
      align: 'center' as const,
      render: (val: number | null) => formatAverageScore(val),
      sorter: (a: GradeDTO, b: GradeDTO) => (a.averageScore || 0) - (b.averageScore || 0),
    },
    {
      title: 'Điểm chữ',
      dataIndex: 'letterGrade',
      key: 'letterGrade',
      width: 100,
      align: 'center' as const,
      render: (letter: string | null) => renderLetterGradeTag(letter),
    },
    {
      title: 'GPA',
      dataIndex: 'gpa4',
      key: 'gpa4',
      width: 90,
      align: 'center' as const,
      render: (val: number | null) => (val !== null && val !== undefined ? val.toFixed(2) : '—'),
      sorter: (a: GradeDTO, b: GradeDTO) => (a.gpa4 || 0) - (b.gpa4 || 0),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 130,
      align: 'center' as const,
      render: (_: any, record: GradeDTO) => (
        <Space size={6}>
          <Button
            type="primary"
            size="small"
            ghost
            icon={<EditOutlined />}
            onClick={() => handleOpenEdit(record)}
            style={{ borderRadius: 6 }}
          >
            Sửa điểm
          </Button>
          <Button
            type="text"
            size="small"
            icon={<EyeOutlined />}
            onClick={() => handleOpenStudentDrawer(record.studentId)}
            title="Xem hồ sơ học sinh"
          />
        </Space>
      ),
    },
  ];

  // Tab 3: Excel Preview Columns
  const previewColumns = [
    {
      title: 'Dòng',
      dataIndex: 'rowIndex',
      key: 'rowIndex',
      width: 60,
      align: 'center' as const,
    },
    {
      title: 'StudentID',
      dataIndex: 'studentId',
      key: 'studentId',
      width: 95,
      align: 'center' as const,
      render: (id: number) => <Tag color="blue">#{id}</Tag>,
    },
    {
      title: 'Tên học sinh',
      dataIndex: 'studentName',
      key: 'studentName',
      width: 180,
      render: (name: string) => <strong>{name}</strong>,
    },
    {
      title: 'Chuyên cần',
      dataIndex: 'attendanceScore',
      key: 'attendanceScore',
      width: 110,
      align: 'center' as const,
      render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
    },
    {
      title: 'Giữa kỳ',
      dataIndex: 'midtermScore',
      key: 'midtermScore',
      width: 100,
      align: 'center' as const,
      render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
    },
    {
      title: 'Cuối kỳ',
      dataIndex: 'finalScore',
      key: 'finalScore',
      width: 100,
      align: 'center' as const,
      render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
    },
    {
      title: 'TB dự kiến',
      dataIndex: 'predictedAverage',
      key: 'predictedAverage',
      width: 110,
      align: 'center' as const,
      render: (val: number | null) =>
        val !== null ? (
          <Tag color="cyan" style={{ fontWeight: 600 }}>
            {val.toFixed(1)}
          </Tag>
        ) : (
          '—'
        ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isValid',
      key: 'isValid',
      width: 110,
      align: 'center' as const,
      render: (isValid: boolean) =>
        isValid ? (
          <Tag color="success" icon={<CheckCircleOutlined />}>
            HỢP LỆ
          </Tag>
        ) : (
          <Tag color="error" icon={<CloseCircleOutlined />}>
            LỖI
          </Tag>
        ),
    },
    {
      title: 'Chi tiết lỗi / Ghi chú',
      dataIndex: 'errors',
      key: 'errors',
      render: (errors: string[]) =>
        errors.length > 0 ? (
          <span style={{ color: '#DC2626', fontSize: 12 }}>{errors.join('; ')}</span>
        ) : (
          <span style={{ color: '#16A34A', fontSize: 12 }}>Đã sẵn sàng cập nhật</span>
        ),
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
              Quản lý Bảng điểm Học sinh
            </Title>
          </div>

          <Space size={12}>
            {/* Global Class Selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Text strong style={{ fontSize: 13 }}>
                Lớp học:
              </Text>
              <Select
                loading={isLoadingClasses}
                value={selectedClassId}
                onChange={(val) => setSelectedClassId(val)}
                placeholder="Chọn lớp"
                style={{ width: 150 }}
                options={classes.map((c) => ({
                  value: c.id,
                  label: `Lớp ${c.className}`,
                }))}
              />
            </div>

            <Button icon={<RedoOutlined spin={isRefetchingGrades} />} onClick={() => refetchGrades()}>
              Tải lại
            </Button>
          </Space>
        </div>
      </div>

      {/* Main Container Card with 3 Tabs */}
      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
        <Tabs
          activeKey={activeTab}
          onChange={(key) => setActiveTab(key)}
          type="line"
          size="middle"
          items={[
            // ==========================================
            // TAB 1: TỔNG QUAN HỌC SINH
            // ==========================================
            {
              key: 'overview',
              label: (
                <Space size={6}>
                  <AppstoreOutlined />
                  <span>Tổng quan Học sinh ({studentOverviewData.length})</span>
                </Space>
              ),
              children: (
                <div>
                  {/* Toolbar */}
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
                        placeholder="Tìm học sinh theo tên hoặc mã..."
                        prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                        style={{ width: 280 }}
                        allowClear
                      />
                      <Tag color="processing" style={{ padding: '4px 10px', fontSize: 12 }}>
                        Nguyên tắc: 1 học sinh = 1 dòng • Chỉ hiển thị Điểm TB các môn
                      </Tag>
                    </Space>

                    <Text type="secondary">
                      Hiển thị: <strong>{studentOverviewData.length} học sinh</strong>
                    </Text>
                  </div>

                  {/* Table State */}
                  {isLoadingGrades ? (
                    <div style={{ textAlign: 'center', padding: '80px 0' }}>
                      <Spin size="large" tip="Đang tổng hợp dữ liệu bảng điểm..." />
                    </div>
                  ) : gradesError ? (
                    <Alert
                      type="error"
                      message="Lỗi kết nối bảng điểm"
                      description="Không thể tải bảng điểm từ máy chủ Backend."
                      showIcon
                    />
                  ) : studentOverviewData.length === 0 ? (
                    <Empty
                      image={Empty.PRESENTED_IMAGE_SIMPLE}
                      description="Chưa có dữ liệu bảng điểm cho lớp này"
                      style={{ padding: '40px 0' }}
                    />
                  ) : (
                    <Table
                      columns={overviewColumns}
                      dataSource={studentOverviewData}
                      rowKey="studentId"
                      bordered
                      size="middle"
                      pagination={{ pageSize: 25, showSizeChanger: true, pageSizeOptions: ['25', '50', '100'] }}
                      scroll={{ x: Math.max(900, 320 + subjects.length * 105 + 280) }}
                    />
                  )}
                </div>
              ),
            },

            // ==========================================
            // TAB 2: THEO MÔN
            // ==========================================
            {
              key: 'bySubject',
              label: (
                <Space size={6}>
                  <TableOutlined />
                  <span>Theo Môn & Học kỳ ({subjectGradesData.length})</span>
                </Space>
              ),
              children: (
                <div>
                  {/* Filter Toolbar */}
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: 12,
                      marginBottom: 16,
                      background: '#F8FAFC',
                      padding: '12px 16px',
                      borderRadius: 12,
                      border: '1px solid #E2E8F0',
                    }}
                  >
                    <Space wrap size={16}>
                      {/* Subject Selector */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <Text strong style={{ fontSize: 13 }}>
                          Môn:
                        </Text>
                        <Select
                          value={selectedSubject}
                          onChange={(val) => setSelectedSubject(val)}
                          style={{ width: 170 }}
                          options={subjects.map((s) => ({
                            value: s.code,
                            label: s.name,
                          }))}
                        />
                      </div>

                      {/* Semester Selector */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <Text strong style={{ fontSize: 13 }}>
                          Học kỳ:
                        </Text>
                        <Select
                          value={selectedSemester}
                          onChange={(val) => setSelectedSemester(val)}
                          style={{ width: 130 }}
                          options={[
                            { value: 1, label: 'Học kỳ 1' },
                            { value: 2, label: 'Học kỳ 2' },
                          ]}
                        />
                      </div>

                      {/* Student Search */}
                      <Input
                        placeholder="Tìm học sinh..."
                        prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                        style={{ width: 200 }}
                        allowClear
                      />
                    </Space>

                    <Text type="secondary">
                      Sĩ số: <strong>{subjectGradesData.length} học sinh</strong>
                    </Text>
                  </div>

                  {/* Table State */}
                  {isLoadingGrades ? (
                    <div style={{ textAlign: 'center', padding: '80px 0' }}>
                      <Spin size="large" tip="Đang tải điểm môn học..." />
                    </div>
                  ) : subjectGradesData.length === 0 ? (
                    <Empty
                      image={Empty.PRESENTED_IMAGE_SIMPLE}
                      description={`Chưa có dữ liệu điểm môn ${
                        subjects.find((s) => s.code === selectedSubject)?.name || selectedSubject
                      } - HK${selectedSemester}`}
                      style={{ padding: '40px 0' }}
                    />
                  ) : (
                    <Table
                      columns={subjectColumns}
                      dataSource={subjectGradesData}
                      rowKey="id"
                      bordered
                      size="middle"
                      pagination={{ pageSize: 25, showSizeChanger: true, pageSizeOptions: ['25', '50'] }}
                      scroll={{ x: 1000 }}
                    />
                  )}
                </div>
              ),
            },

            // ==========================================
            // TAB 3: NHẬP ĐIỂM TỪ EXCEL
            // ==========================================
            {
              key: 'import',
              label: (
                <Space size={6}>
                  <FileExcelOutlined />
                  <span>Nhập điểm từ Excel</span>
                </Space>
              ),
              children: (
                <div>
                  {/* Step 1: Config Area */}
                  <Card
                    size="small"
                    style={{
                      background: '#F8FAFC',
                      borderRadius: 12,
                      border: '1px solid #E2E8F0',
                      marginBottom: 20,
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
                      <Space wrap size={16}>
                        {/* Target Class */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <Text strong style={{ fontSize: 13 }}>
                            Lớp cần nhập:
                          </Text>
                          <Select
                            value={importClassId}
                            onChange={(val) => {
                              setImportClassId(val);
                              setSelectedClassId(val);
                              setParsedRows([]);
                              setUploadedFileName('');
                            }}
                            style={{ width: 140 }}
                            options={classes.map((c) => ({
                              value: c.id,
                              label: `Lớp ${c.className}`,
                            }))}
                          />
                        </div>

                        {/* Target Subject */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <Text strong style={{ fontSize: 13 }}>
                            Môn học:
                          </Text>
                          <Select
                            value={importSubject}
                            onChange={(val) => {
                              setImportSubject(val);
                              setParsedRows([]);
                            }}
                            style={{ width: 170 }}
                            options={subjects.map((s) => ({
                              value: s.code,
                              label: s.name,
                            }))}
                          />
                        </div>

                        {/* Target Semester */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <Text strong style={{ fontSize: 13 }}>
                            Học kỳ:
                          </Text>
                          <Select
                            value={importSemester}
                            onChange={(val) => {
                              setImportSemester(val);
                              setParsedRows([]);
                            }}
                            style={{ width: 120 }}
                            options={[
                              { value: 1, label: 'Học kỳ 1' },
                              { value: 2, label: 'Học kỳ 2' },
                            ]}
                          />
                        </div>
                      </Space>

                      {/* Button Download Templates */}
                      <Space wrap size={10}>
                        <Button
                          type="default"
                          icon={<DownloadOutlined />}
                          onClick={handleDownloadTemplate}
                          style={{ fontWeight: 500 }}
                        >
                          Tải file Excel mẫu trống
                        </Button>
                        <Button
                          type="primary"
                          icon={<DownloadOutlined />}
                          onClick={handleDownloadFilledSample}
                          style={{ fontWeight: 500, backgroundColor: '#059669' }}
                        >
                          Tải file có sẵn điểm hợp lệ (25 HS)
                        </Button>
                      </Space>
                    </div>
                  </Card>

                  {/* Step 2: Upload Area */}
                  <div style={{ marginBottom: 20 }}>
                    <Upload.Dragger
                      accept=".xlsx,.xls"
                      beforeUpload={handleFileUpload}
                      showUploadList={false}
                      style={{
                        padding: '24px 0',
                        backgroundColor: '#fff',
                        borderRadius: 12,
                        border: '2px dashed #93C5FD',
                      }}
                    >
                      <p className="ant-upload-drag-icon">
                        <InboxOutlined style={{ fontSize: 48, color: '#2563EB' }} />
                      </p>
                      <p className="ant-upload-text" style={{ fontSize: 15, fontWeight: 600, color: '#0F172A' }}>
                        Kéo thả file Excel (.xlsx, .xls) vào đây hoặc bấm để chọn tệp
                      </p>
                      <p className="ant-upload-hint" style={{ color: '#64748B', fontSize: 13 }}>
                        Hệ thống dùng <strong>StudentID</strong> để tự động mapping học sinh trong lớp. File yêu cầu các
                        cột: <code>StudentID</code>, <code>StudentName</code>, <code>Chuyên cần</code>, <code>Giữa kỳ</code>,{' '}
                        <code>Cuối kỳ</code>.
                      </p>
                    </Upload.Dragger>
                  </div>

                  {/* Step 3: Validation & Preview */}
                  {parsedRows.length > 0 && (
                    <div>
                      {/* Summary Row */}
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                          flexWrap: 'wrap',
                          gap: 16,
                          marginBottom: 16,
                        }}
                      >
                        <Space size={16}>
                          <Statistic title="Tổng số dòng" value={parsedRows.length} valueStyle={{ fontSize: 18 }} />
                          <Statistic
                            title="Hợp lệ"
                            value={parsedRows.filter((r) => r.isValid).length}
                            valueStyle={{ fontSize: 18, color: '#16A34A' }}
                          />
                          <Statistic
                            title="Lỗi dữ liệu"
                            value={parsedRows.filter((r) => !r.isValid).length}
                            valueStyle={{
                              fontSize: 18,
                              color: parsedRows.some((r) => !r.isValid) ? '#DC2626' : '#64748B',
                            }}
                          />
                        </Space>

                        <Space size={10}>
                          {parsedRows.some((r) => !r.isValid) && (
                            <Button danger icon={<DownloadOutlined />} onClick={handleDownloadErrorRows}>
                              Tải danh sách dòng lỗi (.xlsx)
                            </Button>
                          )}

                          <Button
                            type="primary"
                            size="large"
                            icon={<UploadOutlined />}
                            disabled={parsedRows.some((r) => !r.isValid) || parsedRows.length === 0}
                            loading={isImporting}
                            onClick={handleExecuteImport}
                            style={{
                              backgroundColor: parsedRows.some((r) => !r.isValid) ? undefined : '#2563EB',
                              fontWeight: 600,
                            }}
                          >
                            Xác nhận Nhập điểm ({parsedRows.filter((r) => r.isValid).length} học sinh)
                          </Button>
                        </Space>
                      </div>

                      {/* Progress Bar while importing */}
                      {isImporting && importProgress && (
                        <div style={{ marginBottom: 16 }}>
                          <Text strong>
                            Đang xử lý cập nhật điểm: {importProgress.current} / {importProgress.total} học sinh...
                          </Text>
                          <Progress
                            percent={Math.round((importProgress.current / importProgress.total) * 100)}
                            status="active"
                          />
                        </div>
                      )}

                      {/* Status Alert */}
                      {parsedRows.some((r) => !r.isValid) ? (
                        <Alert
                          type="error"
                          showIcon
                          message="Tệp chứa dữ liệu không hợp lệ"
                          description="Hệ thống từ chối import khi còn dòng dữ liệu lỗi. Vui lòng kiểm tra các dòng bị báo đỏ bên dưới, sửa lại file và tải lại."
                          style={{ marginBottom: 16 }}
                        />
                      ) : (
                        <Alert
                          type="success"
                          showIcon
                          message="Dữ liệu kiểm tra hoàn toàn hợp lệ"
                          description={`Toàn bộ ${parsedRows.length} dòng điểm đã sẵn sàng để lưu vào hệ thống cho môn ${
                            subjects.find((s) => s.code === importSubject)?.name || importSubject
                          } (Học kỳ ${importSemester}).`}
                          style={{ marginBottom: 16 }}
                        />
                      )}

                      {/* Preview Table */}
                      <Table
                        columns={previewColumns}
                        dataSource={parsedRows}
                        rowKey="rowIndex"
                        size="small"
                        bordered
                        pagination={{ pageSize: 15 }}
                        scroll={{ x: 950 }}
                        rowClassName={(record) => (!record.isValid ? 'error-table-row' : '')}
                      />
                    </div>
                  )}
                </div>
              ),
            },
          ]}
        />
      </Card>

      {/* Modal: Nhập / Sửa điểm (Single) */}
      <Modal
        title={
          <Space>
            <EditOutlined style={{ color: '#2563EB' }} />
            <span>Nhập & Cập nhật điểm học sinh</span>
          </Space>
        }
        open={isEditModalOpen}
        onCancel={() => {
          setIsEditModalOpen(false);
          setEditingGrade(null);
          editForm.resetFields();
        }}
        onOk={handleSaveEdit}
        okText="Lưu điểm"
        confirmLoading={updateMutation.isPending}
        cancelText="Hủy bỏ"
      >
        {editingGrade && (
          <div>
            <div
              style={{
                background: '#F8FAFC',
                padding: '12px 16px',
                borderRadius: 8,
                marginBottom: 16,
                border: '1px solid #E2E8F0',
              }}
            >
              <div style={{ fontWeight: 600, fontSize: 15, color: '#0F172A' }}>
                {editingGrade.studentName} <Tag color="blue">#{editingGrade.studentId}</Tag>
              </div>
              <div style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>
                Môn: <strong>{editingGrade.subjectName || editingGrade.subjectCode}</strong> • Lớp: {editingGrade.className} •
                Học kỳ: {editingGrade.semester || 1}
              </div>
            </div>

            <Form form={editForm} layout="vertical">
              <Form.Item
                name="attendanceScore"
                label="Điểm chuyên cần (10%)"
                rules={[
                  { type: 'number', min: 0, max: 10, message: 'Điểm phải từ 0 đến 10' },
                ]}
              >
                <InputNumber min={0} max={10} step={0.1} style={{ width: '100%' }} placeholder="Nhập điểm (0 - 10)" />
              </Form.Item>

              <Form.Item
                name="midtermScore"
                label="Điểm giữa kỳ (40%)"
                rules={[
                  { type: 'number', min: 0, max: 10, message: 'Điểm phải từ 0 đến 10' },
                ]}
              >
                <InputNumber min={0} max={10} step={0.1} style={{ width: '100%' }} placeholder="Nhập điểm (0 - 10)" />
              </Form.Item>

              <Form.Item
                name="finalScore"
                label="Điểm cuối kỳ (50%)"
                rules={[
                  { type: 'number', min: 0, max: 10, message: 'Điểm phải từ 0 đến 10' },
                ]}
              >
                <InputNumber min={0} max={10} step={0.1} style={{ width: '100%' }} placeholder="Nhập điểm (0 - 10)" />
              </Form.Item>

              <Text type="secondary" style={{ fontSize: 12 }}>
                * Công thức Điểm TB Backend: <code>(Chuyên cần + Giữa kỳ × 2 + Cuối kỳ × 3) / 6</code>. Điểm chữ và GPA hệ 4 sẽ
                được Backend tự động tính toán lại.
              </Text>
            </Form>
          </div>
        )}
      </Modal>

      {/* Drawer: Bảng điểm chi tiết của 1 Học sinh */}
      <Drawer
        title={
          <Space>
            <BookOutlined style={{ color: '#2563EB' }} />
            <span>
              Hồ sơ bảng điểm học sinh: <strong>{selectedStudentInDrawer?.studentName}</strong>
            </span>
          </Space>
        }
        width={720}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
      >
        {selectedStudentInDrawer && (
          <Space direction="vertical" size={18} style={{ width: '100%' }}>
            {/* Header info */}
            <div
              style={{
                background: '#F8FAFC',
                padding: '16px',
                borderRadius: 12,
                border: '1px solid #E2E8F0',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: 12,
              }}
            >
              <div>
                <Title level={5} style={{ margin: 0, color: '#0F172A' }}>
                  {selectedStudentInDrawer.studentName}
                </Title>
                <div style={{ marginTop: 4, display: 'flex', gap: 8, alignItems: 'center' }}>
                  <Tag color="blue">Mã HS: #{selectedStudentInDrawer.studentId}</Tag>
                  <Tag color="cyan">Lớp: {selectedStudentInDrawer.className}</Tag>
                  <Tag color="default">Năm học: 2025-2026</Tag>
                </div>
              </div>

              <Space size={16}>
                <Statistic
                  title="Điểm TB tất cả môn"
                  value={drawerStudentStats.avgScore}
                  valueStyle={{ fontSize: 20, fontWeight: 700, color: '#2563EB' }}
                />
                <Statistic
                  title="GPA Tích lũy"
                  value={drawerStudentStats.gpa}
                  valueStyle={{ fontSize: 20, fontWeight: 700, color: '#059669' }}
                />
              </Space>
            </div>

            {/* Semester Filter in Drawer */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text strong style={{ fontSize: 14 }}>
                Danh sách bảng điểm các môn ({studentGradesInDrawer.length} bản ghi):
              </Text>

              <Select
                value={drawerSemesterFilter}
                onChange={(val) => setDrawerSemesterFilter(val)}
                style={{ width: 140 }}
                options={[
                  { value: 'ALL', label: 'Tất cả học kỳ' },
                  { value: 1, label: 'Học kỳ 1' },
                  { value: 2, label: 'Học kỳ 2' },
                ]}
              />
            </div>

            {/* Subject detail list */}
            {studentGradesInDrawer.length === 0 ? (
              <Empty description="Chưa có bản ghi điểm nào cho học sinh này" />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {studentGradesInDrawer.map((g) => (
                  <Card
                    key={g.id}
                    size="small"
                    style={{
                      borderRadius: 10,
                      border: '1px solid #E2E8F0',
                      boxShadow: '0 1px 4px rgba(0,0,0,0.02)',
                    }}
                    title={
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Space size={8}>
                          <Text strong style={{ fontSize: 14, color: '#0F172A' }}>
                            Môn: {g.subjectName || g.subjectCode}
                          </Text>
                          <Tag color="geekblue" style={{ fontSize: 11 }}>
                            Học kỳ {g.semester || 1}
                          </Tag>
                        </Space>
                        <Button
                          type="text"
                          size="small"
                          icon={<EditOutlined style={{ color: '#2563EB' }} />}
                          onClick={() => handleOpenEdit(g)}
                        >
                          Sửa điểm
                        </Button>
                      </div>
                    }
                  >
                    <Row gutter={[12, 12]}>
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Chuyên cần (10%)</div>
                        <div style={{ fontSize: 15, fontWeight: 600 }}>
                          {g.attendanceScore !== null ? g.attendanceScore.toFixed(1) : '—'}
                        </div>
                      </Col>
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Giữa kỳ (40%)</div>
                        <div style={{ fontSize: 15, fontWeight: 600 }}>
                          {g.midtermScore !== null ? g.midtermScore.toFixed(1) : '—'}
                        </div>
                      </Col>
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Cuối kỳ (50%)</div>
                        <div style={{ fontSize: 15, fontWeight: 600 }}>
                          {g.finalScore !== null ? g.finalScore.toFixed(1) : '—'}
                        </div>
                      </Col>
                    </Row>

                    <Divider style={{ margin: '10px 0' }} />

                    <Row gutter={[12, 12]} align="middle">
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Điểm TB môn</div>
                        <div
                          style={{
                            fontSize: 16,
                            fontWeight: 700,
                            color:
                              g.averageScore && g.averageScore >= 8.0
                                ? '#10B981'
                                : g.averageScore && g.averageScore < 5.0
                                ? '#EF4444'
                                : '#2563EB',
                          }}
                        >
                          {g.averageScore !== null ? g.averageScore.toFixed(2) : '—'}
                        </div>
                      </Col>
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Điểm chữ</div>
                        <div>{renderLetterGradeTag(g.letterGrade)}</div>
                      </Col>
                      <Col span={8}>
                        <div style={{ fontSize: 12, color: '#64748B' }}>Thang 4 (GPA)</div>
                        <div style={{ fontSize: 15, fontWeight: 700, color: '#334155' }}>
                          {g.gpa4 !== null ? g.gpa4.toFixed(2) : '—'}
                        </div>
                      </Col>
                    </Row>
                  </Card>
                ))}
              </div>
            )}
          </Space>
        )}
      </Drawer>
    </div>
  );
};
