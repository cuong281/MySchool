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
  Radio,
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
import { subjectApi } from '../../api/subjectApi';
import type { GradeDTO, GradeBatchImportRequest } from '../../types/grade';

const { Title, Text } = Typography;

interface ParsedExcelRow {
  rowIndex: number;
  studentId: number;
  studentCode?: string;
  studentName: string;
  subjectCode: string;
  subjectName?: string;
  semester: number;
  attendanceScore: number | null;
  midtermScore: number | null;
  finalScore: number | null;
  score: number | null; // For exam mode
  predictedAverage: number | null;
  isUpdate: boolean;    // true if Grade already exists, false if new
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
  const [importMode, setImportMode] = useState<'ALL' | 'EXAM'>('EXAM');
  const [examType, setExamType] = useState<'MIDTERM' | 'FINAL'>('MIDTERM');
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

  // Fetch all subjects from backend
  const { data: allSubjects = [] } = useQuery({
    queryKey: ['allSubjects'],
    queryFn: () => subjectApi.getAll(),
  });

  // Fetch all students in the selected import class
  const { data: classStudents = [] } = useQuery({
    queryKey: ['classStudents', importClassId],
    queryFn: () => classApi.getStudents(importClassId!),
    enabled: importClassId !== undefined && importClassId > 0,
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
    const map = new Map<number, { studentId: number; studentCode?: string; studentName: string; className: string }>();
    grades.forEach((g) => {
      if (g.studentId && !map.has(g.studentId)) {
        map.set(g.studentId, {
          studentId: g.studentId,
          studentCode: (g as any).studentCode,
          studentName: g.studentName,
          className: g.className,
        });
      }
    });
    return Array.from(map.values()).sort((a, b) => a.studentId - b.studentId);
  }, [grades]);

  // Available subjects (using backend active subjects or fallback to subjects from grades)
  const availableSubjects = useMemo(() => {
    if (allSubjects && allSubjects.length > 0) {
      return allSubjects.map((s) => ({ code: s.subjectCode, name: s.subjectName }));
    }
    return subjects;
  }, [allSubjects, subjects]);

  // Effective students of the import class (using real class students roster or fallback to grades)
  const effectiveStudents = useMemo(() => {
    if (classStudents && classStudents.length > 0) {
      return classStudents.map((s) => ({
        studentId: s.id,
        studentCode: s.studentCode,
        studentName: s.fullName,
        className: s.className || '',
      }));
    }
    return studentsInClass.map((s) => ({
      studentId: s.studentId,
      studentCode: s.studentCode,
      studentName: s.studentName,
      className: s.className,
    }));
  }, [classStudents, studentsInClass]);

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

  // ==========================================
  // TAB 3: EXCEL IMPORT LOGIC (2 CHẾ ĐỘ: NHẬP TOÀN BỘ & NHẬP ĐIỂM THI)
  // ==========================================

