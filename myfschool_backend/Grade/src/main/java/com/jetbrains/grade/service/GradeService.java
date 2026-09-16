package com.jetbrains.grade.service;

import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.repository.GradeRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import com.jetbrains.grade.dto.GradeBatchImportItemDTO;
import com.jetbrains.grade.dto.GradeBatchImportRequest;
import com.jetbrains.grade.dto.GradeBatchImportResponse;
import com.jetbrains.grade.dto.GradeCreateRequest;
import com.jetbrains.grade.dto.GradeImportErrorDTO;
import com.jetbrains.grade.dto.GradeUpdateRequest;
import com.jetbrains.grade.model.SchoolClass;
import com.jetbrains.grade.model.SchoolYear;
import com.jetbrains.grade.model.Subject;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.SchoolYearRepository;
import com.jetbrains.grade.repository.SubjectRepository;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GradeService {

    private final GradeRepository gradeRepository;
    private final StudentRepository studentRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final SchoolYearRepository schoolYearRepository;
    private final SubjectRepository subjectRepository;
    private final NotificationService notificationService;
    private final com.jetbrains.grade.security.TeacherAssignmentEnforcer teacherAssignmentEnforcer;
    private final SecurityAuditService auditService;

    @Transactional(readOnly = true)
    public List<Grade> getAll() {
        // Enforce role check: students cannot view all grades in the entire school
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem danh sach diem toan truong");
        }
        if (SecurityUtils.isAdmin()) {
            return gradeRepository.findAll();
        }
        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        if (currentTeacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        return gradeRepository.findByTeacherScope(currentTeacherId);
    }

    @Transactional(readOnly = true)
    public org.springframework.data.domain.Page<Grade> getAll(org.springframework.data.domain.Pageable pageable) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem danh sach diem toan truong");
        }
        if (SecurityUtils.isAdmin()) {
            return gradeRepository.findAll(pageable);
        }
        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        if (currentTeacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        return gradeRepository.findByTeacherScope(currentTeacherId, pageable);
    }

    @Transactional(readOnly = true)
    public Optional<Grade> getById(Integer id) {
        Optional<Grade> gradeOpt = gradeRepository.findById(id);
        if (gradeOpt.isEmpty()) {
            return Optional.empty();
        }

        Grade grade = gradeOpt.get();

        // Enforce ownership check: student can only view their own grade
        if (SecurityUtils.isStudent()) {
            Integer currentStudentId = SecurityUtils.getCurrentStudentId();
            if (grade.getStudent() == null || !grade.getStudent().getId().equals(currentStudentId)) {
                throw new AccessDeniedException("Ban khong co quyen xem diem cua hoc sinh khac");
            }
        } else if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanViewGrade(currentTeacherId, grade);
        }

        return gradeOpt;
    }

    @Transactional(readOnly = true)
    public List<Grade> getByUserId(Integer userId) {
        // Enforce ownership check: student can only query their own user ID
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem diem cua hoc sinh khac");
            }
        }

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh cho User ID: " + userId));

        if (SecurityUtils.isAdmin() || SecurityUtils.isStudent()) {
            return gradeRepository.findByStudentId(student.getId());
        }

        // For Teacher: verify assignment to student's class
        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        teacherAssignmentEnforcer.assertCanViewStudentData(currentTeacherId, student);

        // If homeroom teacher, can see all grades of this student
        if (student.getSchoolClass() != null &&
                teacherAssignmentEnforcer.isHomeroomTeacher(currentTeacherId, student.getSchoolClass().getId())) {
            return gradeRepository.findByStudentId(student.getId());
        }

        // If subject teacher, can see only grades for assigned subjects
        return gradeRepository.findByStudentId(student.getId()).stream()
                .filter(g -> g.getSubject() != null && student.getSchoolClass() != null &&
                        teacherAssignmentEnforcer.isSubjectTeacher(currentTeacherId, student.getSchoolClass().getId(), g.getSubject().getId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<Grade> getMyGrades() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return getByUserId(currentUserId);
    }

    @Transactional(readOnly = true)
    public List<Grade> getByClassId(Integer classId) {
        // Students cannot view class-wide grade rosters
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem bang diem ca lop");
        }
        if (SecurityUtils.isAdmin()) {
            return gradeRepository.findByStudentSchoolClassId(classId);
        }

        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        if (!teacherAssignmentEnforcer.isAssignedToClass(currentTeacherId, classId)) {
            throw new AccessDeniedException("Giao vien khong duoc phan cong cho lop hoc nay");
        }

        // If homeroom teacher of this class, can view all grades of the class
        if (teacherAssignmentEnforcer.isHomeroomTeacher(currentTeacherId, classId)) {
            return gradeRepository.findByStudentSchoolClassId(classId);
        }

        // Subject teacher can only view grades of their assigned subject(s) in this class
        return gradeRepository.findByClassIdAndTeacherSubjectScope(classId, currentTeacherId);
    }

    @Transactional
    public Grade create(GradeCreateRequest req) {
        if (req.getStudentId() == null || req.getSubjectId() == null || req.getSchoolYearId() == null) {
            throw new IllegalArgumentException("Khong du thong tin: Student, Subject, SchoolYear");
        }

        Student student = studentRepository.findById(req.getStudentId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh cho ID: " + req.getStudentId()));
        Subject subject = subjectRepository.findById(req.getSubjectId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin mon hoc cho ID: " + req.getSubjectId()));
        SchoolYear schoolYear = schoolYearRepository.findById(req.getSchoolYearId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin nam hoc cho ID: " + req.getSchoolYearId()));

        Grade grade = new Grade();
        grade.setStudent(student);
        grade.setSubject(subject);
        grade.setSchoolYear(schoolYear);
        grade.setSemester(req.getSemester());
        grade.setAttendanceScore(req.getAttendanceScore() != null ? req.getAttendanceScore() : 0.0);
        grade.setMidtermScore(req.getMidtermScore() != null ? req.getMidtermScore() : 0.0);
        grade.setFinalScore(req.getFinalScore() != null ? req.getFinalScore() : 0.0);

        return create(grade);
    }

    @Transactional
    public Grade update(Integer id, GradeUpdateRequest req) {
        Grade grade = new Grade();
        grade.setAttendanceScore(req.getAttendanceScore());
        grade.setMidtermScore(req.getMidtermScore());
        grade.setFinalScore(req.getFinalScore());
        return update(id, grade);
    }

    @Transactional
    public Grade create(Grade grade) {
        // Enforce role check: students cannot create grades
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen tao diem");
        }

        if (grade.getStudent() == null || grade.getSubject() == null || grade.getSchoolYear() == null) {
            throw new IllegalArgumentException("Khong du thong tin: Student, Subject, SchoolYear");
        }

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanManageGrade(
                    currentTeacherId, grade.getStudent().getId(), grade.getSubject().getId());
        }

        if (gradeRepository.existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
                grade.getStudent().getId(), grade.getSubject().getId(), grade.getSchoolYear().getId(), grade.getSemester())) {
            throw new IllegalArgumentException("Hoc sinh da co diem mon nay trong hoc ky va nam hoc nay");
        }

        validateGradeScores(grade.getAttendanceScore(), grade.getMidtermScore(), grade.getFinalScore());

        grade.setId(null);
        grade.setCreatedAt(LocalDateTime.now());
        grade.setUpdatedAt(LocalDateTime.now());
        Grade saved = gradeRepository.save(grade);

        Grade result = gradeRepository.findById(saved.getId()).orElse(saved);

        if (result.getStudent() != null && result.getStudent().getUser() != null) {
            try {
                String subjectName = result.getSubject() != null ? result.getSubject().getSubjectName() : "môn học";
                notificationService.createNotification(
                        result.getStudent().getUser(),
                        "Điểm số mới",
                        String.format("Điểm môn %s đã được cập nhật vào bảng điểm của bạn.", subjectName),
                        "GRADE_UPDATE",
                        result.getId()
                );
            } catch (Exception e) {
                // best-effort
            }
        }

        return result;
    }

    @Transactional
    public Grade update(Integer id, Grade updatedData) {
        // Enforce role check: students cannot update grades
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen sua diem");
        }

        Grade existing = gradeRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Khong tim thay Grade ID: " + id));

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            Integer studentId = existing.getStudent() != null ? existing.getStudent().getId() : null;
            Integer subjectId = existing.getSubject() != null ? existing.getSubject().getId() : null;
            teacherAssignmentEnforcer.assertCanManageGrade(currentTeacherId, studentId, subjectId);
        }

        validateGradeScores(updatedData.getAttendanceScore(), updatedData.getMidtermScore(), updatedData.getFinalScore());

        existing.setAttendanceScore(updatedData.getAttendanceScore());
        existing.setMidtermScore(updatedData.getMidtermScore());
        existing.setFinalScore(updatedData.getFinalScore());
        existing.setUpdatedAt(LocalDateTime.now());

        Grade saved = gradeRepository.save(existing);
        Grade result = gradeRepository.findById(saved.getId()).orElse(saved);

        if (result.getStudent() != null && result.getStudent().getUser() != null) {
            try {
                String subjectName = result.getSubject() != null ? result.getSubject().getSubjectName() : "môn học";
                notificationService.createNotification(
                        result.getStudent().getUser(),
                        "Cập nhật điểm số",
                        String.format("Điểm môn %s của bạn đã được chỉnh sửa.", subjectName),
                        "GRADE_UPDATE",
                        result.getId()
                );
            } catch (Exception e) {
                // best-effort
            }
        }

        auditService.logSecurityEvent(
                "GRADE_UPDATE",
                SecurityUtils.getCurrentUserId(),
                SecurityUtils.getCurrentUsername(),
                SecurityUtils.getCurrentRoles(),
                "GRADE_" + id,
                "SUCCESS",
                String.format("Attendance=%.1f, Midterm=%.1f, Final=%.1f",
                        updatedData.getAttendanceScore(), updatedData.getMidtermScore(), updatedData.getFinalScore())
        );

        return result;
    }

    @Transactional
    public void delete(Integer id) {
        // Enforce role check: students cannot delete grades
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xoa diem");
        }

        Grade existing = gradeRepository.findById(id)
                .orElseThrow(() -> new java.util.NoSuchElementException("Khong tim thay Grade ID: " + id));

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            Integer studentId = existing.getStudent() != null ? existing.getStudent().getId() : null;
            Integer subjectId = existing.getSubject() != null ? existing.getSubject().getId() : null;
            teacherAssignmentEnforcer.assertCanManageGrade(currentTeacherId, studentId, subjectId);
        }

        gradeRepository.deleteById(id);

        auditService.logSecurityEvent(
                "GRADE_DELETE",
                SecurityUtils.getCurrentUserId(),
                SecurityUtils.getCurrentUsername(),
                SecurityUtils.getCurrentRoles(),
                "GRADE_" + id,
                "SUCCESS",
                "Deleted grade record ID " + id
        );
    }

    private void validateGradeScores(Double attendance, Double midterm, Double finalScore) {
        if (attendance != null && (attendance < 0.0 || attendance > 10.0)) {
            throw new IllegalArgumentException("Điểm chuyên cần phải nằm trong khoảng từ 0.0 đến 10.0");
        }
        if (midterm != null && (midterm < 0.0 || midterm > 10.0)) {
            throw new IllegalArgumentException("Điểm giữa kỳ phải nằm trong khoảng từ 0.0 đến 10.0");
        }
        if (finalScore != null && (finalScore < 0.0 || finalScore > 10.0)) {
            throw new IllegalArgumentException("Điểm cuối kỳ phải nằm trong khoảng từ 0.0 đến 10.0");
        }
    }

    @Transactional
    public GradeBatchImportResponse batchImport(GradeBatchImportRequest req) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền import điểm");
        }

        if (req == null) {
            throw new IllegalArgumentException("Yêu cầu import không hợp lệ");
        }

        String importType = req.getImportType();
        if (importType == null || (!importType.equals("IMPORT_ALL") && !importType.equals("IMPORT_MIDTERM") && !importType.equals("IMPORT_FINAL"))) {
            throw new IllegalArgumentException("Loại import không hợp lệ: " + importType + ". Hệ thống hỗ trợ: IMPORT_ALL, IMPORT_MIDTERM, IMPORT_FINAL");
        }

        if (req.getItems() == null || req.getItems().isEmpty()) {
            throw new IllegalArgumentException("Danh sách điểm import trống");
        }

        if (req.getClassId() == null) {
            throw new IllegalArgumentException("Vui lòng chọn lớp học cần import");
        }

        SchoolClass schoolClass = schoolClassRepository.findById(req.getClassId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học có ID: " + req.getClassId()));

        SchoolYear schoolYear;
        if (req.getSchoolYearId() != null) {
            schoolYear = schoolYearRepository.findById(req.getSchoolYearId())
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy năm học có ID: " + req.getSchoolYearId()));
        } else {
            schoolYear = schoolYearRepository.findByIsActiveTrue()
                    .orElseGet(() -> schoolYearRepository.findAll().stream().findFirst()
                            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy năm học hợp lệ trong hệ thống")));
        }

        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        if (!SecurityUtils.isAdmin()) {
            if (currentTeacherId == null) {
                throw new AccessDeniedException("Không tìm thấy thông tin giáo viên hợp lệ");
            }
        }

        List<Student> classStudents = studentRepository.findBySchoolClassId(req.getClassId());
        Map<Integer, Student> studentById = classStudents.stream()
                .collect(Collectors.toMap(Student::getId, s -> s));
        Map<String, Student> studentByCode = classStudents.stream()
                .filter(s -> s.getStudentCode() != null)
                .collect(Collectors.toMap(s -> s.getStudentCode().trim().toUpperCase(), s -> s, (a, b) -> a));

        List<Subject> allSubjects = subjectRepository.findAll();
        Map<Integer, Subject> subjectById = allSubjects.stream()
                .collect(Collectors.toMap(Subject::getId, s -> s));
        Map<String, Subject> subjectByCode = allSubjects.stream()
                .collect(Collectors.toMap(s -> s.getSubjectCode().trim().toUpperCase(), s -> s, (a, b) -> a));

        Subject commonSubject = null;
        if (!"IMPORT_ALL".equals(importType)) {
            if (req.getSubjectId() != null) {
                commonSubject = subjectById.get(req.getSubjectId());
            } else if (req.getSubjectCode() != null) {
                commonSubject = subjectByCode.get(req.getSubjectCode().trim().toUpperCase());
            }
            if (commonSubject == null) {
                throw new IllegalArgumentException("Môn học không hợp lệ cho import điểm thi");
            }

            if (!SecurityUtils.isAdmin()) {
                if (!teacherAssignmentEnforcer.isSubjectTeacher(currentTeacherId, req.getClassId(), commonSubject.getId())) {
                    throw new AccessDeniedException("Giáo viên không được phân công dạy môn " + commonSubject.getSubjectName() + " cho lớp " + schoolClass.getClassName());
                }
            }

            if (req.getSemester() == null || (req.getSemester() != 1 && req.getSemester() != 2)) {
                throw new IllegalArgumentException("Học kỳ không hợp lệ (chỉ chấp nhận 1 hoặc 2)");
            }
        }

        List<GradeImportErrorDTO> errors = new ArrayList<>();
        Set<String> seenKeys = new HashSet<>();

        for (int i = 0; i < req.getItems().size(); i++) {
            GradeBatchImportItemDTO item = req.getItems().get(i);
            int rowNum = item.getRowNumber() != null ? item.getRowNumber() : (i + 1);

            Student student = null;
            if (item.getStudentId() != null) {
                student = studentById.get(item.getStudentId());
                if (student == null) {
                    boolean existsGlobal = studentRepository.existsById(item.getStudentId());
                    if (existsGlobal) {
                        errors.add(GradeImportErrorDTO.builder()
                                .rowNumber(rowNum)
                                .studentId(item.getStudentId())
                                .studentCode(item.getStudentCode())
                                .studentName(item.getStudentName())
                                .field("studentId")
                                .message("Học sinh không thuộc lớp " + schoolClass.getClassName())
                                .build());
                    } else {
                        errors.add(GradeImportErrorDTO.builder()
                                .rowNumber(rowNum)
                                .studentId(item.getStudentId())
                                .studentCode(item.getStudentCode())
                                .studentName(item.getStudentName())
                                .field("studentId")
                                .message("Không tìm thấy học sinh có ID: " + item.getStudentId())
                                .build());
                    }
                }
            } else if (item.getStudentCode() != null && !item.getStudentCode().trim().isEmpty()) {
                student = studentByCode.get(item.getStudentCode().trim().toUpperCase());
                if (student == null) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentCode(item.getStudentCode())
                            .studentName(item.getStudentName())
                            .field("studentCode")
                            .message("Học sinh mã " + item.getStudentCode() + " không thuộc lớp " + schoolClass.getClassName())
                            .build());
                }
            } else {
                errors.add(GradeImportErrorDTO.builder()
                        .rowNumber(rowNum)
                        .studentName(item.getStudentName())
                        .field("studentId")
                        .message("Thiếu thông tin mã học sinh (StudentID hoặc StudentCode)")
                        .build());
            }

            Subject itemSubject = commonSubject;
            Integer itemSemester = req.getSemester();

            if ("IMPORT_ALL".equals(importType)) {
                if (item.getSubjectId() != null) {
                    itemSubject = subjectById.get(item.getSubjectId());
                } else if (item.getSubjectCode() != null && !item.getSubjectCode().trim().isEmpty()) {
                    itemSubject = subjectByCode.get(item.getSubjectCode().trim().toUpperCase());
                } else if (req.getSubjectId() != null) {
                    itemSubject = subjectById.get(req.getSubjectId());
                } else if (req.getSubjectCode() != null) {
                    itemSubject = subjectByCode.get(req.getSubjectCode().trim().toUpperCase());
                }

                if (itemSubject == null) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("subject")
                            .message("Không tìm thấy môn học: " + (item.getSubjectCode() != null ? item.getSubjectCode() : item.getSubjectId()))
                            .build());
                } else if (!SecurityUtils.isAdmin()) {
                    if (!teacherAssignmentEnforcer.isSubjectTeacher(currentTeacherId, req.getClassId(), itemSubject.getId())) {
                        errors.add(GradeImportErrorDTO.builder()
                                .rowNumber(rowNum)
                                .studentId(item.getStudentId())
                                .field("subject")
                                .message("Giáo viên không có quyền nhập điểm môn " + itemSubject.getSubjectName() + " cho lớp này")
                                .build());
                    }
                }

                if (item.getSemester() != null) {
                    itemSemester = item.getSemester();
                }
                if (itemSemester == null || (itemSemester != 1 && itemSemester != 2)) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("semester")
                            .message("Học kỳ không hợp lệ (phải là 1 hoặc 2)")
                            .build());
                }
            }

            if (student != null && itemSubject != null && itemSemester != null) {
                String dupKey = student.getId() + "_" + itemSubject.getId() + "_" + itemSemester;
                if (!seenKeys.add(dupKey)) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(student.getId())
                            .studentCode(student.getStudentCode())
                            .studentName(student.getFullName())
                            .field("duplicate")
                            .message("Bị trùng lặp bản ghi trong file cho học sinh " + student.getFullName() + " (Môn " + itemSubject.getSubjectName() + ", HK" + itemSemester + ")")
                            .build());
                }
            }

            if ("IMPORT_MIDTERM".equals(importType)) {
                Double score = item.getScore() != null ? item.getScore() : item.getMidtermScore();
                if (score == null) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("score")
                            .message("Thiếu điểm giữa kỳ")
                            .build());
                } else if (score < 0.0 || score > 10.0) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("score")
                            .message("Điểm giữa kỳ phải nằm trong khoảng từ 0.0 đến 10.0 (giá trị hiện tại: " + score + ")")
                            .build());
                }
            } else if ("IMPORT_FINAL".equals(importType)) {
                Double score = item.getScore() != null ? item.getScore() : item.getFinalScore();
                if (score == null) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("score")
                            .message("Thiếu điểm cuối kỳ")
                            .build());
                } else if (score < 0.0 || score > 10.0) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("score")
                            .message("Điểm cuối kỳ phải nằm trong khoảng từ 0.0 đến 10.0 (giá trị hiện tại: " + score + ")")
                            .build());
                }
            } else if ("IMPORT_ALL".equals(importType)) {
                if (item.getAttendanceScore() != null && (item.getAttendanceScore() < 0.0 || item.getAttendanceScore() > 10.0)) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("attendanceScore")
                            .message("Điểm chuyên cần phải nằm trong khoảng 0.0 đến 10.0")
                            .build());
                }
                if (item.getMidtermScore() != null && (item.getMidtermScore() < 0.0 || item.getMidtermScore() > 10.0)) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("midtermScore")
                            .message("Điểm giữa kỳ phải nằm trong khoảng 0.0 đến 10.0")
                            .build());
                }
                if (item.getFinalScore() != null && (item.getFinalScore() < 0.0 || item.getFinalScore() > 10.0)) {
                    errors.add(GradeImportErrorDTO.builder()
                            .rowNumber(rowNum)
                            .studentId(item.getStudentId())
                            .field("finalScore")
                            .message("Điểm cuối kỳ phải nằm trong khoảng 0.0 đến 10.0")
                            .build());
                }
            }
        }

        if (!errors.isEmpty()) {
            return GradeBatchImportResponse.builder()
                    .success(false)
                    .totalProcessed(req.getItems().size())
                    .createdCount(0)
                    .updatedCount(0)
                    .failedCount(errors.size())
                    .errors(errors)
                    .build();
        }

        int createdCount = 0;
        int updatedCount = 0;

        for (GradeBatchImportItemDTO item : req.getItems()) {
            Student student = item.getStudentId() != null
                    ? studentById.get(item.getStudentId())
                    : studentByCode.get(item.getStudentCode().trim().toUpperCase());

            Subject subject = commonSubject;
            Integer semester = req.getSemester();
            if ("IMPORT_ALL".equals(importType)) {
                if (item.getSubjectId() != null) {
                    subject = subjectById.get(item.getSubjectId());
                } else if (item.getSubjectCode() != null) {
                    subject = subjectByCode.get(item.getSubjectCode().trim().toUpperCase());
                }
                if (item.getSemester() != null) {
                    semester = item.getSemester();
                }
            }

            Optional<Grade> existingOpt = gradeRepository.findByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
                    student.getId(), subject.getId(), schoolYear.getId(), semester);

            if (existingOpt.isPresent()) {
                Grade existing = existingOpt.get();
                if ("IMPORT_MIDTERM".equals(importType)) {
                    Double score = item.getScore() != null ? item.getScore() : item.getMidtermScore();
                    existing.setMidtermScore(score);
                } else if ("IMPORT_FINAL".equals(importType)) {
                    Double score = item.getScore() != null ? item.getScore() : item.getFinalScore();
                    existing.setFinalScore(score);
                } else {
                    if (item.getAttendanceScore() != null) existing.setAttendanceScore(item.getAttendanceScore());
                    if (item.getMidtermScore() != null) existing.setMidtermScore(item.getMidtermScore());
                    if (item.getFinalScore() != null) existing.setFinalScore(item.getFinalScore());
                }
                existing.setUpdatedAt(LocalDateTime.now());
                gradeRepository.save(existing);
                updatedCount++;
            } else {
                Grade newGrade = new Grade();
                newGrade.setStudent(student);
                newGrade.setSubject(subject);
                newGrade.setSchoolYear(schoolYear);
                newGrade.setSemester(semester);

                if ("IMPORT_MIDTERM".equals(importType)) {
                    Double score = item.getScore() != null ? item.getScore() : item.getMidtermScore();
                    newGrade.setMidtermScore(score != null ? score : 0.0);
                    newGrade.setAttendanceScore(0.0);
                    newGrade.setFinalScore(0.0);
                } else if ("IMPORT_FINAL".equals(importType)) {
                    Double score = item.getScore() != null ? item.getScore() : item.getFinalScore();
                    newGrade.setFinalScore(score != null ? score : 0.0);
                    newGrade.setAttendanceScore(0.0);
                    newGrade.setMidtermScore(0.0);
                } else {
                    newGrade.setAttendanceScore(item.getAttendanceScore() != null ? item.getAttendanceScore() : 0.0);
                    newGrade.setMidtermScore(item.getMidtermScore() != null ? item.getMidtermScore() : 0.0);
                    newGrade.setFinalScore(item.getFinalScore() != null ? item.getFinalScore() : 0.0);
                }
                newGrade.setCreatedAt(LocalDateTime.now());
                newGrade.setUpdatedAt(LocalDateTime.now());
                gradeRepository.save(newGrade);
                createdCount++;
            }
        }

        auditService.logSecurityEvent(
                "GRADE_BATCH_IMPORT",
                SecurityUtils.getCurrentUserId(),
                SecurityUtils.getCurrentUsername(),
                SecurityUtils.getCurrentRoles(),
                "CLASS_" + req.getClassId(),
                "SUCCESS",
                String.format("ImportType=%s, Created=%d, Updated=%d, Total=%d",
                        importType, createdCount, updatedCount, req.getItems().size())
        );

        return GradeBatchImportResponse.builder()
                .success(true)
                .totalProcessed(req.getItems().size())
                .createdCount(createdCount)
                .updatedCount(updatedCount)
                .failedCount(0)
                .errors(Collections.emptyList())
                .build();
    }
}