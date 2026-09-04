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
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class GradeService {

    private final GradeRepository gradeRepository;
    private final StudentRepository studentRepository;
    private final NotificationService notificationService;
    private final com.jetbrains.grade.security.TeacherAssignmentEnforcer teacherAssignmentEnforcer;
    private final SecurityAuditService auditService;

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

    public List<Grade> getMyGrades() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return getByUserId(currentUserId);
    }

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
}