  // Tải file mẫu Excel theo chế độ được chọn
  const handleDownloadTemplate = () => {
    const currentClass = classes.find((c) => c.id === importClassId);
    const className = currentClass ? currentClass.className : 'Class';
    const subjObj = availableSubjects.find((s) => s.code === importSubject);
    const subjName = subjObj?.name || importSubject;

    if (importMode === 'EXAM') {
      // Chế độ B: Nhập điểm thi (StudentID | StudentName | Score)
      const templateData = effectiveStudents.map((s, idx) => ({
        STT: idx + 1,
        StudentID: s.studentId,
        StudentName: s.studentName,
        Score: '',
      }));

      const ws = XLSX.utils.json_to_sheet(templateData);
      ws['!cols'] = [
        { wch: 6 },  // STT
        { wch: 12 }, // StudentID
        { wch: 25 }, // StudentName
        { wch: 12 }, // Score
      ];

      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'DiemThi');
      const examName = examType === 'MIDTERM' ? 'Giua_Ky' : 'Cuoi_Ky';
      const fileName = `Mau_Diem_Thi_${examName}_Lop_${className}_${subjName}_HK${importSemester}.xlsx`;
      XLSX.writeFile(wb, fileName);
      message.success(`Đã tải xuống file mẫu điểm thi: ${fileName}`);
    } else {
      // Chế độ A: Nhập toàn bộ bảng điểm (StudentID | StudentName | Subject | Semester | Attendance | Midterm | Final)
      const templateData = effectiveStudents.map((s, idx) => ({
        STT: idx + 1,
        StudentID: s.studentId,
        StudentName: s.studentName,
        Subject: importSubject,
        Semester: importSemester,
        Attendance: '',
        Midterm: '',
        Final: '',
      }));

      const ws = XLSX.utils.json_to_sheet(templateData);
      ws['!cols'] = [
        { wch: 6 },  // STT
        { wch: 12 }, // StudentID
        { wch: 25 }, // StudentName
        { wch: 12 }, // Subject
        { wch: 10 }, // Semester
        { wch: 14 }, // Attendance
        { wch: 14 }, // Midterm
        { wch: 14 }, // Final
      ];

      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'BangDiem');
      const fileName = `Mau_Toan_Bo_Diem_Lop_${className}_${subjName}_HK${importSemester}.xlsx`;
      XLSX.writeFile(wb, fileName);
      message.success(`Đã tải xuống file mẫu toàn bộ điểm: ${fileName}`);
    }
  };

  // Tải file mẫu có sẵn dữ liệu hợp lệ để kiểm thử nhanh
  const handleDownloadFilledSample = () => {
    const currentClass = classes.find((c) => c.id === importClassId);
    const className = currentClass ? currentClass.className : 'Class';

    if (importMode === 'EXAM') {
      const sampleScores = [9.0, 8.5, 9.5, 8.0, 7.5, 8.5, 9.0, 9.5, 8.0, 7.0, 8.5, 9.0, 8.0, 8.5, 9.0];
      const students = effectiveStudents.slice(0, 25).map((s, idx) => ({
        STT: idx + 1,
        StudentID: s.studentId,
        StudentName: s.studentName,
        Score: sampleScores[idx % sampleScores.length],
      }));

      const ws = XLSX.utils.json_to_sheet(students);
      ws['!cols'] = [{ wch: 6 }, { wch: 12 }, { wch: 25 }, { wch: 12 }];
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'DiemThi');
      const examName = examType === 'MIDTERM' ? 'Giua_Ky' : 'Cuoi_Ky';
      const fileName = `Mau_Co_Diem_Thi_${examName}_Lop_${className}.xlsx`;
      XLSX.writeFile(wb, fileName);
      message.success(`Đã tải xuống file mẫu có sẵn điểm thi: ${fileName}`);
    } else {
      const sampleGrades = [
        { att: 9.0, mid: 8.5, fin: 9.0 },
        { att: 8.5, mid: 8.0, fin: 8.5 },
        { att: 9.5, mid: 9.0, fin: 9.5 },
        { att: 8.0, mid: 7.5, fin: 8.0 },
        { att: 9.0, mid: 8.5, fin: 9.0 },
      ];
      const students = effectiveStudents.slice(0, 25).map((s, idx) => {
        const g = sampleGrades[idx % sampleGrades.length];
        return {
          STT: idx + 1,
          StudentID: s.studentId,
          StudentName: s.studentName,
          Subject: importSubject,
          Semester: importSemester,
          Attendance: g.att,
          Midterm: g.mid,
          Final: g.fin,
        };
      });

      const ws = XLSX.utils.json_to_sheet(students);
      ws['!cols'] = [{ wch: 6 }, { wch: 12 }, { wch: 25 }, { wch: 12 }, { wch: 10 }, { wch: 14 }, { wch: 14 }, { wch: 14 }];
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'BangDiem');
      const fileName = `Mau_Co_San_Diem_Toan_Bo_Lop_${className}.xlsx`;
      XLSX.writeFile(wb, fileName);
      message.success(`Đã tải xuống file mẫu có sẵn toàn bộ điểm: ${fileName}`);
    }
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

        const findColIndex = (keywords: string[]) => {
          return headerRow.findIndex((col) => keywords.some((kw) => col.includes(kw)));
        };

        const studentIdIdx = findColIndex(['studentid', 'student id', 'mã hs', 'ma hs', 'mã học sinh', 'ma hoc sinh', 'id']);
        const studentNameIdx = findColIndex(['studentname', 'student name', 'tên học sinh', 'ten hoc sinh', 'họ và tên', 'ho va ten', 'tên']);

        if (studentIdIdx === -1) {
          message.error('Không tìm thấy cột StudentID hoặc Mã học sinh trong file Excel');
          return;
        }

        const validStudentIdMap = new Map(effectiveStudents.map((s) => [s.studentId, s]));
        const validStudentCodeMap = new Map(
          effectiveStudents.filter((s) => s.studentCode).map((s) => [s.studentCode!.trim().toUpperCase(), s])
        );

        const seenKeys = new Set<string>();
        const parsed: ParsedExcelRow[] = [];

        if (importMode === 'EXAM') {
          // CHẾ ĐỘ B: NHẬP ĐIỂM THI
          let scoreIdx = findColIndex(['score', 'điểm thi', 'diem thi', 'điểm', 'diem']);
          if (scoreIdx === -1) {
            scoreIdx = examType === 'MIDTERM'
              ? findColIndex(['giữa kỳ', 'giua ky', 'gk', 'midterm'])
              : findColIndex(['cuối kỳ', 'cuoi ky', 'ck', 'final']);
          }

          if (scoreIdx === -1) {
            message.error('Không tìm thấy cột Điểm thi (Score / Điểm / Giữa kỳ / Cuối kỳ) trong file Excel');
            return;
          }

          for (let i = 1; i < rawJson.length; i++) {
            const row = rawJson[i];
            if (!row || row.length === 0 || row.every((c: any) => c === null || c === undefined || c === '')) {
              continue;
            }

            const rawId = row[studentIdIdx];
            const rawName = studentNameIdx !== -1 ? String(row[studentNameIdx] || '').trim() : '';
            const rawScore = row[scoreIdx];

            const errors: string[] = [];
            const studentIdNum = Number(rawId);
            let matchedStudent = !isNaN(studentIdNum) ? validStudentIdMap.get(studentIdNum) : undefined;
            if (!matchedStudent && typeof rawId === 'string') {
              matchedStudent = validStudentCodeMap.get(rawId.trim().toUpperCase());
            }

            if (isNaN(studentIdNum) && !matchedStudent) {
              errors.push(`Mã học sinh '${rawId}' không hợp lệ`);
            } else if (!matchedStudent) {
              errors.push(`Học sinh (Mã: ${rawId}) không thuộc lớp được chọn`);
            } else {
              const dupKey = `${matchedStudent.studentId}_${importSubject}_${importSemester}`;
              if (seenKeys.has(dupKey)) {
                errors.push(`Học sinh ${matchedStudent.studentName} (#${matchedStudent.studentId}) bị trùng lặp trong file`);
              }
              seenKeys.add(dupKey);
            }

            let scoreVal: number | null = null;
            if (rawScore === null || rawScore === undefined || String(rawScore).trim() === '') {
              errors.push('Chưa nhập điểm thi');
            } else {
              const n = Number(rawScore);
              if (isNaN(n) || n < 0 || n > 10) {
                errors.push(`Điểm thi (${rawScore}) phải nằm trong khoảng từ 0 đến 10`);
              } else {
                scoreVal = Math.round(n * 10) / 10;
              }
            }

            const studentId = matchedStudent?.studentId || (isNaN(studentIdNum) ? 0 : studentIdNum);
            const studentName = rawName || matchedStudent?.studentName || `Học sinh #${studentId}`;

            // Check if grade already exists in current grades
            const existingGrade = grades.find(
              (g) => g.studentId === studentId && (g.subjectCode === importSubject || g.subjectName === importSubject) && g.semester === importSemester
            );
            const isUpdate = !!existingGrade;

            parsed.push({
              rowIndex: i + 1,
              studentId,
              studentCode: matchedStudent?.studentCode,
              studentName,
              subjectCode: importSubject,
              subjectName: availableSubjects.find((s) => s.code === importSubject)?.name || importSubject,
              semester: importSemester,
              attendanceScore: existingGrade ? existingGrade.attendanceScore : null,
              midtermScore: examType === 'MIDTERM' ? scoreVal : (existingGrade ? existingGrade.midtermScore : null),
              finalScore: examType === 'FINAL' ? scoreVal : (existingGrade ? existingGrade.finalScore : null),
              score: scoreVal,
              predictedAverage: null,
              isUpdate,
              isValid: errors.length === 0,
              errors,
            });
          }
        } else {
          // CHẾ ĐỘ A: NHẬP TOÀN BỘ BẢNG ĐIỂM
          const attendanceIdx = findColIndex(['chuyên cần', 'chuyen can', 'chuyencan', 'cc', 'attendance']);
          const midtermIdx = findColIndex(['giữa kỳ', 'giua ky', 'giuaky', 'gk', 'midterm']);
          const finalIdx = findColIndex(['cuối kỳ', 'cuoi ky', 'cuoiky', 'ck', 'final']);
          const subjectIdx = findColIndex(['môn', 'mon', 'subject']);
          const semesterIdx = findColIndex(['học kỳ', 'hoc ky', 'semester', 'hk']);

          for (let i = 1; i < rawJson.length; i++) {
            const row = rawJson[i];
            if (!row || row.length === 0 || row.every((c: any) => c === null || c === undefined || c === '')) {
              continue;
            }

            const rawId = row[studentIdIdx];
            const rawName = studentNameIdx !== -1 ? String(row[studentNameIdx] || '').trim() : '';
            const rawAttendance = attendanceIdx !== -1 ? row[attendanceIdx] : null;
            const rawMidterm = midtermIdx !== -1 ? row[midtermIdx] : null;
            const rawFinal = finalIdx !== -1 ? row[finalIdx] : null;
            const rawSubject = subjectIdx !== -1 ? String(row[subjectIdx] || '').trim() : importSubject;
            const rawSemester = semesterIdx !== -1 ? Number(row[semesterIdx]) : importSemester;

            const errors: string[] = [];
            const studentIdNum = Number(rawId);
            let matchedStudent = !isNaN(studentIdNum) ? validStudentIdMap.get(studentIdNum) : undefined;
            if (!matchedStudent && typeof rawId === 'string') {
              matchedStudent = validStudentCodeMap.get(rawId.trim().toUpperCase());
            }

            if (isNaN(studentIdNum) && !matchedStudent) {
              errors.push(`Mã học sinh '${rawId}' không hợp lệ`);
            } else if (!matchedStudent) {
              errors.push(`Học sinh (Mã: ${rawId}) không thuộc lớp được chọn`);
            } else {
              const dupKey = `${matchedStudent.studentId}_${rawSubject}_${rawSemester}`;
              if (seenKeys.has(dupKey)) {
                errors.push(`Học sinh ${matchedStudent.studentName} (#${matchedStudent.studentId}) bị trùng lặp môn/học kỳ trong file`);
              }
              seenKeys.add(dupKey);
            }

            let attendanceScore: number | null = null;
            if (rawAttendance !== null && rawAttendance !== undefined && String(rawAttendance).trim() !== '') {
              const n = Number(rawAttendance);
              if (isNaN(n) || n < 0 || n > 10) {
                errors.push(`Điểm chuyên cần (${rawAttendance}) phải từ 0 đến 10`);
              } else {
                attendanceScore = Math.round(n * 10) / 10;
              }
            }

            let midtermScore: number | null = null;
            if (rawMidterm !== null && rawMidterm !== undefined && String(rawMidterm).trim() !== '') {
              const n = Number(rawMidterm);
              if (isNaN(n) || n < 0 || n > 10) {
                errors.push(`Điểm giữa kỳ (${rawMidterm}) phải từ 0 đến 10`);
              } else {
                midtermScore = Math.round(n * 10) / 10;
              }
            }

            let finalScore: number | null = null;
            if (rawFinal !== null && rawFinal !== undefined && String(rawFinal).trim() !== '') {
              const n = Number(rawFinal);
              if (isNaN(n) || n < 0 || n > 10) {
                errors.push(`Điểm cuối kỳ (${rawFinal}) phải từ 0 đến 10`);
              } else {
                finalScore = Math.round(n * 10) / 10;
              }
            }

            let predictedAverage: number | null = null;
            if (attendanceScore !== null && midtermScore !== null && finalScore !== null) {
              predictedAverage =
                Math.round(((attendanceScore + midtermScore * 2.0 + finalScore * 3.0) / 6.0) * 10.0) / 10.0;
            }

            const studentId = matchedStudent?.studentId || (isNaN(studentIdNum) ? 0 : studentIdNum);
            const studentName = rawName || matchedStudent?.studentName || `Học sinh #${studentId}`;

            const existingGrade = grades.find(
              (g) => g.studentId === studentId && (g.subjectCode === rawSubject || g.subjectName === rawSubject) && g.semester === rawSemester
            );
            const isUpdate = !!existingGrade;

            parsed.push({
              rowIndex: i + 1,
              studentId,
              studentCode: matchedStudent?.studentCode,
              studentName,
              subjectCode: rawSubject,
              subjectName: availableSubjects.find((s) => s.code === rawSubject)?.name || rawSubject,
              semester: isNaN(rawSemester) ? importSemester : rawSemester,
              attendanceScore,
              midtermScore,
              finalScore,
              score: null,
              predictedAverage,
              isUpdate,
              isValid: errors.length === 0,
              errors,
            });
          }
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
    return false;
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
      'Môn học': r.subjectCode,
      'Học kỳ': r.semester,
      'Điểm thi': r.score ?? '',
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

  // Thực hiện Batch Import điểm vào Backend
  const handleExecuteImport = () => {
    const validRows = parsedRows.filter((r) => r.isValid);
    if (validRows.length === 0) {
      message.error('Không có dòng dữ liệu hợp lệ nào để nhập.');
      return;
    }

    const newCount = validRows.filter((r) => !r.isUpdate).length;
    const updateCount = validRows.filter((r) => r.isUpdate).length;
    const currentClass = classes.find((c) => c.id === importClassId);
    const className = currentClass ? currentClass.className : `Lớp ${importClassId}`;

    Modal.confirm({
      title: 'Xác nhận nhập điểm vào hệ thống',
      icon: <UploadOutlined style={{ color: '#2563EB' }} />,
      content: (
        <div style={{ marginTop: 8 }}>
          <p>
            Bạn sắp import <strong>{validRows.length}</strong> bản ghi điểm cho <strong>{className}</strong>.
          </p>
          <p style={{ margin: '4px 0' }}>
            • Bản ghi mới: <strong style={{ color: '#16A34A' }}>{newCount}</strong>
          </p>
          <p style={{ margin: '4px 0' }}>
            • Bản ghi cập nhật: <strong style={{ color: '#2563EB' }}>{updateCount}</strong>
          </p>
          <p style={{ color: '#64748B', fontSize: 13, marginTop: 8 }}>
            Hệ thống sẽ chạy trong giao dịch an toàn (All-or-Nothing). Các điểm thành phần khác không thuộc đợt import sẽ được giữ nguyên vẹn.
          </p>
        </div>
      ),
      okText: 'Xác nhận Import',
      cancelText: 'Hủy bỏ',
      onOk: async () => {
        setIsImporting(true);
        setImportProgress({ current: 0, total: validRows.length });

        try {
          const importType =
            importMode === 'EXAM'
              ? examType === 'MIDTERM'
                ? 'IMPORT_MIDTERM'
                : 'IMPORT_FINAL'
              : 'IMPORT_ALL';

          const payload: GradeBatchImportRequest = {
            importType,
            classId: importClassId!,
            subjectCode: importMode === 'EXAM' ? importSubject : undefined,
            semester: importMode === 'EXAM' ? importSemester : undefined,
            items: validRows.map((r) => ({
              rowNumber: r.rowIndex,
              studentId: r.studentId,
              studentCode: r.studentCode,
              studentName: r.studentName,
              subjectCode: r.subjectCode,
              semester: r.semester,
              attendanceScore: r.attendanceScore,
              midtermScore: r.midtermScore,
              finalScore: r.finalScore,
              score: r.score,
            })),
          };

          const res = await gradeApi.batchImport(payload);

          if (res.success) {
            Modal.success({
              title: 'Nhập điểm thành công!',
              content: (
                <div style={{ marginTop: 8 }}>
                  <p>
                    ✓ <strong style={{ color: '#16A34A' }}>{res.createdCount}</strong> bản ghi mới đã được tạo.
                  </p>
                  <p>
                    ✓ <strong style={{ color: '#2563EB' }}>{res.updatedCount}</strong> bản ghi đã được cập nhật thành công.
                  </p>
                  <p style={{ color: '#64748B', fontSize: 13, marginTop: 8 }}>
                    Điểm trung bình và xếp loại học thuật đã được hệ thống tự động tính toán lại.
                  </p>
                </div>
              ),
              okText: 'Xem bảng điểm',
              onOk: () => {
                setSelectedSubject(importSubject);
                setSelectedSemester(importSemester);
                setActiveTab('bySubject');
                setParsedRows([]);
                setUploadedFileName('');
              },
            });

            // Invalidate React Query cache to refresh UI
            queryClient.invalidateQueries({ queryKey: ['classGrades', importClassId] });
            queryClient.invalidateQueries({ queryKey: ['classGrades', selectedClassId] });

            setParsedRows([]);
            setUploadedFileName('');
          } else {
            Modal.error({
              title: 'Nhập điểm không thành công',
              content: (
                <div>
                  <p>Hệ thống đã hủy bỏ giao dịch do phát hiện {res.failedCount} lỗi:</p>
                  <ul style={{ paddingLeft: 20, color: '#DC2626' }}>
                    {res.errors.slice(0, 5).map((e, idx) => (
                      <li key={idx}>
                        Dòng {e.rowNumber}: {e.message}
                      </li>
                    ))}
                  </ul>
                  {res.errors.length > 5 && <p>... và {res.errors.length - 5} lỗi khác.</p>}
                </div>
              ),
            });
          }
        } catch (err: any) {
          const errorMsg =
            err.response?.data?.errors?.[0]?.message ||
            err.response?.data?.error ||
            err.message ||
            'Có lỗi xảy ra khi import điểm';
          Modal.error({
            title: 'Lỗi trong quá trình Import',
            content: errorMsg,
          });
        } finally {
          setIsImporting(false);
          setImportProgress(null);
        }
      },
    });
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
  const previewColumns = useMemo(() => {
    const cols: any[] = [
      {
        title: 'Dòng',
        dataIndex: 'rowIndex',
        key: 'rowIndex',
        width: 65,
        align: 'center' as const,
      },
      {
        title: 'Mã HS',
        dataIndex: 'studentId',
        key: 'studentId',
        width: 100,
        align: 'center' as const,
        render: (id: number, record: ParsedExcelRow) => (
          <Tag color="blue">{record.studentCode || `#${id}`}</Tag>
        ),
      },
      {
        title: 'Học sinh',
        dataIndex: 'studentName',
        key: 'studentName',
        width: 170,
        render: (name: string) => <strong>{name}</strong>,
      },
      {
        title: 'Môn',
        dataIndex: 'subjectName',
        key: 'subjectName',
        width: 120,
        render: (name: string, record: ParsedExcelRow) => name || record.subjectCode,
      },
      {
        title: 'HK',
        dataIndex: 'semester',
        key: 'semester',
        width: 70,
        align: 'center' as const,
        render: (sem: number) => `HK${sem}`,
      },
    ];

    if (importMode === 'ALL') {
      cols.push(
        {
          title: 'Chuyên cần',
          dataIndex: 'attendanceScore',
          key: 'attendanceScore',
          width: 95,
          align: 'center' as const,
          render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
        },
        {
          title: 'Giữa kỳ',
          dataIndex: 'midtermScore',
          key: 'midtermScore',
          width: 90,
          align: 'center' as const,
          render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
        },
        {
          title: 'Cuối kỳ',
          dataIndex: 'finalScore',
          key: 'finalScore',
          width: 90,
          align: 'center' as const,
          render: (val: number | null) => (val !== null ? val.toFixed(1) : <Text type="secondary">—</Text>),
        },
        {
          title: 'TB dự kiến',
          dataIndex: 'predictedAverage',
          key: 'predictedAverage',
          width: 95,
          align: 'center' as const,
          render: (val: number | null) =>
            val !== null ? (
              <Tag color="cyan" style={{ fontWeight: 600 }}>
                {val.toFixed(2)}
              </Tag>
            ) : (
              <Text type="secondary">—</Text>
            ),
        }
      );
    } else {
      cols.push({
        title: examType === 'MIDTERM' ? 'Điểm Giữa kỳ' : 'Điểm Cuối kỳ',
        dataIndex: 'score',
        key: 'score',
        width: 125,
        align: 'center' as const,
        render: (val: number | null) =>
          val !== null ? (
            <strong style={{ color: '#2563EB', fontSize: 14 }}>{val.toFixed(1)}</strong>
          ) : (
            <Text type="secondary">—</Text>
          ),
      });
    }

    cols.push(
      {
        title: 'Loại thao tác',
        dataIndex: 'isUpdate',
        key: 'isUpdate',
        width: 110,
        align: 'center' as const,
        render: (isUpdate: boolean) =>
          isUpdate ? <Tag color="orange">Cập nhật</Tag> : <Tag color="green">Bản ghi mới</Tag>,
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
        render: (errors: string[], record: ParsedExcelRow) =>
          errors.length > 0 ? (
            <span style={{ color: '#DC2626', fontSize: 12, fontWeight: 500 }}>{errors.join('; ')}</span>
          ) : (
            <span style={{ color: '#16A34A', fontSize: 12 }}>
              {record.isUpdate ? 'Sẵn sàng cập nhật điểm' : 'Sẵn sàng tạo mới điểm'}
            </span>
          ),
      }
    );

    return cols;
  }, [importMode, examType]);

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
                    <div style={{ marginBottom: 16 }}>
                      <Title level={5} style={{ margin: 0, color: '#0F172A', textTransform: 'uppercase', letterSpacing: 0.5 }}>
                        Nhập điểm từ Excel
                      </Title>
                    </div>

                    <Row gutter={[24, 16]} align="middle">
                      {/* Lớp */}
                      <Col xs={24} sm={12} md={6}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                          <Text strong style={{ fontSize: 13, color: '#334155' }}>
                            Lớp:
                          </Text>
                          <Select
                            value={importClassId}
                            onChange={(val) => {
                              setImportClassId(val);
                              setSelectedClassId(val);
                              setParsedRows([]);
                              setUploadedFileName('');
                            }}
                            style={{ width: '100%' }}
                            options={classes.map((c) => ({
                              value: c.id,
                              label: `Lớp ${c.className}`,
                            }))}
                          />
                        </div>
                      </Col>

                      {/* Chế độ */}
                      <Col xs={24} sm={12} md={12}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                          <Text strong style={{ fontSize: 13, color: '#334155' }}>
                            Chế độ nhập:
                          </Text>
                          <Radio.Group
                            value={importMode}
                            onChange={(e) => {
                              setImportMode(e.target.value);
                              setParsedRows([]);
                              setUploadedFileName('');
                            }}
                          >
                            <Radio value="EXAM">Nhập điểm thi</Radio>
                            <Radio value="ALL">Nhập toàn bộ bảng điểm</Radio>
                          </Radio.Group>
                        </div>
                      </Col>
                    </Row>

                    <Divider style={{ margin: '16px 0' }} />

                    {/* Mode-specific controls */}
                    {importMode === 'EXAM' ? (
                      <Row gutter={[20, 16]} align="bottom">
                        <Col xs={24} sm={12} md={6}>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                            <Text strong style={{ fontSize: 13, color: '#334155' }}>
                              Môn học:
                            </Text>
                            <Select
                              value={importSubject}
                              onChange={(val) => {
                                setImportSubject(val);
                                setParsedRows([]);
                                setUploadedFileName('');
                              }}
                              style={{ width: '100%' }}
                              options={availableSubjects.map((s) => ({
                                value: s.code,
                                label: s.name,
                              }))}
                            />
                          </div>
                        </Col>

                        <Col xs={12} sm={6} md={4}>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                            <Text strong style={{ fontSize: 13, color: '#334155' }}>
                              Học kỳ:
                            </Text>
                            <Select
                              value={importSemester}
                              onChange={(val) => {
                                setImportSemester(val);
                                setParsedRows([]);
                                setUploadedFileName('');
                              }}
                              style={{ width: '100%' }}
                              options={[
                                { value: 1, label: 'HK1' },
                                { value: 2, label: 'HK2' },
                              ]}
                            />
                          </div>
                        </Col>

                        <Col xs={12} sm={6} md={5}>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                            <Text strong style={{ fontSize: 13, color: '#334155' }}>
                              Loại điểm:
                            </Text>
                            <Select
                              value={examType}
                              onChange={(val) => {
                                setExamType(val);
                                setParsedRows([]);
                                setUploadedFileName('');
                              }}
                              style={{ width: '100%' }}
                              options={[
                                { value: 'MIDTERM', label: 'Giữa kỳ' },
                                { value: 'FINAL', label: 'Cuối kỳ' },
                              ]}
                            />
                          </div>
                        </Col>

                        <Col xs={24} md={9} style={{ textAlign: 'right' }}>
                          <Space wrap>
                            <Button
                              type="default"
                              icon={<DownloadOutlined />}
                              onClick={handleDownloadTemplate}
                              style={{ fontWeight: 500 }}
                            >
                              Tải Excel mẫu (Điểm thi)
                            </Button>
                            <Button
                              type="dashed"
                              icon={<DownloadOutlined />}
                              onClick={handleDownloadFilledSample}
                              style={{ fontWeight: 500 }}
                            >
                              Tải mẫu có sẵn điểm
                            </Button>
                          </Space>
                        </Col>
                      </Row>
                    ) : (
                      <Row gutter={[20, 16]} align="middle" justify="space-between">
                        <Col xs={24} md={14}>
                          <div style={{ color: '#64748B', fontSize: 13 }}>
                            <p style={{ margin: '0 0 4px 0' }}>
                              <strong>Chế độ toàn bộ bảng điểm:</strong> File Excel chứa toàn bộ các cột điểm thành phần.
                            </p>
                            <code>StudentID | StudentName | Subject | Semester | Attendance | Midterm | Final</code>
                          </div>
                        </Col>
                        <Col xs={24} md={10} style={{ textAlign: 'right' }}>
                          <Space wrap>
                            <Button
                              type="default"
                              icon={<DownloadOutlined />}
                              onClick={handleDownloadTemplate}
                              style={{ fontWeight: 500 }}
                            >
                              Tải Excel mẫu (Toàn bộ)
                            </Button>
                            <Button
                              type="dashed"
                              icon={<DownloadOutlined />}
                              onClick={handleDownloadFilledSample}
                              style={{ fontWeight: 500 }}
                            >
                              Tải mẫu có sẵn điểm
                            </Button>
                          </Space>
                        </Col>
                      </Row>
                    )}
                  </Card>

                  {/* Step 2: Upload Area */}
                  <div style={{ marginBottom: 20 }}>
                    <Upload.Dragger
                      accept=".xlsx,.xls"
                      beforeUpload={handleFileUpload}
                      showUploadList={false}
                      style={{
                        padding: '28px 0',
                        backgroundColor: '#fff',
                        borderRadius: 12,
                        border: '2px dashed #93C5FD',
                      }}
                    >
                      <p className="ant-upload-drag-icon">
                        <InboxOutlined style={{ fontSize: 44, color: '#2563EB' }} />
                      </p>
                      <p className="ant-upload-text" style={{ fontSize: 15, fontWeight: 600, color: '#0F172A' }}>
                        {uploadedFileName
                          ? `Tệp đã chọn: ${uploadedFileName} (Bấm hoặc kéo thả tệp khác để thay thế)`
                          : 'Kéo thả file Excel (.xlsx, .xls) vào đây hoặc bấm để chọn tệp'}
                      </p>
                      <p className="ant-upload-hint" style={{ color: '#64748B', fontSize: 13 }}>
                        {importMode === 'EXAM' ? (
                          <>
                            Yêu cầu các cột: <code>StudentID</code> (hoặc Mã HS), <code>StudentName</code>,{' '}
                            <code>Score</code> (hoặc Điểm).
                          </>
                        ) : (
                          <>
                            Yêu cầu các cột: <code>StudentID</code>, <code>StudentName</code>, <code>Subject</code>,{' '}
                            <code>Semester</code>, <code>Attendance</code>, <code>Midterm</code>, <code>Final</code>.
                          </>
                        )}
                      </p>
                    </Upload.Dragger>
                  </div>

                  {/* Step 3: Validation & Preview */}
                  {parsedRows.length > 0 && (
                    <div>
                      {/* 5 Metrics Cards */}
                      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
                        <Col xs={12} sm={8} md={4} lg={4}>
                          <Card size="small" style={{ borderRadius: 8, textAlign: 'center', background: '#F8FAFC' }}>
                            <Statistic
                              title="Tổng bản ghi"
                              value={parsedRows.length}
                              valueStyle={{ fontSize: 20, fontWeight: 700 }}
                            />
                          </Card>
                        </Col>
                        <Col xs={12} sm={8} md={5} lg={5}>
                          <Card size="small" style={{ borderRadius: 8, textAlign: 'center', background: '#F0FDF4' }}>
                            <Statistic
                              title="Hợp lệ"
                              value={parsedRows.filter((r) => r.isValid).length}
                              valueStyle={{ fontSize: 20, fontWeight: 700, color: '#16A34A' }}
                            />
                          </Card>
                        </Col>
                        <Col xs={12} sm={8} md={5} lg={5}>
                          <Card
                            size="small"
                            style={{
                              borderRadius: 8,
                              textAlign: 'center',
                              background: parsedRows.some((r) => !r.isValid) ? '#FEF2F2' : '#F8FAFC',
                            }}
                          >
                            <Statistic
                              title="Lỗi dữ liệu"
                              value={parsedRows.filter((r) => !r.isValid).length}
                              valueStyle={{
                                fontSize: 20,
                                fontWeight: 700,
                                color: parsedRows.some((r) => !r.isValid) ? '#DC2626' : '#64748B',
                              }}
                            />
                          </Card>
                        </Col>
                        <Col xs={12} sm={8} md={5} lg={5}>
                          <Card size="small" style={{ borderRadius: 8, textAlign: 'center', background: '#F0F9FF' }}>
                            <Statistic
                              title="Bản ghi mới"
                              value={parsedRows.filter((r) => r.isValid && !r.isUpdate).length}
                              valueStyle={{ fontSize: 20, fontWeight: 700, color: '#0284C7' }}
                            />
                          </Card>
                        </Col>
                        <Col xs={12} sm={8} md={5} lg={5}>
                          <Card size="small" style={{ borderRadius: 8, textAlign: 'center', background: '#FFFBEB' }}>
                            <Statistic
                              title="Bản ghi cập nhật"
                              value={parsedRows.filter((r) => r.isValid && r.isUpdate).length}
                              valueStyle={{ fontSize: 20, fontWeight: 700, color: '#D97706' }}
                            />
                          </Card>
                        </Col>
                      </Row>

                      {/* Action Bar */}
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
                        <div>
                          {parsedRows.some((r) => !r.isValid) ? (
                            <Alert
                              type="error"
                              showIcon
                              message="Tệp chứa dữ liệu không hợp lệ"
                              description="Hệ thống từ chối import khi còn dòng dữ liệu lỗi. Vui lòng kiểm tra dòng báo đỏ bên dưới, sửa lại file và tải lại."
                            />
                          ) : (
                            <Alert
                              type="success"
                              showIcon
                              message="Dữ liệu kiểm tra hoàn toàn hợp lệ"
                              description={`Toàn bộ ${parsedRows.length} bản ghi đã sẵn sàng (${parsedRows.filter((r) => !r.isUpdate).length} bản ghi mới, ${parsedRows.filter((r) => r.isUpdate).length} bản ghi cập nhật).`}
                            />
                          )}
                        </div>

                        <Space size={12}>
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

                      {/* Preview Table */}
                      <Table
                        columns={previewColumns}
                        dataSource={parsedRows}
                        rowKey="rowIndex"
                        size="small"
                        bordered
                        pagination={{ pageSize: 20 }}
                        scroll={{ x: 1000 }}
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
